# FFI Bindings Quickstart

## 1. Overview
The FFI Bindings module provides direct, low-level access to the underlying native semaphore APIs on both Unix (POSIX) and Windows operating systems. It exports raw FFI functions, macros, structures, and error classes that allow you to interact with semaphores without any higher-level abstractions.

## 2. Import
```dart
// For Unix (POSIX) systems (macOS, Linux)
import 'package:runtime_native_semaphores/src/ffi/unix.dart';

// For Windows systems
import 'package:runtime_native_semaphores/src/ffi/windows.dart';
```

## 3. Setup
To use these bindings, you do not need to instantiate a central class. Instead, you interact with the FFI functions and macro classes directly. Ensure you import `dart:ffi` and `package:ffi/ffi.dart` for memory management and string conversions.

## 4. Common Operations

### Unix POSIX Semaphores
The Unix FFI bindings expose standard POSIX semaphore functions like `sem_open`, `sem_wait`, `sem_trywait`, `sem_post`, `sem_close`, and `sem_unlink`. 

```dart
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:runtime_native_semaphores/src/ffi/unix.dart';

void unixSemaphoreExample() {
  // 1. Define semaphore name
  // The name must begin with a '/' and be less than UnixSemLimits.NAME_MAX_CHARACTERS
  final nameString = '/my_unix_semaphore';
  final name = nameString.toNativeUtf8().cast<Char>();

  // 2. Create or Open the semaphore
  // Using O_CREAT flag creates it if it doesn't exist.
  // The mode parameter specifies the permissions (e.g., 0644).
  final sem = sem_open(
    name,
    UnixSemOpenMacros.O_CREAT,
    MODE_T_PERMISSIONS.RECOMMENDED,
    UnixSemOpenMacros.VALUE_RECOMMENDED,
  );

  // Check if creation failed using SEM_FAILED
  if (sem.address == UnixSemOpenMacros.SEM_FAILED.address) {
    // Read native errno to determine the error
    throw UnixSemOpenError.fromErrno(errno.value);
  }

  // 3. Lock (wait)
  // Decrements the semaphore. Blocks if value is zero.
  final waitResult = sem_wait(sem);
  if (waitResult != 0) {
    throw UnixSemOpenErrorUnixSemWaitOrTryWaitError.fromErrno(errno.value);
  }
  
  // Alternatively, use trywait to return an error immediately instead of blocking:
  // final tryWaitResult = sem_trywait(sem);
  // if (tryWaitResult != 0) {
  //   throw UnixSemOpenErrorUnixSemWaitOrTryWaitError.fromErrno(errno.value);
  // }

  // 4. Unlock (post)
  // Increments the semaphore.
  final postResult = sem_post(sem);
  if (postResult != 0) {
    throw UnixSemUnlockWithPostError.fromErrno(errno.value);
  }

  // 5. Close the semaphore
  final closeResult = sem_close(sem);
  if (closeResult != 0) {
    throw UnixSemCloseError.fromErrno(errno.value);
  }

  // 6. Unlink (destroy) the semaphore
  final unlinkResult = sem_unlink(name);
  if (unlinkResult != 0) {
    throw UnixSemUnlinkError.fromErrno(errno.value);
  }

  // Free allocated memory
  malloc.free(name);
}
```

### Windows Semaphores
The Windows FFI bindings expose Win32 APIs like `CreateSemaphoreW`, `WaitForSingleObject`, `ReleaseSemaphore`, and `CloseHandle`.
It also includes `SECURITY_ATTRIBUTES` for configuring inheritability and security descriptors.

```dart
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:runtime_native_semaphores/src/ffi/windows.dart';

void windowsSemaphoreExample() {
  // 1. Define semaphore name (Local\ or Global\ prefix)
  final nameString = '${WindowsCreateSemaphoreWMacros.LOCAL_NAME_PREFIX}my_win_sem';
  final name = nameString.toNativeUtf16();

  // (Optional) Define SECURITY_ATTRIBUTES to customize inheritable handles.
  // We use cascade notation (..field = value) for the struct builder pattern.
  // Properties mapped in camelCase or exact name per Dart conventions.
  final securityAttributes = calloc<SECURITY_ATTRIBUTES>()
    ..ref.nLength = sizeOf<SECURITY_ATTRIBUTES>()
    ..ref.lpSecurityDescriptor = nullptr
    ..ref.bInheritHandle = 0; // FALSE

  // 2. Create or Open the semaphore
  final handle = CreateSemaphoreW(
    securityAttributes.address, 
    WindowsCreateSemaphoreWMacros.INITIAL_VALUE_RECOMMENDED,
    WindowsCreateSemaphoreWMacros.MAXIMUM_VALUE_RECOMMENDED,
    name,
  );

  if (handle == 0) {
    // Note: Use GetLastError() (if defined/available) in your actual code to map the real error.
    throw WindowsCreateSemaphoreWError(
      WindowsCreateSemaphoreWMacros.ERROR_INVALID_HANDLE,
      'Failed to create Windows semaphore',
      'ERROR_INVALID_HANDLE'
    );
  }

  // 3. Lock (wait)
  final waitResult = WaitForSingleObject(
    handle,
    WindowsWaitForSingleObjectMacros.TIMEOUT_INFINITE,
  );

  if (waitResult == WindowsWaitForSingleObjectMacros.WAIT_FAILED) {
    throw Exception('Wait failed');
  } else if (waitResult == WindowsWaitForSingleObjectMacros.WAIT_TIMEOUT) {
    throw Exception('Wait timeout elapsed');
  }

  // 4. Unlock (release)
  // Increase count by RELEASE_COUNT_RECOMMENDED
  final releaseResult = ReleaseSemaphore(
    handle,
    WindowsReleaseSemaphoreMacros.RELEASE_COUNT_RECOMMENDED,
    nullptr, // Not capturing previous count
  );

  if (releaseResult == 0) {
    throw WindowsReleaseSemaphoreError(
      WindowsReleaseSemaphoreMacros.ERROR_SEM_OVERFLOW,
      'Release failed: the semaphore reached its maximum count',
      'ERROR_SEM_OVERFLOW'
    );
  }

  // 5. Close handle
  final closeResult = CloseHandle(handle);
  if (closeResult == 0) {
    throw Exception('Failed to close handle');
  }

  // Free allocated memory
  malloc.free(securityAttributes);
  malloc.free(name);
}
```

## 5. Configuration
The API relies on system-specific configuration constants available via macros:

- **Unix:** You can refer to `UnixSemLimits.PATH_MAX` for the maximum path length, and `UnixSemLimits.NAME_MAX_CHARACTERS` for name limitations. `MODE_T_PERMISSIONS` provides easy-to-use access masks like `MODE_T_PERMISSIONS.RECOMMENDED`.
- **Windows:** Names are limited to `WindowsCreateSemaphoreWMacros.MAX_PATH` characters and should typically include `Global\` or `Local\` prefixes depending on your desired session namespace.

## 6. Related Modules
- `package:runtime_native_semaphores/src/native_semaphore.dart` - Provides a cross-platform, high-level wrapper over these raw FFI bindings.
- `package:runtime_native_semaphores/src/unix_semaphore.dart` - High-level object-oriented encapsulation for Unix POSIX semaphores.
- `package:runtime_native_semaphores/src/windows_semaphore.dart` - High-level object-oriented encapsulation for Windows semaphores.
