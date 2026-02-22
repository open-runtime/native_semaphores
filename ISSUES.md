# `runtime_native_semaphores` — Comprehensive Issue Registry

> **Generated:** 2026-02-22
> **Scope:** Full static analysis of `lib/`, `test/`, `bin/`, and CI/CD configuration.
> **Severity scale:** `CRITICAL` > `HIGH` > `MODERATE` > `LOW` > `INFO`

---

## Table of Contents

1. [Critical Bugs](#critical-bugs)
   - [C1 — Registry Guard Logic Inverted (3 Files, Copy-Pasted)](#c1--registry-guard-logic-inverted-3-files-copy-pasted)
   - [C2 — `mode_t` ABI Mapping Wrong on macOS Arm64](#c2--mode_t-abi-mapping-wrong-on-macos-arm64)
   - [C3 — `SEM_FAILED` Wrong Value on Linux](#c3--sem_failed-wrong-value-on-linux)
   - [C4 — `unlock()` Short-Circuits OS Semaphore Release on Windows](#c4--unlock-short-circuits-os-semaphore-release-on-windows)
2. [High Severity Bugs](#high-severity-bugs)
   - [H1 — `GetLastError` Entirely Commented Out on Windows](#h1--getlasterror-entirely-commented-out-on-windows)
   - [H2 — `CreateSemaphoreW` First Argument Typed as `int` Instead of `Pointer`](#h2--createsemaphorew-first-argument-typed-as-int-instead-of-pointer)
   - [H3 — `_identifier` Leaked on `close()` (Both Platforms)](#h3--_identifier-leaked-on-close-both-platforms)
   - [H4 — `lock()` Short-Circuits `lockReentrantToIsolate()` on Windows](#h4--lock-short-circuits-lockreentranttoisolate-on-windows)
3. [Moderate Bugs](#moderate-bugs)
   - [M1 — `LatePropertyAssigned` Uses Fragile SDK-Internal String Matching](#m1--latepropertyassigned-uses-fragile-sdk-internal-string-matching)
   - [M2 — `address` Setter Silently Discards the New Value](#m2--address-setter-silently-discards-the-new-value)
   - [M3 — `MAX_PATH` Calculation Subtracts Wrong Prefix Length](#m3--max_path-calculation-subtracts-wrong-prefix-length)
   - [M4 — Non-Atomic Read-Modify-Write in Counter Increment / Decrement](#m4--non-atomic-read-modify-write-in-counter-increment--decrement)
   - [M5 — `putIfAbsent(() => null)` Always Produces `null` `from` Field](#m5--putifabsent---null-always-produces-null-from-field)
   - [M6 — `identifier` Getter Uses Wrong Type Parameter in `LatePropertyAssigned`](#m6--identifier-getter-uses-wrong-type-parameter-in-latepropertyassigned)
   - [M7 — Error Message Typo: "unlocked locked" in Two Files](#m7--error-message-typo-unlocked-locked-in-two-files)
   - [M8 — `isEven` / `isOdd` Used as a Proxy for 0 / -1 Return Codes](#m8--iseven--isodd-used-as-a-proxy-for-0--1-return-codes)
   - [M9 — `NativeSemaphore.__instances` Not Concurrency-Safe](#m9--nativesemaphore__instances-not-concurrency-safe)
   - [M10 — `$unlinked` Prints Stale Value Before `unlinkAttemptSucceeded`](#m10--unlinked-prints-stale-value-before-unlinkattemptssucceeded)
4. [Test Suite Bugs](#test-suite-bugs)
   - [T1 — Windows Test Calls `CloseHandle` on a UTF-16 String Pointer](#t1--windows-test-calls-closehandle-on-a-utf-16-string-pointer)
   - [T2 — Unix Tests Reset `errno` to `-1` Instead of `0`](#t2--unix-tests-reset-errno-to--1-instead-of-0)
   - [T3 — `sem_close` Called on `SEM_FAILED` Pointer (Undefined Behaviour)](#t3--sem_close-called-on-sem_failed-pointer-undefined-behaviour)
   - [T4 — Inverted Comment: `-1` Described as "success"](#t4--inverted-comment--1-described-as-success)
   - [T5 — Timing-Based Cross-Process Assertions Are Inherently Flaky](#t5--timing-based-cross-process-assertions-are-inherently-flaky)
   - [T6 — Tautological `expect` Compares Value to Itself](#t6--tautological-expect-compares-value-to-itself)
   - [T7 — Second `sem_unlink` Result Tested But Left Without Cleanup](#t7--second-sem_unlink-result-tested-but-left-without-cleanup)
   - [T8 — Exception Thrown Inside Isolate Is Silently Swallowed](#t8--exception-thrown-inside-isolate-is-silently-swallowed)
5. [Design and Architecture Concerns](#design-and-architecture-concerns)
   - [D1 — No `dispose()` Implementation: Registry Grows Forever](#d1--no-dispose-implementation-registry-grows-forever)
   - [D2 — `unlock()` Return Value Semantics Are Ambiguous](#d2--unlock-return-value-semantics-are-ambiguous)
   - [D3 — CI Matrix Does Not Test macOS Arm64 for FFI Mode Tests](#d3--ci-matrix-does-not-test-macos-arm64-for-ffi-mode-tests)
   - [D4 — `static late final dynamic __instances` Pattern Is Not Isolate-Safe](#d4--static-late-final-dynamic-__instances-pattern-is-not-isolate-safe)

---

## Critical Bugs

---

### C1 — Registry Guard Logic Inverted (3 Files, Copy-Pasted)

**Severity:** CRITICAL
**Affects:** All platforms (logic error, not platform-specific)
**Files:**
- [`lib/src/semaphore_identity.dart:29`](lib/src/semaphore_identity.dart#L29)
- [`lib/src/semaphore_counter.dart:138`](lib/src/semaphore_counter.dart#L138)
- [`lib/src/native_semaphore.dart:54`](lib/src/native_semaphore.dart#L54)

#### Description

The defensive guard in each `register()` method is logically inverted. The stated intent (as described in the exception message) is to **throw when a name is already registered with a different value**. The actual code throws under the near-impossible condition that the key does *not* exist AND the incoming value happens to compare equal to `null`.

This means:
1. Re-registering a name with a **completely different value** silently succeeds (no throw, no error).
2. The `putIfAbsent` on the line that follows prevents the actual overwrite, but the caller receives no feedback.
3. The exception is unreachable under normal use.

#### Exact Code — `semaphore_identity.dart`

```dart
// lib/src/semaphore_identity.dart:28-35

I register({required String name, required I identity}) {
  (_identities.containsKey(name) || identity != _identities[name]) ||      // ← INVERTED GUARD
      (throw Exception(
        'Failed to register semaphore identity for $name. It already exists or is not the same as the inbound identity being passed.',
      ));

  return _identities.putIfAbsent(name, () => identity);
}
```

#### Exact Code — `semaphore_counter.dart`

```dart
// lib/src/semaphore_counter.dart:135-143

CTR register({required String identifier, required CTR counter}) {
  (_counters.containsKey(identifier) || counter != _counters[identifier]) || // ← INVERTED GUARD
      (throw Exception(
        'Failed to register semaphore counter for $identifier. It already exists or is not the same as the inbound counter being passed.',
      ));

  return _counters.putIfAbsent(identifier, () => counter);
}
```

#### Exact Code — `native_semaphore.dart`

```dart
// lib/src/native_semaphore.dart:53-58

NS register({required String name, required NS semaphore}) {
  (_instantiations.containsKey(name) || semaphore != _instantiations[name]) || // ← INVERTED GUARD
      (throw Exception(
        'Failed to register semaphore counter for $name. It already exists or is not the same as the inbound identity being passed.',
      ));

  return _instantiations.putIfAbsent(name, () => semaphore);
}
```

#### Root Cause

The condition `(A || B)` throws only when both A and B are false:
- `A = containsKey(name)` is false → key **does not** exist
- `B = value != _map[name]` is false → the incoming value equals `_map[name]`; for a non-existent key `_map[name]` returns `null`, so this is false only when `value == null`

The correct guard should be:

```dart
// Intended semantics: throw only if name IS registered with a different value
(!_identities.containsKey(name) || identity == _identities[name]) ||
    (throw Exception(...));
```

This throws when:
- The key **already** exists (`containsKey` is true) AND the value is **different** (`identity != existing`).

#### Impact

Silent duplicate-registration bugs are masked. Tests that exercise the "already registered" path will pass even when the guard is completely bypassed. Any future refactor that relies on this guard for correctness will behave unexpectedly.

---

### C2 — `mode_t` ABI Mapping Wrong on macOS Arm64

**Severity:** CRITICAL
**Affects:** macOS Arm64 (Apple Silicon) — production environment
**File:** [`lib/src/ffi/unix.dart:29–45`](lib/src/ffi/unix.dart#L29)

#### Description

The `mode_t` ABI mapping declares `Abi.macosArm64: Uint64()` (8 bytes), but `mode_t` on all Darwin platforms is a 16-bit unsigned integer (`__uint16_t`). The adjacent comment even confirms this:

```
// POSIX: size_t is 4 bytes on 32-bit and 8 bytes on 64-bit
// mode_t — 2 bytes on MacOS Arm64 and x86_64
```

#### Exact Code

```dart
// lib/src/ffi/unix.dart:38-45

@AbiSpecificIntegerMapping({
  Abi.macosArm64: Uint64(),  // ← WRONG — should be Uint16(). Comment on line 29 even contradicts this.
  Abi.macosX64: Uint16(),    // Correct
  Abi.linuxX64: Uint16(),    // Correct
  Abi.linuxIA32: Uint16(),   // Correct
})
final class mode_t extends AbiSpecificInteger {
  const mode_t();
}
```

#### Impact

When `sem_open()` is called on Apple Silicon the permission argument is written/read as 8 bytes instead of 2 bytes. This corrupts the stack layout of the variadic `sem_open` call, potentially:
- Passing garbage permission bits (reading 6 bytes of adjacent stack memory as part of `mode`)
- Causing `sem_open` to return `SEM_FAILED` with `EINVAL`
- Causing undefined behaviour in the C variadic argument passing convention

Every semaphore open operation on Apple Silicon is affected.

---

### C3 — `SEM_FAILED` Wrong Value on Linux

**Severity:** CRITICAL
**Affects:** Linux (all x64 and IA32)
**File:** [`lib/src/ffi/unix.dart:287–290`](lib/src/ffi/unix.dart#L287)

#### Description

POSIX defines `SEM_FAILED` as `(sem_t *)-1`, which on a 64-bit architecture equals `0xffffffffffffffff`. The code returns `0x0` (NULL) for all non-macOS platforms, meaning any `sem_open` failure on Linux goes **completely undetected**.

#### Exact Code

```dart
// lib/src/ffi/unix.dart:287-290

static Pointer<Uint64> SEM_FAILED = Platform.isMacOS
    ? Pointer.fromAddress(0xffffffffffffffff)  // Correct for macOS
    : Pointer.fromAddress(0x0);               // ← WRONG for Linux: should be 0xffffffffffffffff
```

#### Correct Value

```c
// From <semaphore.h> on Linux:
#define SEM_FAILED   ((sem_t *) 0)   // ... only on some ancient BSDs
// On Linux (glibc), from bits/semaphore.h:
#define SEM_FAILED   ((sem_t *) -1)  // i.e. 0xffffffffffffffff on 64-bit
```

#### Impact

All Linux callers of `sem_open` check:

```dart
// lib/src/unix_semaphore.dart (openAttemptSucceeded)
if (_semaphore.address == UnixSemOpenMacros.SEM_FAILED.address)
```

With `SEM_FAILED = 0x0`, this comparison succeeds **only if** `sem_open` happened to return NULL. The actual failure address `0xffffffffffffffff` will never match `0x0`. Result: every semaphore open failure on Linux is silently treated as success, causing subsequent `sem_wait`/`sem_post` calls to operate on an invalid pointer — undefined behaviour / segfault.

---

### C4 — `unlock()` Short-Circuits OS Semaphore Release on Windows

**Severity:** CRITICAL
**Affects:** Windows — all reentrant-lock scenarios
**File:** [`lib/src/windows_semaphore.dart:368–371`](lib/src/windows_semaphore.dart#L368)

#### Description

The `unlock()` method uses a short-circuit OR:

```dart
// lib/src/windows_semaphore.dart:368-371

@override
bool unlock() {
  if (verbose) print("Evaluating [unlock()]: IDENTITY: ${identity.uuid} LOCKED: $locked");
  return unlockReentrantToIsolate() || unlockAcrossProcesses();  // ← SHORT-CIRCUIT BUG
}
```

`unlockReentrantToIsolate()` returns `true` when `willAttemptUnlockReentrantToIsolate()` succeeds (i.e., when `counter.counts.isolate.get() > 0` **and** `counter.counts.process.get() > 0`). When `unlockReentrantToIsolate()` returns `true`, the `||` operator short-circuits and `unlockAcrossProcesses()` — which contains the `ReleaseSemaphore()` call — is **never invoked**.

#### Analysis of `willAttemptUnlockReentrantToIsolate` on Windows

```dart
// lib/src/windows_semaphore.dart:318-342

@override
bool willAttemptUnlockReentrantToIsolate() {
  ...
  if (counter.counts.process.get() == 0) {         // process=0 → return false
    return false;
  }

  if (counter.counts.isolate.get() == 0 && counter.counts.process.get() > 0) {  // isolate=0 → return false
    return false;
  }

  return true;  // process>0 AND isolate>0 → return true
}
```

For the **final** unlock (process=1, isolate=1): both checks fail (neither equals zero), so `true` is returned. `unlockReentrantToIsolate()` decrements isolate to 0 and returns `true`. The `||` then short-circuits: `ReleaseSemaphore` is never called.

#### Effect

After a single lock–unlock cycle on Windows:
- `counter.counts.isolate.get()` = 0 ✓
- `counter.counts.process.get()` = 1 ✗ (still 1, decrement only happens in `unlockAttemptAcrossProcessesSucceeded`)
- The OS semaphore count is still 0 (WaitForSingleObject was called but ReleaseSemaphore was not)

Any subsequent `lock()` call will see `process > 0` in `willAttemptLockAcrossProcesses()` and return `false`, effectively making the semaphore permanently locked after the first use.

#### Contrast with Unix

The Unix implementation's `willAttemptUnlockReentrantToIsolate` returns `false` when `isolate.get() <= 1`, specifically to allow the OR to fall through to `unlockAcrossProcesses()`. The Windows version was ported without adapting this critical distinction.

---

## High Severity Bugs

---

### H1 — `GetLastError` Entirely Commented Out on Windows

**Severity:** HIGH
**Affects:** Windows — all error reporting
**File:** [`lib/src/ffi/windows.dart:168–177`](lib/src/ffi/windows.dart#L168)

#### Description

The entire `GetLastError` binding is commented out, referencing a Dart SDK issue that has since been closed. Windows error codes are completely inaccessible, making it impossible to distinguish between error conditions.

#### Exact Code

```dart
// lib/src/ffi/windows.dart:168-177

class WindowsKernel32 {
  // TODO: GetLastError is unavailable until https://github.com/dart-lang/sdk/issues/38832 is resolved
  // int GetLastError() => _GetLastError();
  // final _GetLastError = DynamicLibrary.open('kernel32.dll').lookupFunction<
  //     Uint32 Function(),
  //     int Function()>('GetLastError');
  //
  // @Native<Uint32 Function()>()
  // external int GetLastError();
}
```

The referenced Dart issue (`dart-lang/sdk#38832`) was about `GetLastError` being unreliable due to intervening FFI calls resetting the error state. The comment in `unlockAttemptAcrossProcessesSucceeded` and `closeAttemptSucceeded` acknowledges this:

```dart
// lib/src/windows_semaphore.dart:276-279

// TODO utilize something like this in the future when this dart issue is resolved
// TODO ${WindowsReleaseSemaphoreError.fromErrorCode(GetLastError()).toString()}
print(
  "... ERROR: Unavailable('UNABLE TO RETRIEVE ERROR ON WINDOWS AT THIS TIME') ",
);
```

#### Impact

When `ReleaseSemaphore`, `CloseHandle`, or `CreateSemaphoreW` fails, there is no way to retrieve the Windows error code. Errors are logged as `"Unavailable"`. Debugging Windows failures requires attaching WinDbg or a similar tool.

---

### H2 — `CreateSemaphoreW` First Argument Typed as `int` Instead of `Pointer`

**Severity:** HIGH
**Affects:** Windows — security attributes
**File:** [`lib/src/ffi/windows.dart:95–105`](lib/src/ffi/windows.dart#L95)

#### Description

The `lpSecurityAttributes` first parameter of `CreateSemaphoreW` is typed as `int` in the FFI binding instead of `Pointer<SECURITY_ATTRIBUTES>`. This means the type system will not catch accidental passing of non-null integers as pointer addresses.

#### Exact Code

```dart
// lib/src/ffi/windows.dart:95-105 (approximate)

int CreateSemaphoreW(
  int lpSecurityAttributes,       // ← should be Pointer<SECURITY_ATTRIBUTES> or Pointer<NativeType>
  int lInitialCount,
  int lMaximumCount,
  LPCWSTR lpName,
) => _CreateSemaphoreW(lpSecurityAttributes, lInitialCount, lMaximumCount, lpName);
```

#### Impact

The call site always passes `WindowsCreateSemaphoreWMacros.NULL.address` (an integer `0`). This is correct in practice, but the wrong type means that any future caller who accidentally passes a non-zero integer (thinking it's a pointer they own) will hand a garbage address to `CreateSemaphoreW`, causing undefined behaviour or access violations.

---

### H3 — `_identifier` Leaked on `close()` (Both Platforms)

**Severity:** HIGH
**Affects:** macOS, Linux, Windows
**Files:**
- [`lib/src/unix_semaphore.dart:455`](lib/src/unix_semaphore.dart#L455) — freed only in `unlinkAttemptSucceeded`
- [`lib/src/windows_semaphore.dart:457`](lib/src/windows_semaphore.dart#L457) — freed only in `unlinkAttemptSucceeded`

#### Description

The native allocation for the semaphore name string (`_identifier`) is freed only inside `unlinkAttemptSucceeded()`. If the caller follows the `open() → lock() → unlock() → close()` lifecycle **without** calling `unlink()`, the allocation is never freed.

#### Exact Code — Unix

```dart
// lib/src/unix_semaphore.dart:449-458 (approx)

@override
bool unlinkAttemptSucceeded({required int attempt}) {
  ...
  malloc.free(_identifier);  // ← Only place _identifier is freed
  ...
  return hasUnlinked = true;
}
```

There is no corresponding `malloc.free(_identifier)` inside `closeAttemptSucceeded` or anywhere else.

#### Exact Code — Windows

```dart
// lib/src/windows_semaphore.dart:449-462

@override
bool unlinkAttemptSucceeded({int attempt = 0}) {
  ...
  malloc.free(_identifier);   // ← Only freed here, never in close()
  ...
  return hasUnlinked = true;
}
```

#### Impact

Every semaphore that is `close()`d without being `unlink()`d leaks the UTF-8 (Unix) or UTF-16 (Windows) name allocation. For long-running processes that open many named semaphores, this is a steady memory leak. The `Finalizable` interface implemented by `NativeSemaphore` suggests GC-based cleanup was intended but the finalizer is never registered.

---

### H4 — `lock()` Short-Circuits `lockReentrantToIsolate()` on Windows

**Severity:** HIGH
**Affects:** Windows — reentrant locking
**File:** [`lib/src/windows_semaphore.dart:234–245`](lib/src/windows_semaphore.dart#L234)

#### Description

```dart
// lib/src/windows_semaphore.dart:234-245

@override
bool lock({bool blocking = true}) {
  if (verbose) print("Attempting [lock()]: IDENTITY: ${identity.uuid} BLOCKING: $blocking");

  bool processes = lockAcrossProcesses(blocking: blocking);
  bool isolates = processes || lockReentrantToIsolate();  // ← SHORT-CIRCUIT

  return (locked == (processes || isolates)) ||
      (throw Exception(...));
}
```

When `lockAcrossProcesses` succeeds and returns `true`, `lockReentrantToIsolate()` is never called. In the Unix implementation this is compensated for because `lockAttemptAcrossProcessesSucceeded` increments **both** the process and isolate counters. But if the Windows `lockAttemptAcrossProcessesSucceeded` increments only the process counter, the isolate counter remains at 0, breaking the reentrant-unlock path which expects `isolate > 0`.

#### Verification

```dart
// lib/src/windows_semaphore.dart:166-177 — lockAttemptAcrossProcessesSucceeded

@override
bool lockAttemptAcrossProcessesSucceeded({required int attempt}) {
  if (attempt == WindowsWaitForSingleObjectMacros.WAIT_OBJECT_0) {
    ...
    counter.counts.process.increment();  // ← Only process is incremented, NOT isolate
    ...
    return true;
  }
  ...
}
```

The isolate counter is incremented only inside `lockAttemptReentrantToIsolateSucceeded`:

```dart
// lib/src/windows_semaphore.dart:223-231

@override
bool lockAttemptReentrantToIsolateSucceeded() {
  counter.counts.isolate.increment();  // ← Not called on first lock due to short-circuit
  ...
  return true;
}
```

On the first `lock()` call: `processes = true`, `lockReentrantToIsolate()` is short-circuited, `isolate` stays at 0. Then `willAttemptUnlockReentrantToIsolate` checks `isolate == 0 && process > 0` → returns `false`. `unlockReentrantToIsolate()` returns `false`. The OR evaluates `unlockAcrossProcesses()`, which calls `ReleaseSemaphore`. This works for non-reentrant use.

But for reentrant use: after the second `lock()` increments `isolate` to 1, the interaction with `willAttemptUnlockReentrantToIsolate` becomes inconsistent with the process counter being 1. The counter states become desynced from actual lock depth.

---

## Moderate Bugs

---

### M1 — `LatePropertyAssigned` Uses Fragile SDK-Internal String Matching

**Severity:** MODERATE
**File:** [`lib/src/utils/late_property_assigned.dart:6–9`](lib/src/utils/late_property_assigned.dart#L6)

#### Description

The utility detects `LateInitializationError` by inspecting the string representation of the caught error, rather than catching the specific exception type.

#### Exact Code

```dart
// lib/src/utils/late_property_assigned.dart:1-10

bool LatePropertyAssigned<T>(Function accessor) {
  try {
    accessor();
    return true;
  } catch (error, trace) {
    return !(error.toString().contains('has not been initialized.') ||
        (Error.throwWithStackTrace(error, trace)));
  }
}
```

#### Why This Is Fragile

- The message `"has not been initialized."` is not part of Dart's public API; it is an implementation detail of the VM.
- Dart SDK 3.x or future versions could change this message (e.g., to `"has not been set"`) without a breaking-change notice, silently causing `LatePropertyAssigned` to rethrow all `LateInitializationError`s as unhandled exceptions.
- The `LateInitializationError` class has been publicly exported since Dart 2.18 via `dart:core` and can be caught by type directly.

#### Correct Approach

```dart
bool LatePropertyAssigned<T>(Function accessor) {
  try {
    accessor();
    return true;
  } on LateInitializationError {
    return false;
  }
}
```

---

### M2 — `address` Setter Silently Discards the New Value

**Severity:** MODERATE
**File:** [`lib/src/semaphore_identity.dart:62`](lib/src/semaphore_identity.dart#L62)

#### Description

The setter for `address` reads the current value of `_address` but discards it when the property is already assigned. The caller receives no error.

#### Exact Code

```dart
// lib/src/semaphore_identity.dart:58-62

late final int _address;

int get address => _address;

set address(int value) =>
    !LatePropertyAssigned<int>(() => _address) ? _address = value : _address;
//                                                                    ^^^^^^^
//                              evaluates _address and throws away the result.
//                              The incoming `value` is silently ignored.
```

#### Impact

Callers who call `identity.address = newValue` when `_address` is already set will:
1. Receive no exception.
2. Observe that `identity.address` still returns the old value.
3. Have no way to know the assignment was silently dropped.

A typical defensive pattern would be:

```dart
set address(int value) {
  if (LatePropertyAssigned<int>(() => _address)) {
    throw StateError('address is already set to $_address; cannot reassign to $value');
  }
  _address = value;
}
```

---

### M3 — `MAX_PATH` Calculation Subtracts Wrong Prefix Length

**Severity:** MODERATE
**Affects:** Windows — name length validation
**File:** [`lib/src/ffi/windows.dart:228`](lib/src/ffi/windows.dart#L228)

#### Description

```dart
// lib/src/ffi/windows.dart:224-232 (approx)

class WindowsCreateSemaphoreWMacros {
  static String GLOBAL_NAME_PREFIX = 'Global\\';  // 7 characters
  static String LOCAL_NAME_PREFIX  = 'Local\\';   // 6 characters

  static int MAX_PATH =
      260 - min(GLOBAL_NAME_PREFIX.length, LOCAL_NAME_PREFIX.length);
  //          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  //          min(7, 6) = 6, so MAX_PATH = 254
```

#### Why This Is Wrong

`MAX_PATH` represents the maximum length for a combined prefix + name string. Subtracting the *shorter* of the two prefixes means:
- A name exactly 254 characters long prepended with `Global\` (7 chars) would produce a 261-character path — 1 over the Windows limit.
- The semantic intent is to compute the maximum allowed user-supplied portion of the name, which depends on which prefix is **actually** being used.

The correct approach is to subtract the length of the prefix that will actually be prepended:

```dart
// For Global\ namespace:
static int MAX_GLOBAL_NAME_LENGTH = 260 - GLOBAL_NAME_PREFIX.length;  // 253

// For Local\ namespace:
static int MAX_LOCAL_NAME_LENGTH = 260 - LOCAL_NAME_PREFIX.length;    // 254
```

Or simply document that `MAX_PATH` is the raw Windows constant and leave the subtraction to the caller.

---

### M4 — Non-Atomic Read-Modify-Write in Counter Increment / Decrement

**Severity:** MODERATE
**File:** [`lib/src/semaphore_counter.dart:76–79`](lib/src/semaphore_counter.dart#L76)

#### Description

```dart
// lib/src/semaphore_counter.dart:76-79

CU increment() => update(value: get() + 1);   // read then write — not atomic
CU decrement() => update(value: get() - 1);   // read then write — not atomic
```

Between `get()` and `update()`, another thread / isolate could modify the counter, causing a lost update. This is a classic TOCTOU (time-of-check-time-of-use) race.

#### Impact

Dart isolates have independent heaps, so cross-isolate races are limited to shared native memory. However, the `SemaphoreCount` stores values in a `Map<String, int>` which **is** shared within a single isolate. If multiple fibers or microtasks within the same isolate call `increment()` concurrently (e.g., via async callbacks), lost updates are possible.

The `update()` method also performs a non-atomic read-then-write:

```dart
CU update({required int value}) => (_counts[identifier] = value) != null
    ? SemaphoreCountUpdate(from: ..., to: value, ...) as CU
    : throw Exception(...);
```

For correctness, a compare-and-swap or a Dart `Mutex` should be used.

---

### M5 — `putIfAbsent(() => null)` Always Produces `null` `from` Field

**Severity:** MODERATE
**File:** [`lib/src/semaphore_counter.dart:~51`](lib/src/semaphore_counter.dart#L46)

#### Description

Inside `update()`, the `from` field of the returned `SemaphoreCountUpdate` is computed as:

```dart
// lib/src/semaphore_counter.dart (approximately line 48-55)

from: counts.putIfAbsent(identifier, () => null) ?? counts[identifier],
```

On the first call for a given `identifier`, `putIfAbsent(identifier, () => null)` inserts `null` into `counts` and returns `null`. The `?? counts[identifier]` then re-reads the same key, returning `null` again. So `from` is always `null` for the first update. Any consumer that relies on `SemaphoreCountUpdate.from` to understand the previous count will observe `null` on the first increment.

---

### M6 — `identifier` Getter Uses Wrong Type Parameter in `LatePropertyAssigned`

**Severity:** MODERATE** (type-annotation bug, no runtime crash)
**File:** [`lib/src/windows_semaphore.dart:51`](lib/src/windows_semaphore.dart#L51)

#### Description

```dart
// lib/src/windows_semaphore.dart:49-53

late final LPCWSTR _identifier;   // LPCWSTR = Pointer<Uint16>

({bool isSet, LPCWSTR? get}) get identifier =>
    LatePropertyAssigned<Pointer<Char>>(() => _identifier)  // ← Pointer<Char> ≠ LPCWSTR
        ? (isSet: true, get: _identifier)
        : (isSet: false, get: null);
```

The type parameter `Pointer<Char>` does not match the actual field type `LPCWSTR` (`Pointer<Uint16>`). Since `LatePropertyAssigned<T>` never actually instantiates `T` (it only catches errors from calling the accessor), this causes no runtime crash. But it is a documentation and type-safety failure — anyone reading the generic parameter as documentation would believe `_identifier` is a `Pointer<Char>` (UTF-8) when it is actually UTF-16.

---

### M7 — Error Message Typo: "unlocked locked" in Two Files

**Severity:** LOW
**Files:**
- [`lib/src/unix_semaphore.dart:186`](lib/src/unix_semaphore.dart#L186) (approx)
- [`lib/src/windows_semaphore.dart:204`](lib/src/windows_semaphore.dart#L204)

#### Exact Code — Windows

```dart
// lib/src/windows_semaphore.dart:202-205

counter.counts.process.get() > 0 ||
    (throw Exception(
      'Failed [willAttemptLockReentrantToIsolate()]: IDENTITY: ${identity.uuid} REASON: Cannot lock reentrant to isolate while outer process is unlocked locked.',
      //                                                                                                                                             ^^^^^^^^^^^^^
      //                                                           "unlocked locked" — contradictory; should be "is not locked" or "is unlocked"
    ));
```

The phrase "unlocked locked" is a copy-paste artifact and internally contradictory. Minor but visible in production logs.

---

### M8 — `isEven` / `isOdd` Used as a Proxy for 0 / -1 Return Codes

**Severity:** LOW
**Files:** [`lib/src/unix_semaphore.dart:163`](lib/src/unix_semaphore.dart#L163) and throughout test files

#### Description

```dart
// lib/src/unix_semaphore.dart:163 (approx)

if (attempt.isEven) {  // 0 is even = success, -1 is odd = failure
```

`isEven` checks divisibility by 2, not equality to 0. While `0.isEven == true` and `(-1).isEven == false`, any future change that allows other return values (e.g., a non-zero positive on partial success) would silently misfire. `attempt == 0` is unambiguous and directly expresses intent.

This pattern appears pervasively in the test files as well (e.g., `closed.isEven`, `unlocked.isEven`, `waited.isOdd && waited.isNegative`).

---

### M9 — `NativeSemaphore.__instances` Not Concurrency-Safe

**Severity:** MODERATE
**File:** [`lib/src/native_semaphore.dart:91`](lib/src/native_semaphore.dart#L91)

#### Description

```dart
// lib/src/native_semaphore.dart:91

static late final dynamic __instances;
```

`static late final` fields in Dart are initialized lazily on first access. If two isolates (sharing the same isolate group and thus the same static field) call `NativeSemaphore.instantiate` simultaneously before `__instances` is set, both may attempt the assignment. `late final` throws a `LateInitializationError` on double-assignment. This race can be triggered in real applications using `Isolate.spawn` within the same group.

The same pattern exists in `SemaphoreIdentity.__instances` ([`semaphore_identity.dart:45`](lib/src/semaphore_identity.dart#L45)) and `SemaphoreCounter.__instances`.

---

### M10 — `$unlinked` Prints Stale Value Before `unlinkAttemptSucceeded`

**Severity:** LOW
**File:** [`lib/src/windows_semaphore.dart:472`](lib/src/windows_semaphore.dart#L472)

#### Description

```dart
// lib/src/windows_semaphore.dart:465-474

@override
bool unlink() {
  if (!willAttemptUnlink()) return false;

  if (verbose) print("Attempting [unlink()]: IDENTITY: ${identity.uuid}");

  // There is no 'unlink' equivalent on Windows so this will always proceed to the success method

  if (verbose) print("Attempted [unlink()]: IDENTITY: ${identity.uuid} ATTEMPT RESPONSE: $unlinked");
  //                                                                                      ^^^^^^^^
  //  `unlinked` getter: hasUnlinked is not yet set → returns false. Misleading print.

  return unlinkAttemptSucceeded();   // ← hasUnlinked is set INSIDE here, AFTER the print
}
```

The verbose line prints `"ATTEMPT RESPONSE: false"` even when unlink is about to succeed, because `hasUnlinked` is set in `unlinkAttemptSucceeded` which is called on the next line.

---

## Test Suite Bugs

---

### T1 — Windows Test Calls `CloseHandle` on a UTF-16 String Pointer

**Severity:** HIGH (test logic error, wrong cleanup)
**File:** [`test/windows_named_semaphore_ffi_bindings_test.dart:256–258`](test/windows_named_semaphore_ffi_bindings_test.dart#L256)

#### Description

After the two-isolate test completes, the test runner attempts cleanup using:

```dart
// test/windows_named_semaphore_ffi_bindings_test.dart:256-259

LPCWSTR _name = (name.toNativeUtf16());
final int closed = CloseHandle(_name.address);

expect(closed, equals(0));
```

`_name` is a `Pointer<Uint16>` (a heap allocation of the semaphore's name string). `CloseHandle(_name.address)` passes the address of the string buffer as a Windows HANDLE. `CloseHandle` returns `0` (failure) because it is not a valid kernel handle. The test **asserts this failure** with `expect(closed, equals(0))`, which means it treats a wrong API call as an expected result.

This pattern repeats identically at:
- Line 388–392 (second cross-isolate test)
- Line 457–461 (third cross-isolate test)

The `malloc.free(_name)` call is missing, also causing a memory leak per test.

#### Correct Cleanup

The semaphore handles are already closed by each isolate via `CloseHandle(sem.address)`. The name pointer should be freed, not passed to `CloseHandle`:

```dart
// Correct cleanup:
LPCWSTR _name = (name.toNativeUtf16());
// No CloseHandle needed — handles are already closed by isolates
malloc.free(_name);
```

---

### T2 — Unix Tests Reset `errno` to `-1` Instead of `0`

**Severity:** MODERATE
**File:** [`test/unix_named_semaphore_ffi_bindings_test.dart`](test/unix_named_semaphore_ffi_bindings_test.dart) — lines 49, 89, 251, 301, 362, 463, 573

#### Description

Throughout the FFI binding tests, `errno` is reset between operations using:

```dart
// test/unix_named_semaphore_ffi_bindings_test.dart:49

errno.value = -1;
```

The correct reset value is `0`. On POSIX systems, `errno` is only meaningful after a failing system call; its initial / reset state is `0`. Setting it to `-1` is non-standard — `errno` values are always positive integers (`ENOENT = 2`, `EEXIST = 17`, etc.) or `0` (no error). While this does not cause incorrect behavior in the tests (the next syscall will overwrite `errno`), it is incorrect practice and could mislead future readers about POSIX `errno` semantics.

---

### T3 — `sem_close` Called on `SEM_FAILED` Pointer (Undefined Behaviour)

**Severity:** HIGH
**File:** [`test/unix_named_semaphore_ffi_bindings_test.dart:303–306`](test/unix_named_semaphore_ffi_bindings_test.dart#L303)

#### Description

In the secondary isolate of the cross-isolate test, `sem_open` with `O_EXCL` fails (correctly, because the semaphore already exists), returning `SEM_FAILED`. The code then calls `sem_close` on this invalid pointer:

```dart
// test/unix_named_semaphore_ffi_bindings_test.dart:303-306

int closed = sem_close(sem);  // sem == SEM_FAILED (0xffffffffffffffff on macOS, or 0x0 on Linux with the bug)
(closed.isNegative && closed.isOdd) ||
    (throw Exception("sem_closed in secondary isolate should have expected -1, got $closed"));
```

Calling `sem_close(SEM_FAILED)` is **undefined behaviour** per POSIX. The pointer is either `(sem_t*)-1` or NULL depending on the platform. In practice glibc returns `-1` with `EINVAL`, but this is not guaranteed. The correct behavior is to skip `sem_close` entirely when `sem_open` failed:

```dart
// Correct:
if (sem.address == UnixSemOpenMacros.SEM_FAILED.address) {
  // sem is invalid — do NOT call sem_close
  sender.send(true);
  malloc.free(_name);
  return;
}
```

---

### T4 — Inverted Comment: `-1` Described as "success"

**Severity:** LOW (documentation bug)
**File:** [`test/unix_named_semaphore_ffi_bindings_test.dart:186`](test/unix_named_semaphore_ffi_bindings_test.dart#L186)

#### Description

```dart
// test/unix_named_semaphore_ffi_bindings_test.dart:184-186

final int unlinked_two = sem_unlink(name);
expect(unlinked_two, equals(-1));  // -1 indicates success because the semaphore was already unlinked
//                                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
//                                    WRONG: -1 always indicates FAILURE. 0 = success.
```

`sem_unlink` returns `0` on success and `-1` on failure (setting `errno = ENOENT` if the name doesn't exist). The comment inverts this. The assertion is correct (expecting `-1` for a double-unlink), but the comment describing `-1` as "success" will mislead any reader.

---

### T5 — Timing-Based Cross-Process Assertions Are Inherently Flaky

**Severity:** MODERATE
**File:** [`test/cross_process_semaphore_test.dart:83–84`](test/cross_process_semaphore_test.dart#L83)

#### Description

```dart
// test/cross_process_semaphore_test.dart:70-84

RegExp lock_time = RegExp(r"Locking semaphore with name \d+_named_sem took: \[(\d+)\] seconds");

int? primary_lock_time   = int.tryParse(lock_time.firstMatch(stdout1)?.group(1) ?? '-1');
int? secondary_lock_time = int.tryParse(lock_time.firstMatch(stdout2)?.group(1) ?? '-1');

expect(primary_lock_time, equals(anyOf([3, 4])));      // ← hard-coded timing window
expect(secondary_lock_time, equals(anyOf([4, 5, 6]))); // ← hard-coded timing window
```

The test asserts that a child process acquires the semaphore in exactly 3 or 4 seconds. On a heavily loaded CI runner or a slow machine, process startup can take > 2 seconds, shifting these values outside the acceptable range and causing spurious failures. Additionally, the `anyOf([4, 5, 6])` window for the secondary process is asymmetric — there is no upper bound protection if the machine is very slow.

The test also has a pre-existing locking issue in the main process (`Future.delayed(Duration(seconds: 4), () => sem.unlock())`) — a fire-and-forget future with no `await`, meaning the test can complete before the unlock occurs.

---

### T6 — Tautological `expect` Compares Value to Itself

**Severity:** MODERATE
**Files:**
- [`test/semaphore_count_test.dart:76`](test/semaphore_count_test.dart#L76)
- [`test/semaphore_reentrant_test.dart:94–97`](test/semaphore_reentrant_test.dart#L94)

#### Description — `semaphore_count_test.dart:76`

```dart
// test/semaphore_count_test.dart:75-77

// verify the name is the same as the counter's name
expect(counter.identity.name, equals(counter.identity.name));
//     ^^^^^^^^^^^^^^^^^^^^           ^^^^^^^^^^^^^^^^^^^^
//     Same expression on both sides. Always passes regardless of actual value.
```

The intent is almost certainly `expect(counter.identity.name, equals(name))` (the local test variable `name`).

#### Description — `semaphore_reentrant_test.dart:94–97`

```dart
// test/semaphore_reentrant_test.dart:94-97

expect(
  sem.counter.counts.isolate.get(),
  equals(currentDepth - (currentDepth - sem.counter.counts.isolate.get())),
  //                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  //  currentDepth - (currentDepth - x) == x, always.
  //  This assertion is trivially true and tests nothing.
);
```

The algebraic simplification `currentDepth - (currentDepth - x) = x` means this `expect` always compares the counter value to itself. The test should assert the expected value at each recursion depth explicitly, e.g., `equals(depth - currentDepth + 1)`.

---

### T7 — Second `sem_unlink` Result Tested But Left Without Cleanup

**Severity:** LOW
**File:** [`test/unix_named_semaphore_ffi_bindings_test.dart:182–188`](test/unix_named_semaphore_ffi_bindings_test.dart#L182)

#### Description

```dart
// test/unix_named_semaphore_ffi_bindings_test.dart:182-188

final int unlinked_one = sem_unlink(name);
expect(unlinked_one, equals(0)); // 0 indicates success

final int unlinked_two = sem_unlink(name);
expect(unlinked_two, equals(-1)); // -1 indicates failure because the semaphore was already unlinked

malloc.free(name);
```

After the double-unlink, `malloc.free(name)` is called once. This is correct. However, `name` is a `Pointer<Char>` allocated at the top of the test and is only freed here — this is fine. But the test name says "Opens Existing Semaphore with same name and O_CREATE Flag", and the test itself allocates `sem_two` via `sem_open` with `O_CREAT` (not `O_EXCL`). Both `sem_one` and `sem_two` are properly closed. Minor coverage concern: `errno` is never read after the second `sem_unlink` to confirm it's set to `ENOENT`.

---

### T8 — Exception Thrown Inside Isolate Is Silently Swallowed

**Severity:** HIGH
**File:** [`test/unix_named_semaphore_ffi_bindings_test.dart:40–46`](test/unix_named_semaphore_ffi_bindings_test.dart#L40)

#### Description

```dart
// test/unix_named_semaphore_ffi_bindings_test.dart:40-46

try {
  int error_number = errno.value;
  (sem.address != UnixSemOpenMacros.SEM_FAILED.address) ||
      (throw "${UnixSemOpenError.fromErrno(error_number).toString()}");
} catch (e) {
  print(e);  // ← Exception caught and swallowed — test continues regardless
}
```

If `sem_open` fails and `SEM_FAILED` is returned, this block throws a string error (not an `Exception` or `Error`). The `catch (e) { print(e); }` block catches the thrown string and prints it, but the test **continues** without failing. The `expect` on line 38 would have already caught the failure via `expect(sem.address != ..., isTrue)`, but the try/catch block creates a false impression of error handling while silently eating the exception. Any time the inner throw fires, it should be allowed to propagate.

---

## Design and Architecture Concerns

---

### D1 — No `dispose()` Implementation: Registry Grows Forever

**Severity:** HIGH
**Files:** [`lib/src/semaphore_identity.dart:99`](lib/src/semaphore_identity.dart#L99), [`lib/src/native_semaphore.dart:63-66`](lib/src/native_semaphore.dart#L63)

#### Description

```dart
// lib/src/semaphore_identity.dart:99

bool dispose() => throw UnimplementedError('Dispose not implemented');
```

The `SemaphoreIdentities`, `SemaphoreCounters`, and `NativeSemaphores` registries are backed by `static final Map` fields:

```dart
// lib/src/native_semaphore.dart:41
static final Map<String, dynamic> __instantiations = {};

// lib/src/semaphore_identity.dart:16
static final Map<String, dynamic> __identities = {};
```

`static final` maps in Dart persist for the lifetime of the isolate. Every call to `NativeSemaphore.instantiate(name: ...)` with a distinct name adds an entry that is **never removed**. Long-running processes that open many semaphores with unique names will accumulate entries indefinitely.

The `delete()` method exists on the registry classes but is never called by the lifecycle methods (`close()`, `unlink()`). The `dispose()` method on `SemaphoreIdentity` is `UnimplementedError`.

---

### D2 — `unlock()` Return Value Semantics Are Ambiguous

**Severity:** MODERATE

The `unlock()` return value can mean:
- `true` → reentrant unlock performed (process lock still held)
- `true` → process lock released via `sem_post` / `ReleaseSemaphore`
- `false` → not locked at all (no-op)
- `false` → locked but `willAttemptUnlockAcrossProcesses` decided not to release (still reentrant locks)

Callers cannot distinguish between "successfully decremented one reentrant layer" and "fully released the semaphore". The method signature should return an enum or a named record:

```dart
({bool reentrantDecremented, bool processReleased}) unlock();
```

---

### D3 — CI Matrix Does Not Test macOS Arm64 for FFI Mode Tests

**Severity:** HIGH
**File:** [`.github/workflows/dart.yml`](.github/workflows/dart.yml)

#### Description

The CI matrix includes `macos-latest` (which may be x64 or Arm64 depending on GitHub-hosted runner availability), but the `mode_t` bug (C2 above) specifically affects `Abi.macosArm64`. Until C2 is fixed, FFI binding tests on Apple Silicon will likely fail with `EINVAL` from `sem_open`. After C2 is fixed, the CI should explicitly include an `arm64` macOS runner to prevent regression.

---

### D4 — `static late final dynamic __instances` Pattern Is Not Isolate-Safe

**Severity:** MODERATE
**Files:** All registry classes

#### Description

Dart's `late final` is not thread-safe for concurrent initialization from multiple isolates within the same isolate group (Dart 2.15+ `Isolate.spawn` with `isBroadcastChannel` or shared memory). The following pattern appears in three classes:

```dart
// lib/src/native_semaphore.dart:91
static late final dynamic __instances;

// lib/src/native_semaphore.dart:164-166
if (!LatePropertyAssigned<NSS>(() => __instances)) {
  __instances = NativeSemaphores<...>();
}
```

If two isolates execute the `if (!LatePropertyAssigned...)` check simultaneously, both may find `__instances` unassigned and attempt to assign. The second assignment of a `late final` field throws `LateInitializationError`. This is a TOCTOU race that is difficult to trigger in tests but is a real risk in production with concurrent isolates.

---

## Summary Table

| ID  | File                                  | Line(s)     | Severity | Category             |
|-----|---------------------------------------|-------------|----------|----------------------|
| C1  | `semaphore_identity.dart`             | 29          | CRITICAL | Logic Error          |
| C1  | `semaphore_counter.dart`              | 138         | CRITICAL | Logic Error          |
| C1  | `native_semaphore.dart`               | 54          | CRITICAL | Logic Error          |
| C2  | `ffi/unix.dart`                       | 42          | CRITICAL | ABI / FFI            |
| C3  | `ffi/unix.dart`                       | 289         | CRITICAL | ABI / FFI            |
| C4  | `windows_semaphore.dart`              | 370         | CRITICAL | Correctness          |
| H1  | `ffi/windows.dart`                    | 168–177     | HIGH     | Missing Functionality|
| H2  | `ffi/windows.dart`                    | ~100        | HIGH     | Type Safety          |
| H3  | `unix_semaphore.dart`                 | 455         | HIGH     | Memory Leak          |
| H3  | `windows_semaphore.dart`              | 457         | HIGH     | Memory Leak          |
| H4  | `windows_semaphore.dart`              | 239         | HIGH     | Counter State        |
| M1  | `utils/late_property_assigned.dart`   | 8           | MODERATE | Fragility            |
| M2  | `semaphore_identity.dart`             | 62          | MODERATE | Silent Failure       |
| M3  | `ffi/windows.dart`                    | 228         | MODERATE | Logic Error          |
| M4  | `semaphore_counter.dart`              | 76–79       | MODERATE | Race Condition       |
| M5  | `semaphore_counter.dart`              | ~51         | MODERATE | Incorrect Data       |
| M6  | `windows_semaphore.dart`              | 51          | MODERATE | Type Annotation      |
| M7  | `unix_semaphore.dart`                 | ~186        | LOW      | Documentation        |
| M7  | `windows_semaphore.dart`              | 204         | LOW      | Documentation        |
| M8  | `unix_semaphore.dart`                 | 163         | LOW      | Code Clarity         |
| M9  | `native_semaphore.dart`               | 91          | MODERATE | Concurrency          |
| M10 | `windows_semaphore.dart`              | 472         | LOW      | Misleading Log       |
| T1  | `windows_ffi_bindings_test.dart`      | 257, 389, 458 | HIGH   | Wrong API Call       |
| T2  | `unix_ffi_bindings_test.dart`         | 49, 89+     | MODERATE | Incorrect errno Use  |
| T3  | `unix_ffi_bindings_test.dart`         | 303–306     | HIGH     | Undefined Behaviour  |
| T4  | `unix_ffi_bindings_test.dart`         | 186         | LOW      | Bad Comment          |
| T5  | `cross_process_semaphore_test.dart`   | 83–84       | MODERATE | Flaky Test           |
| T6  | `semaphore_count_test.dart`           | 76          | MODERATE | Tautological Test    |
| T6  | `semaphore_reentrant_test.dart`       | 94–97       | MODERATE | Tautological Test    |
| T7  | `unix_ffi_bindings_test.dart`         | 182–188     | LOW      | Incomplete Coverage  |
| T8  | `unix_ffi_bindings_test.dart`         | 40–46       | HIGH     | Swallowed Exception  |
| D1  | Registry classes                      | —           | HIGH     | Design               |
| D2  | `unix/windows_semaphore.dart`         | —           | MODERATE | API Design           |
| D3  | `.github/workflows/dart.yml`          | —           | HIGH     | CI Coverage Gap      |
| D4  | Registry classes                      | —           | MODERATE | Concurrency          |
