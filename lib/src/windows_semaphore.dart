import 'dart:ffi' show Char, NativeType, Pointer;

import 'package:ffi/ffi.dart' show StringUtf16Pointer, malloc;

import 'native_semaphore.dart' show NativeSemaphore;
import 'semaphore_counter.dart'
    show
        SemaphoreCount,
        SemaphoreCountDeletion,
        SemaphoreCountUpdate,
        SemaphoreCounter,
        SemaphoreCounters,
        SemaphoreCounts;
import 'semaphore_identity.dart' show SemaphoreIdentities, SemaphoreIdentity;

import 'ffi/windows.dart'
    show
        CloseHandle,
        CreateSemaphoreW,
        LPCWSTR,
        ReleaseSemaphore,
        WaitForSingleObject,
        WindowsCreateSemaphoreWError,
        WindowsCreateSemaphoreWMacros,
        WindowsReleaseSemaphoreMacros,
        WindowsWaitForSingleObjectMacros;
import 'utils/late_property_assigned.dart' show LatePropertyAssigned;

class WindowsSemaphore<
/*  Identity */
    I extends SemaphoreIdentity,
/* Semaphore Identities */
    IS extends SemaphoreIdentities<I>,
/*Count Update*/
    CU extends SemaphoreCountUpdate,
/*Count Deletion*/
    CD extends SemaphoreCountDeletion,
/* Semaphore Count */
    CT extends SemaphoreCount<CU, CD>,
/* Semaphore Counts */
    CTS extends SemaphoreCounts<CU, CD, CT>,
/* Semaphore Counter */
    CTR extends SemaphoreCounter<I, CU, CD, CT, CTS>,
/* Semaphore Counter */
    CTRS extends SemaphoreCounters<I, CU, CD, CT, CTS, CTR>
