# Semaphore Core API Reference

This document provides a comprehensive API reference for the Semaphore Core module.

## 1. Classes

### Core Semaphore Entities

**NativeSemaphore** -- An abstract base wrapper tracking instances and states of a native semaphore.
- **Fields**:
  - `bool verbose`: Flag for detailed debugging output.
  - `String name`: The name of the semaphore.
  - `CTR counter`: The counter tracking semaphore isolate/process locks.
  - `I identity`: The underlying `SemaphoreIdentity` representing this semaphore instance.
  - `bool opened`: Evaluates to true if the semaphore has been successfully opened.
  - `bool closed`: Evaluates to true if the semaphore has been successfully closed.
  - `bool unlinked`: Evaluates to true if the semaphore has been successfully unlinked.
  - `bool locked`: Evaluates to true if the semaphore is currently locked by this isolate or process.
  - `bool reentrant`: Evaluates to true if the isolate count is greater than 1.
- **Methods**:
  - `bool open()`: Attempts to open the native semaphore.
  - `bool lock({bool blocking = true})`: Locks the semaphore across processes and reentrant isolates.
  - `bool unlock()`: Unlocks the semaphore.
  - `bool close()`: Closes the active semaphore handle.
  - `bool unlink()`: Destroys the named semaphore in the system.
- **Constructors**:
  - `NativeSemaphore({required String name, required CTR counter, bool verbose = false})`
  - `static NativeSemaphore instantiate<...>(...)`: Factory method to instantiate or retrieve a cached native semaphore.

**NativeSemaphores** -- A registry wrapper for tracking active `NativeSemaphore` instances.
- **Fields**:
  - `Map<String, dynamic> all`: Returns an unmodifiable map of all registered semaphore instances.
- **Methods**:
  - `bool has<T>({required String name})`: Checks if a semaphore instance with the given name exists.
  - `NS get({required String name})`: Retrieves the semaphore counter instance by name.
  - `NS register({required String name, required NS semaphore})`: Registers a new native semaphore.
  - `void delete({required String name})`: Deletes a semaphore from the registry.

**UnixSemaphore** -- A Unix-specific implementation of `NativeSemaphore`.
- **Fields**:
  - `({bool isSet, Pointer<Char>? get}) identifier`: Tuple containing the C-string pointer to the semaphore name.
  - `({bool isSet, Pointer<sem_t>? get}) semaphore`: Tuple containing the memory pointer to the `sem_t` handle.
- **Methods**:
  - Includes overrides for `open()`, `lock()`, `unlock()`, `close()`, and `unlink()`.
- **Constructors**:
  - `UnixSemaphore({required String name, required CTR counter, bool verbose = false})`

**WindowsSemaphore** -- A Windows-specific implementation of `NativeSemaphore`.
- **Fields**:
  - `({bool isSet, LPCWSTR? get}) identifier`: Tuple containing the wide string pointer to the semaphore name.
  - `({bool isSet, Pointer<NativeType>? get}) semaphore`: Tuple containing the Windows native `HANDLE` to the semaphore.
- **Methods**:
  - Includes overrides for `open()`, `lock()`, `unlock()`, `close()`, and `unlink()`. Note: `unlink()` is a no-op on Windows.
- **Constructors**:
  - `WindowsSemaphore({required String name, required CTR counter, bool verbose = false})`

### Identity Management

**SemaphoreIdentity** -- Represents the identity and active metadata of a native semaphore across isolates and processes.
- **Fields**:
  - `String prefix`: The standard global identity prefix.
  - `String isolate`: Unique identifier for the current Dart isolate.
  - `String process`: Unique identifier for the current system process ID.
  - `int address`: The raw memory address pointing to the native semaphore.
  - `String name`: The validated semaphore name without namespace prefixes.
  - `bool registered`: Checks whether the identity has been registered.
  - `String uuid`: Unique identifier concatenating name, isolate, and process.
- **Methods**:
  - `bool dispose()`: Hook for disposing of the identity.
  - `String toString()`: String representation of the identity.
- **Constructors**:
  - `SemaphoreIdentity({required String name})`: Validates and creates a new identity.
  - `static SemaphoreIdentity instantiate<...>(...)`: Instantiates or retrieves an identity.

**SemaphoreIdentities** -- Registry and utility class for tracking active identities.
- **Fields**:
  - `static String prefix`: Global prefix (`runtime_native_semaphores`).
  - `static String isolate`: Isolate identifier.
  - `static String process`: Process ID.
  - `Map<String, I> all`: Read-only map of all identities.
