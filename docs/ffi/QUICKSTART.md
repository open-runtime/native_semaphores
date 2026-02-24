# FFI Bindings Quickstart

## 1. Overview
The FFI Bindings module provides direct, low-level Dart Foreign Function Interface (FFI) bindings to native operating system semaphore APIs. It enables access to POSIX semaphores (`sem_open`, `sem_wait`, `sem_trywait`, `sem_post`, `sem_close`, `sem_unlink`) for Unix/macOS, and Win32 semaphores (`CreateSemaphoreW`, `WaitForSingleObject`, `ReleaseSemaphore`, `CloseHandle`) for Windows. It also includes comprehensive error handling classes, system limit macros, and security attribute structures.

## 2. Import
Depending on your target platform, import the corresponding FFI bindings directly from the `src/ffi` directory:

```dart
// For Unix (Linux/macOS) bindings
import 'package:runtime_native_semaphores/src/ffi/unix.dart';

// For Windows bindings
import 'package:runtime_native_semaphores/src/ffi/windows.dart';

// You will also need dart:ffi and package:ffi for pointer/memory management
import 'dart:ffi';
import 'package:ffi/ffi.dart';
```

## 3. Setup
These bindings are direct C-interop functions, so there are no classes to instantiate for setup. Instead, you interact with top-level native functions and use the provided macro classes to configure your calls.

### Unix Configuration Utilities
```dart
// Check system limits
int maxPath = UnixSemLimits.PATH_MAX;
int maxValue = UnixSemLimits.SEM_VALUE_MAX;
int nameMax = UnixSemLimits.NAME_MAX;

// Define permissions (e.g., 0644 - Owner read/write, Group/Others read)
int permissions = MODE_T_PERMISSIONS.RECOMMENDED;
int customPermissions = MODE_T_PERMISSIONS.perm(
  u: MODE_T_PERMISSIONS.rwx,
  g: MODE_T_PERMISSIONS.rx,
  o: 0,
);
```

### Windows Configuration Utilities
```dart
// Windows specific limits and prefixes
String prefix = WindowsCreateSemaphoreWMacros.LOCAL_NAME_PREFIX; // 'Local\'
String globalPrefix = WindowsCreateSemaphoreWMacros.GLOBAL_NAME_PREFIX; // 'Global\'
int maxPath = WindowsCreateSemaphoreWMacros.MAX_PATH;
```

## 4. Common Operations

### Unix: Open or Create a Named Semaphore
Use `sem_open` to create or open a POSIX semaphore.
```dart
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:runtime_native_semaphores/src/ffi/unix.dart';

void main() {
  final name = '/my_semaphore'.toNativeUtf8().cast<Char>();

  final Pointer<sem_t> sem = sem_open(
    name,
    UnixSemOpenMacros.O_CREAT, // Create if it doesn't exist
    MODE_T_PERMISSIONS.RECOMMENDED,
    UnixSemOpenMacros.VALUE_RECOMMENDED,
  );

  if (sem == UnixSemOpenMacros.SEM_FAILED) {
    final err = errno.value;
    calloc.free(name);
    throw UnixSemOpenError.fromErrno(err);
  }
  
  // Use the semaphore...
  calloc.free(name);
}
```

### Unix: Wait, TryWait, Post, and Cleanup
```dart
import 'dart:ffi';
import 'package:runtime_native_semaphores/src/ffi/unix.dart';

void processCriticalSection(Pointer<sem_t> sem) {
  // Try to decrement (lock) the semaphore without blocking
  if (sem_trywait(sem) != 0) {
    final err = errno.value;
    if (err == UnixSemWaitOrTryWaitMacros.EAGAIN) {
      print("Semaphore is already locked, would block.");
    } else {
      throw UnixSemOpenErrorUnixSemWaitOrTryWaitError.fromErrno(err);
    }
  }

  // Decrement (lock) the semaphore (blocks until available)
  if (sem_wait(sem) != 0) {
    throw UnixSemOpenErrorUnixSemWaitOrTryWaitError.fromErrno(errno.value);
  }

  // ... critical section ...

  // Increment (unlock) the semaphore
  if (sem_post(sem) != 0) {
    throw UnixSemUnlockWithPostError.fromErrno(errno.value);
  }
}

void cleanup(Pointer<sem_t> sem, Pointer<Char> name) {
  // Close the named semaphore
  if (sem_close(sem) != 0) {
    throw UnixSemCloseError.fromErrno(errno.value);
  }
  
  // Unlink (remove) the semaphore name
  if (sem_unlink(name) != 0) {
    throw UnixSemUnlinkError.fromErrno(errno.value);
  }
}
```

