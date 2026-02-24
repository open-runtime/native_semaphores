# Semaphore Core API Reference

This document covers the **Semaphore Core** classes, types, error handling, and FFI bindings that make up `runtime_native_semaphores`.

## 1. Classes

### Core Semaphore API

**NativeSemaphores<I, IS, CU, CD, CT, CTS, CTR, CTRS, NS>** -- Tracks instances of NativeSemaphore.
- **Fields:**
  - `all` (`Map<String, dynamic>`): Unmodifiable map of all semaphores.
- **Methods:**
  - `has<T>({required String name})` -> `bool`: Checks if a semaphore is instantiated.
  - `get({required String name})` -> `NS`: Retrieves the requested native semaphore.
  - `register({required String name, required NS semaphore})` -> `NS`: Registers a semaphore instance.
  - `delete({required String name})` -> `void`: Removes a semaphore.

**NativeSemaphore<I, IS, CU, CD, CT, CTS, CTR, CTRS>** -- Core abstract base class representing the native semaphore wrapper. Implements `Finalizable`.
- **Fields:**
  - `verbose` (`bool`): Enable debug logging.
  - `name` (`String`): Semaphore identifier name.
  - `counter` (`CTR`): Associated state and counting object.
  - `identity` (`I`): Target identity object.
  - `opened` (`bool`): Determines if the semaphore is currently open.
  - `closed` (`bool`): Determines if the semaphore has been successfully closed.
  - `unlinked` (`bool`): Determines if the semaphore has been unlinked (Unix only natively).
  - `locked` (`bool`): Checks if the total count indicates a locked state.
  - `reentrant` (`bool`): Checks if the isolate count is greater than 1.
- **Methods:**
  - `instantiate<...>` -> `NativeSemaphore`: Static generic factory method, instantiates the platform-appropriate implementation (`UnixSemaphore` or `WindowsSemaphore`).
  - `open()` -> `bool`: Open the native semaphore.
  - `lock({bool blocking = true})` -> `bool`: Abstract lock execution interface.
  - `unlock()` -> `bool`: Abstract unlock execution interface.
  - `close()` -> `bool`: Abstract close execution interface.
  - `unlink()` -> `bool`: Abstract unlink execution interface.

**Example Usage:**
```dart
import 'package:runtime_native_semaphores/runtime_native_semaphores.dart';

void main() {
  final semaphore = NativeSemaphore.instantiate(name: 'my_shared_resource')
    ..open()
    ..lock();

  try {
    // Critical section
    print('Semaphore is locked: ${semaphore.locked}');
  } finally {
    semaphore
      ..unlock()
      ..close()
      ..unlink();
  }
}
```

**UnixSemaphore<I, IS, CU, CD, CT, CTS, CTR, CTRS>** -- Unix-specific native semaphore implementation.
- **Fields:**
  - `identifier` (`({bool isSet, Pointer<Char>? get})`): Property wrapper for native UTF-8 string memory pointer.
  - `semaphore` (`({bool isSet, Pointer<sem_t>? get})`): Property wrapper for native `sem_t` memory address pointer.
- **Methods:**
  - Provides platform-specific implementations of `open()`, `lock()`, `unlock()`, `close()`, and `unlink()` leveraging Unix FFI bindings.

**WindowsSemaphore<I, IS, CU, CD, CT, CTS, CTR, CTRS>** -- Windows-specific native semaphore implementation.
- **Fields:**
  - `identifier` (`({bool isSet, LPCWSTR? get})`): Property wrapper for native UTF-16 string memory pointer.
  - `semaphore` (`({bool isSet, Pointer<NativeType>? get})`): Property wrapper for native `HANDLE` memory address pointer.
- **Methods:**
  - Provides platform-specific implementations of `open()`, `lock()`, `unlock()`, `close()`, and `unlink()` leveraging Windows FFI bindings.

### Semaphore Identity Management

**SemaphoreIdentities<I extends SemaphoreIdentity>** -- Manages a collection of semaphore identity instances.
- **Fields:**
  - `prefix` (`String`): Static prefix for the runtime native semaphores.
  - `isolate` (`String`): Static isolate identifier.
  - `process` (`String`): Static process identifier.
  - `all` (`Map<String, I>`): Unmodifiable map of all registered identities.
- **Methods:**
  - `has<T>({required String name})` -> `bool`: Checks if an identity exists.
  - `get({required String name})` -> `I`: Returns the semaphore identity for the given identifier.
  - `register({required String name, required I identity})` -> `I`: Registers a new identity.
  - `delete({required String name})` -> `void`: Deletes an identity from the registry.

**SemaphoreIdentity** -- Represents the unique identity of a semaphore.
- **Fields:**
  - `prefix` (`String`): Global prefix string.
  - `isolate` (`String`): Current isolate identifier string.
  - `process` (`String`): Current process identifier string.
  - `address` (`int`): Address of the opened native semaphore.
  - `name` (`String`): Cleaned name identifier.
  - `registered` (`bool`): Helper property denoting if it is registered in a named semaphore instance.
  - `uuid` (`String`): Unique identifier combining name, isolate, and process.
