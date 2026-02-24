# Package Entry Points - API Reference

## 1. Classes

### Core Semaphore Classes

**NativeSemaphore** -- A finalizable base wrapper class to track instances of native semaphores.
- **Fields:**
  - `bool verbose` - Toggles verbose logging output.
  - `String name` - The name of the semaphore.
  - `CTR counter` - The counter tracking lock instances.
  - `I identity` - The associated semaphore identity.
  - `bool opened` - Whether the semaphore has been successfully opened.
  - `bool closed` - Whether the semaphore has been closed.
  - `bool unlinked` - Whether the semaphore has been unlinked.
  - `bool locked` - Whether the semaphore is currently locked (isolate or process count > 0).
  - `bool reentrant` - Whether the semaphore is locked reentrantly by the current isolate.
- **Methods:**
  - `bool open()` - Opens the underlying native semaphore.
  - `bool lock({bool blocking = true})` - Locks the semaphore, optionally blocking until available.
  - `bool unlock()` - Unlocks the semaphore across isolates or processes.
  - `bool close()` - Closes the native semaphore.
  - `bool unlink()` - Unlinks the native semaphore.
  - `String toString()` - Returns a string representation of the semaphore.
- **Constructors:**
  - `NativeSemaphore({required String name, required CTR counter, bool verbose = false})`
  - Factory `instantiate(...)` - Instantiates or retrieves a native semaphore for the given name.

**NativeSemaphores** -- A wrapper to track instantiations of native semaphores.
- **Fields:**
  - `Map<String, dynamic> all` - Unmodifiable map of all native semaphore instantiations.
- **Methods:**
  - `bool has<T>({required String name})` - Checks if a semaphore instance exists by name.
  - `NS get({required String name})` - Retrieves a semaphore instance.
  - `NS register({required String name, required NS semaphore})` - Registers a newly created semaphore.
  - `void delete({required String name})` - Deletes a semaphore instance from tracking.

**UnixSemaphore** -- An implementation of `NativeSemaphore` specifically for Unix platforms.
- **Fields:**
  - `({bool isSet, Pointer<Char>? get}) identifier` - Record containing the FFI name pointer.
  - `({bool isSet, Pointer<sem_t>? get}) semaphore` - Record containing the FFI semaphore pointer.
- **Methods:**
  - `bool open()` - Opens the Unix semaphore using `sem_open`.
  - `bool lock({bool blocking = true})` - Locks using `sem_wait` or `sem_trywait`.
  - `bool unlock()` - Unlocks using `sem_post`.
  - `bool close()` - Closes using `sem_close`.
  - `bool unlink()` - Unlinks using `sem_unlink`.
- **Constructors:**
  - `UnixSemaphore({required String name, required CTR counter, bool verbose = false})`

**WindowsSemaphore** -- An implementation of `NativeSemaphore` specifically for Windows platforms.
- **Fields:**
  - `({bool isSet, LPCWSTR? get}) identifier` - Record containing the FFI name string pointer.
  - `({bool isSet, Pointer<NativeType>? get}) semaphore` - Record containing the Windows HANDLE.
- **Methods:**
  - `bool open()` - Opens the Windows semaphore using `CreateSemaphoreW`.
  - `bool lock({bool blocking = true})` - Locks using `WaitForSingleObject`.
  - `bool unlock()` - Unlocks using `ReleaseSemaphore`.
  - `bool close()` - Closes the handle using `CloseHandle`.
  - `bool unlink()` - Unlinks the semaphore (Windows has no native unlink; handles success natively).
- **Constructors:**
  - `WindowsSemaphore({required String name, required CTR counter, bool verbose = false})`

### Identity & Counter Classes

**SemaphoreIdentity** -- Represents the unique identity of a semaphore tracking its lifecycle.
- **Fields:**
  - `String prefix` - Common naming prefix.
  - `String isolate` - The identifier for the current isolate.
  - `String process` - The identifier for the current process.
  - `int address` - The underlying native memory address (set when opened).
  - `String name` - The normalized name of the semaphore.
  - `bool registered` - Indicates if the identity has been registered.
  - `String uuid` - The uniquely generated identifier (name + isolate + process).
- **Methods:**
  - `bool dispose()` - Disposes the identity.
  - `String toString()` - String representation including name, isolate, and process.
- **Constructors:**
  - `SemaphoreIdentity({required String name})`
  - Factory `instantiate(...)` - Gets or registers a singleton identity.

**SemaphoreIdentities** -- Registry wrapper for `SemaphoreIdentity` instances.
- **Fields:**
  - `static String prefix` - Defines the global `runtime_native_semaphores` prefix.
  - `static String isolate` - The isolate hash or ID.
  - `static final String process` - The process ID.
  - `Map<String, I> all` - Unmodifiable view of registered identities.
