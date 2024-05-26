import 'dart:async' show Future, FutureOr;
import 'dart:ffi' show AbiSpecificIntegerPointer, Char, Pointer;

import 'package:ffi/ffi.dart' show StringUtf8Pointer, malloc;

import 'native_semaphore.dart' show NativeSemaphore;
import 'persisted_native_semaphore_metadata.dart' show PersistedNativeSemaphoreAccessor;
import 'persisted_native_semaphore_operation.dart' show NATIVE_SEMAPHORE_OPERATION, PersistedNativeSemaphoreOperation, PersistedNativeSemaphoreOperations;
import 'semaphore_counter.dart' show SemaphoreCount, SemaphoreCountDeletion, SemaphoreCountUpdate, SemaphoreCounter, SemaphoreCounters, SemaphoreCounts;
import 'semaphore_identity.dart' show SemaphoreIdentities, SemaphoreIdentity;
import 'ffi/unix.dart'
    show
        MODE_T_PERMISSIONS,
        UnixSemCloseError,
        UnixSemLimits,
        UnixSemOpenError,
        UnixSemOpenMacros,
        UnixSemUnlinkError,
        UnixSemUnlockWithPostError,
        errno,
        sem_close,
        sem_open,
        sem_post,
        sem_t,
        sem_trywait,
        sem_unlink,
        sem_wait;
import 'utils/late_property_assigned.dart' show LatePropertyAssigned;

