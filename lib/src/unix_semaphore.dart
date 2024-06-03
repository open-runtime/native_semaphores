import 'dart:async' show Future, FutureOr;
import 'dart:ffi' show AbiSpecificIntegerPointer, Char, Pointer;
import 'package:ffi/ffi.dart' show StringUtf8Pointer, malloc;
import 'ffi/unix.dart' show MODE_T_PERMISSIONS, UnixSemCloseError, UnixSemLimits, UnixSemOpenError, UnixSemOpenMacros, UnixSemUnlinkError, UnixSemUnlockWithPostError, errno, sem_close, sem_open, sem_post, sem_t, sem_trywait, sem_unlink, sem_wait;
import 'native_semaphore.dart' show NativeSemError, NativeSemaphore;
import 'native_semaphore_operations.dart' show NativeSemaphoreProcessOperationStatus, NativeSemaphoreProcessOperationStatusState, NativeSemaphoreProcessOperationStatuses;
import 'persisted_native_semaphore_metadata.dart' show PersistedNativeSemaphoreAccessor, PersistedNativeSemaphoreMetadata;
import 'persisted_native_semaphore_operation.dart' show PersistedNativeSemaphoreOperation, PersistedNativeSemaphoreOperations;
import 'semaphore_counter.dart' show SemaphoreCount, SemaphoreCountDeletion, SemaphoreCountUpdate, SemaphoreCounter, SemaphoreCounters, SemaphoreCounts;
import 'semaphore_identity.dart' show SemaphoreIdentities, SemaphoreIdentity;
import 'utils/late_final_property.dart' show LateProperty;

class UnixSemaphore<I extends SemaphoreIdentity, IS extends SemaphoreIdentities<I>, CU extends SemaphoreCountUpdate, CD extends SemaphoreCountDeletion, CT extends SemaphoreCount<CU, CD>, CTS extends SemaphoreCounts<CU, CD, CT>, NSPOSS extends NativeSemaphoreProcessOperationStatusState, NSPOS extends NativeSemaphoreProcessOperationStatus<I, NSPOSS>, NSPOSES extends NativeSemaphoreProcessOperationStatuses<I, NSPOSS, NSPOS>, CTR extends SemaphoreCounter<I, CU, CD, CT, CTS, NSPOSS, NSPOS, NSPOSES>, CTRS extends SemaphoreCounters<I, CU, CD, CT, CTS, NSPOSS, NSPOS, NSPOSES, CTR>, PNSO extends PersistedNativeSemaphoreOperation, PNSOS extends PersistedNativeSemaphoreOperations<PNSO>, PNSA extends PersistedNativeSemaphoreAccessor, PNSM extends PersistedNativeSemaphoreMetadata<PNSA>> extends NativeSemaphore<I, IS, CU, CD, CT, CTS, NSPOSS, NSPOS, NSPOSES, CTR, CTRS, PNSO, PNSOS, PNSA> {
  LateProperty<Pointer<Char>> identifier = LateProperty<Pointer<Char>>(name: 'identifier', updatable: false);
  LateProperty<Pointer<sem_t>> semaphore = LateProperty<Pointer<sem_t>>(name: 'semaphore', updatable: false);

  UnixSemaphore({required String Function() tracerFn, required CTR counter, verbose = false}) : super(tracerFn: () => tracerFn(), counter: counter, verbose: verbose);

  @override
  bool willAttemptOpenAcrossProcesses({bool? state, bool persisted = true}) {
    // TODO other checks on the identifier string
    (identity.name.get.replaceFirst(('/'), '').length <= UnixSemLimits.NAME_MAX_CHARACTERS) || (throw ArgumentError('Identifier is too long. Must be less than or equal to ${UnixSemLimits.NAME_MAX_CHARACTERS} characters.'));
    return super.willAttemptOpenAcrossProcesses(/*Dont pass state as true or false explicitly here as super will determine it based on !opened */ state: state);
  }

  @override
  bool openAcrossProcesses() {
    if (!willAttemptOpenAcrossProcesses()) return false;
    identifier.set(('/${identity.name.get.replaceFirst(('/'), '')}'.toNativeUtf8()).cast()).succeeded || (throw 'Failed to set identifier');
    super.attemptingOpenAcrossProcesses(/*Dont pass state as true or false explicitly here as super will determine it based on !opened */);
    identity.address = semaphore.set(sem_open(identifier.get, UnixSemOpenMacros.O_CREAT, MODE_T_PERMISSIONS.RECOMMENDED, UnixSemOpenMacros.VALUE_RECOMMENDED)).get.address;
    super.attemptedOpenAcrossProcesses(state: semaphore.get.address != UnixSemOpenMacros.SEM_FAILED.address);
    return openAttemptAcrossProcessesSucceeded();
  }

  @override
  bool openAttemptAcrossProcessesSucceeded({bool? state, bool persisted = true}) {
    (semaphore.get.address != UnixSemOpenMacros.SEM_FAILED.address) || (throw "${UnixSemOpenError.fromErrno(errno.value).toString()}");
    return super.openAttemptAcrossProcessesSucceeded(/* If we made it this far, we're passing true */ state: true);
  }

