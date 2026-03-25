# Package Entry Points API Reference

## 1. Classes

### Core Classes

**SemaphoreIdentities** -- Registry and utility class for tracking `SemaphoreIdentity` instances.
- **Fields**:
  - `static String prefix`: The global prefix string.
  - `static String isolate`: The current isolate ID.
  - `static final String process`: The current process ID.
  - `Map<String, I> all`: Gets all registered identities as an unmodifiable map.
- **Methods**:
  - `bool has<T>({required String name})`: Checks if an identity exists by name.
  - `I get({required String name})`: Returns the semaphore identity for the given identifier.
  - `I register({required String name, required I identity})`: Registers a new identity.
  - `void delete({required String name})`: Deletes an identity from the registry.

**SemaphoreIdentity** -- Represents the unique identity of a native semaphore across isolates and processes.
- **Fields**:
  - `String prefix`: The global prefix.
  - `String isolate`: The isolate ID.
  - `String process`: The process ID.
  - `int address`: Gets/sets the address when the semaphore is opened.
  - `String name`: The name of the identity.
  - `bool registered`: Helper to know if it has been registered.
  - `String uuid`: A unique identifier combining name, isolate, and process.
- **Methods**:
  - `static SemaphoreIdentity instantiate(...)`: Factory method to instantiate or retrieve an identity.
  - `bool dispose()`: Disposes of the identity.
- **Example**:
  ```dart
  import 'package:runtime_native_semaphores/runtime_native_semaphores.dart';

  final identity = SemaphoreIdentity.instantiate(name: 'my_semaphore');
  print('Identity UUID: ${identity.uuid}');
  ```

**NativeSemaphores** -- A wrapper class to track instances of `NativeSemaphore`.
- **Fields**:
  - `Map<String, dynamic> all`: Gets all registered semaphore instances as an unmodifiable map.
- **Methods**:
  - `bool has<T>({required String name})`: Checks if a semaphore instance exists.
  - `NS get({required String name})`: Gets a registered semaphore instance.
  - `NS register({required String name, required NS semaphore})`: Registers a new semaphore instance.
  - `void delete({required String name})`: Removes a registered semaphore instance.

**NativeSemaphore** -- The core base class representing a native semaphore. Implemented by OS-specific classes.
- **Fields**:
  - `bool verbose`: Whether verbose logging is enabled.
  - `String name`: The name of the semaphore.
  - `CTR counter`: The `SemaphoreCounter` tracking this semaphore's usage.
  - `I identity`: The identity of the semaphore.
  - `bool opened`: Evaluates whether the semaphore is currently opened.
  - `bool closed`: Evaluates whether the semaphore is currently closed.
  - `bool unlinked`: Evaluates whether the semaphore has been unlinked (deleted).
  - `bool locked`: Evaluates whether the semaphore count is greater than zero (locked state).
  - `bool reentrant`: Evaluates whether the semaphore is locked reentrantly in the current isolate.
- **Methods**:
  - `static NativeSemaphore instantiate(...)`: Factory method to instantiate or retrieve a native semaphore instance (returns Windows or Unix variant based on platform).
  - `bool open()`: Opens the native semaphore.
  - `bool lock({bool blocking = true})`: Locks the native semaphore, updating process and isolate counts.
  - `bool unlock()`: Unlocks the native semaphore.
  - `bool close()`: Closes the native semaphore instance.
  - `bool unlink()`: Unlinks the native semaphore from the system.
- **Example**:
  ```dart
  import 'package:runtime_native_semaphores/runtime_native_semaphores.dart';

  void main() {
    final semaphore = NativeSemaphore.instantiate(name: 'shared_resource');
    semaphore.open();
    semaphore.lock();
    try {
      // Access shared resource securely across processes
      print('Semaphore locked: ${semaphore.locked}');
    } finally {
      semaphore.unlock();
      semaphore.close();
      semaphore.unlink();
    }
  }
  ```

**UnixSemaphore** -- Unix-specific implementation of `NativeSemaphore`.
- **Fields**:
  - `({bool isSet, Pointer<Char>? get}) identifier`: Gets the native UTF-8 identifier pointer if set.
  - `({bool isSet, Pointer<sem_t>? get}) semaphore`: Gets the native semaphore pointer if set.
