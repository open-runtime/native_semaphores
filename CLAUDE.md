# CLAUDE.md — runtime_native_semaphores

## Project Overview

`runtime_native_semaphores` is a Dart FFI library providing cross-platform named semaphore support on **macOS**, **Linux**, and **Windows**. It enables mutual exclusion across **processes** and **isolates** using POSIX (`sem_open`/`sem_wait`/`sem_post`/`sem_close`/`sem_unlink`) on Unix and `CreateSemaphoreW`/`WaitForSingleObject`/`ReleaseSemaphore`/`CloseHandle` on Windows.

- **Package name**: `runtime_native_semaphores`
- **Current version**: `1.0.0-beta.7`
- **SDK constraint**: `^3.9.0`
- **Publish**: `publish_to: none` (internal/monorepo package)

---

## Architecture

### Class Hierarchy

```
NativeSemaphore<I, IS, CU, CD, CT, CTS, CTR, CTRS>   (abstract, in native_semaphore.dart)
├── UnixSemaphore<...>    (unix_semaphore.dart)         — POSIX sem_t via FFI
└── WindowsSemaphore<...> (windows_semaphore.dart)      — WinAPI HANDLE via FFI

SemaphoreIdentity                (semaphore_identity.dart) — name + isolate + process metadata
SemaphoreCounter<...>            (semaphore_counter.dart)  — isolate-local + process-global lock counts
SemaphoreCount<CU, CD>           (semaphore_counter.dart)  — single counter (isolate OR process)
SemaphoreCounts<CU, CD, CT>      (semaphore_counter.dart)  — holds both {isolate, process} counts
NativeSemaphores<...>            (native_semaphore.dart)   — global singleton registry keyed by name
```

### Type Alias Convenience (`native_semaphore_types.dart`)

```dart
typedef I    = SemaphoreIdentity;
typedef IS   = SemaphoreIdentities<I>;
typedef CU   = SemaphoreCountUpdate;
typedef CD   = SemaphoreCountDeletion;
typedef CT   = SemaphoreCount<CU, CD>;
typedef CTS  = SemaphoreCounts<CU, CD, CT>;
typedef CTR  = SemaphoreCounter<I, CU, CD, CT, CTS>;
typedef CTRS = SemaphoreCounters<I, CU, CD, CT, CTS, CTR>;
typedef NS   = NativeSemaphore<I, IS, CU, CD, CT, CTS, CTR, CTRS>;
```

Use these aliases everywhere — the raw 8-parameter form is almost unreadable.

### Lifecycle

```
instantiate() → open() → lock() [→ lock() reentrant...] → unlock() [→ unlock()...] → close() → unlink()
```

- `open()` calls `sem_open` / `CreateSemaphoreW`.
- `lock(blocking: true)` calls `sem_wait` / `WaitForSingleObject(INFINITE)`.
- `lock(blocking: false)` calls `sem_trywait` / `WaitForSingleObject(0)`.
- `unlock()` calls `sem_post` / `ReleaseSemaphore`.
- `close()` calls `sem_close` / `CloseHandle`.
- `unlink()` calls `sem_unlink` (no-op on Windows — sets flag only).

### Singleton / Registry Pattern

`NativeSemaphore.instantiate(name: ...)` returns the same instance for the same name within a process/isolate. The `NativeSemaphores` class is the backing registry.

---

## Key Design Patterns

| Pattern | Where |
|---------|-------|
| Singleton per name | `NativeSemaphore.instantiate()` / `NativeSemaphores` registry |
| Template Method | `willAttempt*()` / `*Succeeded()` hooks in base class, overridden by platform subclasses |
| `late` variable guard | `LatePropertyAssigned<T>()` utility (fragile — see bugs below) |
| Reentrant counting | `SemaphoreCount` isolate-level counter tracks depth; process-level counter tracks OS lock |

---

## File Map

