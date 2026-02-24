# Unix FFI Bindings API Reference

## 1. Classes

### mode_t
Data Type: `mode_t` is typically defined as an unsigned integer type. It specifies file permissions and type when creating new files or directories. Extends `AbiSpecificInteger`.
- **Constructors**
  - `const mode_t()`: Creates a new `mode_t` instance.

### MODE_T_PERMISSIONS
A class defining the various permission bits and macros for a `mode_t` integer.

```dart
import 'package:native_semaphores/src/ffi/unix.dart';

// Example: Creating custom permissions
final int myPermissions = MODE_T_PERMISSIONS.perm(
  u: MODE_T_PERMISSIONS.rwx, 
  g: MODE_T_PERMISSIONS.rx, 
  o: MODE_T_PERMISSIONS.r,
);
```

- **Fields**
  - `static int x`: Execute permission bit (1).
  - `static int w`: Write permission bit (2).
  - `static int r`: Read permission bit (4).
  - `static int rw`: Read and write permission (`r | w`).
  - `static int rx`: Read and execute permission (`r | x`).
  - `static int wx`: Write and execute permission (`w | x`).
  - `static int rwx`: Read, write, and execute permission (`r | w | x`).
  - `static int RECOMMENDED`: Most common for named semaphores (`OWNER_READ_WRITE_GROUP_READ`).
  - `static int OWNER_READ_WRITE_GROUP_READ`: 0644 - Owner can read and write; the group can read; others can read.
  - `static int OWNER_READ_WRITE_GROUP_AND_OTHERS_READ_WRITE`: 0666 - Owner can read and write; the group can read and write; others can read and write.
  - `static int OWNER_READ_WRITE_GROUP_NO_ACCESS`: 0600 - Owner can read and write; the group cannot access; others cannot access.
  - `static int OWNER_READ_WRITE_EXECUTE_GROUP_NO_ACCESS`: 0700 - Owner can read, write, and execute; the group cannot access; others cannot access.
  - `static int OWNER_READ_WRITE_EXECUTE_GROUP_AND_OTHERS_READ_EXECUTE`: 0755 - Owner can read, write, and execute; the group can read and execute; others can read and execute.
  - `static int ALL_READ_WRITE_EXECUTE`: 0777 - Owner can read, write, and execute; the group can read, write, and execute; others can read, write, and execute.
- **Methods**
  - `static int perm({int u = 0, int g = 0, int o = 0, int user = 0, int group = 0, int others = 0})`: Helper method to generate an integer representing octal permissions.

### UnixSemLimits
Defines limits and maximums specific to Unix implementations of semaphores.
- **Fields**
  - `static bool isBSD`: `true` if platform is MacOS.
  - `static int PATH_MAX`: Size in bytes for a path including null terminator (1024).
  - `static int SEM_VALUE_MAX`: Maximum value of a semaphore (32767).
  - `static int NAME_MAX`: Maximum bytes of a semaphore name (255).
  - `static int NAME_MAX_CHARACTERS`: Maximum characters of a semaphore name (30).

### UnixSemOpenMacros
Defines macros and error codes corresponding to `sem_open` operations.
- **Fields**
  - `static bool isBSD`: Returns true if the platform is MacOS.
  - `static int EACCES`: Permission denied error code (13).
  - `static int EINTR`: Interrupted by a signal error code (4).
  - `static int EEXIST`: Semaphore already exists error code (17).
  - `static int EINVAL`: Invalid argument or unsupported name error code (22).
  - `static int EMFILE`: Too many semaphore descriptors or file descriptors open error code (24).
  - `static int ENAMETOOLONG`: Name too long error code.
  - `static int ENFILE`: Too many semaphores are currently open in the system error code (23).
  - `static int ENOENT`: No semaphore with this name exists error code (2).
  - `static int ENOMEM`: Insufficient memory error code (12).
  - `static int ENOSPC`: Insufficient space error code (28).
  - `static int EFAULT`: Invalid memory address error code (14).
  - `static Pointer<Uint64> SEM_FAILED`: Pointer representing a failed semaphore open attempt.
  - `static int O_CREAT`: Flag to create a semaphore if it does not already exist.
  - `static int _O_EXCL`: Internal exclusive flag.
  - `static int O_EXCL`: Exclusive flag used alongside `O_CREAT` to fail if the semaphore name already exists.
  - `static int VALUE_RECOMMENDED`: Default initial value for a new semaphore (1).