- **Methods**:
  - Overrides core lifecycle methods (`open`, `lock`, `unlock`, `close`, `unlink`) to interact with POSIX FFI bindings.

**WindowsSemaphore** -- Windows-specific implementation of `NativeSemaphore`.
- **Fields**:
  - `({bool isSet, LPCWSTR? get}) identifier`: Gets the native UTF-16 identifier pointer if set.
  - `({bool isSet, Pointer<NativeType>? get}) semaphore`: Gets the native semaphore handle if set.
- **Methods**:
  - Overrides core lifecycle methods (`open`, `lock`, `unlock`, `close`, `unlink`) to interact with Win32 API FFI bindings.

### Counters & State Tracking

**SemaphoreCountUpdate** -- Represents an update operation to a semaphore count.
- **Fields**:
  - `String identifier`: The parent identifier.
  - `int? from`: The count value updated from.
  - `int to`: The count value updated to.

**SemaphoreCountDeletion** -- Represents a deletion operation of a semaphore count.
- **Fields**:
  - `String identifier`: The parent identifier.
  - `int? at`: The count value at deletion.

**SemaphoreCount** -- Tracks numerical state (like isolate/process locks) for a specific identifier.
- **Fields**:
  - `bool verbose`: Toggle logging.
  - `String identifier`: Internal composite string identifier.
  - `String forProperty`: Designation property (e.g., 'isolate', 'process').
  - `Map<String, int?> all`: Gets an unmodifiable map of the counts.
- **Methods**:
  - `int get()`: Retrieves the current count.
  - `CU increment()`: Increments the count.
  - `CU decrement()`: Decrements the count.
  - `CD delete()`: Removes the count data.

**SemaphoreCounts** -- Groups specific domain counts (`isolate` and `process`) together.
- **Fields**:
  - `CT isolate`: Count tracking isolate-level reentrant locks.
  - `CT process`: Count tracking external/process-level locks.

**SemaphoreCounter** -- Associates specific `SemaphoreCounts` with a `SemaphoreIdentity`.
- **Fields**:
  - `String identifier`: The string identifier.
  - `I identity`: The identity context.
  - `CTS counts`: The counts container.
- **Methods**:
  - `static SemaphoreCounter instantiate(...)`: Factory method to register or retrieve a counter.

**SemaphoreCounters** -- Registry tracking `SemaphoreCounter` instances.
- **Methods**:
  - `bool has<T>({required String identifier})`: Checks if a counter exists.
  - `CTR get({required String identifier})`: Retrieves a registered counter.
  - `CTR register({required String identifier, required CTR counter})`: Registers a new counter.
  - `void delete({required String identifier})`: Deletes a registered counter.

### Unix FFI & OS Structs

**mode_t** -- `AbiSpecificInteger` representing the `mode_t` size on various architectures (e.g., `Uint16` or `Uint64`).

**MODE_T_PERMISSIONS** -- Constants for UNIX file permissions.
- **Fields**: `x`, `w`, `r`, `rw`, `rx`, `wx`, `rwx`, `RECOMMENDED`, `OWNER_READ_WRITE_GROUP_READ`, `OWNER_READ_WRITE_GROUP_AND_OTHERS_READ_WRITE`, `OWNER_READ_WRITE_GROUP_NO_ACCESS`, `OWNER_READ_WRITE_EXECUTE_GROUP_NO_ACCESS`, `OWNER_READ_WRITE_EXECUTE_GROUP_AND_OTHERS_READ_EXECUTE`, `ALL_READ_WRITE_EXECUTE`.
- **Methods**: `static int perm(...)` to compute permission values.

**UnixSemLimits** -- Limit constants for UNIX semaphores.
- **Fields**: `isBSD`, `PATH_MAX`, `SEM_VALUE_MAX`, `NAME_MAX`, `NAME_MAX_CHARACTERS`.

**UnixSemOpenMacros** -- Constants used when opening UNIX semaphores.
- **Fields**: `EACCES`, `EINTR`, `EEXIST`, `EINVAL`, `EMFILE`, `ENAMETOOLONG`, `ENFILE`, `ENOENT`, `ENOMEM`, `ENOSPC`, `EFAULT`, `SEM_FAILED`, `O_CREAT`, `O_EXCL`, `VALUE_RECOMMENDED`.

