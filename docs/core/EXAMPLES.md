# Semaphore Core: Practical Examples

This document provides comprehensive, copy-paste-ready Dart examples for the `runtime_native_semaphores` package. It covers everything from basic semaphore usage to advanced configurations, manual identity management, platform-specific error handling, and accessing global registries.

## 1. Basic Usage

The most common workflow involves instantiating a named semaphore, opening it, locking it for a critical section, unlocking it, and finally cleaning up resources. The `NativeSemaphore.instantiate` factory automatically creates a `UnixSemaphore` or `WindowsSemaphore` depending on the platform.

```dart
import 'dart:io';
import 'package:runtime_native_semaphores/runtime_native_semaphores.dart';

void main() {
  // 1. Instantiate the semaphore wrapper. 
  // It automatically tracks instances in a global NativeSemaphores registry.
  final semaphore = NativeSemaphore.instantiate(
    name: 'my_first_semaphore',
    verbose: true, // Set to true to print lifecycle debug logs
  );

  // 2. Open (creates or connects to the native named semaphore)
  if (semaphore.open()) {
    print('Semaphore opened successfully.');
  }

  // 3. Lock the semaphore (blocking until acquired)
  print('Attempting to acquire lock...');
  semaphore.lock(blocking: true);

  try {
    // Perform work in critical section...
    print('Lock acquired. In critical section.');
    
    // You can inspect the underlying state
    print('Is Locked? ${semaphore.locked}');
    print('Is Reentrant? ${semaphore.reentrant}');
    
    // Check lifecycle statuses
    print('Is Opened? ${semaphore.opened}');
    print('Is Closed? ${semaphore.closed}');
    print('Is Unlinked? ${semaphore.unlinked}');
    
  } finally {
    // 4. Unlock the semaphore across processes/isolates
    semaphore.unlock();
    print('Lock released.');
  }

  // 5. Close the semaphore handle (frees local memory/handles)
  semaphore.close();

  // 6. Unlink the semaphore from the system (removes the named semaphore entirely)
  // Note: On Windows, unlinking is a no-op but frees Dart-side identifier memory.
  semaphore.unlink();
}
```

## 2. Common Workflows

### Non-Blocking Try-Lock & Reentrancy

Semaphores natively support reentrant locking within the same Dart isolate using the `SemaphoreCounter` subsystem (`SemaphoreCounts`, `SemaphoreCount`). This allows a single isolate to acquire the same lock multiple times without deadlocking.

```dart
import 'package:runtime_native_semaphores/runtime_native_semaphores.dart';

void main() {
  final semaphore = NativeSemaphore.instantiate(name: 'workflow_semaphore');
  semaphore.open();

  // Try to lock without blocking
  bool acquired = semaphore.lock(blocking: false);

  if (acquired) {
    try {
      print('Initial lock acquired.');
      
      // The process count tracks locks across native OS processes.
      // The isolate count tracks reentrant locks within the Dart isolate.
      print('Process lock count: ${semaphore.counter.counts.process.get()}');
      print('Isolate lock count: ${semaphore.counter.counts.isolate.get()}');

      // Reentrant Lock: Safely acquire the lock again in the same isolate
      semaphore.lock();
      try {
        print('Reentrant lock acquired.');
        print('Updated isolate lock count: ${semaphore.counter.counts.isolate.get()}');
      } finally {
        // Unlock the reentrant lock
        semaphore.unlock();
      }

    } finally {
      // Final unlock across the OS process
      semaphore.unlock();
    }
  } else {
    print('Semaphore is currently locked by another process.');
  }

  semaphore.close();
  semaphore.unlink();
}
```

## 3. Error Handling

The package provides rich, platform-specific error handling. When interacting with POSIX/Unix systems, you may encounter subclasses of `UnixSemError`. On Windows, you will see `WindowsCreateSemaphoreWError` and `WindowsReleaseSemaphoreError`.

