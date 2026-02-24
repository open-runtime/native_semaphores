# Quickstart: Native Semaphores

## 1. Overview
The `runtime_native_semaphores` module provides cross-platform, native inter-process semaphores for Dart using FFI. It seamlessly abstracts POSIX semaphores (`sem_open`, `sem_wait`) and Windows semaphores (`CreateSemaphoreW`, `WaitForSingleObject`) into a unified `NativeSemaphore` API. This enables safe, reliable synchronization across multiple Dart isolates and OS-level processes, complete with reentrancy tracking and process-level lock counts.

## 2. Import
```dart
import 'package:runtime_native_semaphores/runtime_native_semaphores.dart';
```

## 3. Setup
To get started, instantiate a `NativeSemaphore`. The module automatically provisions either a `UnixSemaphore` or a `WindowsSemaphore` depending on the host OS.

```dart
// Instantiate a native semaphore with a system-wide unique identifier
final semaphore = NativeSemaphore.instantiate(
  name: 'myGlobalSemaphore',
  verbose: true, // Enables detailed operation tracking
);
```

## 4. Common Operations

### Opening and Locking
Before acquiring a lock, you must `open` the semaphore. Once opened, you can lock it to synchronize access to shared resources. 

```dart
// 1. Open the semaphore (creates it if it does not exist)
semaphore.open();

// 2. Lock the semaphore (blocking: true waits indefinitely until acquired)
bool acquired = semaphore.lock(blocking: true);

if (acquired) {
  print('Semaphore locked successfully! Count: ${semaphore.counter.counts.isolate.get()}');
}
```

### Try-Locking (Non-Blocking)
If you want to attempt to acquire a lock without waiting indefinitely, use `blocking: false`.

```dart
bool tryAcquired = semaphore.lock(blocking: false);
if (tryAcquired) {
  print('Successfully acquired lock without blocking.');
} else {
  print('Failed to acquire lock. The resource is busy.');
}
```

### Unlocking and Closing
Always release locks and close the handle when finished.

```dart
// 1. Unlock to release the semaphore for other isolates/processes
semaphore.unlock();

// 2. Close the handle for the current process
semaphore.close();
```

### Unlinking (Cleanup)
To completely remove the named semaphore from the OS (primarily affecting UNIX systems), you can unlink it after closing. On Windows, this safely returns true without executing OS logic, as Windows uses reference counting to destroy semaphores.

```dart
if (semaphore.closed) {
  // Removes the semaphore name immediately. Destroyed when all processes close it.
  semaphore.unlink();
}
```

### Using Cascade Builder Pattern
A common and concise way to manage the lifecycle of a semaphore is using Dart's cascade operator (`..`), ensuring that operations flow sequentially.

```dart
void accessCriticalResource() {
  final sem = NativeSemaphore.instantiate(name: 'sharedResourceSem');

  try {
    // Open and lock using cascade notation
    sem
      ..open()
      ..lock(blocking: true);
    
    // Perform operations on the shared resource
    print('Critical section entered. Reentrant? ${sem.reentrant}');
  } finally {
    // Ensure the semaphore is cleanly unlocked and disposed of
    sem
      ..unlock()
      ..close()
      ..unlink();
  }
}
```

### Inspecting State
You can inspect the synchronization counters and metadata directly.

```dart
print('Is Locked: ${semaphore.locked}');
print('Is Reentrant: ${semaphore.reentrant}');
print('Is Opened: ${semaphore.opened}');
print('Is Closed: ${semaphore.closed}');
print('Identity UUID: ${semaphore.identity.uuid}');
print('Address: ${semaphore.identity.address}');
```

## 5. Configuration and Edge Cases

*   **Naming Limits:** Semaphore names must be <= 30 characters on UNIX (`UnixSemLimits.NAME_MAX_CHARACTERS`) and <= `WindowsCreateSemaphoreWMacros.MAX_PATH` on Windows. Windows automatically prefixes names with `Global\\`.
*   **Permissions (UNIX):** Semaphores are created using `MODE_T_PERMISSIONS.RECOMMENDED` (0644 - Owner read/write, group read).
*   **Initial Values:** Both platforms use a recommended initial value of 1 (`UnixSemOpenMacros.VALUE_RECOMMENDED`, `WindowsCreateSemaphoreWMacros.INITIAL_VALUE_RECOMMENDED`), effectively acting as a standard mutex out-of-the-box.
*   **Reentrancy:** The `NativeSemaphore` tracks how many times an isolate has reentrantly locked the same semaphore, keeping counters separated (`isolate` vs `process`).
*   **Verbosity:** Set `verbose = true` upon instantiation to automatically print lifecycle events and cross-process interactions.