| File | Purpose |
|------|---------|
| `lib/runtime_native_semaphores.dart` | Barrel export |
| `lib/src/native_semaphore.dart` | Abstract base + registry |
| `lib/src/native_semaphore_types.dart` | Type aliases (I, IS, CU, …) |
| `lib/src/semaphore_identity.dart` | Name/isolate/process identity |
| `lib/src/semaphore_counter.dart` | Lock counting (isolate + process) |
| `lib/src/unix_semaphore.dart` | POSIX implementation |
| `lib/src/windows_semaphore.dart` | Windows implementation |
| `lib/src/ffi/unix.dart` | FFI bindings: `sem_open`, `sem_wait`, `sem_post`, `sem_close`, `sem_unlink`, errno |
| `lib/src/ffi/windows.dart` | FFI bindings: `CreateSemaphoreW`, `WaitForSingleObject`, `ReleaseSemaphore`, `CloseHandle` |
| `lib/src/utils/late_property_assigned.dart` | `late` initialization check utility |
| `bin/test/primary_semaphore.dart` | AOT binary spawned by cross-process tests |
| `test/semaphore_test.dart` | Cross-isolate basic semaphore test |
| `test/semaphore_count_test.dart` | Counter state management tests |
| `test/semaphore_reentrant_test.dart` | Reentrant lock depth tests |
| `test/cross_process_semaphore_test.dart` | Cross-process timing/coordination test |
| `test/unix_named_semaphore_ffi_bindings_test.dart` | Raw FFI tests (Linux/macOS) |
| `test/windows_named_semaphore_ffi_bindings_test.dart` | Raw FFI tests (Windows) |
| `_scripts/*.sh` | Shell scripts for probing platform C type sizes/constants |
| `.github/workflows/` | CI/CD: `ci.yaml`, `release.yaml`, `workflow.yaml`, reusable tester |
| `.runtime_ci/config.json` | CI automation config (Gemini, Sentry, cross-repo) |
| `.runtime_ci/autodoc.json` | AI documentation generation config |

---

## Running Tests

Tests must be run from the **package directory**, not the monorepo root.

```bash
cd packages/libraries/dart/native_semaphores

# All tests
dart test .

# Single file
dart test test/semaphore_test.dart

# Platform-specific (Unix only)
dart test test/unix_named_semaphore_ffi_bindings_test.dart

# Cross-process test requires AOT binary — compile first if missing:
dart compile exe bin/test/primary_semaphore.dart -o bin/test/primary_semaphore
dart test test/cross_process_semaphore_test.dart
```

**WARNING**: Running from the monorepo root with `melos` will produce "Couldn't resolve package" errors.

---

## Known Bugs (Confirmed — Do Not Regress)

### CRITICAL — Will crash or silently misbehave

#### BUG-1: Registry `register()` logic is inverted
**File**: `lib/src/native_semaphore.dart` (~line 54), `lib/src/semaphore_counter.dart` (~line 138), `lib/src/semaphore_identity.dart` (~line 29)
```dart
// Current (broken): throws when adding NEW entry (containsKey is false → condition false → OR chain reaches throw)
(_instantiations.containsKey(name) || semaphore != _instantiations[name]) || (throw Exception(...));

// Should be:
(!_instantiations.containsKey(name) || semaphore == _instantiations[name]) || (throw Exception(...));
```
The same inverted pattern appears in all three registry classes (copy-pasted bug). This makes registering any new semaphore unreliable.

#### BUG-2: Windows `identifier` getter checks wrong type
**File**: `lib/src/windows_semaphore.dart` (~line 51)
```dart
// WRONG: _identifier is LPCWSTR (Pointer<Utf16>), not Pointer<Char>
LatePropertyAssigned<Pointer<Char>>(() => _identifier)

// Should be:
LatePropertyAssigned<LPCWSTR>(() => _identifier)
```
This always evaluates to `false`, breaking the `isSet` check. All `identifier.isSet` calls return `false` on Windows.