**UnixSemWaitOrTryWaitMacros** -- Macros evaluating `sem_wait` and `sem_trywait`.
- **Fields**: `EAGAIN`, `EDEADLK`, `EINTR`, `EINVAL`.

**UnixSemCloseMacros** -- Macros evaluating `sem_close`.
- **Fields**: `EINVAL`.

**UnixSemUnlinkMacros** -- Macros evaluating `sem_unlink`.
- **Fields**: `ENOENT`, `EACCES`, `ENAMETOOLONG`.

**UnixSemUnlockWithPostMacros** -- Macros evaluating `sem_post`.
- **Fields**: `EINVAL`, `EOVERFLOW`.

**UnixSemError** (and subclasses `UnixSemOpenError`, `UnixSemOpenErrorUnixSemWaitOrTryWaitError`, `UnixSemCloseError`, `UnixSemUnlinkError`, `UnixSemUnlockWithPostError`) -- Error wrappers mapping UNIX `errno` codes to Dart exceptions.
- **Fields**: `critical`, `code`, `message`, `identifier`, `description`.
- **Methods**: `static fromErrno(int errno)` maps the numeric C `errno` value to a specific error instance.

### Windows FFI Structs & OS Macros

**SECURITY_ATTRIBUTES** -- Windows FFI Struct containing the security descriptor for an object and handling inheritability.
- **Fields**: `nLength`, `lpSecurityDescriptor`, `bInheritHandle`.

**SECURITY_DESCRIPTOR** -- Windows FFI Struct containing security information associated with an object.
- **Fields**: `Revision`, `Sbz1`, `Control`, `Owner`, `Group`, `Sacl`, `Dacl`.

**ACL** -- Windows FFI Struct representing the header of an access control list.
- **Fields**: `AclRevision`, `Sbz1`, `AclSize`, `AceCount`, `Sbz2`.

**WindowsCreateSemaphoreWMacros** -- Macros mapping Win32 constants for creating semaphores.
- **Fields**: `NULL`, `SEM_FAILED`, `ERROR_INVALID_NAME`, `ERROR_SUCCESS`, `ERROR_ACCESS_DENIED`, `ERROR_INVALID_HANDLE`, `ERROR_INVALID_PARAMETER`, `ERROR_TOO_MANY_POSTS`, `ERROR_SEM_NOT_FOUND`, `ERROR_SEM_IS_SET`, `INITIAL_VALUE_RECOMMENDED`, `MAXIMUM_VALUE_RECOMMENDED`, `GLOBAL_NAME_PREFIX`, `LOCAL_NAME_PREFIX`, `MAX_PATH`.

**WindowsWaitForSingleObjectMacros** -- Macros mapping return values for Win32 synchronization wait status.
- **Fields**: `TIMEOUT_RECOMMENDED`, `TIMEOUT_INFINITE`, `TIMEOUT_ZERO`, `WAIT_ABANDONED`, `WAIT_OBJECT_0`, `WAIT_TIMEOUT`, `WAIT_FAILED`.

**WindowsReleaseSemaphoreMacros** -- Macros representing `ReleaseSemaphore` states.
- **Fields**: `RELEASE_COUNT_RECOMMENDED`, `PREVIOUS_RELEASE_COUNT_RECOMMENDED`, `ERROR_SEM_OVERFLOW`, `NULL`.

**WindowsCloseHandleMacros** -- Macros for object handle states.
- **Fields**: `INVALID_HANDLE_VALUE`.

**WindowsCreateSemaphoreWError** / **WindowsReleaseSemaphoreError** -- Error subclasses bridging Windows API failure codes to Dart errors.
- **Methods**: `static fromErrorCode(int code)`.

## 2. Enums
*(None)*

## 3. Extensions
*(None)*

## 4. Top-Level Functions

**LatePropertyAssigned<X>**
- **Signature:** `bool LatePropertyAssigned<X>(LatePropertySetParameterType function)`
- **Description:** Helper function to cleanly evaluate if a Dart `late` property has been initialized by intercepting its `LateInitializationError` inside the try/catch closure.

