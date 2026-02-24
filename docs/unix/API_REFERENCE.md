# Unix FFI Bindings API Reference

This module provides direct Dart FFI bindings to POSIX semaphores for Unix-based systems (macOS and Linux). 

## 1. Top-Level Functions

### **sem_t** (Typedef)
```dart
typedef sem_t = Int;
```
Native type representation of a Unix semaphore.

### **sem_open**
```dart
@Native<Pointer<sem_t> Function(Pointer<Char>, Int, VarArgs<(mode_t, UnsignedInt)>)>()
external Pointer<sem_t> sem_open(Pointer<Char> name, int oflag, int mode, int value);
```
Creates a new POSIX semaphore or opens an existing semaphore identified by `name`.

**Parameters:**
- `name`: Pointer to the semaphore name string.
- `oflag`: Flags that control the operation (e.g., `UnixSemOpenMacros.O_CREAT`, `UnixSemOpenMacros.O_EXCL`).
- `mode`: Permissions to be placed on the new semaphore (e.g., `MODE_T_PERMISSIONS.RECOMMENDED`).
- `value`: Initial value for the new semaphore.

**Returns:**
A pointer to the semaphore, or `UnixSemOpenMacros.SEM_FAILED` on error. Check `errno.value` for the specific error.

### **sem_wait**
```dart
@Native<Int Function(Pointer<sem_t>)>()
external int sem_wait(Pointer<sem_t> sem_t);
```
Decrements (locks) the semaphore. If the semaphore currently has the value zero, the call blocks until the semaphore value rises above zero or a signal interrupts the call.

**Returns:**
`0` on success, or `-1` on error with `errno` set.

### **sem_trywait**
```dart
@Native<Int Function(Pointer<sem_t>)>()
external int sem_trywait(Pointer<sem_t> sem_t);
```
Decrements (locks) the semaphore only if it can be immediately performed without blocking.

**Returns:**
`0` on success, or `-1` on error (returns `UnixSemWaitOrTryWaitMacros.EAGAIN` in `errno` if it would block).

### **sem_post**
```dart
@Native<Int Function(Pointer<sem_t>)>()
external int sem_post(Pointer<sem_t> sem_t);
```
Increments (unlocks) the semaphore, potentially waking up processes blocked on `sem_wait`.

**Returns:**
`0` on success, or `-1` on error with `errno` set.

### **sem_close**
```dart
@Native<Int Function(Pointer<sem_t>)>()
external int sem_close(Pointer<sem_t> sem_t);
```
Closes the named semaphore, allowing any resources that the system has allocated to be freed.

**Returns:**
`0` on success, or `-1` on error with `errno` set.

### **sem_unlink**
```dart
@Native<Int Function(Pointer<Char>)>()
external int sem_unlink(Pointer<Char> name);
```
Removes the named semaphore. The semaphore is destroyed once all other processes close it.

**Returns:**
`0` on success, or `-1` on error with `errno` set.

### **errno**
```dart
Pointer<Int> get errno;
```
Dynamically returns a pointer to the current platform's `errno` by delegating to `__error()` on macOS (BSD) or `__errno_location()` on Linux.

---

## 2. Example Usage

```dart
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:runtime_native_semaphores/src/ffi/unix.dart';

void main() {
  final name = '/my_semaphore'.toNativeUtf8();
  
  // 1. Create a new semaphore with initial value 1
  final sem = sem_open(
    name.cast<Char>(),
    UnixSemOpenMacros.O_CREAT,
    MODE_T_PERMISSIONS.RECOMMENDED,
    UnixSemOpenMacros.VALUE_RECOMMENDED,
  );
  
  if (sem.address == UnixSemOpenMacros.SEM_FAILED.address) {
    throw UnixSemOpenError.fromErrno(errno.value);
  }
  
  // 2. Wait (lock)
  if (sem_wait(sem) != 0) {
    throw UnixSemOpenErrorUnixSemWaitOrTryWaitError.fromErrno(errno.value);
  }
  
  // ... perform critical section work ...
  
  // 3. Post (unlock)
  if (sem_post(sem) != 0) {
    throw UnixSemUnlockWithPostError.fromErrno(errno.value);
  }
  
  // 4. Close the semaphore
  if (sem_close(sem) != 0) {
    throw UnixSemCloseError.fromErrno(errno.value);
  }
  
  // 5. Unlink the semaphore from the system
  if (sem_unlink(name.cast<Char>()) != 0) {
    throw UnixSemUnlinkError.fromErrno(errno.value);
  }
  
  malloc.free(name);
}
```