  @override
  bool lockAcrossProcesses({bool blocking = true, Duration? timeout}) {
    if (!willAttemptLockAcrossProcesses()) return false;

    waiting = blocking;
    int attempt = sem_trywait(semaphore.get);
    if (blocking && /* i.e. same as !attempt.isEven */ !attemptingLockAcrossProcesses(state: attempt.isEven)) attempt = sem_wait(semaphore.get);
    waiting = false;

    attemptedLockAcrossProcesses(attempt: attempt, state: attempt.isEven);
    return lockAttemptAcrossProcessesSucceeded(attempt: attempt);
  }

  @override
  bool lockAttemptAcrossProcessesSucceeded<E extends NativeSemError>({required int attempt, bool? state, E? error}) {
    state = state ?? attempt.isEven;
    // TODO if handle other cases i.e. EINTR, EAGAIN, EDEADLK etc.
    //  i.e. (!state) /*if the error is not critical then we don't throw */ !(error = UnixSemLockError.fromErrno(errno.value) as E).critical || (throw error);
    return super.lockAttemptAcrossProcessesSucceeded(attempt: attempt, state: state);
  }

  // TODO Remove
  Future<bool> lockWithDelay({bool blocking = true, Duration? delay, FutureOr Function()? before, FutureOr Function()? after}) async {
    delay ??= Duration(seconds: 0);
    await Future.delayed(delay);
    before != null ? await before.call() : null;

    Stopwatch stopwatch = Stopwatch()..start();
    bool locked = lock(blocking: blocking);
    stopwatch.stop();
    after != null ? await after.call() : null;
    return locked;
  }

  @override
  bool unlockAttemptAcrossProcessesSucceeded<E extends NativeSemError>({required int attempt, bool? state, E? error}) {
    if (/* If the attempt is 0 that means we succeeded on unix */ attempt != 0) /*if the error is not critical then we don't throw */
      !(error = UnixSemUnlockWithPostError.fromErrno(errno.value) as E).critical || (throw error);
    return super.unlockAttemptAcrossProcessesSucceeded<E>(attempt: attempt, state: state = state ?? attempt == 0, error: error);
  }

  @override
  bool unlockAcrossProcesses() {
    if (!willAttemptUnlockAcrossProcesses()) return false; // TODO perhaps call completers.complete here? & Synchronize within the hook itself?
    attemptingUnlockAcrossProcesses(state: true);
    int attempt = sem_post(semaphore.get);
    attemptedUnlockAcrossProcesses(attempt: attempt, state: attempt == 0);
    return unlockAttemptAcrossProcessesSucceeded(attempt: attempt);
  }

  Future<bool> unlockWithDelay({Duration? delay, FutureOr Function()? before, FutureOr Function()? after}) async {
    delay ??= Duration(seconds: 0);
    before != null ? await before.call() : null;
    await Future.delayed(delay);
    bool returnable = unlock();
    after != null ? await after.call() : null;
    return returnable;
  }

  @override
  bool closeAttemptAcrossProcessesSucceeded<E extends NativeSemError>({required int attempt, bool? state, E? error}) {
    state = state ?? attempt == 0;
    if (attempt != 0) /*if the error is not critical then we don't throw */ !(error = UnixSemCloseError.fromErrno(errno.value) as E).critical || (throw error);
    return super.closeAttemptAcrossProcessesSucceeded<E>(attempt: attempt, state: state, error: error);
  }

  @override
  bool closeAcrossProcesses() {
    if (!willAttemptCloseAcrossProcesses()) return false;
    super.attemptingCloseAcrossProcesses(state: true);
    final int attempt = sem_close(semaphore.get);
    super.attemptedCloseAcrossProcesses(attempt: attempt, state: attempt == 0);
    return closeAttemptAcrossProcessesSucceeded(attempt: attempt);
  }

  @override
  bool unlinkAttemptAcrossProcessesSucceeded<E extends NativeSemError>({required int attempt, bool? state, E? error}) {
    // If the attempt is 0 that means we succeeded on unix
    state = state ?? attempt == 0;
    if (attempt != 0) /*if the error is not critical then we don't throw */ !(error = UnixSemUnlinkError.fromErrno(errno.value) as E).critical || (throw error);
    state = error is UnixSemUnlinkError && !error.critical || state;

    if (super.unlinkAttemptAcrossProcessesSucceeded<E>(attempt: attempt, state: state, error: error)) {
      malloc.free(identifier.get);
    }

    return state;
  }

  @override
  bool unlinkAcrossProcesses() {
    if (!willAttemptUnlinkAcrossProcesses()) return false;
    super.attemptingUnlinkAcrossProcesses(state: true);
    final int attempt = sem_unlink(identifier.get);
    super.attemptedUnlinkAcrossProcesses(attempt: attempt, state: attempt == 0);
    return unlinkAttemptAcrossProcessesSucceeded(attempt: attempt);
  }

  @override
  String toString() => 'UnixSemaphore()';
}