class UnixSemaphore<
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
    CTRS extends SemaphoreCounters<I, CU, CD, CT, CTS, CTR>,
    /* Persisted Native Semaphore Operation */
    PNSO extends PersistedNativeSemaphoreOperation,
    /* Persisted Native Semaphore Operations */
    PNSOS extends PersistedNativeSemaphoreOperations<PNSO>,
    /* Persisted Native Semaphore Accessor */
    PNSA extends PersistedNativeSemaphoreAccessor
    /* formatting guard comment */
    > extends NativeSemaphore<I, IS, CU, CD, CT, CTS, CTR, CTRS, PNSO, PNSOS, PNSA> {
  late final Pointer<Char> _identifier;

  ({bool isSet, Pointer<Char>? get}) get identifier => LatePropertyAssigned<Pointer<Char>>(() => _identifier) ? (isSet: true, get: _identifier) : (isSet: false, get: null);

  late final Pointer<sem_t> _semaphore;

  ({bool isSet, Pointer<sem_t>? get}) get semaphore => LatePropertyAssigned<Pointer<sem_t>>(() => _semaphore) ? (isSet: true, get: _semaphore) : (isSet: false, get: null);

  UnixSemaphore({required CTR counter, verbose = false}) : super(counter: counter, verbose: verbose);

  @override
  bool willAttemptOpen() {

    if (verbose) print("Evaluating [willAttemptOpen()]: IDENTITY: ${identity.identifier}");
    // TODO other checks on the identifier string
    (identity.name.replaceFirst(('/'), '').length <= UnixSemLimits.NAME_MAX_CHARACTERS) ||
        (throw ArgumentError('Identifier is too long. Must be less than or equal to ${UnixSemLimits.NAME_MAX_CHARACTERS} characters.'));

    // TODO - create a temp file with identity && uuid with file io and update the status to opening and the time stamp

    persist(status: NATIVE_SEMAPHORE_OPERATION.willAttemptOpen) || (throw Exception('Failed to persist operation status to temp file.'));

    if (verbose) print("Proceeding to [open()] semaphore: ${identity.name}");
    logs.add('NOTIFICATION: Attempting to open semaphore with name: ${identity.name}');
    return true;
  }

  @override
  bool open() {
    if (!willAttemptOpen()) return false;

    if (!identifier.isSet) _identifier = ('/${identity.name.replaceFirst(('/'), '')}'.toNativeUtf8()).cast();

    if (verbose) print("Attempting to [open()] semaphore: ${identity.name}");

    if (!semaphore.isSet) _semaphore = sem_open(_identifier, UnixSemOpenMacros.O_CREAT, MODE_T_PERMISSIONS.RECOMMENDED, UnixSemOpenMacros.VALUE_RECOMMENDED);

    identity.address = _semaphore.address;

    persist(status: NATIVE_SEMAPHORE_OPERATION.open) || (throw Exception('Failed to persist operation status to temp file.'));

    // TODO - update the status within the temp file to opened and verified false the time stamp

    if (verbose) print("Semaphore [open()] attempt response: ${semaphore}");

    return openAttemptSucceeded();
  }

  @override
  bool openAttemptSucceeded() {
    (_semaphore.address != UnixSemOpenMacros.SEM_FAILED.address) || (throw "${UnixSemOpenError.fromErrno(errno.value).toString()}");

    if (verbose) print("Successfully [openAttemptSucceeded()] unix semaphore: ${identity.name} at address: ${semaphore.get?.address}");

    // TODO - update the status within the temp file to opened and verified true the time stamp

    LatePropertyAssigned<bool>(() => hasOpened)  || (hasOpened = true);

    persist(status: NATIVE_SEMAPHORE_OPERATION.openAttemptSucceeded) || (throw Exception('Failed to persist operation status to temp file.'));


    return opened;
  }

  @override
  bool willAttemptLockAcrossProcesses() {
    if (verbose) print("Evaluating [willAttemptLockAcrossProcesses()]: IDENTITY: ${identity.identifier}");

    if (opened == false) {
      if (verbose) print("Failed [willAttemptLockAcrossProcesses()]: IDENTITY: ${identity.identifier} REASON: Cannot lock semaphore that has not been opened.");

      throw Exception('Failed [willAttemptLockAcrossProcesses()]: IDENTITY: ${identity.identifier} REASON: Cannot lock semaphore that has not been opened.');
    }

    if (counter.counts.process.get() > 0) {
      if (verbose) print("Failed [willAttemptLockAcrossProcesses()]: IDENTITY: ${identity.identifier} REASON: Current Process already locked semaphore.");
      return false;
    }

    if (verbose) print("Proceeding [lockAcrossProcesses()]: IDENTITY: ${identity.identifier}");

    persist(status: NATIVE_SEMAPHORE_OPERATION.willAttemptLockAcrossProcesses, sync: true) || (throw Exception('Failed to persist operation status to temp file.'));

    return true;
  }

  @override
  bool lockAcrossProcesses({bool blocking = true, Duration? timeout}) {
    waiting = blocking;
    if (!willAttemptLockAcrossProcesses()) return false;

    if (verbose) print("Attempting [lockAcrossProcesses()]: IDENTITY: ${identity.identifier} BLOCKING: $blocking");

    int attempt = sem_trywait(_semaphore);

    persist(status: NATIVE_SEMAPHORE_OPERATION.willAttemptLockAcrossProcesses, sync: true) || (throw Exception('Failed to persist operation status to temp file.'));

    if(blocking && !attempt.isEven) {
      attempt = sem_wait(_semaphore);
    }

    waiting = false;

    if (verbose) print("Attempted [lockAcrossProcesses()]: IDENTITY: ${identity.identifier} BLOCKING: $blocking ATTEMPT RESPONSE: $attempt");

    persist(status: NATIVE_SEMAPHORE_OPERATION.lockAcrossProcesses, sync: true) || (throw Exception('Failed to persist operation status to temp file.'));

    return lockAttemptAcrossProcessesSucceeded(attempt: attempt);
  }

  @override
  bool lockAttemptAcrossProcessesSucceeded({required int attempt}) {
    if (attempt.isEven) {
      counter.counts.process.increment();

      if (verbose)
        print(
            "Incremented [lockAttemptAcrossProcessesSucceeded()] Count: IDENTITY: ${identity.identifier} PROCESS COUNT: ${counter.counts.process.get()} ISOLATE COUNT: ${counter.counts.isolate.get()}");

      persist(status: NATIVE_SEMAPHORE_OPERATION.lockAttemptAcrossProcessesSucceeded, sync: true) || (throw Exception('Failed to persist operation status to temp file.'));
      return true;
    }

    if (verbose) print("Failed [lockAttemptAcrossProcessesSucceeded()] [sem_wait] Semaphore resulted in non 0 response: IDENTITY: ${identity.identifier} ATTEMPT RESULT: $attempt");
    return false;
  }

  @override
  bool willAttemptLockReentrantToIsolate() {
    if (verbose) print("Evaluating [willAttemptLockReentrantToIsolate()]: IDENTITY: ${identity.identifier}");

    counter.counts.process.get() > 0 ||
        (throw Exception(
            'Failed [willAttemptLockReentrantToIsolate()]: IDENTITY: ${identity.identifier} REASON: Cannot lock reentrant to isolate while outer process is unlocked locked.'));

    if (verbose) print("Proceeding [lockReentrantToIsolate()]: IDENTITY: ${identity.identifier}");

    persist(status: NATIVE_SEMAPHORE_OPERATION.willAttemptLockReentrantToIsolate) || (throw Exception('Failed to persist operation status to temp file.'));

    return true;
  }

  @override
  bool lockReentrantToIsolate() {
    if (!willAttemptLockReentrantToIsolate()) return false;

    if (verbose) print("Attempting [lockReentrantToIsolate()]: IDENTITY: ${identity.identifier}");

    persist(status: NATIVE_SEMAPHORE_OPERATION.lockReentrantToIsolate) || (throw Exception('Failed to persist operation status to temp file.'));

    // We aren't actually going to do anything here and proceed to increment in the _lockAttemptReentrantToIsolateSucceeded method
    return lockAttemptReentrantToIsolateSucceeded();
  }

  @override
  bool lockAttemptReentrantToIsolateSucceeded() {
    counter.counts.isolate.increment();

    if (verbose)
      print(
          "Incremented [lockAttemptReentrantToIsolateSucceeded()] Count: IDENTITY: ${identity.identifier} PROCESS COUNT: ${counter.counts.process.get()} ISOLATE COUNT: ${counter.counts.isolate.get()}");

    persist(status: NATIVE_SEMAPHORE_OPERATION.lockAttemptReentrantToIsolateSucceeded) || (throw Exception('Failed to persist operation status to temp file.'));

    return true;
  }

  // TODO Remove
  Future<bool> lockWithDelay({bool blocking = true, Duration? delay, FutureOr Function()? before, FutureOr Function()? after}) async {
    delay ??= Duration(seconds: 0);
    logs.add('NOTIFICATION: Locking semaphore with name ${identity.name} is delayed by: [${delay.inSeconds}] seconds');
    await Future.delayed(delay);
    logs.add('NOTIFICATION: Attempting to lock semaphore with name ${identity.name} and tracer ${identity.tracer}');
    before != null ? await before.call() : null;


    Stopwatch stopwatch = Stopwatch()..start();
    bool locked = lock(blocking: blocking);
    stopwatch.stop();
    logs.add('NOTIFICATION: Locking semaphore with name ${identity.name} took: [${stopwatch.elapsed.inSeconds}] seconds');
    after != null ? await after.call() : null;
    return locked;
  }

  @override
  // TODO handle other cases i.e. EINTR, EAGAIN, EDEADLK etc.
  bool lock({bool blocking = true}) {

    if (verbose) print("Attempting [lock()]: IDENTITY: ${identity.identifier} BLOCKING: $blocking");

    bool processes = lockAcrossProcesses(blocking: blocking);
    bool isolates = processes || lockReentrantToIsolate();

    return (locked == (processes || isolates)) ||
        (throw Exception(
            'Failed [lock()] IDENTITY: ${identity.identifier} REASON: Mismatched lock statuses. ISOLATES STATUS: $isolates PROCESSES STATUS: $processes LOCKED STATUS: $locked'));
  }

  @override
  bool willAttemptUnlockAcrossProcesses() {
    if (verbose) print("Evaluating [willAttemptUnlockAcrossProcesses()]: IDENTITY: ${identity.identifier}");
    if (verbose) print("Process Counts [willAttemptUnlockAcrossProcesses()]: ${counter.counts.process.get()} locked $locked Isolate Counts: ${counter.counts.isolate.get()}");

    if (locked && counter.counts.isolate.get() > 0) {
      if (verbose) print("Failed [willAttemptUnlockAcrossProcesses()]: IDENTITY: ${identity.identifier} REASON: Semaphore already locked across processes");
      return false;
    }

    // TODO eventually consider globally tracked processes?

    if (verbose) print("Proceeding to [unlock()] from [willAttemptUnlockAcrossProcesses()]: IDENTITY: ${identity.identifier}");

    persist(status: NATIVE_SEMAPHORE_OPERATION.willAttemptUnlockAcrossProcesses, sync: true) || (throw Exception('Failed to persist operation status to temp file.'));

    return true;
  }

  @override
  bool unlockAttemptAcrossProcessesSucceeded({required int attempt}) {
    if (verbose) print("Evaluating [unlockAttemptAcrossProcessesSucceeded()]: IDENTITY: ${identity.identifier}");

    if (attempt == -1) {
      UnixSemUnlockWithPostError error = UnixSemUnlockWithPostError.fromErrno(errno.value);

      if (verbose) print("Failed Evaluation [unlockAttemptAcrossProcessesSucceeded()]: IDENTITY: ${identity.identifier} ATTEMPT RESPONSE: $attempt ERROR: ${error.toString()}");
      return false;
    }

    if (attempt == 0) {
      if (verbose)
        print(
            "Successful Evaluation [unlockAttemptAcrossProcessesSucceeded()]: IDENTITY: ${identity.identifier} ATTEMPT RESPONSE: $attempt DETAILS: Blocked threads were waiting for the semaphore to become unlocked and one of them is now allowed to return from their sem_wait call.");
      // Decrement the semaphore count
      counter.counts.process.decrement();

      if (verbose)
        print(
            "Decremented [unlockAttemptAcrossProcessesSucceeded()] Count: IDENTITY: ${identity.identifier} PROCESS COUNT: ${counter.counts.process.get()} ISOLATE COUNT: ${counter.counts.isolate.get()}");

      LatePropertyAssigned<bool>(() => hasUnlocked) || (hasUnlocked = true);

      persist(status: NATIVE_SEMAPHORE_OPERATION.unlockAttemptAcrossProcessesSucceeded, sync: true) || (throw Exception('Failed to persist operation status to temp file.'));

    }

    return unlocked || reentrant;
  }

  @override
  bool unlockAcrossProcesses() {
    if (!willAttemptUnlockAcrossProcesses()) return false;

    if (verbose) print("Attempting [unlockAcrossProcesses()]: IDENTITY: ${identity.identifier}");

    int attempt = sem_post(_semaphore);

    if (verbose) print("Attempted [unlockAcrossProcesses()]: IDENTITY: ${identity.identifier} ATTEMPT RESPONSE: $attempt");

    persist(status: NATIVE_SEMAPHORE_OPERATION.unlockAcrossProcesses) || (throw Exception('Failed to persist operation status to temp file.'));

    return unlockAttemptAcrossProcessesSucceeded(attempt: attempt);
  }

  @override
  bool willAttemptUnlockReentrantToIsolate() {
    if (verbose)
      print(
          "Evaluating [willAttemptUnlockReentrantToIsolate()]: IDENTITY: ${identity.identifier} PROCESS COUNT: ${counter.counts.process.get()} ISOLATE COUNT: ${counter.counts.isolate.get()}");

    if (counter.counts.process.get() == 0) {
      if (verbose)
        print(
            "Failed [willAttemptUnlockReentrantToIsolate()]: IDENTITY: ${identity.identifier} REASON: Cannot reentrantly unlock semaphore that is not locked reentrant to isolates.");
      return false;
    }

    if (counter.counts.isolate.get() == 0 && counter.counts.process.get() > 0) {
      if (verbose)
        print(
            "Failed [willAttemptUnlockReentrantToIsolate()]: IDENTITY: ${identity.identifier} REASON: Cannot reentrantly unlock semaphore that is not locked reentrant to isolates.");
      return false;
    }

    if (verbose) print("Proceeding to [unlockReentrantToIsolate()]: IDENTITY: ${identity.identifier}");

    persist(status: NATIVE_SEMAPHORE_OPERATION.willAttemptUnlockReentrantToIsolate) || (throw Exception('Failed to persist operation status to temp file.'));

    return true;
  }

  @override
  bool unlockReentrantToIsolate() {
    if (!willAttemptUnlockReentrantToIsolate()) return false;

    if (verbose) print("Attempting [Unlock Reentrant To Isolate]: IDENTITY: ${identity.identifier}");

    persist(status: NATIVE_SEMAPHORE_OPERATION.unlockReentrantToIsolate) || (throw Exception('Failed to persist operation status to temp file.'));
    // We will do nothing here and proceed to decrement in the _unlockAttemptReentrantToIsolateSucceeded method

    return unlockAttemptReentrantToIsolateSucceeded();
  }

  @override
  bool unlockAttemptReentrantToIsolateSucceeded() {
    counter.counts.isolate.decrement();

    if (verbose)
      print(
          "Decremented [Unlock Reentrant To Isolate] Count: IDENTITY: ${identity.identifier}  PROCESS COUNT: ${counter.counts.process.get()} ISOLATE COUNT: ${counter.counts.isolate.get()}");

    persist(status: NATIVE_SEMAPHORE_OPERATION.unlockAttemptReentrantToIsolateSucceeded) || (throw Exception('Failed to persist operation status to temp file.'));
    return true;
  }

  Future<bool> unlockWithDelay({Duration? delay, FutureOr Function()? before, FutureOr Function()? after}) async {
    delay ??= Duration(seconds: 0);
    logs.add('NOTIFICATION: Unlocking semaphore with name ${identity.name} is delayed by: [${delay.inSeconds}] seconds');
    before != null ? await before.call() : null;
    await Future.delayed(delay);
    bool returnable = unlock();
    logs.add('NOTIFICATION: Semaphore unlocked with name: ${identity.name}');
    after != null ? await after.call() : null;
    return returnable;
  }

  @override
  bool unlock() {
    if (verbose) print("Evaluating [Unlock]: IDENTITY: ${identity.identifier} LOCKED: $locked");
    return unlockReentrantToIsolate() || unlockAcrossProcesses();
  }

  @override
  bool willAttemptClose() {
    if (verbose) print("Evaluating [willAttemptClose()]: IDENTITY: ${identity.identifier}");

    if (locked) {
      if (verbose) print("Failed [willAttemptClose()]: IDENTITY: ${identity.identifier} REASON: Cannot close while semaphore is locked reentrant to isolates or across the process.");
      return false;
    }

    if (verbose) print("Proceeding to [close()]: IDENTITY: ${identity.identifier}");

    persist(status: NATIVE_SEMAPHORE_OPERATION.willAttemptClose, sync: true) || (throw Exception('Failed to persist operation status to temp file.'));
    return true;
  }

  @override
  bool closeAttemptSucceeded({required int attempt}) {
    if (verbose) print("Evaluating [Close Attempt Succeeded]: IDENTITY: ${identity.identifier}");

    if (attempt == 0) {
      if (verbose) print("Successful Evaluation [Close Attempt Succeeded]: IDENTITY: ${identity.identifier}");

      LatePropertyAssigned<bool>(() => hasClosed) || (hasClosed = true);

      persist(status: NATIVE_SEMAPHORE_OPERATION.closeAttemptSucceeded, sync: true) || (throw Exception('Failed to persist operation status to temp file.'));
      return closed;
    }

    UnixSemCloseError error = UnixSemCloseError.fromErrno(errno.value);
    if (verbose)
      print("Failed Evaluation [Close Attempt Succeeded]: IDENTITY: ${identity.identifier} REASON: Close attempt resulted in non 0 response: $attempt ERROR: ${error.toString()}");

    return false;
  }

  // Closing has no reentrant effect
  @override
  bool close() {
    if (!willAttemptClose()) return false;

    if (verbose) print("Attempting [Close]: IDENTITY: ${identity.identifier}");

    final int attempt = sem_close(_semaphore);

    if (verbose) print("Attempted [Close]: IDENTITY: ${identity.identifier} ATTEMPT RESPONSE: $attempt");

    persist(status: NATIVE_SEMAPHORE_OPERATION.close) || (throw Exception('Failed to persist operation status to temp file.'));

    return closeAttemptSucceeded(attempt: attempt);
  }

  // TODO prevent calling unlink on a semaphore that is not closed
  @override
  bool willAttemptUnlink() {
    if (verbose) print("Evaluating [willAttemptUnlink()]: IDENTITY: ${identity.identifier}");

    if (counter.counts.process.get() > 0) {
      if (verbose) print("Failed [willAttemptUnlink()]: IDENTITY: ${identity.identifier} REASON: Cannot unlink while process semaphore is locked.");
      return false;
    }

    if (!closed) {
      if (verbose) print("Failed [willAttemptUnlink()]: IDENTITY: ${identity.identifier} REASON: Cannot unlink before calling close() on the semaphore");
      return false;
    }

    if (verbose) print("Proceeding to [unlink()]: IDENTITY: ${identity.identifier}");

    persist(status: NATIVE_SEMAPHORE_OPERATION.willAttemptUnlink, sync: true) || (throw Exception('Failed to persist operation status to temp file.'));

    return true;
  }

  @override
  bool unlinkAttemptSucceeded({required int attempt}) {
    if (verbose) print("Evaluating [unlinkAttemptSucceeded()]: IDENTITY: ${identity.identifier} ATTEMPT RESPONSE: $attempt");

    UnixSemUnlinkError? error;

    if (attempt.isOdd && attempt.isNegative) {
      error = UnixSemUnlinkError.fromErrno(errno.value);

      if (error.critical) {
        if (verbose)
          print(
              "Non-Zero Evaluation of [unlinkAttemptSucceeded()]: IDENTITY: ${identity.identifier} REASON: Unlink attempt resulted in non 0 response: $attempt ERROR: ${error.toString()}");
        return false;
      }
    }

    // If it is odd and negative i.e. -1 unlink has already been called and succeded
    if (attempt == 0) if (verbose) print("Successful Evaluation [unlinkAttemptSucceeded()]: IDENTITY: ${identity.identifier}");

    if (error is UnixSemUnlinkError && !error.critical) if (verbose)
      print("Non-Critical Error in Evaluation [unlinkAttemptSucceeded()]: IDENTITY: ${identity.identifier} ERROR: ${error.toString()}");

    malloc.free(_identifier);

    if (verbose) print("Freed memory within [unlinkAttemptSucceeded()] allocated for semaphore: ${_identifier}");

    LatePropertyAssigned<bool>(() => hasUnlinked) || (hasUnlinked = true);

    persist(status: NATIVE_SEMAPHORE_OPERATION.unlinkAttemptSucceeded, sync: true) || (throw Exception('Failed to persist operation status to temp file.'));

    logs.close();

    return unlinked;
  }

  @override
  bool unlink() {
    if (!willAttemptUnlink()) return false;

    if (verbose) print("Attempting [unlink()]: IDENTITY: ${identity.identifier}");

    final int unlinked = sem_unlink(_identifier);

    if (verbose) print("Attempted [unlink()]: IDENTITY: ${identity.identifier} ATTEMPT RESPONSE: $unlinked");

    persist(status: NATIVE_SEMAPHORE_OPERATION.unlink) || (throw Exception('Failed to persist operation status to temp file.'));

    return unlinkAttemptSucceeded(attempt: unlinked);
  }

  @override
  String toString() => 'UnixSemaphore()';
}