#### BUG-3: Undefined variable `$unlinked` crashes on Windows (verbose mode)
**File**: `lib/src/windows_semaphore.dart` (~line 472)
```dart
// CRASH when verbose=true — $unlinked is not defined in scope
if (verbose) print("Attempted [unlink()]: ${identity.uuid} ATTEMPT RESPONSE: $unlinked");
```
Replace with a literal (e.g., `0`) or a proper variable.

#### BUG-4: `LatePropertyAssigned` has broken error-rethrow logic
**File**: `lib/src/utils/late_property_assigned.dart` (~line 8)
```dart
// Current (broken): if error IS "not initialized" → re-throws via the OR branch
return !(error.toString().contains('has not been initialized.') || (Error.throwWithStackTrace(error, trace)));

// Should be (no rethrow needed):
return error is LateInitializationError;
```
Also: string matching on error messages is fragile across Dart versions. Catch `LateInitializationError` specifically.

---

### HIGH — Logic errors and resource leaks

#### BUG-5: `mode_t` wrong size on macOS Arm64
**File**: `lib/src/ffi/unix.dart` (~line 42)
```dart
// WRONG: macOS Arm64 mode_t is 2 bytes (Uint16), not 8 bytes (Uint64)
Abi.macosArm64: Uint64(),

// Should be:
Abi.macosArm64: Uint16(),
```
This corrupts the permission bits passed to `sem_open()` on Apple Silicon.

#### BUG-6: `SEM_FAILED` wrong value on Linux
**File**: `lib/src/ffi/unix.dart` (~line 289)
```dart
// WRONG: On Linux, SEM_FAILED = (sem_t*)-1, not NULL
SEM_FAILED = Pointer.fromAddress(0x0)  // Linux branch

// Should be:
SEM_FAILED = Pointer.fromAddress(0xffffffffffffffff)
```
This means semaphore open failures are not detected on Linux.

#### BUG-7: `GetLastError` is commented out on Windows
**File**: `lib/src/ffi/windows.dart` (~lines 168–174)
The entire `GetLastError` FFI binding is commented out. Windows error codes are inaccessible, making any Windows error handling essentially a stub.

#### BUG-8: `_identifier` memory leaked on `close()` without `unlink()`
**Files**: `lib/src/unix_semaphore.dart` (~line 455), `lib/src/windows_semaphore.dart` (~line ~472)
`_identifier` (UTF-8 or UTF-16 native string) is only freed inside `unlinkAttemptSucceeded()`. If the caller calls `close()` but not `unlink()`, the allocation leaks.

#### BUG-9: Unlock logic uses `||` instead of sequential execution
**File**: `lib/src/unix_semaphore.dart` (~line 350)
```dart
// Current: if reentrant unlock succeeds, process unlock is skipped
return unlockReentrantToIsolate() || unlockAcrossProcesses();

// Should be: decrement isolate count THEN conditionally release process lock
```

#### BUG-10: `MAX_PATH` calculation is wrong on Windows
**File**: `lib/src/ffi/windows.dart` (~line 228)
```dart
// Subtracts min prefix length (7) from 260, yielding 253
static int MAX_PATH = 260 - min(GLOBAL_NAME_PREFIX.length, LOCAL_NAME_PREFIX.length);
```
The intent is unclear but the result is an artificially reduced name limit.

#### BUG-11: `address` setter on `SemaphoreIdentity` doesn't prevent reassignment
**File**: `lib/src/semaphore_identity.dart` (~line 62)
```dart
// Returns value without side effect; assignment still succeeds
set address(int value) => !LatePropertyAssigned<int>(() => _address)
    ? _address = value
    : _address;
```
The `? _address = value : _address` branch is an expression, not a guard.

#### BUG-12: Windows test closes UTF-16 string pointer instead of semaphore handle
**File**: `test/windows_named_semaphore_ffi_bindings_test.dart` (~lines 257, 389)
```dart
LPCWSTR _name = (name.toNativeUtf16());
final int closed = CloseHandle(_name.address);  // BUG: closes the string, not the semaphore
```
The actual semaphore handle is never closed. This leaks OS handles.