- **Methods:**
  - `instantiate<I, IS>({required String name})` -> `SemaphoreIdentity`: Static factory method.
  - `dispose()` -> `bool`: Unimplemented method to dispose of the identity.

**Example Usage:**
```dart
import 'package:runtime_native_semaphores/runtime_native_semaphores.dart';

void main() {
  final identity = SemaphoreIdentity.instantiate(name: 'my_semaphore_id');
  print('Semaphore UUID: ${identity.uuid}');
  print('Process ID: ${identity.process}');
}
```

### Semaphore Counting & State Tracking

**SemaphoreCountUpdate** -- Represents an update operation to a semaphore count.
- **Fields:**
  - `identifier` (`String`): Updated parent identifier.
  - `from` (`int?`): Original count before the update.
  - `to` (`int`): New count after the update.

**SemaphoreCountDeletion** -- Represents the deletion of a semaphore count.
- **Fields:**
  - `identifier` (`String`): Deleted parent identifier.
  - `at` (`int?`): Count value at the time of deletion.

**SemaphoreCount<CU, CD>** -- A single counter wrapper.
- **Fields:**
  - `verbose` (`bool`): Flag for debug logging.
  - `identifier` (`String`): The concatenated unique name of the count.
  - `forProperty` (`String`): The property this count is tracking (e.g., 'isolate' or 'process').
  - `all` (`Map<String, int?>`): Unmodifiable map of all registered counts.
- **Methods:**
  - `get()` -> `int`: Retrieves the current count.
  - `update({required int value})` -> `CU`: Updates the count to a specific value.
  - `delete()` -> `CD`: Removes the tracked count.
  - `increment()` -> `CU`: Increments the count by 1.
  - `decrement()` -> `CU`: Decrements the count by 1.

**SemaphoreCounts<CU, CD, CT>** -- Wraps both the isolate and process counters.
- **Fields:**
  - `isolate` (`CT`): Counter updated by reentrant locks/unlocks.
  - `process` (`CT`): Counter updated by external cross-process lock requests.

**SemaphoreCounters<I, CU, CD, CT, CTS, CTR>** -- Manages a collection of SemaphoreCounter instances.
- **Fields:**
  - `all` (`Map<String, CTR>`): Unmodifiable map of all counters.
- **Methods:**
  - `has<T>({required String identifier})` -> `bool`: Checks if a counter exists.
  - `get({required String identifier})` -> `CTR`: Returns the requested counter.
  - `register({required String identifier, required CTR counter})` -> `CTR`: Registers a counter.
  - `delete({required String identifier})` -> `void`: Deletes a counter.

**SemaphoreCounter<I, CU, CD, CT, CTS>** -- Associates a SemaphoreIdentity with its corresponding counters.
- **Fields:**
  - `identifier` (`String`): Target identifier string.
  - `identity` (`I`): Target semaphore identity.
  - `counts` (`CTS`): Wrapper for both process and isolate counts.
- **Methods:**
  - `instantiate<I, CU, CD, CT, CTS, CTR, CTRS>({required I identity})` -> `SemaphoreCounter`: Static factory.


### Unix FFI Structs, Macros, & Errors

**mode_t** -- Unix FFI structure representing file permissions. Extends `AbiSpecificInteger`.

**MODE_T_PERMISSIONS** -- Namespace for Unix permission constants.
- **Methods:**
  - `perm({int u, int g, int o, int user, int group, int others})` -> `int`: Bitwise shifting helper for permissions.

**UnixSemLimits** -- Namespace for common Unix macro boundaries.

**UnixSemOpenMacros** -- Namespace for Unix `sem_open` error codes and flags.

**UnixSemWaitOrTryWaitMacros** -- Namespace for Unix `sem_wait` and `sem_trywait` error codes.

**UnixSemCloseMacros** -- Namespace for Unix `sem_close` error codes.

**UnixSemUnlinkMacros** -- Namespace for Unix `sem_unlink` error codes.

**UnixSemUnlockWithPostMacros** -- Namespace for Unix `sem_post` error codes.

**UnixSemError** -- Base Error class for Unix semaphore operations.
- **Fields:** `critical` (`bool`), `code` (`int`), `message` (`String`), `identifier` (`String?`), `description` (`String?`).

**UnixSemOpenError** -- Error class for sem_open.

**UnixSemOpenErrorUnixSemWaitOrTryWaitError** -- Error class for wait operations.

**UnixSemCloseError** -- Error class for close operation.

**UnixSemUnlinkError** -- Error class for unlink operation.

**UnixSemUnlockWithPostError** -- Error class for post operations.

### Windows FFI Structs, Macros, & Errors

**SECURITY_ATTRIBUTES** -- Windows FFI struct for security descriptors and handle inheritance.
- **Fields:** `nLength`, `lpSecurityDescriptor`, `bInheritHandle`.