```dart
import 'dart:io';
import 'package:runtime_native_semaphores/runtime_native_semaphores.dart';

void main() {
  // Catching limits early
  // UnixSemLimits.NAME_MAX_CHARACTERS (30) ensures cross-platform compatibility
  final String tooLongName = 'this_name_exceeds_the_maximum_allowed_length_for_a_semaphore';
  
  try {
    final semaphore = NativeSemaphore.instantiate(name: tooLongName);
    semaphore.open();
  } on ArgumentError catch (e) {
    print('ArgumentError caught successfully: $e');
  }

  final semaphore = NativeSemaphore.instantiate(name: 'error_handling_test');
  
  try {
    semaphore.open();
    semaphore.lock();
    semaphore.unlock();
    semaphore.close();
    semaphore.unlink();
    
    // Attempting to unlink again usually throws a platform error
    semaphore.unlink(); 
    
  } catch (e) {
    // Platform-specific error routing
    if (Platform.isMacOS || Platform.isLinux) {
      if (e is UnixSemOpenError) {
        print('Failed to open: ${e.message} (Errno: ${e.code})');
        // Matches macros like UnixSemOpenMacros.EACCES or UnixSemOpenMacros.EEXIST
      } else if (e is UnixSemOpenErrorUnixSemWaitOrTryWaitError) {
        print('Wait/TryWait failed: ${e.message}');
        // Matches macros like UnixSemWaitOrTryWaitMacros.EAGAIN
      } else if (e is UnixSemUnlockWithPostError) {
        print('Post/Unlock failed: ${e.message}');
        // Matches macros like UnixSemUnlockWithPostMacros.EOVERFLOW
      } else if (e is UnixSemCloseError) {
        print('Close failed: ${e.message} (Errno: ${e.code})');
        // Matches macros like UnixSemCloseMacros.EINVAL
      } else if (e is UnixSemUnlinkError) {
        print('Unlink failed: ${e.message} (Errno: ${e.code})');
        // Matches macros like UnixSemUnlinkMacros.ENOENT
      } else if (e is UnixSemError) {
        print('Generic Unix Semaphore Error: ${e.message}');
      }
    } else if (Platform.isWindows) {
      if (e is WindowsCreateSemaphoreWError) {
        print('Windows Create Error: ${e.message} (Code: ${e.code})');
        // Matches macros like WindowsCreateSemaphoreWMacros.ERROR_ACCESS_DENIED
      } else if (e is WindowsReleaseSemaphoreError) {
        print('Windows Release Error: ${e.message} (Code: ${e.code})');
        // Matches macros like WindowsReleaseSemaphoreMacros.ERROR_SEM_OVERFLOW
      }
    }
  }
}
```

## 4. Advanced Usage

For complex applications, you can take manual control of `SemaphoreIdentity`, `SemaphoreCount`, and the registry singletons (`NativeSemaphores`, `SemaphoreIdentities`, `SemaphoreCounters`).

```dart
import 'package:runtime_native_semaphores/runtime_native_semaphores.dart';

void main() {
  final String semName = 'advanced_custom_semaphore';

  // 1. Manually instantiate an Identity (tracked in SemaphoreIdentities)
  final SemaphoreIdentity identity = SemaphoreIdentity.instantiate(name: semName);
  
  print('Identity UUID: ${identity.uuid}');
  print('Current Isolate: ${identity.isolate}');
  print('Current Process ID: ${identity.process}');

  // 2. Manually instantiate the Counter subsystem (tracked in SemaphoreCounters)
  final SemaphoreCounter counter = SemaphoreCounter.instantiate(identity: identity);

  // Optional: Listen to or inspect raw Counter classes directly
  // Features SemaphoreCountUpdate and SemaphoreCountDeletion tracking under the hood
  SemaphoreCount processCount = counter.counts.process;
  SemaphoreCount isolateCount = counter.counts.isolate;

  // 3. Inject identity and counter into NativeSemaphore
  final semaphore = NativeSemaphore.instantiate(
    name: semName,
    identity: identity,
    counter: counter,
    verbose: true,
  );

  // Advanced POSIX limits and permission checks via macros:
  print('Recommended POSIX Perms: ${MODE_T_PERMISSIONS.RECOMMENDED}'); // typically 0644
  print('Unix Path Max: ${UnixSemLimits.PATH_MAX}');
  print('Unix Name Max: ${UnixSemLimits.NAME_MAX}');
  
  // Advanced Windows macro properties:
  print('Windows Global Prefix: ${WindowsCreateSemaphoreWMacros.GLOBAL_NAME_PREFIX}');
  print('Windows Wait Object 0: ${WindowsWaitForSingleObjectMacros.WAIT_OBJECT_0}');
  print('Windows Close Invalid Handle: ${WindowsCloseHandleMacros.INVALID_HANDLE_VALUE}');

  semaphore.open();
  
  if (semaphore.lock(blocking: false)) {
    try {
      print('Advanced lock acquired!');
    } finally {
      semaphore.unlock();
    }
  }

  semaphore.close();
  semaphore.unlink();
}
```

## 5. Investigating the Registry

The global registries tracking your semaphore instances, identities, and counters can be queried to debug your application. Since dart types are heavily genericized, we can access the underlying singletons or cache properties via reflection or directly.

```dart
import 'package:runtime_native_semaphores/runtime_native_semaphores.dart';

void main() {
  final semaphore = NativeSemaphore.instantiate(name: 'registry_test');
  
  // The identity registry maintains all SemaphoreIdentity instances
  final SemaphoreIdentity identity = semaphore.identity;
  
  // We can query internal counts directly
  print('Isolate count for ${identity.name}: ${semaphore.counter.counts.isolate.get()}');
  print('Process count for ${identity.name}: ${semaphore.counter.counts.process.get()}');
  
  // Note: Registries such as SemaphoreIdentities and SemaphoreCounters track the instances globally.
  // The system guarantees singleton instances are returned for matching identities.
}
```