- **Methods:**
  - `bool has<T>({required String name})`
  - `I get({required String name})`
  - `I register({required String name, required I identity})`
  - `void delete({required String name})`

**SemaphoreCountUpdate** -- A model representing an update of a tracked count.
- **Fields:**
  - `String identifier` - The parent identifier.
  - `int? from` - Prior count value.
  - `int to` - Updated count value.

**SemaphoreCountDeletion** -- A model representing the deletion of a tracked count.
- **Fields:**
  - `String identifier` - The parent identifier.
  - `int? at` - Count at the time of deletion.

**SemaphoreCount** -- Tracks a specific integer count (e.g., process locks, isolate reentrancy).
- **Fields:**
  - `bool verbose` - Toggles logging.
  - `String identifier` - Full formatted identity string.
  - `String forProperty` - Descriptive property track name.
  - `Map<String, int?> all` - All globally tracked counts.
- **Methods:**
  - `int get()` - Retrieves the current count value.
  - `CD delete()` - Removes the count from the internal map.
  - `CU increment()` - Increments the count by one.
  - `CU decrement()` - Decrements the count by one.

**SemaphoreCounts** -- Data class containing specific `SemaphoreCount` objects.
- **Fields:**
  - `CT isolate` - Count updated by isolate reentrant locks/unlocks.
  - `CT process` - Count updated by external cross-process lock requests.

**SemaphoreCounter** -- Associates a `SemaphoreIdentity` with its tracked `SemaphoreCounts`.
- **Fields:**
  - `String identifier` - Tracked identifier string.
  - `I identity` - Link to the identity object.
  - `CTS counts` - Tracked counts container.
- **Constructors:**
  - Factory `instantiate({required I identity})`

**SemaphoreCounters** -- Registry tracking active `SemaphoreCounter` instances.
- **Fields:**
  - `Map<String, CTR> all` - All active counters.
- **Methods:**
  - `bool has<T>({required String identifier})`
  - `CTR get({required String identifier})`
  - `CTR register({required String identifier, required CTR counter})`
  - `void delete({required String identifier})`

### Unix Specific FFI Classes

**mode_t** -- Native FFI wrapper class for C's `mode_t`.
- **Constructors:** `const mode_t()`

**MODE_T_PERMISSIONS** -- Permissions configuration flags for `sem_open` arguments.
- **Fields:**
  - `static int x`, `w`, `r`, `rw`, `rx`, `wx`, `rwx` - Raw bitwise modes.
  - `static int RECOMMENDED` - Recommended default mode (`OWNER_READ_WRITE_GROUP_READ`).
  - `static int OWNER_READ_WRITE_GROUP_READ` - Evaluates to octal `0644`.
  - `static int OWNER_READ_WRITE_GROUP_AND_OTHERS_READ_WRITE` - `0666`.
  - `static int OWNER_READ_WRITE_GROUP_NO_ACCESS` - `0600`.
  - `static int OWNER_READ_WRITE_EXECUTE_GROUP_NO_ACCESS` - `0700`.
  - `static int OWNER_READ_WRITE_EXECUTE_GROUP_AND_OTHERS_READ_EXECUTE` - `0755`.
  - `static int ALL_READ_WRITE_EXECUTE` - `0777`.
- **Methods:**
  - `static int perm({int u = 0, int g = 0, int o = 0, int user = 0, int group = 0, int others = 0})` - Formats the permission integer.

**UnixSemLimits** -- System limits based on standard POSIX implementations.
- **Fields:**
  - `static bool isBSD` - Checked if running on MacOS.
  - `static int PATH_MAX` - 1024.
  - `static int SEM_VALUE_MAX` - 32767.
  - `static int NAME_MAX` - 255.
  - `static int NAME_MAX_CHARACTERS` - Max dart string limit enforced internally (30).

**UnixSemOpenMacros** -- Posix error codes and flags for `sem_open`.
- **Fields:**
  - `static int EACCES`, `EINTR`, `EEXIST`, `EINVAL`, `EMFILE`, `ENAMETOOLONG`, `ENFILE`, `ENOENT`, `ENOMEM`, `ENOSPC`, `EFAULT`.
  - `static Pointer<Uint64> SEM_FAILED` - The pointer address returned upon failure.
  - `static int O_CREAT` - The `O_CREAT` creation flag.
  - `static int O_EXCL` - The `O_EXCL` exclusion flag.
  - `static int VALUE_RECOMMENDED` - Default value.

**UnixSemWaitOrTryWaitMacros** -- Error codes mapped for `sem_wait` and `sem_trywait`.
- **Fields:** `EAGAIN`, `EDEADLK`, `EINTR`, `EINVAL`.