**SECURITY_DESCRIPTOR** -- Windows FFI struct for associated object security info.
- **Fields:** `Revision`, `Sbz1`, `Control`, `Owner`, `Group`, `Sacl`, `Dacl`.

**ACL** -- Windows FFI struct representing the header of an access control list.
- **Fields:** `AclRevision`, `Sbz1`, `AclSize`, `AceCount`, `Sbz2`.

**WindowsCreateSemaphoreWMacros** -- Namespace for Windows `CreateSemaphoreW` constants.

**WindowsWaitForSingleObjectMacros** -- Namespace for Windows `WaitForSingleObject` constants.

**WindowsReleaseSemaphoreMacros** -- Namespace for Windows `ReleaseSemaphore` constants.

**WindowsCloseHandleMacros** -- Namespace for Windows `CloseHandle` constants.

**WindowsCreateSemaphoreWError** -- Error representation class for Windows semaphore creations.
- **Fields:** `code` (`int`), `message` (`String`), `identifier` (`String?`), `description` (`String?`).

**WindowsReleaseSemaphoreError** -- Error representation class for Windows semaphore releases.
- **Fields:** `code` (`int`), `message` (`String`), `identifier` (`String?`), `description` (`String?`).

## 2. Enums

*(None defined)*

## 3. Extensions

*(None defined)*

## 4. Top-Level Functions

**LatePropertyAssigned<X>**
- **Signature:** `bool LatePropertyAssigned<X>(LatePropertySetParameterType function)`
- **Description:** safely evaluates whether a late variable has been assigned by invoking a parameterless getter wrapper function and capturing standard `LateInitializationError` string failures.

**sem_open**
- **Signature:** `@Native<Pointer<sem_t> Function(Pointer<Char>, Int, VarArgs<(mode_t, UnsignedInt)>)>() external Pointer<sem_t> sem_open(Pointer<Char> name, int oflag, int mode, int value)`
- **Description:** C native binding to create or open a POSIX semaphore.

**sem_wait**
- **Signature:** `@Native<Int Function(Pointer<sem_t> sem_t)>() external int sem_wait(Pointer<sem_t> sem_t)`
- **Description:** C native binding to blockingly decrement (lock) the POSIX semaphore.

**sem_trywait**
- **Signature:** `@Native<Int Function(Pointer<sem_t>)>() external int sem_trywait(Pointer<sem_t> sem_t)`
- **Description:** C native binding to non-blockingly attempt decrementing (locking) the POSIX semaphore.

**sem_post**
- **Signature:** `@Native<Int Function(Pointer<sem_t>)>() external int sem_post(Pointer<sem_t> sem_t)`
- **Description:** C native binding to increment (unlock) the POSIX semaphore.

**sem_close**
- **Signature:** `@Native<Int Function(Pointer<sem_t>)>() external int sem_close(Pointer<sem_t> sem_t)`
- **Description:** C native binding to close the named POSIX semaphore for the calling process.

**sem_unlink**
- **Signature:** `@Native<Int Function(Pointer<Char>)>() external int sem_unlink(Pointer<Char> name)`
- **Description:** C native binding to remove the named POSIX semaphore immediately from the system.

**__error**
- **Signature:** `@Native<Pointer<Int> Function()>() external Pointer<Int> __error()`
- **Description:** MacOS specific C binding exposing system errno codes.

**__errno_location**
- **Signature:** `@Native<Pointer<Int> Function()>() external Pointer<Int> __errno_location()`
- **Description:** Linux/GNU specific C binding exposing system errno codes.

**CreateSemaphoreW**
- **Signature:** `@Native<HANDLE Function(IntPtr lpSecurityAttributes, LONG lInitialCount, LONG lMaximumCount, LPCWSTR lpName)>() external int CreateSemaphoreW(int lpSecurityAttributes, int lInitialCount, int lMaximumCount, LPCWSTR lpName)`
- **Description:** Windows native C API binding to create or open a named/unnamed semaphore object.

**WaitForSingleObject**
- **Signature:** `@Native<Uint32 Function(HANDLE hHandle, DWORD dwMilliseconds)>() external int WaitForSingleObject(int hHandle, int dwMilliseconds)`
- **Description:** Windows native C API binding to wait (lock) until the specified object is in a signaled state.

**ReleaseSemaphore**
- **Signature:** `@Native<BOOL Function(HANDLE hSemaphore, LONG lReleaseCount, Pointer<LONG> lpPreviousCount)>() external int ReleaseSemaphore(int hSemaphore, int lReleaseCount, Pointer<LONG> lpPreviousCount)`
- **Description:** Windows native C API binding to release (unlock) the semaphore by increasing its count.

**CloseHandle**
- **Signature:** `@Native<BOOL Function(HANDLE hObject)>() external int CloseHandle(int hObject)`
- **Description:** Windows native C API binding to close the open object handle.