### UnixSemError
Base class for all errors related to Unix semaphores. Extends `Error`.
- **Constructors**
  - `UnixSemError(this.code, this.message, this.identifier, [this.critical = true])`
- **Fields**
  - `final bool critical`: True if the error is considered critical.
  - `final int code`: The internal errno code.
  - `final String message`: Descriptive error message.
  - `final String? identifier`: A string identifier for the error.
  - `late final String? description`: A string representation of the error object.
- **Methods**
  - `String toString()`: Returns a string describing the error code and message.

### UnixSemOpenError
An error thrown specifically during a `sem_open` operation. Extends `UnixSemError`.
- **Constructors**
  - `UnixSemOpenError(code, message, identifier, [bool critical = true])`
- **Methods**
  - `static UnixSemOpenError fromErrno(int errno)`: Factory constructor to create an error from a system `errno`.
  - `String toString()`: Overrides to indicate an open error.

### UnixSemWaitOrTryWaitMacros
Defines macros and error codes corresponding to `sem_wait` and `sem_trywait` operations.
- **Fields**
  - `static bool isBSD`: Returns true if the platform is MacOS.
  - `static int EAGAIN`: Semaphore already locked error code.
  - `static int EDEADLK`: Deadlock condition detected error code.
  - `static int EINTR`: Call interrupted by a signal error code.
  - `static int EINVAL`: Invalid semaphore argument error code.

### UnixSemOpenErrorUnixSemWaitOrTryWaitError
An error thrown during a `sem_wait` or `sem_trywait` operation. Extends `UnixSemError`.
- **Constructors**
  - `UnixSemOpenErrorUnixSemWaitOrTryWaitError(code, message, identifier, [critical = true])`
- **Methods**
  - `static UnixSemOpenErrorUnixSemWaitOrTryWaitError fromErrno(int errno)`: Factory method to construct an error from a system `errno`.
  - `String toString()`: Overrides to indicate a sem_wait/try_wait error.

### UnixSemCloseMacros
Defines macros and error codes corresponding to `sem_close` operations.
- **Fields**
  - `static bool isBSD`: Returns true if the platform is MacOS.
  - `static int EINVAL`: Invalid semaphore argument error code (22).

### UnixSemCloseError
An error thrown specifically during a `sem_close` operation. Extends `UnixSemError`.
- **Constructors**
  - `UnixSemCloseError(code, message, identifier, [critical = true])`
- **Methods**
  - `static UnixSemCloseError fromErrno(int errno)`: Factory method to construct an error from a system `errno`.
  - `String toString()`: Overrides to indicate a close error.

### UnixSemUnlinkMacros
Defines macros and error codes corresponding to `sem_unlink` operations.
- **Fields**
  - `static bool isBSD`: Returns true if the platform is MacOS.
  - `static int ENOENT`: Named semaphore does not exist error code (2).
  - `static int EACCES`: Permission denied to unlink error code (13).
  - `static int ENAMETOOLONG`: Name too long error code.

### UnixSemUnlinkError
An error thrown specifically during a `sem_unlink` operation. Extends `UnixSemError`.
- **Constructors**
  - `UnixSemUnlinkError(code, message, identifier, [critical = true])`
- **Methods**
  - `static UnixSemUnlinkError fromErrno(int errno)`: Factory method to construct an error from a system `errno`.
  - `String toString()`: Overrides to indicate an unlink error.

### UnixSemUnlockWithPostMacros
Defines macros and error codes corresponding to `sem_post` operations.
- **Fields**
  - `static bool isBSD`: Returns true if the platform is MacOS.
  - `static int EINVAL`: Invalid semaphore argument error code.
  - `static int EOVERFLOW`: Maximum allowable value for a semaphore exceeded error code.

### UnixSemUnlockWithPostError
An error thrown specifically during a `sem_post` (unlock) operation. Extends `UnixSemError`.
- **Constructors**
  - `UnixSemUnlockWithPostError(code, message, identifier, [critical = true])`