**UnixSemCloseMacros** -- Error codes mapped for `sem_close`.
- **Fields:** `EINVAL`.

**UnixSemUnlinkMacros** -- Error codes mapped for `sem_unlink`.
- **Fields:** `ENOENT`, `EACCES`, `ENAMETOOLONG`.

**UnixSemUnlockWithPostMacros** -- Error codes mapped for `sem_post`.
- **Fields:** `EINVAL`, `EOVERFLOW`.

### Windows Specific FFI Classes

**SECURITY_ATTRIBUTES** -- Windows FFI Struct for security descriptor definitions.
- **Fields:** `int nLength`, `Pointer lpSecurityDescriptor`, `int bInheritHandle`.

**SECURITY_DESCRIPTOR** -- Windows FFI Struct for holding security queries and object statuses.
- **Fields:** `int Revision`, `int Sbz1`, `int Control`, `Pointer Owner`, `Pointer Group`, `Pointer<ACL> Sacl`, `Pointer<ACL> Dacl`.

**ACL** -- Windows FFI Struct mapping the Access Control List header.
- **Fields:** `int AclRevision`, `int Sbz1`, `int AclSize`, `int AceCount`, `int Sbz2`.

**WindowsCreateSemaphoreWMacros** -- Windows API constants and flags related to `CreateSemaphoreW`.
- **Fields:**
  - `static Pointer<Never> NULL`, `SEM_FAILED`
  - `static const int ERROR_INVALID_NAME`, `ERROR_SUCCESS`, `ERROR_ACCESS_DENIED`, `ERROR_INVALID_HANDLE`, `ERROR_INVALID_PARAMETER`, `ERROR_TOO_MANY_POSTS`, `ERROR_SEM_NOT_FOUND`, `ERROR_SEM_IS_SET`.
  - `static int INITIAL_VALUE_RECOMMENDED`, `MAXIMUM_VALUE_RECOMMENDED`
  - `static String GLOBAL_NAME_PREFIX`, `LOCAL_NAME_PREFIX`
  - `static int MAX_PATH`

**WindowsWaitForSingleObjectMacros** -- Windows API constants and flags related to `WaitForSingleObject`.
- **Fields:**
  - `static const int TIMEOUT_RECOMMENDED`, `TIMEOUT_INFINITE`, `TIMEOUT_ZERO`.
  - `static const int WAIT_ABANDONED`, `WAIT_OBJECT_0`, `WAIT_TIMEOUT`, `WAIT_FAILED`.

**WindowsReleaseSemaphoreMacros** -- Windows API constants and flags related to `ReleaseSemaphore`.
- **Fields:**
  - `static const int RELEASE_COUNT_RECOMMENDED`.
  - `static Pointer<Never> PREVIOUS_RELEASE_COUNT_RECOMMENDED`.
  - `static int ERROR_SEM_OVERFLOW`.
  - `static Pointer<Never> NULL`.

**WindowsCloseHandleMacros** -- Windows API constants and flags related to `CloseHandle`.
- **Fields:**
  - `static const int INVALID_HANDLE_VALUE`.

### Error Classes

- **UnixSemError** - Base class for UNIX semaphore errors.
- **UnixSemOpenError** - Wraps `sem_open` errors. `fromErrno(int errno)` maps native code.
- **UnixSemOpenErrorUnixSemWaitOrTryWaitError** - Wraps `sem_wait`/`sem_trywait` errors. `fromErrno(int errno)` maps native code.
- **UnixSemCloseError** - Wraps `sem_close` errors. `fromErrno(int errno)` maps native code.
- **UnixSemUnlinkError** - Wraps `sem_unlink` errors. `fromErrno(int errno)` maps native code.
- **UnixSemUnlockWithPostError** - Wraps `sem_post` errors. `fromErrno(int errno)` maps native code.
- **WindowsCreateSemaphoreWError** - Wraps `CreateSemaphoreW` errors. `fromErrorCode(int code)` maps native code.
- **WindowsReleaseSemaphoreError** - Wraps `ReleaseSemaphore` errors. `fromErrorCode(int code)` maps native code.

## Examples

### Creating and Using a NativeSemaphore

```dart
import 'package:runtime_native_semaphores/runtime_native_semaphores.dart';

void main() {
  // Instantiate a semaphore
  final semaphore = NativeSemaphore.instantiate(name: 'my_semaphore', verbose: true);

  // Open the semaphore
  if (semaphore.open()) {
    print('Semaphore opened successfully!');
    
    // Lock the semaphore
    if (semaphore.lock(blocking: true)) {
      try {
        print('Semaphore locked, performing critical section task...');
      } finally {
        // Always unlock in a finally block
        semaphore.unlock();
        print('Semaphore unlocked.');
      }
    }
    
    // Close the semaphore
    semaphore.close();
    
    // Unlink the semaphore (Cleans up resources, only applicable on Unix)
    semaphore.unlink();
  }
}
```

