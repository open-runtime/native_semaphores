# Windows FFI Bindings API Reference

## 1. Structs (Classes)

### **SECURITY_ATTRIBUTES**
The `SECURITY_ATTRIBUTES` structure contains the security descriptor for an object and specifies whether the handle retrieved by specifying this structure is inheritable. This structure provides security settings for objects created by various functions.

- **Fields:**
  - `nLength` (`int`): The size, in bytes, of this structure. Set this value to the size of the `SECURITY_ATTRIBUTES` structure.
  - `lpSecurityDescriptor` (`Pointer`): A pointer to a `SECURITY_DESCRIPTOR` structure that controls access to the object.
  - `bInheritHandle` (`int`): A Boolean value that specifies whether the returned handle is inherited when a new process is created.

**Example:**
```dart
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:runtime_native_semaphores/runtime_native_semaphores.dart';

void main() {
  final sa = calloc<SECURITY_ATTRIBUTES>()
    ..ref.nLength = sizeOf<SECURITY_ATTRIBUTES>()
    ..ref.bInheritHandle = 1 // TRUE
    ..ref.lpSecurityDescriptor = nullptr;

  print('SECURITY_ATTRIBUTES initialized with size: ${sa.ref.nLength}');
  calloc.free(sa);
}
```

### **SECURITY_DESCRIPTOR**
The `SECURITY_DESCRIPTOR` structure contains the security information associated with an object. Applications use this structure to set and query an object's security status.

- **Fields:**
  - `Revision` (`int`)
  - `Sbz1` (`int`)
  - `Control` (`int`)
  - `Owner` (`Pointer`)
  - `Group` (`Pointer`)
  - `Sacl` (`Pointer<ACL>`)
  - `Dacl` (`Pointer<ACL>`)

### **ACL**
The `ACL` structure is the header of an access control list (ACL). A complete ACL consists of an `ACL` structure followed by an ordered list of zero or more access control entries (ACEs).

- **Fields:**
  - `AclRevision` (`int`)
  - `Sbz1` (`int`)
  - `AclSize` (`int`)
  - `AceCount` (`int`)
  - `Sbz2` (`int`)

### **WindowsCreateSemaphoreWMacros**
Macros and constants used with the `CreateSemaphoreW` function.

- **Constants:**
  - `NULL` (`Pointer<Never>`): A null pointer constant.
  - `SEM_FAILED` (`Pointer<Never>`): A null pointer indicating a failed semaphore creation.
  - `ERROR_INVALID_NAME` (`int`: `123`): The specified name is invalid (too long or invalid characters).
  - `ERROR_SUCCESS` (`int`: `0`): The operation completed successfully.
  - `ERROR_ACCESS_DENIED` (`int`: `5`): The caller does not have the required access rights.
  - `ERROR_INVALID_HANDLE` (`int`: `6`): An invalid handle was specified.
  - `ERROR_INVALID_PARAMETER` (`int`: `87`): One of the parameters was invalid.
  - `ERROR_TOO_MANY_POSTS` (`int`: `298`): Exceeds maximum count.
  - `ERROR_SEM_NOT_FOUND` (`int`: `187`): Semaphore does not exist.
  - `ERROR_SEM_IS_SET` (`int`: `102`): Semaphore is already set.
  - `INITIAL_VALUE_RECOMMENDED` (`int`: `1`)
  - `MAXIMUM_VALUE_RECOMMENDED` (`int`: `2`)
  - `GLOBAL_NAME_PREFIX` (`String`: `'Global\\'`)
  - `LOCAL_NAME_PREFIX` (`String`: `'Local\\'`)
  - `MAX_PATH` (`int`): Maximum length of a path for a named semaphore.

### **WindowsCreateSemaphoreWError**
Error class representing errors that occur when creating or opening a semaphore. Extends `Error`.

- **Constructors:**
  - `WindowsCreateSemaphoreWError(int code, String message, String? identifier)`
- **Factory Methods:**
  - `static WindowsCreateSemaphoreWError fromErrorCode(int code)`: Creates an error instance from a specific Windows error code.
- **Fields:**
  - `code` (`int`)
  - `message` (`String`)
  - `identifier` (`String?`)
  - `description` (`String?`)

### **WindowsWaitForSingleObjectMacros**
Macros and constants used with the `WaitForSingleObject` function.

- **Constants:**
  - `TIMEOUT_RECOMMENDED` (`int`): Default timeout value (Infinite).
  - `TIMEOUT_INFINITE` (`int`: `0xFFFFFFFF`): Return only when the object is signaled.
  - `TIMEOUT_ZERO` (`int`: `0`): Return immediately if the object is not signaled.
  - `WAIT_ABANDONED` (`int`: `0x00000080`): The specified object is a mutex object that was not released.
  - `WAIT_OBJECT_0` (`int`: `0x00000000`): The state of the specified object is signaled.
  - `WAIT_TIMEOUT` (`int`: `0x00000102`): The time-out interval elapsed.
  - `WAIT_FAILED` (`int`: `0xFFFFFFFF`): The function has failed.

### **WindowsReleaseSemaphoreMacros**
Macros and constants used with the `ReleaseSemaphore` function.

- **Constants:**
  - `RELEASE_COUNT_RECOMMENDED` (`int`: `1`)
  - `PREVIOUS_RELEASE_COUNT_RECOMMENDED` (`Pointer<Never>`)
  - `ERROR_SEM_OVERFLOW` (`int`: `105`)
  - `NULL` (`Pointer<Never>`)

