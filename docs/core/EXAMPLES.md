# Semaphore Core Examples

This document provides practical, copy-paste-ready examples for using the **Semaphore Core** module. These examples cover the lifecycle of creating, locking, unlocking, closing, and cleaning up cross-process native semaphores.

## 1. Basic Usage

### Instantiating and using a Native Semaphore

This basic example demonstrates how to instantiate a native semaphore by name, open it, lock it across processes, perform some work, and cleanly release it.

```dart
import 'package:runtime_native_semaphores/runtime_native_semaphores.dart';

void main() {
  // 1. Instantiate the semaphore
  // The underlying implementation (UnixSemaphore or WindowsSemaphore) 
  // is automatically determined based on the host platform.
  final semaphore = NativeSemaphore.instantiate(
    name: 'my_global_resource_semaphore',
    verbose: true,
  );

  try {
    // 2. Open the semaphore (creates it if it doesn't exist)
    final bool opened = semaphore.open();
    if (!opened) {
      print('Failed to open the semaphore.');
      return;
    }

    // 3. Lock the semaphore
    // This blocks the current isolate/process until the lock is acquired
    print('Waiting to acquire lock...');
    final bool locked = semaphore.lock(blocking: true);
    
    if (locked) {
      print('Lock acquired! Performing protected work...');
      // Simulate some critical section work
      // ...
    }
  } finally {
    // 4. Unlock the semaphore if we successfully locked it
    if (semaphore.locked) {
      semaphore.unlock();
      print('Semaphore unlocked.');
    }

    // 5. Close the local handle to the semaphore
    if (semaphore.opened && !semaphore.locked) {
      semaphore.close();
      print('Semaphore closed.');
    }

    // 6. Unlink the semaphore from the system (if no longer needed by any process)
    if (semaphore.closed && !semaphore.unlinked) {
      semaphore.unlink();
      print('Semaphore unlinked from system.');
    }
  }
}
```

## 2. Common Workflows

### Reentrant Locking within the Same Isolate

The NativeSemaphore module is designed to track process and isolate counts, enabling reentrant locks within the same isolate.

```dart
import 'package:runtime_native_semaphores/runtime_native_semaphores.dart';

void main() {
  final semaphore = NativeSemaphore.instantiate(
    name: 'reentrant_test_semaphore',
  );

  semaphore.open();

  // Initial lock (cross-process boundary)
  semaphore.lock(blocking: true);
  print('Outer lock acquired. Is reentrant? ${semaphore.reentrant}');

  // Reentrant lock (same isolate, simply increments internal counter)
  semaphore.lock(blocking: true);
  print('Inner lock acquired. Is reentrant? ${semaphore.reentrant}'); // true

  // Inner unlock
  semaphore.unlock();
  print('Inner lock released.');

  // Outer unlock (releases across-process boundary)
  semaphore.unlock();
  print('Outer lock released.');

  semaphore.close();
  semaphore.unlink();
}
```

### Checking Semaphore Status and Counts

You can introspect the current status of the semaphore using its properties.

```dart
import 'package:runtime_native_semaphores/runtime_native_semaphores.dart';

void main() {
  final semaphore = NativeSemaphore.instantiate(name: 'status_semaphore');
  
  semaphore.open();
  semaphore.lock();

  // Inspect internal boolean states
  print('Is Opened: ${semaphore.opened}');
  print('Is Locked: ${semaphore.locked}');
  print('Is Closed: ${semaphore.closed}');
  print('Is Unlinked: ${semaphore.unlinked}');

  // Inspect internal counters via the SemaphoreCounter
  final counters = semaphore.counter.counts;
  print('Current Process lock count: ${counters.process.get()}');
  print('Current Isolate reentrant count: ${counters.isolate.get()}');
  
  // Clean up
  semaphore.unlock();
  semaphore.close();
  semaphore.unlink();
}
```

## 3. Error Handling

### Catching and Handling Platform-Specific Exceptions

The NativeSemaphore throws platform-specific errors if something goes wrong under the hood. For instance, on Unix systems, `UnixSemOpenError` or `UnixSemUnlinkError` might be thrown.

