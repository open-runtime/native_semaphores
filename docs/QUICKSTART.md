# Quickstart: Native Semaphores

## 1. Overview
The `runtime_native_semaphores` module provides a comprehensive API for cross-platform, native inter-process and inter-isolate semaphores in Dart. By abstracting POSIX (Unix) and Windows semaphores into a unified `NativeSemaphore` interface, it enables safe concurrency, shared resource locking, and reentrant lock tracking across diverse operating system environments.

## 2. Import
Import the top-level package entry point to access the unified API and all necessary classes:

```dart
import 'package:runtime_native_semaphores/runtime_native_semaphores.dart';
```

## 3. Setup
To get started, you do not need to manually choose the platform. Use the `NativeSemaphore.instantiate` factory method, which automatically resolves to a `UnixSemaphore` or `WindowsSemaphore` instance based on your current operating system.

```dart
// Instantiate a cross-platform semaphore
final semaphore = NativeSemaphore.instantiate(
  name: 'my_global_resource',
  verbose: true, // Set to true for deep FFI and lock state logging
);
```

## 4. Common Operations

### Opening a Semaphore
Before locking, the semaphore must be opened or natively created. This automatically binds the identifier to the underlying OS representation:
```dart
bool success = semaphore.open();
print('Opened: ${semaphore.opened}'); // true
```

### Locking (Critical Section)
Locking blocks across isolates and OS processes until the semaphore is available. It is also reentrant-safe for the current isolate:
```dart
// Acquire the lock (blocks by default)
semaphore.lock(blocking: true);

try {
  // Perform cross-process / cross-isolate critical work here...
  print('Currently locked: ${semaphore.locked}'); // true
  print('Is reentrant: ${semaphore.reentrant}'); // false (or true if locked multiple times)
} finally {
  // Release the lock
  semaphore.unlock();
}
```

### Closing and Unlinking
When the semaphore is no longer needed, close the handle. Call `unlink()` to physically remove the named semaphore from the system (acts as a deletion on Unix; harmless no-op on Windows):
```dart
semaphore.close();
print('Closed: ${semaphore.closed}'); // true

semaphore.unlink();
print('Unlinked: ${semaphore.unlinked}'); // true
```

## 5. Configuration & Platform Specifics
While `NativeSemaphore` abstracts the underlying OS, deep configuration macros and error states are available.
- **Windows Names**: Automatically prefixed with `Global\` to ensure cross-session namespace visibility. Governed by `WindowsCreateSemaphoreWMacros`.
- **Unix Names**: Automatically prefixed with `/`. Max length defined by `UnixSemLimits.NAME_MAX_CHARACTERS` (30).
- **Debugging**: Enable `verbose: true` on instantiation or on specific internal trackers (`SemaphoreCount(verbose: true)`) for internal debugging of reference counts and OS `errno` logs.

## 6. Advanced Error Handling
The package provides structured error wrappers for underlying system errors. Catch exceptions to handle precise POSIX or Kernel32 signals:

```dart
try {
  semaphore.open();
} on UnixSemOpenError catch (e) {
  print('Unix Open Failed. Code: ${e.code}, Identifier: ${e.identifier}, Message: ${e.message}');
} on WindowsCreateSemaphoreWError catch (e) {
  print('Windows Create Failed. Code: ${e.code}, Identifier: ${e.identifier}, Message: ${e.message}');
} catch (e) {
  print('Unknown Error: $e');
}
```

## 7. API Reference Summary
As part of the module export, the following structures, classes, and macros are available for advanced usage:

### Core Controllers
* `NativeSemaphores`, `NativeSemaphore`
* `UnixSemaphore`, `WindowsSemaphore`

### State & Tracking
* `SemaphoreIdentities`, `SemaphoreIdentity`
* `SemaphoreCounters`, `SemaphoreCounter`
* `SemaphoreCounts`, `SemaphoreCount`
* `SemaphoreCountUpdate`, `SemaphoreCountDeletion`
* `LatePropertyAssigned` (Utility method)

### Type Aliases
For extensive type parameter bindings, use the aliases defined in `src/native_semaphore_types.dart`:
* `I`, `IS`, `CU`, `CD`, `CT`, `CTS`, `CTR`, `CTRS`, `NS`

### Unix FFI (Bindings & Macros)
* `mode_t`
* `MODE_T_PERMISSIONS`
* `UnixSemLimits`
* `UnixSemOpenMacros`, `UnixSemWaitOrTryWaitMacros`, `UnixSemCloseMacros`, `UnixSemUnlinkMacros`, `UnixSemUnlockWithPostMacros`
* `UnixSemError`, `UnixSemOpenError`, `UnixSemOpenErrorUnixSemWaitOrTryWaitError`, `UnixSemCloseError`, `UnixSemUnlinkError`, `UnixSemUnlockWithPostError`

### Windows FFI (Bindings & Macros)
* `SECURITY_ATTRIBUTES`, `SECURITY_DESCRIPTOR`, `ACL`
* `WindowsCreateSemaphoreWMacros`, `WindowsWaitForSingleObjectMacros`, `WindowsReleaseSemaphoreMacros`, `WindowsCloseHandleMacros`
* `WindowsCreateSemaphoreWError`, `WindowsReleaseSemaphoreError`

## 8. Related Modules
- `src/ffi/unix.dart`: Direct POSIX bindings (`sem_open`, `sem_wait`, `sem_post`, `sem_close`, `sem_unlink`).
- `src/ffi/windows.dart`: Direct Kernel32 bindings (`CreateSemaphoreW`, `WaitForSingleObject`, `ReleaseSemaphore`, `CloseHandle`).