**errno**
- **Signature:** `Pointer<Int> get errno`
- **Description:** Top-level getter that abstracts `__error()` vs `__errno_location()` to return the correct C `errno` variable reference for the underlying POSIX system.

**sem_open**
- **Signature:** `Pointer<sem_t> sem_open(Pointer<Char> name, int oflag, int mode, int value)`
- **Description:** FFI binding that creates a new POSIX semaphore or opens an existing semaphore.

**sem_wait**
- **Signature:** `int sem_wait(Pointer<sem_t> sem_t)`
- **Description:** FFI binding that decrements (locks) the POSIX semaphore. Blocks if the value is zero.

**sem_trywait**
- **Signature:** `int sem_trywait(Pointer<sem_t> sem_t)`
- **Description:** FFI binding identical to `sem_wait`, but returns an error immediately (`EAGAIN`) instead of blocking if the decrement cannot be performed.

**sem_post**
- **Signature:** `int sem_post(Pointer<sem_t> sem_t)`
- **Description:** FFI binding that increments (unlocks) the POSIX semaphore, waking up blocked processes or threads.

**sem_close**
- **Signature:** `int sem_close(Pointer<sem_t> sem_t)`
- **Description:** FFI binding that closes the named POSIX semaphore.

**sem_unlink**
- **Signature:** `int sem_unlink(Pointer<Char> name)`
- **Description:** FFI binding that removes the named POSIX semaphore immediately, destroying it once all processes that have the semaphore open close it.

**__error**
- **Signature:** `Pointer<Int> __error()`
- **Description:** MacOS/BSD FFI binding that retrieves the pointer to the thread-local C `errno` variable.

**__errno_location**
- **Signature:** `Pointer<Int> __errno_location()`
- **Description:** Linux/GNU FFI binding that retrieves the pointer to the thread-local C `errno` variable.

**CreateSemaphoreW**
- **Signature:** `int CreateSemaphoreW(int lpSecurityAttributes, int lInitialCount, int lMaximumCount, LPCWSTR lpName)`
- **Description:** FFI binding that creates or opens a named or unnamed Win32 semaphore object.

**WaitForSingleObject**
- **Signature:** `int WaitForSingleObject(int hHandle, int dwMilliseconds)`
- **Description:** FFI binding that blocks execution and waits until the specified Windows kernel object is in the signaled state or the time-out interval elapses.

**ReleaseSemaphore**
- **Signature:** `int ReleaseSemaphore(int hSemaphore, int lReleaseCount, Pointer<LONG> lpPreviousCount)`
- **Description:** FFI binding that releases the specified Windows semaphore by increasing its count.

**CloseHandle**
- **Signature:** `int CloseHandle(int hObject)`
- **Description:** FFI binding that closes an open Win32 object handle.

## 5. Typedefs

**sem_t** -- Typedef mapping the POSIX `sem_t` type to a Dart FFI type (`Int`).

**HANDLE** -- Typedef mapping Windows `HANDLE` to a Dart FFI `IntPtr`.

**LONG** -- Typedef mapping Windows `LONG` to a Dart FFI `Int32`.

**BOOL** -- Typedef mapping Windows `BOOL` to a Dart FFI `Uint32`.

**DWORD** -- Typedef mapping Windows `DWORD` to a Dart FFI `Uint32`.

**LPCWSTR** -- Typedef mapping Windows `LPCWSTR` to a Dart FFI `Pointer<Utf16>`.

**LatePropertySetParameterType** -- Typedef for the closure function passed to `LatePropertyAssigned` (`dynamic Function()`).

**Generics and Core API Typdefs**:
These typedefs provide shortcuts for the deep generic signatures used within the object lifecycle tracking of semaphores:
- `I`: `SemaphoreIdentity`
- `IS`: `SemaphoreIdentities<I>`
- `CU`: `SemaphoreCountUpdate`
- `CD`: `SemaphoreCountDeletion`
- `CT`: `SemaphoreCount<CU, CD>`
- `CTS`: `SemaphoreCounts<CU, CD, CT>`
- `CTR`: `SemaphoreCounter<I, CU, CD, CT, CTS>`
- `CTRS`: `SemaphoreCounters<I, CU, CD, CT, CTS, CTR>`
- `NS`: `NativeSemaphore<I, IS, CU, CD, CT, CTS, CTR, CTRS>`