## 6. Related Modules & Internal Types Reference

For complete integration clarity, the following classes, macros, and structures are defined within the module:

### Core Abstractions (`src/native_semaphore.dart`, `src/unix_semaphore.dart`, `src/windows_semaphore.dart`)
*   `NativeSemaphores`, `NativeSemaphore`
*   `UnixSemaphore`
*   `WindowsSemaphore`

### State Tracking (`src/semaphore_counter.dart`, `src/semaphore_identity.dart`)
*   **`SemaphoreIdentity` / `SemaphoreIdentities`**: Tracks `prefix`, `isolate`, `process`, `address`, `name`, `registered`, `uuid`.
*   **`SemaphoreCountUpdate`**: Contains `identifier`, `from`, `to`.
*   **`SemaphoreCountDeletion`**: Contains `identifier`, `at`.
*   **`SemaphoreCount`, `SemaphoreCounts`, `SemaphoreCounter`, `SemaphoreCounters`**: Hierarchical tracking of isolate-level vs process-level lock state.

### UNIX FFI Bindings (`src/ffi/unix.dart`)
*   **Types**: `mode_t`, `sem_t`
*   **Functions**: `sem_open`, `sem_wait`, `sem_trywait`, `sem_post`, `sem_close`, `sem_unlink`, `__error`, `__errno_location`
*   **Macros & Limits**:
    *   `UnixSemLimits`: `PATH_MAX`, `SEM_VALUE_MAX`, `NAME_MAX`, `NAME_MAX_CHARACTERS`
    *   `MODE_T_PERMISSIONS`: `OWNER_READ_WRITE_GROUP_READ`, `ALL_READ_WRITE_EXECUTE`, etc.
    *   `UnixSemOpenMacros`: `EACCES`, `EINTR`, `EEXIST`, `EINVAL`, `EMFILE`, `ENAMETOOLONG`, `ENFILE`, `ENOENT`, `ENOMEM`, `ENOSPC`, `EFAULT`, `SEM_FAILED`, `O_CREAT`, `O_EXCL`
    *   `UnixSemWaitOrTryWaitMacros`: `EAGAIN`, `EDEADLK`, `EINTR`, `EINVAL`
    *   `UnixSemCloseMacros`: `EINVAL`
    *   `UnixSemUnlinkMacros`: `ENOENT`, `EACCES`, `ENAMETOOLONG`
    *   `UnixSemUnlockWithPostMacros`: `EINVAL`, `EOVERFLOW`
*   **Errors**: `UnixSemError`, `UnixSemOpenError`, `UnixSemOpenErrorUnixSemWaitOrTryWaitError`, `UnixSemCloseError`, `UnixSemUnlinkError`, `UnixSemUnlockWithPostError`

### Windows FFI Bindings (`src/ffi/windows.dart`)
*   **Types**: `SECURITY_ATTRIBUTES` (`nLength`, `lpSecurityDescriptor`, `bInheritHandle`), `SECURITY_DESCRIPTOR` (`Revision`, `Sbz1`, `Control`, `Owner`, `Group`, `Sacl`, `Dacl`), `ACL` (`AclRevision`, `Sbz1`, `AclSize`, `AceCount`, `Sbz2`)
*   **Functions**: `CreateSemaphoreW`, `WaitForSingleObject`, `ReleaseSemaphore`, `CloseHandle`
*   **Macros & Limits**:
    *   `WindowsCreateSemaphoreWMacros`: `NULL`, `SEM_FAILED`, `ERROR_INVALID_NAME`, `ERROR_SUCCESS`, `ERROR_ACCESS_DENIED`, `ERROR_INVALID_HANDLE`, `ERROR_INVALID_PARAMETER`, `ERROR_TOO_MANY_POSTS`, `ERROR_SEM_NOT_FOUND`, `ERROR_SEM_IS_SET`, `GLOBAL_NAME_PREFIX`, `LOCAL_NAME_PREFIX`, `MAX_PATH`
    *   `WindowsWaitForSingleObjectMacros`: `TIMEOUT_RECOMMENDED`, `TIMEOUT_INFINITE`, `TIMEOUT_ZERO`, `WAIT_ABANDONED`, `WAIT_OBJECT_0`, `WAIT_TIMEOUT`, `WAIT_FAILED`
    *   `WindowsReleaseSemaphoreMacros`: `RELEASE_COUNT_RECOMMENDED`, `PREVIOUS_RELEASE_COUNT_RECOMMENDED`, `ERROR_SEM_OVERFLOW`, `NULL`
    *   `WindowsCloseHandleMacros`: `INVALID_HANDLE_VALUE`
*   **Errors**: `WindowsCreateSemaphoreWError`, `WindowsReleaseSemaphoreError`