/* formatting guard comment */
    > extends NativeSemaphore<I, IS, CU, CD, CT, CTS, CTR, CTRS> {
  late final LPCWSTR _identifier;

  ({bool isSet, LPCWSTR? get}) get identifier =>
      LatePropertyAssigned<Pointer<Char>>(() => _identifier)
          ? (isSet: true, get: _identifier)
          : (isSet: false, get: null);

  late final Pointer<NativeType> _semaphore;

  ({bool isSet, Pointer<NativeType>? get}) get semaphore =>
      LatePropertyAssigned<Pointer<NativeType>>(() => _semaphore)
          ? (isSet: true, get: _semaphore)
          : (isSet: false, get: null);

  WindowsSemaphore(
      {required super.name, required super.counter, super.verbose = false});

  @override
  bool willAttemptOpen() {
    if (verbose)
      print("Evaluating [willAttemptOpen()]: IDENTITY: ${identity.uuid}");
    // TODO other checks on the identifier string
    (name.length <= WindowsCreateSemaphoreWMacros.MAX_PATH) ||
        (throw ArgumentError(
            'Identifier is too long. Must be less than or equal to ${WindowsCreateSemaphoreWMacros.MAX_PATH} characters.'));

    identity.name == name ||
        (throw ArgumentError(
            'Identity name does not match the name provided to the semaphore.'));

    if (verbose) print("Proceeding to [open()] semaphore: ${name}");
    return true;
  }

  @override
  bool open() {
    if (!willAttemptOpen()) return false;

    if (!identifier.isSet) _identifier = ('Global\\${name}'.toNativeUtf16());

    if (verbose) print("Attempting to [open()] semaphore: ${name}");

    if (!semaphore.isSet)
      _semaphore = Pointer.fromAddress(CreateSemaphoreW(
          WindowsCreateSemaphoreWMacros.NULL.address,
          WindowsCreateSemaphoreWMacros.INITIAL_VALUE_RECOMMENDED,
          WindowsCreateSemaphoreWMacros.MAXIMUM_VALUE_RECOMMENDED,
          _identifier));

    if (verbose) print("Semaphore [open()] attempt response: ${semaphore}");
    if (verbose)
      print("Proceeding to [openAttemptSucceeded()] semaphore: ${name}");

    return openAttemptSucceeded();
  }

  @override
  bool openAttemptSucceeded() {
    if (_semaphore.address ==
        WindowsCreateSemaphoreWMacros.SEM_FAILED.address) {
      if (verbose)
        print(
            "Failed [openAttemptSucceeded()] windows semaphore: ${name} with error: ${WindowsCreateSemaphoreWError.fromErrorCode(_semaphore.address).toString()}");
      throw Exception(
          "CreateSemaphoreW in secondary isolate should have succeeded, got ${_semaphore.address}");
    }

    if (verbose)
      print(
          "Successfully [openAttemptSucceeded()] windows semaphore: ${name} at address: ${semaphore.get?.address}");

    return !LatePropertyAssigned<bool>(() => hasOpened)
        ? hasOpened = true
        : opened;
  }

  @override
  bool willAttemptLockAcrossProcesses() {
    if (verbose)
      print(
          "Evaluating [willAttemptLockAcrossProcesses()]: IDENTITY: ${identity.uuid}");

    if (opened == false) {
      if (verbose)
        print(
            "Failed [willAttemptLockAcrossProcesses()]: IDENTITY: ${identity.uuid} REASON: Cannot lock semaphore that has not been opened.");

      throw Exception(
          'Failed [willAttemptLockAcrossProcesses()]: IDENTITY: ${identity.uuid} REASON: Cannot lock semaphore that has not been opened.');
    }

    if (counter.counts.process.get() > 0) {
      if (verbose)
        print(
            "Failed [willAttemptLockAcrossProcesses()]: IDENTITY: ${identity.uuid} REASON: Current Process already locked semaphore.");
      return false;
    }

    if (verbose)
      print(
          "Proceeding [willAttemptLockAcrossProcesses()]: IDENTITY: ${identity.uuid}");

    return true;
  }

  @override
  bool lockAcrossProcesses({bool blocking = true, Duration? timeout}) {
    if (!willAttemptLockAcrossProcesses()) return false;

    if (verbose)
      print(
          "Attempting [lockAcrossProcesses()]: IDENTITY: ${identity.uuid} BLOCKING: $blocking");

    int attempt = blocking
        ? WaitForSingleObject(_semaphore.address,
            WindowsWaitForSingleObjectMacros.TIMEOUT_RECOMMENDED)
        : WaitForSingleObject(
            _semaphore.address, WindowsWaitForSingleObjectMacros.TIMEOUT_ZERO);

    if (verbose)
      print(
          "Attempted [lockAcrossProcesses()]: IDENTITY: ${identity.uuid} BLOCKING: $blocking ATTEMPT RESPONSE: $attempt");

    return lockAttemptAcrossProcessesSucceeded(attempt: attempt);
  }

  @override
  bool lockAttemptAcrossProcessesSucceeded({required int attempt}) {
    if (attempt == WindowsWaitForSingleObjectMacros.WAIT_OBJECT_0) {
      if (verbose)
        print(
            "Successful [lockAttemptAcrossProcessesSucceeded()] [WaitForSingleObject] Attempt: IDENTITY: ${identity.uuid} ATTEMPT RESULT: $attempt");
      counter.counts.process.increment();
      if (verbose)
        print(
            "Incremented [lockAttemptAcrossProcessesSucceeded()] Count: IDENTITY: ${identity.uuid} PROCESS COUNT: ${counter.counts.process.get()} ISOLATE COUNT: ${counter.counts.isolate.get()}");
      return true;
    }

    if (attempt == WindowsWaitForSingleObjectMacros.WAIT_ABANDONED && verbose)
      print(
          "Failed [lockAttemptAcrossProcessesSucceeded()] [WaitForSingleObject] Attempt was abandoned: IDENTITY: ${identity.uuid} ATTEMPT RESULT: $attempt");

    if (attempt == WindowsWaitForSingleObjectMacros.WAIT_TIMEOUT && verbose)
      print(
          "Failed [lockAttemptAcrossProcessesSucceeded()] [WaitForSingleObject] Attempt timed out: IDENTITY: ${identity.uuid} ATTEMPT RESULT: $attempt");

    if (attempt == WindowsWaitForSingleObjectMacros.WAIT_FAILED && verbose)
      print(
          "Failed [lockAttemptAcrossProcessesSucceeded()] [WaitForSingleObject] Attempt failed: IDENTITY: ${identity.uuid} ATTEMPT RESULT: $attempt");

    return false;
  }

  @override
  bool willAttemptLockReentrantToIsolate() {
    if (verbose)
      print(
          "Evaluating [willAttemptLockReentrantToIsolate()]: IDENTITY: ${identity.uuid}");

    counter.counts.process.get() > 0 ||
        (throw Exception(
            'Failed [willAttemptLockReentrantToIsolate()]: IDENTITY: ${identity.uuid} REASON: Cannot lock reentrant to isolate while outer process is unlocked locked.'));

    if (verbose)
      print(
          "Proceeding [willAttemptLockReentrantToIsolate()]: IDENTITY: ${identity.uuid}");

    return true;
  }

  @override
  bool lockReentrantToIsolate() {
    if (!willAttemptLockReentrantToIsolate()) return false;

    if (verbose)
      print(
          "Attempting [lockReentrantToIsolate()]: IDENTITY: ${identity.uuid}");

    // We aren't actually going to do anything here and proceed to increment in the _lockAttemptReentrantToIsolateSucceeded method
    return lockAttemptReentrantToIsolateSucceeded();
  }

  @override
  bool lockAttemptReentrantToIsolateSucceeded() {
    counter.counts.isolate.increment();

    if (verbose)
      print(
          "Incremented [lockAttemptReentrantToIsolateSucceeded()] Count: IDENTITY: ${identity.uuid} PROCESS COUNT: ${counter.counts.process.get()} ISOLATE COUNT: ${counter.counts.isolate.get()}");

    return true;
  }

  @override
  bool lock({bool blocking = true}) {
    if (verbose)
      print(
          "Attempting [lock()]: IDENTITY: ${identity.uuid} BLOCKING: $blocking");

    bool processes = lockAcrossProcesses(blocking: blocking);
    bool isolates = processes || lockReentrantToIsolate();

    return (locked == (processes || isolates)) ||
        (throw Exception(
            'Failed [lock()] IDENTITY: ${identity.uuid} REASON: Mismatched lock statuses. ISOLATES STATUS: $isolates PROCESSES STATUS: $processes LOCKED STATUS: $locked'));
  }

  @override
  bool willAttemptUnlockAcrossProcesses() {
    if (verbose)
      print(
          "Evaluating [willAttemptUnlockAcrossProcesses()]: IDENTITY: ${identity.uuid}");
    if (verbose)
      print(
          "Process Counts [willAttemptUnlockAcrossProcesses()]: ${counter.counts.process.get()} locked $locked Isolate Counts: ${counter.counts.isolate.get()}");

    if (locked && counter.counts.isolate.get() > 0) {
      if (verbose)
        print(
            "Failed [willAttemptUnlockAcrossProcesses()]: IDENTITY: ${identity.uuid} REASON: Semaphore already locked across processes");
      return false;
    }

    // TODO eventually consider globally tracked processes?

    if (verbose)
      print(
          "Proceeding to [unlock()] from [Will Attempt Unlock Across Process]: IDENTITY: ${identity.uuid}");
    return true;
  }

  @override
  bool unlockAttemptAcrossProcessesSucceeded({required int attempt}) {
    if (verbose)
      print(
          "Evaluating [unlockAttemptAcrossProcessesSucceeded()]: IDENTITY: ${identity.uuid}");

    if (attempt == 0) {
      if (verbose)
        // TODO utilize something like this in the future when this dart issue is resolved https://github.com/dart-lang/sdk/issues/38832
        // TODO ${WindowsReleaseSemaphoreError.fromErrorCode(GetLastError()).toString()}
        print(
            "Failed Evaluation [unlockAttemptAcrossProcessesSucceeded()]: IDENTITY: ${identity.uuid} ATTEMPT RESPONSE: $attempt ERROR: Unavailable('UNABLE TO RETRIEVE ERROR ON WINDOWS AT THIS TIME') ");
      return false;
    }

    if (verbose)
      print(
          "Successful Evaluation [unlockAttemptAcrossProcessesSucceeded()]: IDENTITY: ${identity.uuid} ATTEMPT RESPONSE: $attempt DETAILS: Blocked threads were waiting for the semaphore to become unlocked and one of them is now allowed to return from their sem_wait call.");

    // Decrement the semaphore count
    counter.counts.process.decrement();

    if (verbose)
      print(
          "Decremented [unlockAttemptAcrossProcessesSucceeded()] Count: IDENTITY: ${identity.uuid} PROCESS COUNT: ${counter.counts.process.get()} ISOLATE COUNT: ${counter.counts.isolate.get()}");
    return true;
  }

  @override
  bool unlockAcrossProcesses() {
    if (!willAttemptUnlockAcrossProcesses()) return false;

    if (verbose)
      print("Attempting [unlockAcrossProcesses()]: IDENTITY: ${identity.uuid}");

    //Returns a nonzero value if the function succeeds, or zero if the function fails.
    int attempt = ReleaseSemaphore(
        _semaphore.address,
        WindowsReleaseSemaphoreMacros.RELEASE_COUNT_RECOMMENDED,
        WindowsReleaseSemaphoreMacros.NULL);

    if (verbose)
      print(
          "Attempted [unlockAcrossProcesses()]: IDENTITY: ${identity.uuid} ATTEMPT RESPONSE: $attempt");

    return unlockAttemptAcrossProcessesSucceeded(attempt: attempt);
  }

  @override
  bool willAttemptUnlockReentrantToIsolate() {
    if (verbose)
      print(
          "Evaluating [willAttemptUnlockReentrantToIsolate()]: IDENTITY: ${identity.uuid} PROCESS COUNT: ${counter.counts.process.get()} ISOLATE COUNT: ${counter.counts.isolate.get()}");

    if (counter.counts.process.get() == 0) {
      if (verbose)
        print(
            "Failed [willAttemptUnlockReentrantToIsolate()]: IDENTITY: ${identity.uuid} REASON: Cannot reentrantly unlock semaphore that is not locked reentrant to isolates.");
      return false;
    }

    if (counter.counts.isolate.get() == 0 && counter.counts.process.get() > 0) {
      if (verbose)
        print(
            "Failed [willAttemptUnlockReentrantToIsolate()]: IDENTITY: ${identity.uuid} REASON: Cannot reentrantly unlock semaphore that is not locked reentrant to isolates.");
      return false;
    }

    if (verbose)
      print(
          "Proceeding to [unlockReentrantToIsolate()]: IDENTITY: ${identity.uuid}");
    return true;
  }

  @override
  bool unlockReentrantToIsolate() {
    if (!willAttemptUnlockReentrantToIsolate()) return false;

    if (verbose)
      print(
          "Attempting [unlockReentrantToIsolate()]: IDENTITY: ${identity.uuid}");

    // We will do nothing here and proceed to decrement in the _unlockAttemptReentrantToIsolateSucceeded method

    return unlockAttemptReentrantToIsolateSucceeded();
  }

  @override
  bool unlockAttemptReentrantToIsolateSucceeded() {
    counter.counts.isolate.decrement();

    if (verbose)
      print(
          "Decremented [unlockReentrantToIsolate()] Count: IDENTITY: ${identity.uuid}  PROCESS COUNT: ${counter.counts.process.get()} ISOLATE COUNT: ${counter.counts.isolate.get()}");

    return true;
  }

  @override
  bool unlock() {
    if (verbose)
      print(
          "Evaluating [unlock()]: IDENTITY: ${identity.uuid} LOCKED: $locked");
    return unlockReentrantToIsolate() || unlockAcrossProcesses();
  }

  @override
  bool willAttemptClose() {
    if (verbose)
      print("Evaluating [willAttemptClose()]: IDENTITY: ${identity.uuid}");

    if (locked) {
      if (verbose)
        print(
            "Failed [willAttemptClose()]: IDENTITY: ${identity.uuid} REASON: Cannot close while semaphore is locked reentrant to isolates or across the process.");

      return false;
    }

    if (verbose) print("Proceeding to [close()]: IDENTITY: ${identity.uuid}");

    return true;
  }

  @override
  bool closeAttemptSucceeded({required int attempt}) {
    if (verbose)
      print("Evaluating [closeAttemptSucceeded()]: IDENTITY: ${identity.uuid}");

    if (attempt == 0) {
      // TODO utilize something like this in the future when this dart issue is resolved https://github.com/dart-lang/sdk/issues/38832
      // TODO ${WindowsCloseHandleError.fromErrorCode(GetLastError()).toString()}
      if (verbose)
        print(
            "Failed Evaluation [closeAttemptSucceeded()]: IDENTITY: ${identity.uuid} REASON: Close attempt resulted in non 0 response: $attempt ERROR: Unavailable('UNABLE TO RETRIEVE ERROR ON WINDOWS') ");

      return false;
    } else {
      if (verbose)
        print(
            "Successful Evaluation [closeAttemptSucceeded()]: IDENTITY: ${identity.uuid}");
      return !LatePropertyAssigned<bool>(() => hasClosed)
          ? hasClosed = true
          : closed;
    }
  }

  // Closing has no reentrant effect
  @override
  bool close() {
    if (!willAttemptClose()) return false;

    if (verbose) print("Attempting [close()]: IDENTITY: ${identity.uuid}");

    // Returns a nonzero value if the function succeeds, or zero if the function fails.
    final int attempt = CloseHandle(_semaphore.address);

    if (verbose)
      print(
          "Attempted [close()]: IDENTITY: ${identity.uuid} ATTEMPT RESPONSE: $attempt");

    return closeAttemptSucceeded(attempt: attempt);
  }

  @override
  bool willAttemptUnlink() {
    if (verbose)
      print("Evaluating [willAttemptUnlink()]: IDENTITY: ${identity.uuid}");

    if (counter.counts.process.get() > 0) {
      if (verbose)
        print(
            "Failed [willAttemptUnlink()]: IDENTITY: ${identity.uuid} REASON: Cannot unlink while process semaphore is locked.");
      return false;
    }

    if (!closed) {
      if (verbose)
        print(
            "Failed [willAttemptUnlink()]: IDENTITY: ${identity.uuid} REASON: Cannot unlink before calling close() on the semaphore");
      return false;
    }

    if (verbose) print("Proceeding to [unlink()]: IDENTITY: ${identity.uuid}");
    return true;
  }

  @override
  bool unlinkAttemptSucceeded({int attempt = 0}) {
    if (verbose)
      print(
          "Evaluating [unlinkAttemptSucceeded()]: IDENTITY: ${identity.uuid} ATTEMPT RESPONSE: $attempt");

    // There is no 'unlink' equivalent on Windows
    if (attempt == 0) if (verbose)
      print(
          "Successful Evaluation [unlinkAttemptSucceeded()]: IDENTITY: ${identity.uuid}");

    malloc.free(_identifier);

    if (verbose)
      print(
          "Freed memory within [unlinkAttemptSucceeded()] allocated for semaphore: ${_identifier}");

    return hasUnlinked = true;
  }

  @override
  bool unlink() {
    if (!willAttemptUnlink()) return false;

    if (verbose) print("Attempting [unlink()]: IDENTITY: ${identity.uuid}");

    // There is no 'unlink' equivalent on Windows so this will always proceed to the success method

    if (verbose)
      print(
          "Attempted [unlink()]: IDENTITY: ${identity.uuid} ATTEMPT RESPONSE: $unlinked");

    return unlinkAttemptSucceeded();
  }

  @override
  String toString() => 'WindowsSemaphore(name: $name)';
}
