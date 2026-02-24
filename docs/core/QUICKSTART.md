# Semaphore Core - Quickstart

## 1. Overview
The Semaphore Core module provides a cross-platform (Unix and Windows) implementation of native OS semaphores in Dart. It enables robust inter-process communication (IPC) and isolate synchronization using FFI to interface with system-level semaphore APIs (like `sem_open` on POSIX and `CreateSemaphoreW` on Windows). The module automatically handles platform-specific bindings, reentrant locking within the same isolate, and reference counting across processes.

## 2. Import

To use the core classes and convenient type definitions (like `NS` for NativeSemaphore), import the main library:

```dart
import 'package:runtime_native_semaphores/runtime_native_semaphores.dart';
```

## 3. Setup
To use native semaphores, instantiate a `NativeSemaphore` using its `instantiate` factory method. This automatically resolves to the correct underlying implementation (`UnixSemaphore` or `WindowsSemaphore`) based on the host operating system.

Using the builder pattern (cascade `..`), you can instantiate and open the semaphore in one step. It is recommended to use the `NS` typedef to avoid complex generic type parameter requirements.

```dart
// Instantiate and open the semaphore with a unique system-wide name.
// Note the use of camelCase naming for the system-wide resource.
final NS semaphore = NativeSemaphore.instantiate(
  name: 'mySharedResource',
  verbose: true, // Set to true for detailed lifecycle logs
)..open();
```

Alternatively, you can open it separately to verify the result:

```dart
final NS separateSemaphore = NativeSemaphore.instantiate(
  name: 'anotherSharedResource',
);

// Open or create the native semaphore instance
bool isOpened = separateSemaphore.open();
```

## 4. Common Operations

### Locking (Acquire)
You can lock the semaphore across processes and isolates. The `lock` method supports blocking (wait) or non-blocking (try-wait) attempts.

```dart
// Block the current isolate/thread until the semaphore is acquired
bool locked = semaphore.lock(blocking: true);

// Attempt to lock without blocking, returning false immediately if already locked
bool tryLocked = semaphore.lock(blocking: false);
```

### Unlocking (Release)
Releasing the semaphore automatically decrements the internal isolate/process counters and notifies the OS to awake blocked processes.

```dart
// Release the lock for other processes or isolates
bool unlocked = semaphore.unlock();
```

### Checking Status
You can check the internal state of the semaphore using its properties.

```dart
bool isLocked = semaphore.locked;
bool isReentrant = semaphore.reentrant;
bool isOpened = semaphore.opened;
bool isClosed = semaphore.closed;
bool isUnlinked = semaphore.unlinked;
```

### Cleanup (Close and Unlink)
Always `close()` a semaphore when finished to prevent memory and handle leaks. On Unix systems, you can also `unlink()` the semaphore to completely remove it from the OS registry. You can chain these cleanups using the cascade pattern.

```dart
// Close the local process handle and completely destroy the 
// semaphore from the OS (Unix only; safe but no-op on Windows)
semaphore
  ..close()
  ..unlink();
```

## 5. Configuration & Edge Cases
- **Naming Rules**: The `name` provided to `NativeSemaphore.instantiate` must use valid characters. It must not contain restricted characters (`\`, `/`, `:`, `*`, `?`, `"`, `<`, `>`, `|`) and is automatically prefixed (`Global\` on Windows, `/` on Unix). Length must be under `30` characters for Unix (`UnixSemLimits.NAME_MAX_CHARACTERS`) and `260` characters for Windows (`WindowsCreateSemaphoreWMacros.MAX_PATH`). An `ArgumentError` is thrown otherwise.
- **Reentrancy**: Semaphores are completely reentrant on a per-isolate basis. Locking an already locked semaphore by the same isolate merely increments an internal counter (`semaphore.counter.counts.isolate.get()`), avoiding deadlocks. Ensure you `unlock()` the same number of times you `lock()`.
- **Verbose Logging**: Passing `verbose: true` to the instantiation method prints detailed internal FFI and lifecycle evaluations to the console, useful for debugging IPC issues.

## 6. Related Modules
- `SemaphoreIdentity`: Tracks the `isolate` and `process` UUIDs to manage reentrant locking.
- `SemaphoreCounter` / `SemaphoreCounts`: Automatically tracks isolate-level and process-level lock counts internally.
- `ffi/unix.dart` & `ffi/windows.dart`: Contains the low-level FFI bindings and OS-specific error codes (e.g., `UnixSemOpenError`, `WindowsCreateSemaphoreWError`).