#### BUG-13: `errno` reset uses wrong value in tests
**File**: `test/unix_named_semaphore_ffi_bindings_test.dart` (~lines 49, 89, 174, 251, 301, 362)
```dart
errno.value = -1;  // Wrong: should reset to 0
```

#### BUG-14: `sem_unlink` return value assertion is inverted in test
**File**: `test/unix_named_semaphore_ffi_bindings_test.dart` (~lines 185–186)
```dart
expect(unlinked_two, equals(-1)); // Comment says "-1 indicates success" — this is false
```
`sem_unlink` returns 0 on success and -1 on failure. The assertion is correct (second unlink should fail) but the comment is wrong and misleading.

---

### MEDIUM — Design issues and fragility

#### BUG-15: Non-atomic increment/decrement in `SemaphoreCount`
**File**: `lib/src/semaphore_counter.dart` (~lines 76–79)
`get() + 1` then `update()` is a TOCTOU race if multiple isolates share the counter.

#### BUG-16: `success.isEven` used as proxy for `== 0`
**Files**: `lib/src/unix_semaphore.dart` (~line 163), test files
`sem_wait` returns 0 (even) on success and -1 (odd) on failure, so `isEven` accidentally works — but `== 0` is clearer and more correct.

#### BUG-17: Tautological assertions in reentrant test
**File**: `test/semaphore_reentrant_test.dart` (~lines 92–93, 137–138)
```dart
expect(value, equals(currentDepth - (currentDepth - value)));  // Always true
```
No real assertion; rewrite with expected computed values.

#### BUG-18: Exception suppression in Unix FFI test
**File**: `test/unix_named_semaphore_ffi_bindings_test.dart` (~lines 41–45)
```dart
try { ... (throw "error"); } catch (e) { print(e); }  // Swallows failures silently
```

#### BUG-19: `Global\` prefix stripping regex broken
**File**: `lib/src/semaphore_identity.dart` (~line 76)
```dart
name.replaceFirst('Global\\', '')  // Only strips on Unix if 'Global\' is literal
```
Windows path prefix handling needs a raw string: `r'Global\'`.

---

## FFI Binding Reference

### Unix (`lib/src/ffi/unix.dart`)

| Symbol | Purpose |
|--------|---------|
| `sem_open(name, oflag, mode, value)` | Create/open named semaphore |
| `sem_wait(sem)` | Block until lock acquired (returns 0 or -1) |
| `sem_trywait(sem)` | Non-blocking lock attempt (returns 0 or -1) |
| `sem_post(sem)` | Release lock (returns 0 or -1) |
| `sem_close(sem)` | Close handle (returns 0 or -1) |
| `sem_unlink(name)` | Remove semaphore by name (returns 0 or -1) |
| `__error()` / `__errno_location()` | Get errno pointer (macOS / Linux) |

**Constants** (`UnixSemOpenMacros`):
- `O_CREAT`: 512 (BSD) / 64 (GNU)
- `O_EXCL`: 2560 (BSD) / 192 (GNU)
- `SEM_FAILED`: `0xffffffffffffffff` (macOS) — **currently wrong on Linux** (see BUG-6)
- `NAME_MAX_CHARACTERS`: 30 (effective macOS limit), 255 (Linux)

### Windows (`lib/src/ffi/windows.dart`)

| Symbol | Purpose |
|--------|---------|
| `CreateSemaphoreW(attrs, initial, max, name)` | Create/open named semaphore |
| `WaitForSingleObject(handle, timeout)` | Wait for lock (returns WAIT_OBJECT_0=0 on success) |
| `ReleaseSemaphore(handle, count, prev)` | Release lock (returns non-zero on success) |
| `CloseHandle(handle)` | Close handle (returns non-zero on success) |
| `GetLastError()` | **CURRENTLY COMMENTED OUT** — see BUG-7 |

