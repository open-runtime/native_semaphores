# FFI Bindings API Reference

This document provides a comprehensive API reference for the native FFI bindings used in the `native_semaphores` package, covering both UNIX (POSIX) and Windows implementations.

## UNIX FFI Bindings

### Structs and Primitive Types

#### `mode_t`

16-bit unsigned integer type typically specifying file permissions.

```dart
import 'package:runtime_native_semaphores/src/ffi/unix.dart';

// mode_t is an AbiSpecificInteger
const mode_t myMode = mode_t();
```

#### `MODE_T_PERMISSIONS`

Common permission bits and octal values used for named semaphores.

```dart
import 'package:runtime_native_semaphores/src/ffi/unix.dart';

// Create a custom permission
int customPerm = MODE_T_PERMISSIONS.perm(u: MODE_T_PERMISSIONS.rwx, g: MODE_T_PERMISSIONS.rx, o: 0);

// Use a recommended preset
int recommendedPerm = MODE_T_PERMISSIONS.RECOMMENDED;
```

#### `UnixSemLimits`

Defines platform-specific limits for semaphores on UNIX systems.

```dart
import 'package:runtime_native_semaphores/src/ffi/unix.dart';

void exampleUnixSemLimits() {
  print('Maximum path length: ${UnixSemLimits.PATH_MAX}');
  print('Maximum semaphore value: ${UnixSemLimits.SEM_VALUE_MAX}');
  print('Is BSD (MacOS): ${UnixSemLimits.isBSD}');
}
```

#### `UnixSemOpenMacros`

Error codes and macros related to `sem_open` operations.

```dart
import 'package:runtime_native_semaphores/src/ffi/unix.dart';

void exampleUnixSemOpenMacros() {
  int flags = UnixSemOpenMacros.O_CREAT | UnixSemOpenMacros.O_EXCL;
  print('EACCES error code: ${UnixSemOpenMacros.EACCES}');
}
```

#### `UnixSemWaitOrTryWaitMacros`, `UnixSemCloseMacros`, `UnixSemUnlinkMacros`, `UnixSemUnlockWithPostMacros`

These classes define the standard error macros (like `EAGAIN`, `EINVAL`, `ENOENT`, `EOVERFLOW`) related to their respective semaphore operations.

### Error Classes

#### `UnixSemError`

Base error class for all UNIX semaphore failures.

#### `UnixSemOpenError`

Represents an error encountered during a `sem_open` operation.

```dart
import 'package:runtime_native_semaphores/src/ffi/unix.dart';

void exampleUnixSemOpenError() {
  // Create an error from errno
  final error = UnixSemOpenError.fromErrno(UnixSemOpenMacros.EACCES);
  print(error.toString()); // UnixSemOpenError: [Error: EACCES Code: 13]: ...
}
```

*Other Error Classes:* `UnixSemOpenErrorUnixSemWaitOrTryWaitError`, `UnixSemCloseError`, `UnixSemUnlinkError`, `UnixSemUnlockWithPostError` all follow the same pattern and can be instantiated via their respective `.fromErrno(int errno)` factories.

### Top-Level Functions

#### `sem_open`

Creates a new POSIX semaphore or opens an existing one.

```dart
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:runtime_native_semaphores/src/ffi/unix.dart';

void exampleSemOpen() {
  final Pointer<Char> namePtr = '/my_semaphore'.toNativeUtf8().cast<Char>();

  // Open or create a semaphore
  final Pointer<sem_t> semPtr = sem_open(
    namePtr,
    UnixSemOpenMacros.O_CREAT,
    MODE_T_PERMISSIONS.RECOMMENDED,
    UnixSemOpenMacros.VALUE_RECOMMENDED,
  );

  if (semPtr == UnixSemOpenMacros.SEM_FAILED) {
    throw UnixSemOpenError.fromErrno(errno.value);
  }
}
```

#### `sem_wait`, `sem_trywait`, `sem_post`, `sem_close`, `sem_unlink`

Core operations on the UNIX semaphore.

```dart
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:runtime_native_semaphores/src/ffi/unix.dart';

void exampleSemOperations(Pointer<sem_t> semPtr) {
  // Wait on the semaphore (decrement)
  int waitResult = sem_wait(semPtr);
  if (waitResult == -1) {
    throw UnixSemOpenErrorUnixSemWaitOrTryWaitError.fromErrno(errno.value);
  }

  // Post to the semaphore (increment)
  int postResult = sem_post(semPtr);
  if (postResult == -1) {
    throw UnixSemUnlockWithPostError.fromErrno(errno.value);
  }

  // Close the semaphore
  int closeResult = sem_close(semPtr);
  if (closeResult == -1) {
    throw UnixSemCloseError.fromErrno(errno.value);
  }

  // Unlink the semaphore
  final Pointer<Char> namePtr = '/my_semaphore'.toNativeUtf8().cast<Char>();
  int unlinkResult = sem_unlink(namePtr);
  if (unlinkResult == -1) {
    throw UnixSemUnlinkError.fromErrno(errno.value);
  }
}
```

#### `errno`

Retrieves the correct pointer for the current OS error value.

```dart
import 'package:runtime_native_semaphores/src/ffi/unix.dart';

void exampleErrno() {
  print('Current error code: ${errno.value}');
}
```

## Windows FFI Bindings

### Structs

#### `SECURITY_ATTRIBUTES`

The `SECURITY_ATTRIBUTES` structure contains the security descriptor for an object and specifies whether the handle retrieved by specifying this structure is inheritable.