---

## 3. Classes and Macros

### **mode_t**
Data Type: `mode_t` is typically defined as an unsigned integer type for specifying file permissions and type when creating new files or directories. Extending `AbiSpecificInteger`.

### **MODE_T_PERMISSIONS**
Provides constants and helper methods for setting `mode_t` permissions using octal bitmask patterns.
- `static int RECOMMENDED`: Recommended permissions for named semaphores (`0644`).
- `static int OWNER_READ_WRITE_GROUP_READ`: Permissions `0644`.
- `static int OWNER_READ_WRITE_GROUP_AND_OTHERS_READ_WRITE`: Permissions `0666`.
- `static int OWNER_READ_WRITE_GROUP_NO_ACCESS`: Permissions `0600`.
- `static int OWNER_READ_WRITE_EXECUTE_GROUP_NO_ACCESS`: Permissions `0700`.
- `static int OWNER_READ_WRITE_EXECUTE_GROUP_AND_OTHERS_READ_EXECUTE`: Permissions `0755`.
- `static int ALL_READ_WRITE_EXECUTE`: Permissions `0777`.

**Helper Method:**
```dart
static int perm({int u = 0, int g = 0, int o = 0, int user = 0, int group = 0, int others = 0})
```

### **UnixSemLimits**
Constants defining various limits for Unix semaphores.
- `PATH_MAX` (1024): Maximum length for a path in bytes.
- `SEM_VALUE_MAX` (32767): Maximum value for a semaphore.
- `NAME_MAX` (255): Maximum size of a name component in bytes.
- `NAME_MAX_CHARACTERS` (30): Maximum characters for a named semaphore.

### **UnixSemOpenMacros**
Macros and flags used by the `sem_open` function.
- `O_CREAT`: Flag to create a semaphore if it does not already exist.
- `O_EXCL`: Flag used with `O_CREAT` to fail if semaphore already exists.
- `SEM_FAILED`: Pointer value returned when `sem_open` fails.
- `VALUE_RECOMMENDED`: Recommended initial value for the semaphore (1).
- Error constants: `EACCES`, `EINTR`, `EEXIST`, `EINVAL`, `EMFILE`, `ENAMETOOLONG`, `ENFILE`, `ENOENT`, `ENOMEM`, `ENOSPC`, `EFAULT`.

### **UnixSemWaitOrTryWaitMacros**
Macros and flags related to `sem_wait` and `sem_trywait`.
- Error constants: `EAGAIN` (already locked), `EDEADLK`, `EINTR`, `EINVAL`.

### **UnixSemCloseMacros**
- `EINVAL`: Semaphore argument is invalid.

### **UnixSemUnlinkMacros**
- Error constants: `ENOENT`, `EACCES`, `ENAMETOOLONG`.

### **UnixSemUnlockWithPostMacros**
- Error constants: `EINVAL`, `EOVERFLOW`.

---

## 4. Error Handling Classes

All error classes extend `UnixSemError` (which extends `Error`) and provide a `fromErrno(int errno)` factory method to map POSIX error codes to Dart exceptions.

- **UnixSemError**: Base class for errors raised during Unix semaphore operations.
- **UnixSemOpenError**: Specific to failures originating from `sem_open`.
- **UnixSemOpenErrorUnixSemWaitOrTryWaitError**: Specific to failures originating from `sem_wait` or `sem_trywait`.
- **UnixSemCloseError**: Specific to failures originating from `sem_close`.
- **UnixSemUnlinkError**: Specific to failures originating from `sem_unlink`.
- **UnixSemUnlockWithPostError**: Specific to failures originating from `sem_post`.

Each class provides the following properties:
- `int code`: The underlying POSIX error code (`errno`).
- `String message`: Descriptive error message corresponding to the code.
- `String? identifier`: String identifier for the error (e.g., `'EACCES'`).
- `bool critical`: Indicates if the error is critical.