### Windows: Create a Named Semaphore
```dart
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:runtime_native_semaphores/src/ffi/windows.dart';

void main() {
  final semName = '${WindowsCreateSemaphoreWMacros.LOCAL_NAME_PREFIX}my_semaphore'.toNativeUtf16();

  // Create optional SECURITY_ATTRIBUTES using calloc
  final securityAttributes = calloc<SECURITY_ATTRIBUTES>()
    ..ref.nLength = sizeOf<SECURITY_ATTRIBUTES>()
    ..ref.bInheritHandle = 1
    ..ref.lpSecurityDescriptor = nullptr;

  final int handle = CreateSemaphoreW(
    securityAttributes.address, // Security attributes pointer address (or 0 for NULL)
    WindowsCreateSemaphoreWMacros.INITIAL_VALUE_RECOMMENDED,
    WindowsCreateSemaphoreWMacros.MAXIMUM_VALUE_RECOMMENDED,
    semName,
  );

  calloc.free(securityAttributes);
  calloc.free(semName);

  if (handle == 0) { // 0 indicates failure
    // Note: Use GetLastError() (via kernel32 or custom FFI) in a real scenario to get error code
    throw WindowsCreateSemaphoreWError.fromErrorCode(WindowsCreateSemaphoreWMacros.ERROR_ACCESS_DENIED); 
  }
}
```

### Windows: Wait, Release, and Cleanup
```dart
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:runtime_native_semaphores/src/ffi/windows.dart';

void processCriticalSection(int handle) {
  // Wait (lock)
  final waitResult = WaitForSingleObject(
    handle, 
    WindowsWaitForSingleObjectMacros.TIMEOUT_INFINITE
  );

  if (waitResult == WindowsWaitForSingleObjectMacros.WAIT_OBJECT_0) {
    // ... critical section ...

    // Release (unlock)
    final previousCount = calloc<LONG>();
    final bool success = ReleaseSemaphore(
      handle, 
      WindowsReleaseSemaphoreMacros.RELEASE_COUNT_RECOMMENDED, 
      previousCount,
    ) != 0;
    
    calloc.free(previousCount);

    if (!success) {
      throw WindowsReleaseSemaphoreError.fromErrorCode(WindowsReleaseSemaphoreMacros.ERROR_SEM_OVERFLOW);
    }
  } else if (waitResult == WindowsWaitForSingleObjectMacros.WAIT_TIMEOUT) {
    print("Wait timed out.");
  }
}

void cleanup(int handle) {
  // Clean up
  if (CloseHandle(handle) == 0) {
    print("Failed to close handle.");
  }
}
```

## 5. Structs and Configuration Details
The module automatically handles underlying platform discrepancies (e.g., BSD vs GNU sizes on macOS vs Linux) using `Platform.isMacOS` checks built into the macro classes. 

### Unix Error Handling and Config
- **Unix Permissions:** Use the `MODE_T_PERMISSIONS` class to set appropriate file access flags (e.g., `OWNER_READ_WRITE_GROUP_READ`).
- **Error Handling:** Use custom error classes like `UnixSemError` (and subclasses `UnixSemOpenError`, `UnixSemCloseError`, `UnixSemUnlinkError`, etc.) to decode system errors safely. The `errno` getter fetches the current thread's error number.

### Windows Structs
- **SECURITY_ATTRIBUTES:** Used to define security descriptors and inheritance for Windows handles. It contains:
  - `nLength`: Size of the struct.
  - `lpSecurityDescriptor`: Pointer to a `SECURITY_DESCRIPTOR`.
  - `bInheritHandle`: Boolean flag for handle inheritance.
- **SECURITY_DESCRIPTOR** and **ACL**: Used to set fine-grained access control lists.

- **Windows Namespaces:** When naming Windows semaphores, prefix the name with `WindowsCreateSemaphoreWMacros.GLOBAL_NAME_PREFIX` or `WindowsCreateSemaphoreWMacros.LOCAL_NAME_PREFIX` to assign it to the correct session namespace.
- **Error Handling:** Use `WindowsCreateSemaphoreWError`, `WindowsReleaseSemaphoreError`, and related classes to decode Windows specific errors.

## 6. Related Modules
- `dart:ffi`: Required for native types (`Int`, `Pointer`, `Char`, `Struct`).
- `package:ffi`: Required for string allocations and pointer utilities (`toNativeUtf8()`, `toNativeUtf16()`, `calloc`).
- High-level wrappers (`lib/src/unix_semaphore.dart` and `lib/src/windows_semaphore.dart`) in this package, which abstract away manual pointer and memory management for safer application code.