```dart
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:runtime_native_semaphores/src/ffi/windows.dart';

void exampleSecurityAttributes() {
  // Building a SECURITY_ATTRIBUTES struct using the cascade operator
  final Pointer<SECURITY_ATTRIBUTES> securityAttributes = calloc<SECURITY_ATTRIBUTES>()
    ..ref.nLength = sizeOf<SECURITY_ATTRIBUTES>()
    ..ref.lpSecurityDescriptor = nullptr
    ..ref.bInheritHandle = 0; // FALSE
}
```

#### `SECURITY_DESCRIPTOR`

The `SECURITY_DESCRIPTOR` structure contains the security information associated with an object.

```dart
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:runtime_native_semaphores/src/ffi/windows.dart';

void exampleSecurityDescriptor() {
  final Pointer<SECURITY_DESCRIPTOR> sd = calloc<SECURITY_DESCRIPTOR>()
    ..ref.Revision = 1
    ..ref.Sbz1 = 0
    ..ref.Control = 0
    ..ref.Owner = nullptr
    ..ref.Group = nullptr
    ..ref.Sacl = nullptr
    ..ref.Dacl = nullptr;
}
```

#### `ACL`

The `ACL` structure is the header of an access control list (ACL).

```dart
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:runtime_native_semaphores/src/ffi/windows.dart';

void exampleAcl() {
  final Pointer<ACL> acl = calloc<ACL>()
    ..ref.AclRevision = 2
    ..ref.Sbz1 = 0
    ..ref.AclSize = sizeOf<ACL>()
    ..ref.AceCount = 0
    ..ref.Sbz2 = 0;
}
```

### Macros and Error Classes

#### `WindowsCreateSemaphoreWMacros`, `WindowsWaitForSingleObjectMacros`, `WindowsReleaseSemaphoreMacros`, `WindowsCloseHandleMacros`

These classes define essential constants and error codes required for working with Windows Semaphores.

```dart
import 'package:runtime_native_semaphores/src/ffi/windows.dart';

void exampleWindowsMacros() {
  print('Infinite timeout: ${WindowsWaitForSingleObjectMacros.TIMEOUT_INFINITE}');
  print('Max path for semaphore: ${WindowsCreateSemaphoreWMacros.MAX_PATH}');
  print('Global prefix: ${WindowsCreateSemaphoreWMacros.GLOBAL_NAME_PREFIX}');
}
```

#### `WindowsCreateSemaphoreWError`, `WindowsReleaseSemaphoreError`

Custom error classes for specific Windows FFI operations.

```dart
import 'package:runtime_native_semaphores/src/ffi/windows.dart';

void exampleWindowsErrors() {
  // Generating an error from an error code
  final error = WindowsCreateSemaphoreWError.fromErrorCode(
    WindowsCreateSemaphoreWMacros.ERROR_ACCESS_DENIED
  );
  print(error.message); // The caller does not have the required access rights...
}
```

### Top-Level Functions

#### `CreateSemaphoreW`

Creates or opens a named or unnamed semaphore object.

```dart
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:runtime_native_semaphores/src/ffi/windows.dart';

void exampleCreateSemaphoreW() {
  final Pointer<Utf16> namePtr = 'Local\\MySemaphore'.toNativeUtf16();

  // Note: Ensure the string is correctly formatted as LPCWSTR (Utf16)
  final int handle = CreateSemaphoreW(
    0, // NULL security attributes (represented as int address 0)
    WindowsCreateSemaphoreWMacros.INITIAL_VALUE_RECOMMENDED,
    WindowsCreateSemaphoreWMacros.MAXIMUM_VALUE_RECOMMENDED,
    namePtr,
  );

  if (handle == 0) {
    // In a real application, you'd use GetLastError() instead of a hardcoded constant
    throw WindowsCreateSemaphoreWError.fromErrorCode(
      WindowsCreateSemaphoreWMacros.ERROR_INVALID_NAME
    );
  }
}
```

#### `WaitForSingleObject`

Waits until the specified object is in the signaled state or the time-out interval elapses.

```dart
import 'package:runtime_native_semaphores/src/ffi/windows.dart';

void exampleWaitForSingleObject(int handle) {
  int waitResult = WaitForSingleObject(
    handle, 
    WindowsWaitForSingleObjectMacros.TIMEOUT_INFINITE
  );

  if (waitResult == WindowsWaitForSingleObjectMacros.WAIT_FAILED) {
    print('Wait failed');
  } else if (waitResult == WindowsWaitForSingleObjectMacros.WAIT_OBJECT_0) {
    print('Semaphore acquired');
  }
}
```

#### `ReleaseSemaphore`

Releases the specified semaphore by increasing its count.

```dart
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:runtime_native_semaphores/src/ffi/windows.dart';

void exampleReleaseSemaphore(int handle) {
  final Pointer<Int32> previousCount = calloc<Int32>();

  int success = ReleaseSemaphore(
    handle,
    WindowsReleaseSemaphoreMacros.RELEASE_COUNT_RECOMMENDED,
    previousCount,
  );

  if (success == 0) {
    throw WindowsReleaseSemaphoreError.fromErrorCode(
      WindowsReleaseSemaphoreMacros.ERROR_SEM_OVERFLOW
    );
  } else {
    print('Semaphore released, previous count: ${previousCount.value}');
  }
}
```

#### `CloseHandle`

Closes an open object handle.

```dart
import 'package:runtime_native_semaphores/src/ffi/windows.dart';

void exampleCloseHandle(int handle) {
  int success = CloseHandle(handle);

  if (success == 0) {
    print('Failed to close handle');
  }
}
```