- **Methods**
  - `static UnixSemUnlockWithPostError fromErrno(int errno)`: Factory method to construct an error from a system `errno`.
  - `String toString()`: Overrides to indicate a sem_post error.

## 2. Enums
*(No public enums are defined in this module)*

## 3. Extensions
*(No public extensions are defined in this module)*

## 4. Top-Level Functions

### sem_open
`external Pointer<sem_t> sem_open(Pointer<Char> name, int oflag, int mode, int value)`
Creates a new POSIX semaphore or opens an existing semaphore identified by `name`.

```dart
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:native_semaphores/src/ffi/unix.dart';

// Example: Opening a semaphore
final Pointer<Char> namePtr = '/my_semaphore'.toNativeUtf8().cast<Char>();
final Pointer<sem_t> sem = sem_open(
  namePtr,
  UnixSemOpenMacros.O_CREAT,
  MODE_T_PERMISSIONS.RECOMMENDED,
  UnixSemOpenMacros.VALUE_RECOMMENDED,
);

if (sem.address == UnixSemOpenMacros.SEM_FAILED.address) {
  throw UnixSemOpenError.fromErrno(errno.value);
}
```

### sem_wait
`external int sem_wait(Pointer<sem_t> sem_t)`
Decrements (locks) the semaphore pointed to by `sem_t`. Blocks if the value is zero until it becomes possible to perform the decrement.

```dart
// Example: Waiting (locking) the semaphore
final int result = sem_wait(sem);
if (result != 0) {
  throw UnixSemOpenErrorUnixSemWaitOrTryWaitError.fromErrno(errno.value);
}
```

### sem_trywait
`external int sem_trywait(Pointer<sem_t> sem_t)`
Decrements (locks) the semaphore pointed to by `sem_t`. Returns an error (`EAGAIN`) immediately if the decrement cannot be performed instead of blocking.

```dart
// Example: Attempting to lock without blocking
final int tryResult = sem_trywait(sem);
if (tryResult != 0) {
  if (errno.value == UnixSemWaitOrTryWaitMacros.EAGAIN) {
    print('Semaphore is currently locked.');
  } else {
    throw UnixSemOpenErrorUnixSemWaitOrTryWaitError.fromErrno(errno.value);
  }
}
```

### sem_post
`external int sem_post(Pointer<sem_t> sem_t)`
Increments (unlocks) the semaphore pointed to by `sem_t`. Unblocks any thread blocked waiting in `sem_wait`.

```dart
// Example: Releasing (unlocking) the semaphore
final int postResult = sem_post(sem);
if (postResult != 0) {
  throw UnixSemUnlockWithPostError.fromErrno(errno.value);
}
```

### sem_close
`external int sem_close(Pointer<sem_t> sem_t)`
Closes the named semaphore referred to by `sem_t`, allowing resources allocated to the process to be freed.

```dart
// Example: Closing the semaphore for the current process
final int closeResult = sem_close(sem);
if (closeResult != 0) {
  throw UnixSemCloseError.fromErrno(errno.value);
}
```

### sem_unlink
`external int sem_unlink(Pointer<Char> name)`
Removes the named semaphore referred to by `name`. The semaphore is destroyed once all other processes that have it open close it.

```dart
// Example: Unlinking the semaphore globally
final int unlinkResult = sem_unlink(namePtr);
if (unlinkResult != 0) {
  throw UnixSemUnlinkError.fromErrno(errno.value);
}

// Don't forget to free the allocated memory for the name
malloc.free(namePtr);
```

### __error
`external Pointer<Int> __error()`
Retrieves the system's `errno` value pointer on macOS platforms.

### __errno_location
`external Pointer<Int> __errno_location()`
Retrieves the system's `errno` value pointer on Linux platforms.

### _errno
`Pointer<Int> Function() _errno`
Variable storing the function that gets the current `errno` dynamically based on the platform (`Platform.isMacOS ? __error() : __errno_location()`).

### get errno
`Pointer<Int> get errno`
Top-level getter returning the current value of the system `errno` variable using the platform-specific implementation.

```dart
// Example: Getting the current errno value
final int currentError = errno.value;
```