### **WindowsReleaseSemaphoreError**
Error class representing errors that occur when releasing a semaphore. Extends `Error`.

- **Constructors:**
  - `WindowsReleaseSemaphoreError(int code, String message, String? identifier)`
- **Factory Methods:**
  - `static WindowsReleaseSemaphoreError fromErrorCode(int code)`: Creates an error from a specific Windows error code.
- **Fields:**
  - `code` (`int`)
  - `message` (`String`)
  - `identifier` (`String?`)
  - `description` (`String?`)

### **WindowsCloseHandleMacros**
Macros and constants used with the `CloseHandle` function.

- **Constants:**
  - `INVALID_HANDLE_VALUE` (`int`: `-1`)

---

## 2. Enums

*(No public enums defined in this module)*

---

## 3. Extensions

*(No public extensions defined in this module)*

---

## 4. Top-Level Functions

### **CreateSemaphoreW**
Creates or opens a named or unnamed semaphore object.

- **Signature:** `int CreateSemaphoreW(int lpSecurityAttributes, int lInitialCount, int lMaximumCount, LPCWSTR lpName)`
- **Parameters:**
  - `lpSecurityAttributes` (`int`): Pointer to a `SECURITY_ATTRIBUTES` structure (passed as `IntPtr`). Can be `NULL` for default security.
  - `lInitialCount` (`int`): Initial count for the semaphore object.
  - `lMaximumCount` (`int`): Maximum count for the semaphore object.
  - `lpName` (`LPCWSTR`): Name of the semaphore object, encoded as UTF-16.

**Example:**
```dart
import 'package:ffi/ffi.dart';
import 'package:runtime_native_semaphores/runtime_native_semaphores.dart';

void main() {
  final semaphoreName = 'Global\\MyTestSemaphore'.toNativeUtf16();
  
  // Create a new semaphore with an initial and maximum count of 1
  final handle = CreateSemaphoreW(
    WindowsCreateSemaphoreWMacros.NULL.address,
    1, // Initial count
    1, // Maximum count
    semaphoreName,
  );
  
  if (handle == WindowsCreateSemaphoreWMacros.SEM_FAILED.address) {
    print('Failed to create semaphore');
  } else {
    print('Semaphore created successfully with handle: $handle');
    CloseHandle(handle);
  }
  
  calloc.free(semaphoreName);
}
```

### **WaitForSingleObject**
Waits until the specified object is in the signaled state or the time-out interval elapses.

- **Signature:** `int WaitForSingleObject(int hHandle, int dwMilliseconds)`
- **Parameters:**
  - `hHandle` (`int`): Handle to the object (such as a semaphore).
  - `dwMilliseconds` (`int`): Time-out interval in milliseconds, or `TIMEOUT_INFINITE`.
- **Return Value:** Returns `WAIT_FAILED` on failure, `WAIT_OBJECT_0` if signaled, `WAIT_TIMEOUT` if timeout elapsed, and `WAIT_ABANDONED` if a mutex was not released.

**Example:**
```dart
import 'package:runtime_native_semaphores/runtime_native_semaphores.dart';

void waitOnSemaphore(int handle) {
  // Wait infinitely until the semaphore becomes signaled
  final result = WaitForSingleObject(
    handle, 
    WindowsWaitForSingleObjectMacros.TIMEOUT_INFINITE,
  );
  
  if (result == WindowsWaitForSingleObjectMacros.WAIT_OBJECT_0) {
    print('Semaphore acquired (signaled)!');
  } else if (result == WindowsWaitForSingleObjectMacros.WAIT_FAILED) {
    print('Wait failed.');
  }
}
```

### **ReleaseSemaphore**
Releases the specified semaphore by increasing its count by `lReleaseCount`.

- **Signature:** `int ReleaseSemaphore(int hSemaphore, int lReleaseCount, Pointer<LONG> lpPreviousCount)`
- **Parameters:**
  - `hSemaphore` (`int`): Handle to the semaphore object.
  - `lReleaseCount` (`int`): Amount to increase the current count. Must be greater than zero.
  - `lpPreviousCount` (`Pointer<LONG>`): Pointer to a variable to receive the previous count, or `NULL`.

**Example:**
```dart
import 'package:runtime_native_semaphores/runtime_native_semaphores.dart';

void releaseMySemaphore(int handle) {
  // Release the semaphore, increasing its count by 1
  final success = ReleaseSemaphore(
    handle, 
    WindowsReleaseSemaphoreMacros.RELEASE_COUNT_RECOMMENDED, 
    WindowsReleaseSemaphoreMacros.NULL.cast(),
  );
  
  if (success != 0) {
    print('Semaphore released successfully.');
  } else {
    print('Failed to release semaphore.');
  }
}
```

### **CloseHandle**
Closes an open object handle to avoid resource leaks.

- **Signature:** `int CloseHandle(int hObject)`
- **Parameters:**
  - `hObject` (`int`): Valid handle to an open object.
- **Return Value:** Returns a nonzero value if successful, or zero if it fails.

**Example:**
```dart
import 'package:runtime_native_semaphores/runtime_native_semaphores.dart';

void cleanUpHandle(int handle) {
  final success = CloseHandle(handle);
  if (success != 0) {
    print('Handle closed successfully.');
  } else {
    print('Failed to close handle.');
  }
}
```