- **Methods**:
  - `bool has<T>({required String name})`: Checks if identity exists.
  - `I get({required String name})`: Gets a registered identity.
  - `I register({required String name, required I identity})`: Registers an identity.
  - `void delete({required String name})`: Deletes an identity.

### Counter Management

**SemaphoreCountUpdate** -- Represents an update operation to a count.
- **Fields**:
  - `String identifier`: The identifier of the updated count.
  - `int? from`: The previous count value.
  - `int to`: The new count value.

**SemaphoreCountDeletion** -- Represents a deletion operation on a count.
- **Fields**:
  - `String identifier`: The identifier of the deleted count.
  - `int? at`: The count value at the time of deletion.

**SemaphoreCount** -- Tracks a specific integer count (isolate or process level) for a semaphore.
- **Fields**:
  - `bool verbose`: Print debugging info.
  - `String identifier`: Unique ID for the count context.
  - `String forProperty`: Distinguishes between 'isolate' or 'process' counts.
  - `Map<String, int?> all`: The global registry of all counts.
- **Methods**:
  - `int get()`: Returns the current count.
  - `CU update({required int value})`: Updates the count to `value`.
  - `CD delete()`: Deletes the count record.
  - `CU increment()`: Increments count by 1.
  - `CU decrement()`: Decrements count by 1.

**SemaphoreCounts** -- Groups isolate and process counts together.
- **Fields**:
  - `CT isolate`: Tracks reentrant locks per isolate.
  - `CT process`: Tracks global locks per process.

**SemaphoreCounter** -- Associates an identity with a set of `SemaphoreCounts`.
- **Fields**:
  - `String identifier`: The string identifier matching the identity.
  - `I identity`: The linked `SemaphoreIdentity`.
  - `CTS counts`: The grouped isolate/process counts.
- **Constructors**:
  - `static SemaphoreCounter instantiate<...>({required I identity})`: Gets or registers a counter.

**SemaphoreCounters** -- Registry for `SemaphoreCounter` instances.
- **Fields**:
  - `Map<String, CTR> all`: A map of all registered counters.
- **Methods**:
  - `bool has<T>({required String identifier})`: Checks for existence of counter.
  - `CTR get({required String identifier})`: Retrieves counter.
  - `CTR register({required String identifier, required CTR counter})`: Registers new counter.
  - `void delete({required String identifier})`: Deletes counter.

## 2. Typedefs

Located in `lib/src/native_semaphore_types.dart`. These aliases simplify the highly generic type constraints:
- `I = SemaphoreIdentity`
- `IS = SemaphoreIdentities<I>`
- `CU = SemaphoreCountUpdate`
- `CD = SemaphoreCountDeletion`
- `CT = SemaphoreCount<CU, CD>`
- `CTS = SemaphoreCounts<CU, CD, CT>`
- `CTR = SemaphoreCounter<I, CU, CD, CT, CTS>`
- `CTRS = SemaphoreCounters<I, CU, CD, CT, CTS, CTR>`
- `NS = NativeSemaphore<I, IS, CU, CD, CT, CTS, CTR, CTRS>`

## 3. Usage Examples

### Retrieving a Cached Native Semaphore

```dart
import 'package:runtime_native_semaphores/src/native_semaphore.dart';
import 'package:runtime_native_semaphores/src/native_semaphore_types.dart';

// Instantiate cross-platform semaphore
final NS mySem = NativeSemaphore.instantiate(
  name: 'my_shared_resource',
  verbose: true,
);

// Lock, do work, then unlock
if (mySem.open()) {
  mySem.lock();
  try {
    // Shared resource access here
  } finally {
    mySem.unlock();
  }
}
```

### Instantiating a Semaphore Count

Although normally abstracted behind `NativeSemaphore.instantiate`, you can manually build a count update using cascade notation if necessary:

```dart
import 'package:runtime_native_semaphores/src/semaphore_counter.dart';

final update = SemaphoreCountUpdate(
  identifier: 'my_semaphore_for_isolate',
  to: 1
)..from = 0; // Note: 'from' is optional in the constructor, but we show cascade assignment here.

final deletion = SemaphoreCountDeletion(
  identifier: 'my_semaphore_for_isolate'
)..at = 1; // Assuming it was at 1 when deleted
```
