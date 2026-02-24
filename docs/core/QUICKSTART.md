# Semaphore Core - Quickstart

## 1. Overview
The **Semaphore Core** module provides cross-platform, POSIX-style named semaphores for Dart isolates and distinct processes. It manages semaphore lifecycle—creation, locking, unlocking, closing, and unlinking—while seamlessly handling OS-specific FFI bindings (`sem_t` on Unix, `HANDLE` on Windows), reentrancy via isolate tracking, and process-level cross-synchronization.

## 2. Import
Import the core module using the package's primary entrypoint:
```dart
import 'package:runtime_native_semaphores/runtime_native_semaphores.dart';
```

Or, if you are importing directly from the `src` directory within the package:
```dart
import 'package:runtime_native_semaphores/src/native_semaphore.dart';
import 'package:runtime_native_semaphores/src/semaphore_identity.dart';
```

## 3. Setup
To get started, instantiate a `NativeSemaphore` with a unique identifier. The module automatically provisions the underlying `UnixSemaphore` or `WindowsSemaphore` based on the host platform.

```dart
// Instantiate and open a semaphore using the builder pattern (cascade notation)
// This will create it if it doesn't exist or open the existing one with the provided name.
var semaphore = NativeSemaphore.instantiate(name: 'mySharedResource')
  ..open();
```

## 4. Common Operations

### Locking and Unlocking (Blocking)
Locking a semaphore blocks the current isolate or process until the shared resource becomes available. Once your critical section is finished, you must `unlock()` the semaphore.

```dart
// Acquire the lock (blocks until available)
bool isLocked = semaphore.lock(blocking: true);

if (!isLocked) {
  throw Exception('Failed to acquire the lock.');
}

try {
  // Perform operations on the shared resource safely
  print('Inside the critical section');
} finally {
  // Release the lock
  semaphore.unlock();
}
```

### Non-Blocking Lock Attempt
You can attempt to acquire a lock without waiting. If the semaphore is already locked by another process, `lock(blocking: false)` returns `false` (via `sem_trywait` on Unix or a `TIMEOUT_ZERO` wait on Windows).

```dart
// Attempt to acquire the lock without blocking, using the cascade operator where appropriate
bool acquired = semaphore.lock(blocking: false);

if (acquired) {
  try {
    print('Lock acquired instantly!');
  } finally {
    semaphore.unlock();
  }
} else {
  print('Resource is busy. Try again later.');
}
```

### Closing and Unlinking
When you are completely finished with the semaphore in your application, you should `close()` and `unlink()` it to prevent system resource leaks. Note that `unlink()` completely removes the named semaphore from the system on Unix (and performs a no-op memory cleanup on Windows).

```dart
// Safely close and unlink the semaphore using cascade notation
semaphore
  ..close()
  ..unlink();
```

### Inspecting State
The semaphore provides several properties to inspect its current state and identity:

```dart
print('Is opened: ${semaphore.opened}');
print('Is locked: ${semaphore.locked}');
print('Is closed: ${semaphore.closed}');
print('Is unlinked: ${semaphore.unlinked}');
print('Is reentrant: ${semaphore.reentrant}');
print('Identity UUID: ${semaphore.identity.uuid}');
```

### Reentrancy
The `NativeSemaphore` tracks locks on a per-isolate and per-process basis via `SemaphoreCounter`. This enables reentrancy. When an isolate calls `lock()` multiple times, the isolate-level counter is incremented, meaning subsequent `lock()` calls from the same isolate succeed immediately. You must call `unlock()` the exact same number of times you called `lock()`.

```dart
// First lock blocks until available
semaphore.lock();

// Subsequent locks in the same isolate are non-blocking and increment the isolate count
semaphore.lock();

print('Isolate is reentrant: ${semaphore.reentrant}'); // true

// Must unlock twice
semaphore
  ..unlock()
  ..unlock();
```

## 5. Configuration

### Debugging and Verbosity
You can enable verbose logging during instantiation to trace native FFI calls, reentrancy counts, and process synchronizations. This is extremely helpful when debugging deadlocks.

```dart
var verboseSemaphore = NativeSemaphore.instantiate(
  name: 'debugSemaphore', 
  verbose: true,
);
```

### Optional Setup Parameters
You can explicitly provide a `SemaphoreIdentity` and `SemaphoreCounter` when instantiating the semaphore. If not provided, they are instantiated automatically.

```dart
var identity = SemaphoreIdentity.instantiate(name: 'customIdentity');
var customSemaphore = NativeSemaphore.instantiate(
  name: 'customIdentity',
  identity: identity,
  verbose: false,
)
  ..open()
  ..close()
  ..unlink();
```

### Naming Constraints
- **Max length:** 30 characters on Unix (`UnixSemLimits.NAME_MAX_CHARACTERS`), longer on Windows (`WindowsCreateSemaphoreWMacros.MAX_PATH`).
- **Invalid characters:** Identifiers cannot contain the characters `\ / : * ? " < > |`.
- **Platform prefixes:** Windows identifiers implicitly receive a `Global\` prefix. All identifiers internally strip any leading slashes or existing `Global\` / `Local\` prefixes before allocation.

## 6. Related Modules
- `SemaphoreIdentity`: Tracks isolate and process information to securely assign reference UUIDs to callers.
- `SemaphoreCounter`: Manages reference counts (via `SemaphoreCounts`, `SemaphoreCountUpdate`, and `SemaphoreCountDeletion`) for both process-level and isolate-level reentrant locking.
- `UnixSemaphore` & `WindowsSemaphore`: Platform-specific concrete implementations of `NativeSemaphore`.
