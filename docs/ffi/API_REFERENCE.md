# FFI Bindings API Reference

This document covers the FFI Bindings for both POSIX (Unix) and Windows platforms provided in the `lib/src/ffi/` directory.

---

## Unix FFI Bindings (`unix.dart`)

### Typedefs

* **`sem_t`**
  `typedef sem_t = Int;`
  Defines the native integer type for `sem_t` on Unix systems.

### Structs and Core Types

* **`mode_t`**
  `final class mode_t extends AbiSpecificInteger`
  An ABI-specific unsigned integer type used for specifying file permissions and types during creation or modification operations. Maps to `Uint16` or `Uint64` depending on the platform ABI.

### Constants & Utilities

* **`MODE_T_PERMISSIONS`**
  Constants and utility functions for POSIX permissions.
  * **Methods:**
    * `static int perm({int u = 0, int g = 0, int o = 0, int user = 0, int group = 0, int others = 0})`: Generates permission masks.
  * **Constants:**
    * `x` (1), `w` (2), `r` (4), `rw`, `rx`, `wx`, `rwx`
    * `RECOMMENDED`
    * `OWNER_READ_WRITE_GROUP_READ`
    * `OWNER_READ_WRITE_GROUP_AND_OTHERS_READ_WRITE`
    * `OWNER_READ_WRITE_GROUP_NO_ACCESS`
    * `OWNER_READ_WRITE_EXECUTE_GROUP_NO_ACCESS`
    * `OWNER_READ_WRITE_EXECUTE_GROUP_AND_OTHERS_READ_EXECUTE`
    * `ALL_READ_WRITE_EXECUTE`

* **`UnixSemLimits`**
  System limit values for semaphores.
  * `static bool isBSD`
  * `static int PATH_MAX`
  * `static int SEM_VALUE_MAX`
  * `static int NAME_MAX`
  * `static int NAME_MAX_CHARACTERS`

* **`UnixSemOpenMacros`**
  Macros and error codes used with `sem_open`.
  * Flags: `O_CREAT`, `_O_EXCL`, `O_EXCL`, `SEM_FAILED`, `VALUE_RECOMMENDED`
  * Error Codes: `EACCES`, `EINTR`, `EEXIST`, `EINVAL`, `EMFILE`, `ENAMETOOLONG`, `ENFILE`, `ENOENT`, `ENOMEM`, `ENOSPC`, `EFAULT`

* **`UnixSemWaitOrTryWaitMacros`**
  Macros and error codes used with `sem_wait` and `sem_trywait`.
  * Error Codes: `EAGAIN`, `EDEADLK`, `EINTR`, `EINVAL`

* **`UnixSemCloseMacros`**
  Macros for `sem_close`.
  * Error Codes: `EINVAL`

* **`UnixSemUnlinkMacros`**
  Macros for `sem_unlink`.
  * Error Codes: `ENOENT`, `EACCES`, `ENAMETOOLONG`

* **`UnixSemUnlockWithPostMacros`**
  Macros for `sem_post`.
  * Error Codes: `EINVAL`, `EOVERFLOW`

### External Functions

```dart
/// Creates or opens a named POSIX semaphore.
external Pointer<sem_t> sem_open(Pointer<Char> name, int oflag, int mode, int value);

/// Decrements (locks) the semaphore, blocking if value is currently zero.
external int sem_wait(Pointer<sem_t> sem_t);

/// Decrements (locks) the semaphore if possible, without blocking.
external int sem_trywait(Pointer<sem_t> sem_t);

/// Increments (unlocks) the semaphore.
external int sem_post(Pointer<sem_t> sem_t);

/// Closes the semaphore.
external int sem_close(Pointer<sem_t> sem_t);

/// Unlinks the named semaphore.
external int sem_unlink(Pointer<Char> name);
```

### Errors

