import 'dart:async' show Future, FutureOr;
import 'dart:ffi' show AbiSpecificIntegerPointer, Char, Pointer;

import 'package:ffi/ffi.dart' show StringUtf8Pointer, malloc;

import 'native_semaphore.dart' show NativeSemaphore, NativeSemaphoreProcessOperationStatus, NativeSemaphoreProcessOperationStatusState, NativeSemaphoreProcessOperationStatuses;
import 'persisted_native_semaphore_metadata.dart' show PersistedNativeSemaphoreAccessor, PersistedNativeSemaphoreMetadata;
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
        I extends SemaphoreIdentity,
        IS extends SemaphoreIdentities<I>,
        CU extends SemaphoreCountUpdate,
        CD extends SemaphoreCountDeletion,
        CT extends SemaphoreCount<CU, CD>,
        CTS extends SemaphoreCounts<CU, CD, CT>,
        CTR extends SemaphoreCounter<I, CU, CD, CT, CTS>,
        CTRS extends SemaphoreCounters<I, CU, CD, CT, CTS, CTR>,
        PNSO extends PersistedNativeSemaphoreOperation,
        PNSOS extends PersistedNativeSemaphoreOperations<PNSO>,
        PNSA extends PersistedNativeSemaphoreAccessor,
        PNSM extends PersistedNativeSemaphoreMetadata<PNSA>,
        NSPOSS extends NativeSemaphoreProcessOperationStatusState,
        NSPOS extends NativeSemaphoreProcessOperationStatus<I, NSPOSS>,
        NSPOSES extends NativeSemaphoreProcessOperationStatuses<I, NSPOSS, NSPOS>>
    extends NativeSemaphore<I, IS, CU, CD, CT, CTS, CTR, CTRS, PNSO, PNSOS, PNSA, NSPOSS, NSPOS, NSPOSES> {
  late final Pointer<Char> _identifier;

  ({bool isSet, Pointer<Char>? get}) get identifier => LatePropertyAssigned<Pointer<Char>>(() => _identifier) ? (isSet: true, get: _identifier) : (isSet: false, get: null);

  late final Pointer<sem_t> _semaphore;

  ({bool isSet, Pointer<sem_t>? get}) get semaphore => LatePropertyAssigned<Pointer<sem_t>>(() => _semaphore) ? (isSet: true, get: _semaphore) : (isSet: false, get: null);

  UnixSemaphore({required CTR counter, verbose = false}) : super(counter: counter, verbose: verbose);

  @override
  bool willAttemptOpen() {
    // TODO other checks on the identifier string
    (identity.name.replaceFirst(('/'), '').length <= UnixSemLimits.NAME_MAX_CHARACTERS) ||
        (throw ArgumentError('Identifier is too long. Must be less than or equal to ${UnixSemLimits.NAME_MAX_CHARACTERS} characters.'));

    persist(status: NATIVE_SEMAPHORE_OPERATION.willAttemptOpen) || (throw Exception('Failed to persist operation status to temp file.'));

    logs.add('NOTIFICATION: Attempting to open semaphore with name: ${identity.name}');

    bool value = true;
    statuses.synchronize(operation: NATIVE_SEMAPHORE_OPERATION.willAttemptOpen, value: value, verification: (status: statuses.open, expected_operation: NATIVE_SEMAPHORE_OPERATION.willAttemptOpen, expected_value: value));
    return value;
  }

  @override
  bool open() {
    if(opened) {
      print("${identity.tracer} already opened and is reentrant $reentrant");
    }

    // if(opened || reentrant) return opened;

    if (!willAttemptOpen()) return false;

    if (!identifier.isSet) _identifier = ('/${identity.name.replaceFirst(('/'), '')}'.toNativeUtf8()).cast();

    persist(status: NATIVE_SEMAPHORE_OPERATION.attemptingOpen) || (throw Exception('Failed to persist operation status to temp file.'));

    bool value = true;
    // statuses.synchronize(operation: NATIVE_SEMAPHORE_OPERATION.attemptingOpen, value: value, verification: (status: statuses.open, expected_operation: NATIVE_SEMAPHORE_OPERATION.attemptingOpen, expected_value: value));

    if (!semaphore.isSet) _semaphore = sem_open(_identifier, UnixSemOpenMacros.O_CREAT, MODE_T_PERMISSIONS.RECOMMENDED, UnixSemOpenMacros.VALUE_RECOMMENDED);

    identity.address = _semaphore.address;

    persist(status: NATIVE_SEMAPHORE_OPERATION.open) || (throw Exception('Failed to persist operation status to temp file.'));
    // persist(status: NATIVE_SEMAPHORE_OPERATION.attemptedOpen) || (throw Exception('Failed to persist operation status to temp file.'));
    // TODO potentially pass through the semaphore address to the status object
    statuses.synchronize(operation: NATIVE_SEMAPHORE_OPERATION.attemptedOpen, value: value = _semaphore.address != UnixSemOpenMacros.SEM_FAILED.address, verification: (status: statuses.open, expected_operation: NATIVE_SEMAPHORE_OPERATION.attemptedOpen, expected_value: value));
    return openAttemptSucceeded();

  }

  @override
  bool openAttemptSucceeded() {
    (_semaphore.address != UnixSemOpenMacros.SEM_FAILED.address) || (throw "${UnixSemOpenError.fromErrno(errno.value).toString()}");


    // TODO - update the status within the temp file to opened and verified true the time stamp
    LatePropertyAssigned<bool>(() => hasOpened) || (hasOpened = true);

    persist(status: NATIVE_SEMAPHORE_OPERATION.openAttemptSucceeded) || (throw Exception('Failed to persist operation status to temp file.'));

    statuses.synchronize(operation: NATIVE_SEMAPHORE_OPERATION.openAttemptSucceeded, value: opened, verification: (status: statuses.open, expected_operation: NATIVE_SEMAPHORE_OPERATION.openAttemptSucceeded, expected_value: opened));
    return opened;
  }

  @override
  bool willAttemptLockAcrossProcesses() {
    if (opened == false) throw Exception('Failed [willAttemptLockAcrossProcesses()]: IDENTITY: ${identity.identifier} REASON: Cannot lock semaphore that has not been opened.');

    if (counter.counts.process.get() > 0) {
      bool value = false;
      statuses.synchronize(operation: NATIVE_SEMAPHORE_OPERATION.willAttemptLockAcrossProcesses, value: value, verification: (status: statuses.lock, expected_operation: NATIVE_SEMAPHORE_OPERATION.willAttemptLockAcrossProcesses, expected_value: value));
      return value;
    }

    bool value = true;

    persist(status: NATIVE_SEMAPHORE_OPERATION.willAttemptLockAcrossProcesses, sync: true) || (throw Exception('Failed to persist operation status to temp file.'));
    statuses.synchronize(operation: NATIVE_SEMAPHORE_OPERATION.willAttemptLockAcrossProcesses, value: value, verification: (status: statuses.lock, expected_operation: NATIVE_SEMAPHORE_OPERATION.willAttemptLockAcrossProcesses, expected_value: value));
    return value;
  }

  @override
  bool lockAcrossProcesses({bool blocking = true, Duration? timeout}) {
    waiting = blocking;
    if (!willAttemptLockAcrossProcesses()) return false;

    int attempt = sem_trywait(_semaphore);

    // TODO deprecate will attempt
    persist(status: NATIVE_SEMAPHORE_OPERATION.willAttemptLockAcrossProcesses, sync: true) || (throw Exception('Failed to persist operation status to temp file.'));

    bool value = attempt.isEven;
    // persist(status: NATIVE_SEMAPHORE_OPERATION.attemptingLockAcrossProcesses, sync: true) || (throw Exception('Failed to persist operation status to temp file.'));
    statuses.synchronize(operation: NATIVE_SEMAPHORE_OPERATION.attemptingLockAcrossProcesses, value: value, verification: (status: statuses.lock, expected_operation: NATIVE_SEMAPHORE_OPERATION.attemptingLockAcrossProcesses, expected_value: value));

    if (blocking && !attempt.isEven) attempt = sem_wait(_semaphore);

    waiting = false;

    // TODO deprecate lockAcrossProcesses
    persist(status: NATIVE_SEMAPHORE_OPERATION.lockAcrossProcesses, sync: true) || (throw Exception('Failed to persist operation status to temp file.'));

    // persist(status: NATIVE_SEMAPHORE_OPERATION.attemptedLockAcrossProcesses, sync: true) || (throw Exception('Failed to persist operation status to temp file.'));
    statuses.synchronize(operation: NATIVE_SEMAPHORE_OPERATION.attemptedLockAcrossProcesses, value: value = attempt.isEven, verification: (status: statuses.lock, expected_operation: NATIVE_SEMAPHORE_OPERATION.attemptedLockAcrossProcesses, expected_value: value));

    return lockAttemptAcrossProcessesSucceeded(attempt: attempt);
  }

  @override
  bool lockAttemptAcrossProcessesSucceeded({required int attempt}) {
    if (attempt.isEven) {
      bool value = true;
      counter.counts.process.increment();

      persist(status: NATIVE_SEMAPHORE_OPERATION.lockAttemptAcrossProcessesSucceeded, sync: true) || (throw Exception('Failed to persist operation status to temp file.'));
      statuses.synchronize(operation: NATIVE_SEMAPHORE_OPERATION.lockAttemptAcrossProcessesSucceeded, value: value, verification: (status: statuses.lock, expected_operation: NATIVE_SEMAPHORE_OPERATION.lockAttemptAcrossProcessesSucceeded, expected_value: value));
      return value;
    }

    bool value = false;
    statuses.synchronize(operation: NATIVE_SEMAPHORE_OPERATION.lockAttemptAcrossProcessesSucceeded, value: value, verification: (status: statuses.lock, expected_operation: NATIVE_SEMAPHORE_OPERATION.lockAttemptAcrossProcessesSucceeded, expected_value: value));
    return value;
  }

  @override
  bool willAttemptLockReentrantToIsolate() {
    counter.counts.process.get() > 0 ||
        (throw Exception(
            'Failed [willAttemptLockReentrantToIsolate()]: IDENTITY: ${identity.identifier} REASON: Cannot lock reentrant to isolate while outer process is unlocked locked.'));

    persist(status: NATIVE_SEMAPHORE_OPERATION.willAttemptLockReentrantToIsolate) || (throw Exception('Failed to persist operation status to temp file.'));
    // TODO synchronize the statuses
    return true;
  }

  @override
  bool lockReentrantToIsolate() {
    if (!willAttemptLockReentrantToIsolate()) return false;

    persist(status: NATIVE_SEMAPHORE_OPERATION.lockReentrantToIsolate) || (throw Exception('Failed to persist operation status to temp file.'));

    // We aren't actually going to do anything here and proceed to increment in the _lockAttemptReentrantToIsolateSucceeded method
    return lockAttemptReentrantToIsolateSucceeded();
  }

  @override
  bool lockAttemptReentrantToIsolateSucceeded() {
    counter.counts.isolate.increment();

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
    if(locked) {
      print("${identity.tracer} already locked and is reentrant $reentrant");
    }
    bool processes = lockAcrossProcesses(blocking: blocking);
    bool isolates = processes || lockReentrantToIsolate();

    return (locked == (processes || isolates)) ||
        (throw Exception(
            'Failed [lock()] IDENTITY: ${identity.identifier} REASON: Mismatched lock statuses. ISOLATES STATUS: $isolates PROCESSES STATUS: $processes LOCKED STATUS: $locked'));
  }

  @override
  bool willAttemptUnlockAcrossProcesses() {
    if (locked && counter.counts.isolate.get() > 0) {
      bool value = false;
      statuses.synchronize(operation: NATIVE_SEMAPHORE_OPERATION.willAttemptUnlockAcrossProcesses, value: value, verification: (status: statuses.unlock, expected_operation: NATIVE_SEMAPHORE_OPERATION.willAttemptUnlockAcrossProcesses, expected_value: value));
      return value;
    }

    bool value = true;
    persist(status: NATIVE_SEMAPHORE_OPERATION.willAttemptUnlockAcrossProcesses, sync: true) || (throw Exception('Failed to persist operation status to temp file.'));
    statuses.synchronize(operation: NATIVE_SEMAPHORE_OPERATION.willAttemptUnlockAcrossProcesses, value: value, verification: (status: statuses.unlock, expected_operation: NATIVE_SEMAPHORE_OPERATION.willAttemptUnlockAcrossProcesses, expected_value: value));
    return value;
  }

  @override
  bool unlockAttemptAcrossProcessesSucceeded({required int attempt}) {
    if (attempt == -1) {
      bool value = false;
      UnixSemUnlockWithPostError error = UnixSemUnlockWithPostError.fromErrno(errno.value);
      statuses.synchronize(operation: NATIVE_SEMAPHORE_OPERATION.unlockAttemptAcrossProcessesSucceeded, value: value, verification: (status: statuses.unlock, expected_operation: NATIVE_SEMAPHORE_OPERATION.unlockAttemptAcrossProcessesSucceeded, expected_value: value));
      return value;
    }

    if (attempt == 0) {
      bool value = true;
      // Decrement the semaphore count
      counter.counts.process.decrement();
      LatePropertyAssigned<bool>(() => hasUnlocked) || (hasUnlocked = true);

      persist(status: NATIVE_SEMAPHORE_OPERATION.unlockAttemptAcrossProcessesSucceeded, sync: true) || (throw Exception('Failed to persist operation status to temp file.'));
      statuses.synchronize(operation: NATIVE_SEMAPHORE_OPERATION.unlockAttemptAcrossProcessesSucceeded, value: value = unlocked, verification: (status: statuses.unlock, expected_operation: NATIVE_SEMAPHORE_OPERATION.unlockAttemptAcrossProcessesSucceeded, expected_value: value));
      return value;
    }

    // TODO potentially synchronize?
    return unlocked || reentrant;
  }

  @override
  bool unlockAcrossProcesses() {
    if (!willAttemptUnlockAcrossProcesses()) return false;

    bool value = true;
    // persist(status: NATIVE_SEMAPHORE_OPERATION.attemptingUnlockAcrossProcesses) || (throw Exception('Failed to persist operation status to temp file.'));
    statuses.synchronize(operation: NATIVE_SEMAPHORE_OPERATION.attemptingUnlockAcrossProcesses, value: value, verification: (status: statuses.unlock, expected_operation: NATIVE_SEMAPHORE_OPERATION.attemptingUnlockAcrossProcesses, expected_value: value));

    int attempt = sem_post(_semaphore);

    persist(status: NATIVE_SEMAPHORE_OPERATION.unlockAcrossProcesses) || (throw Exception('Failed to persist operation status to temp file.'));

    value = attempt == -1
        ? false
        : attempt == 0
            ? true
            : (unlocked || reentrant);

    // persist(status: NATIVE_SEMAPHORE_OPERATION.attemptedUnlockAcrossProcesses) || (throw Exception('Failed to persist operation status to temp file.'));
    statuses.synchronize(operation: NATIVE_SEMAPHORE_OPERATION.attemptedUnlockAcrossProcesses, value: value, verification: (status: statuses.unlock, expected_operation: NATIVE_SEMAPHORE_OPERATION.attemptedUnlockAcrossProcesses, expected_value: value));

    return unlockAttemptAcrossProcessesSucceeded(attempt: attempt);
  }

  @override
  bool willAttemptUnlockReentrantToIsolate() {
    if (counter.counts.process.get() == 0) return false;

    if (counter.counts.isolate.get() == 0 && counter.counts.process.get() > 0) return false;

    persist(status: NATIVE_SEMAPHORE_OPERATION.willAttemptUnlockReentrantToIsolate) || (throw Exception('Failed to persist operation status to temp file.'));
    return true;
  }

  @override
  bool unlockReentrantToIsolate() {
    if (!willAttemptUnlockReentrantToIsolate()) return false;

    persist(status: NATIVE_SEMAPHORE_OPERATION.unlockReentrantToIsolate) || (throw Exception('Failed to persist operation status to temp file.'));
    // We will do nothing here and proceed to decrement in the _unlockAttemptReentrantToIsolateSucceeded method

    return unlockAttemptReentrantToIsolateSucceeded();
  }

  @override
  bool unlockAttemptReentrantToIsolateSucceeded() {
    counter.counts.isolate.decrement();

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
    return unlockReentrantToIsolate() || unlockAcrossProcesses();
  }

  @override
  bool willAttemptClose() {
    if (locked) {
      bool value = false;
      statuses.synchronize(operation: NATIVE_SEMAPHORE_OPERATION.willAttemptClose, value: value, verification: (status: statuses.close, expected_operation: NATIVE_SEMAPHORE_OPERATION.willAttemptClose, expected_value: value));
      return value;
    }

    bool value = true;
    persist(status: NATIVE_SEMAPHORE_OPERATION.willAttemptClose, sync: true) || (throw Exception('Failed to persist operation status to temp file.'));
    statuses.synchronize(operation: NATIVE_SEMAPHORE_OPERATION.willAttemptClose, value: value, verification: (status: statuses.close, expected_operation: NATIVE_SEMAPHORE_OPERATION.willAttemptClose, expected_value: value));
    return value;
  }

  @override
  bool closeAttemptSucceeded({required int attempt}) {
    if (attempt == 0) {
      LatePropertyAssigned<bool>(() => hasClosed) || (hasClosed = true);
      bool value = closed;
      persist(status: NATIVE_SEMAPHORE_OPERATION.closeAttemptSucceeded, sync: true) || (throw Exception('Failed to persist operation status to temp file.'));
      statuses.synchronize(operation: NATIVE_SEMAPHORE_OPERATION.closeAttemptSucceeded, value: value, verification: (status: statuses.close, expected_operation: NATIVE_SEMAPHORE_OPERATION.closeAttemptSucceeded, expected_value: value));
      return value;
    }

    bool value = false;
    UnixSemCloseError error = UnixSemCloseError.fromErrno(errno.value);
    statuses.synchronize(operation: NATIVE_SEMAPHORE_OPERATION.closeAttemptSucceeded, value: value,   verification: (status: statuses.close, expected_operation: NATIVE_SEMAPHORE_OPERATION.closeAttemptSucceeded, expected_value: value));
    return value;
  }

  // Closing has no reentrant effect
  @override
  bool close() {
    if(closed) {
      print("${identity.tracer} already closed and is reentrant $reentrant");
    }

    // if(reentrant || closed) return closed;

    if (!willAttemptClose()) return false;

    bool value = true;
    // persist(status: NATIVE_SEMAPHORE_OPERATION.attemptingClose) || (throw Exception('Failed to persist operation status to temp file.'));
    statuses.synchronize(operation: NATIVE_SEMAPHORE_OPERATION.attemptingClose, value: value, verification: (status: statuses.close, expected_operation: NATIVE_SEMAPHORE_OPERATION.attemptingClose, expected_value: value));


    final int attempt = sem_close(_semaphore);

    persist(status: NATIVE_SEMAPHORE_OPERATION.close) || (throw Exception('Failed to persist operation status to temp file.'));

    // persist(status: NATIVE_SEMAPHORE_OPERATION.attemptedClose) || (throw Exception('Failed to persist operation status to temp file.'));
    statuses.synchronize(operation: NATIVE_SEMAPHORE_OPERATION.attemptedClose, value: value = (attempt == 0), verification: (status: statuses.close, expected_operation: NATIVE_SEMAPHORE_OPERATION.attemptedClose, expected_value: value));


    return closeAttemptSucceeded(attempt: attempt);
  }

  @override
  bool willAttemptUnlink() {
    // Not sure if this is needed
    if (counter.counts.process.get() > 0) {
      bool value = false;
      statuses.synchronize(operation: NATIVE_SEMAPHORE_OPERATION.willAttemptUnlink, value: value, verification: (status: statuses.unlink, expected_operation: NATIVE_SEMAPHORE_OPERATION.willAttemptUnlink, expected_value: value));
      return value;
    }

    if (!closed) {
      bool value = false;
      statuses.synchronize(operation: NATIVE_SEMAPHORE_OPERATION.willAttemptUnlink, value: value, verification: (status: statuses.unlink, expected_operation: NATIVE_SEMAPHORE_OPERATION.willAttemptUnlink, expected_value: value));
      return value;
    }

    bool value = true;
    persist(status: NATIVE_SEMAPHORE_OPERATION.willAttemptUnlink, sync: true) || (throw Exception('Failed to persist operation status to temp file.'));
    statuses.synchronize(operation: NATIVE_SEMAPHORE_OPERATION.willAttemptUnlink, value: value, verification: (status: statuses.unlink, expected_operation: NATIVE_SEMAPHORE_OPERATION.willAttemptUnlink, expected_value: value));
    return value;
  }

  @override
  bool unlinkAttemptSucceeded({required int attempt}) {
    UnixSemUnlinkError? error;

    if (attempt.isOdd && attempt.isNegative) {
      error = UnixSemUnlinkError.fromErrno(errno.value);

      if (error.critical) {
        bool value = false;
        statuses.synchronize(operation: NATIVE_SEMAPHORE_OPERATION.unlinkAttemptSucceeded, value: value, verification: (status: statuses.unlink, expected_operation: NATIVE_SEMAPHORE_OPERATION.unlinkAttemptSucceeded, expected_value: value));
        return value;
      }
    }


    if (error is UnixSemUnlinkError && !error.critical) if (verbose)
      print("Non-Critical Error in Evaluation [unlinkAttemptSucceeded()]: IDENTITY: ${identity.identifier} ERROR: ${error.toString()}");

    malloc.free(_identifier);

    LatePropertyAssigned<bool>(() => hasUnlinked) || (hasUnlinked = true);

    bool value = unlinked;

    persist(status: NATIVE_SEMAPHORE_OPERATION.unlinkAttemptSucceeded, sync: true) || (throw Exception('Failed to persist operation status to temp file.'));
    statuses.synchronize(operation: NATIVE_SEMAPHORE_OPERATION.unlinkAttemptSucceeded, value: value, verification: (status: statuses.unlink, expected_operation: NATIVE_SEMAPHORE_OPERATION.unlinkAttemptSucceeded, expected_value: value));

    // TODO deprecate this
    logs.close();

    return value;
  }

  @override
  bool unlink() {
    if(unlinked) {
      print("${identity.tracer} already unlinked and is reentrant $reentrant");
    }

    // if(unlinked || reentrant) return unlinked;

    if (!willAttemptUnlink()) return false;

    bool value = true;
    // persist(status: NATIVE_SEMAPHORE_OPERATION.attemptingUnlink) || (throw Exception('Failed to persist operation status to temp file.'));
    statuses.synchronize(operation: NATIVE_SEMAPHORE_OPERATION.attemptingUnlink, value: value, verification: (status: statuses.unlink, expected_operation: NATIVE_SEMAPHORE_OPERATION.attemptingUnlink, expected_value: value));

    final int _unlinked = sem_unlink(_identifier);


    persist(status: NATIVE_SEMAPHORE_OPERATION.unlink) || (throw Exception('Failed to persist operation status to temp file.'));
    // persist(status: NATIVE_SEMAPHORE_OPERATION.attemptedUnlink) || (throw Exception('Failed to persist operation status to temp file.'));
    statuses.synchronize(operation: NATIVE_SEMAPHORE_OPERATION.attemptedUnlink, value: value = _unlinked == 0, verification: (status: statuses.unlink, expected_operation: NATIVE_SEMAPHORE_OPERATION.attemptedUnlink, expected_value: value));


    return unlinkAttemptSucceeded(attempt: _unlinked);
  }

  @override
  String toString() => 'UnixSemaphore()';
}