```dart
import 'package:runtime_native_semaphores/runtime_native_semaphores.dart';
import 'dart:io' show Platform;

void main() {
  final semaphore = NativeSemaphore.instantiate(
    // Intentionally using an invalid name to trigger an error
    name: 'invalid/name/with/slashes/that/is/way/too/long/for/the/system/to/handle/properly',
  );

  try {
    semaphore.open();
  } catch (e) {
    if (Platform.isMacOS || Platform.isLinux) {
      if (e is UnixSemOpenError) {
        print('Failed to open Unix semaphore: ${e.message} (Code: ${e.code})');
        
        // Match specific error codes if necessary
        if (e.code == UnixSemOpenMacros.ENAMETOOLONG) {
          print('The provided name was too long!');
        }
      } else {
        print('An unexpected Unix error occurred: $e');
      }
    } else if (Platform.isWindows) {
      if (e is WindowsCreateSemaphoreWError) {
        print('Failed to create Windows semaphore: ${e.message} (Code: ${e.code})');
        
        if (e.code == WindowsCreateSemaphoreWMacros.ERROR_INVALID_NAME) {
          print('Invalid characters in the semaphore name!');
        }
      }
    }
  }
}
```

### Safe Cleanup Using Try-Catch

If an error is thrown while the lock is acquired, it's critical to ensure resources are cleaned up.

```dart
import 'package:runtime_native_semaphores/runtime_native_semaphores.dart';

void safeExecution() {
  final semaphore = NativeSemaphore.instantiate(name: 'safe_exec_semaphore');
  
  if (!semaphore.open()) return;

  try {
    if (semaphore.lock(blocking: true)) {
      // Perform task that might throw
      throw Exception('Something went wrong during execution!');
    }
  } catch (e) {
    print('Caught exception: $e');
  } finally {
    // Always check locked status before attempting to unlock
    if (semaphore.locked) {
      semaphore.unlock();
    }
    
    // Always check opened status before attempting to close
    if (semaphore.opened && !semaphore.closed) {
      semaphore.close();
    }
    
    if (semaphore.closed && !semaphore.unlinked) {
      semaphore.unlink();
    }
  }
}
```

## 4. Advanced Usage

### Using Custom Identities and Identity Tracking

Under the hood, `NativeSemaphore` manages instances based on a `SemaphoreIdentity` and Tracks locks/unlocks across isolates and processes using `SemaphoreCounters`. You can explicitly instantiate these or manage deletion.

```dart
import 'package:runtime_native_semaphores/runtime_native_semaphores.dart';

void main() {
  final identity = SemaphoreIdentity.instantiate(name: 'custom_identity_sem');
  print('Semaphore Identity UUID: ${identity.uuid}');
  print('Isolate ID: ${identity.isolate}');
  print('Process ID: ${identity.process}');

  // Inject the custom identity
  final semaphore = NativeSemaphore.instantiate(
    name: 'custom_identity_sem',
    identity: identity,
  );

  semaphore.open();
  semaphore.lock();
  
  // The identity address is bound once opened
  print('Semaphore native address: ${identity.address}');

  semaphore.unlock();
  semaphore.close();
  semaphore.unlink();
  
  // Explicitly delete identities or counters if you are managing a large number of dynamic semaphores
  final identitiesTracker = SemaphoreIdentities();
  if (identitiesTracker.has(name: 'custom_identity_sem')) {
    identitiesTracker.delete(name: 'custom_identity_sem');
  }

  final semaphoresTracker = NativeSemaphores();
  if (semaphoresTracker.has(name: 'custom_identity_sem')) {
    semaphoresTracker.delete(name: 'custom_identity_sem');
  }
}
```

### Try-Lock (Non-blocking)

You can attempt to lock a semaphore without blocking the execution thread. If the semaphore is already locked by another process, it will immediately return false.

```dart
import 'package:runtime_native_semaphores/runtime_native_semaphores.dart';

void main() {
  final semaphore = NativeSemaphore.instantiate(name: 'try_lock_semaphore');
  semaphore.open();

  // Attempt to lock but don't wait if it's currently held
  final bool acquired = semaphore.lock(blocking: false);

  if (acquired) {
    print('Successfully acquired lock immediately.');
    
    // ... work ...
    
    semaphore.unlock();
  } else {
    print('Could not acquire lock immediately. Another process holds it.');
  }

  semaphore.close();
  semaphore.unlink();
}
```