**Constants** (`WindowsWaitForSingleObjectMacros`):
- `WAIT_OBJECT_0`: 0 (success)
- `WAIT_TIMEOUT`: 258
- `WAIT_ABANDONED`: 0x80
- `WAIT_FAILED`: 0xFFFFFFFF
- `TIMEOUT_INFINITE`: 0xFFFFFFFF
- `TIMEOUT_ZERO`: 0

**Critical note**: Windows return conventions are OPPOSITE to Unix — `0` means failure, non-zero means success for most calls except `WaitForSingleObject`.

---

## Semaphore Naming Conventions

| Platform | Format | Limit |
|----------|--------|-------|
| macOS | `/name` (leading slash required) | 30 characters (including `/`) |
| Linux | `/name` (leading slash required) | 255 characters |
| Windows | `Global\name` or `Local\name` | 260 characters |

The library handles prefix normalization internally via `SemaphoreIdentity`.

---

## CI/CD Summary

### Workflows

| Workflow | Trigger | Platforms |
|----------|---------|-----------|
| `ci.yaml` | Push/PR to `main` | **Linux only** (limitation) |
| `workflow.yaml` | Push to `main`, `aot_monorepo_compat`, manual | macOS Arm64, macOS x64, Linux, Windows |
| `release.yaml` | After `ci.yaml` succeeds | AI-powered 7-stage release |
| `issue-triage.yaml` | Issue opened/comment with `@gemini-cli` | — |

### Platform Runners

- macOS Arm64: `macos-13-xlarge` (GitHub-hosted)
- macOS Intel: `macos-13-large` (GitHub-hosted)
- Linux: `aot-linux-runner` (self-hosted)
- Windows: `aot-windows-x64-runner` (self-hosted)

### Known CI Issues

- **Dart SDK and pub caching disabled** in `reusable-native-semaphore-platform-tester.yaml` (lines 50–66) — re-enable for faster runs
- **Main CI only tests Linux** — FFI/platform bugs on macOS/Windows not caught by `ci.yaml`
- Test reports not collected (no JUnit XML output)

---

## Development Workflow

### Adding a new platform API

1. Add FFI binding to `lib/src/ffi/unix.dart` or `lib/src/ffi/windows.dart`
2. Add `willAttempt*()` + `*Succeeded()` hook methods to `NativeSemaphore` base
3. Implement in `UnixSemaphore` and `WindowsSemaphore`
4. Add tests to both `unix_named_semaphore_ffi_bindings_test.dart` and `windows_named_semaphore_ffi_bindings_test.dart`

### Testing cross-process behavior

Cross-process tests require the `primary_semaphore` AOT binary:
```bash
dart compile exe bin/test/primary_semaphore.dart -o bin/test/primary_semaphore
```
The binary is pre-compiled and checked in. Recompile after any changes to `bin/test/primary_semaphore.dart`.

### Checking platform constant values

Use the scripts in `_scripts/` to probe actual C type sizes/constant values on the current system:
```bash
bash _scripts/sem_t_properties.sh
bash _scripts/mode_t_properties.sh
bash _scripts/SEM_FAILED_properties.sh
```
These require `gcc` to be available.

---

## Outstanding TODOs (from CHANGELOG)

- Implement a clean-up mechanism for stray locks across the OS (process crash leaves semaphore locked)
- Implement a way to track blocked lock requests across processes
- Re-enable Dart SDK and pub caching in reusable CI tester
- Fix all CRITICAL bugs listed above before `1.0.0` stable release

---

## Documentation Gaps

The README is missing:
1. Explanation of the singleton/registry pattern (`NativeSemaphore.instantiate` returns same instance per name)
2. Reentrant behavior (how isolate-level counts work, when a process lock is truly released)
3. Error handling — all lifecycle methods return `bool`; failure must be checked
4. Non-blocking usage example (`lock(blocking: false)`)
5. Platform-specific naming format differences
6. Verbose mode (`verbose: true` on `instantiate()`)
7. Guidance on cleanup after process crash (stray semaphores)

README also has a typo at line 44: `"I's suggest using an safe integer"` → `"I suggest using a safe integer"`.