### Advanced Usage with Platform Specific Semaphores

```dart
import 'dart:io';
import 'package:runtime_native_semaphores/runtime_native_semaphores.dart';

void main() {
  NativeSemaphore semaphore;
  
  // You can construct Windows or Unix semaphores directly
  if (Platform.isWindows) {
    // Windows expects an identifier without invalid characters
    final identity = SemaphoreIdentity.instantiate(name: 'Global\\my_windows_sem');
    final counter = SemaphoreCounter.instantiate(identity: identity);
    semaphore = WindowsSemaphore(name: 'Global\\my_windows_sem', counter: counter);
  } else {
    // Unix uses POSIX semaphores
    final identity = SemaphoreIdentity.instantiate(name: 'my_unix_sem');
    final counter = SemaphoreCounter.instantiate(identity: identity);
    semaphore = UnixSemaphore(name: 'my_unix_sem', counter: counter);
  }
  
  semaphore.open();
  if (semaphore.lock(blocking: false)) {
    semaphore.unlock();
  }
  semaphore.close();
}
```

## 2. Enums

*(No enums are publicly defined in this module)*

## 3. Extensions

*(No extensions are publicly defined in this module)*

## 4. Top-Level Functions & Properties

- **LatePropertyAssigned<X>(LatePropertySetParameterType function)**
  - Safely checks if a late property has been initialized by calling it and catching assignment errors without throwing them.
  - **Parameters:** `LatePropertySetParameterType function`
  - **Returns:** `bool`

- **Pointer<Int> get errno**
  - **Getter** returning the current Unix `errno` value pointer.
  - **Returns:** `Pointer<Int>`

### Native Unix Functions

- **sem_open(Pointer<Char> name, int oflag, int mode, int value)**
  - Creates a new POSIX semaphore or opens an existing one.
  - **Parameters:** `Pointer<Char> name`, `int oflag`, `int mode`, `int value`
  - **Returns:** `Pointer<sem_t>`

- **sem_wait(Pointer<sem_t> sem_t)**
  - Decrements (locks) the Unix semaphore. Blocks if the count is zero.
  - **Parameters:** `Pointer<sem_t> sem_t`
  - **Returns:** `int`

- **sem_trywait(Pointer<sem_t> sem_t)**
  - Tries to decrement the semaphore. Returns an error immediately instead of blocking if the value is zero.
  - **Parameters:** `Pointer<sem_t> sem_t`
  - **Returns:** `int`

- **sem_post(Pointer<sem_t> sem_t)**
  - Increments (unlocks) the Unix semaphore, optionally waking blocked processes.
  - **Parameters:** `Pointer<sem_t> sem_t`
  - **Returns:** `int`

- **sem_close(Pointer<sem_t> sem_t)**
  - Closes the named semaphore, allowing resources to be freed.
  - **Parameters:** `Pointer<sem_t> sem_t`
  - **Returns:** `int`

- **sem_unlink(Pointer<Char> name)**
  - Removes the named Unix semaphore immediately, destroying it once all other processes close it.
  - **Parameters:** `Pointer<Char> name`
  - **Returns:** `int`

- **__error()**
  - MacOS BSD specific lookup for `errno`.
  - **Returns:** `Pointer<Int>`

- **__errno_location()**
  - Linux specific lookup for `errno`.
  - **Returns:** `Pointer<Int>`

### Native Windows Functions

- **CreateSemaphoreW(int lpSecurityAttributes, int lInitialCount, int lMaximumCount, LPCWSTR lpName)**
  - Creates or opens a named/unnamed Windows semaphore object.
  - **Parameters:** `int lpSecurityAttributes`, `int lInitialCount`, `int lMaximumCount`, `LPCWSTR lpName`
  - **Returns:** `int` (Representing the HANDLE pointer address)

- **WaitForSingleObject(int hHandle, int dwMilliseconds)**
  - Waits until the Windows semaphore is in a signaled state or the interval elapses.
  - **Parameters:** `int hHandle`, `int dwMilliseconds`
  - **Returns:** `int` (Status `DWORD`)

- **ReleaseSemaphore(int hSemaphore, int lReleaseCount, Pointer<LONG> lpPreviousCount)**
  - Releases the Windows semaphore by increasing its count.
  - **Parameters:** `int hSemaphore`, `int lReleaseCount`, `Pointer<LONG> lpPreviousCount`
  - **Returns:** `int` (`BOOL` success indicator)

- **CloseHandle(int hObject)**
  - Closes an open object handle on Windows.
  - **Parameters:** `int hObject`
  - **Returns:** `int` (`BOOL` success indicator)