* **`UnixSemError`**: Base class for all Unix semaphore FFI errors.
* **`UnixSemOpenError`**: Thrown when `sem_open` fails.
* **`UnixSemOpenErrorUnixSemWaitOrTryWaitError`**: Thrown when `sem_wait` or `sem_trywait` fail.
* **`UnixSemCloseError`**: Thrown when `sem_close` fails.
* **`UnixSemUnlinkError`**: Thrown when `sem_unlink` fails.
* **`UnixSemUnlockWithPostError`**: Thrown when `sem_post` fails.

Each error class has a `.fromErrno(int errno)` factory.

---

## Windows FFI Bindings (`windows.dart`)

### Typedefs

* **`HANDLE`** (`IntPtr`)
* **`LONG`** (`Int32`)
* **`BOOL`** (`Uint32`)
* **`DWORD`** (`Uint32`)
* **`LPCWSTR`** (`Pointer<Utf16>`)

### Structs

* **`SECURITY_ATTRIBUTES`**
  Specifies the security descriptor for an object and indicates if the handle is inheritable.
  * `int nLength`
  * `Pointer lpSecurityDescriptor`
  * `int bInheritHandle`

* **`SECURITY_DESCRIPTOR`**
  Contains the security information associated with an object.
  * `int Revision`
  * `int Sbz1`
  * `int Control`
  * `Pointer Owner`
  * `Pointer Group`
  * `Pointer<ACL> Sacl`
  * `Pointer<ACL> Dacl`

* **`ACL`**
  Access Control List structure.
  * `int AclRevision`
  * `int Sbz1`
  * `int AclSize`
  * `int AceCount`
  * `int Sbz2`

### Constants & Utilities

* **`WindowsCreateSemaphoreWMacros`**
  Macros and error codes for creating a semaphore.
  * Defaults: `INITIAL_VALUE_RECOMMENDED`, `MAXIMUM_VALUE_RECOMMENDED`, `NULL`, `SEM_FAILED`
  * Prefixes: `GLOBAL_NAME_PREFIX`, `LOCAL_NAME_PREFIX`
  * Error Codes: `ERROR_SUCCESS`, `ERROR_ACCESS_DENIED`, `ERROR_INVALID_HANDLE`, `ERROR_INVALID_PARAMETER`, `ERROR_TOO_MANY_POSTS`, `ERROR_SEM_NOT_FOUND`, `ERROR_SEM_IS_SET`, `ERROR_INVALID_NAME`

* **`WindowsWaitForSingleObjectMacros`**
  Macros for `WaitForSingleObject`.
  * Constants: `TIMEOUT_RECOMMENDED`, `TIMEOUT_INFINITE`, `TIMEOUT_ZERO`
  * Return states: `WAIT_OBJECT_0`, `WAIT_TIMEOUT`, `WAIT_ABANDONED`, `WAIT_FAILED`

* **`WindowsReleaseSemaphoreMacros`**
  Macros for releasing a semaphore.
  * Constants: `RELEASE_COUNT_RECOMMENDED`, `PREVIOUS_RELEASE_COUNT_RECOMMENDED`, `NULL`
  * Error Codes: `ERROR_SEM_OVERFLOW`

* **`WindowsCloseHandleMacros`**
  Macros for handle closing operations.
  * Constants: `INVALID_HANDLE_VALUE`

### External Functions

```dart
/// Creates or opens a named or unnamed semaphore object.
external int CreateSemaphoreW(int lpSecurityAttributes, int lInitialCount, int lMaximumCount, LPCWSTR lpName);

/// Waits until the specified object is in the signaled state or the time-out interval elapses.
external int WaitForSingleObject(int hHandle, int dwMilliseconds);

/// Releases the specified semaphore by increasing its count.
external int ReleaseSemaphore(int hSemaphore, int lReleaseCount, Pointer<LONG> lpPreviousCount);

/// Closes an open object handle.
external int CloseHandle(int hObject);
```

### Errors

* **`WindowsCreateSemaphoreWError`**: Thrown on `CreateSemaphoreW` failure.
* **`WindowsReleaseSemaphoreError`**: Thrown on `ReleaseSemaphore` failure.

Each error class has a `.fromErrorCode(int code)` factory to map Windows error codes to Dart exceptions.
