import 'dart:async' show Completer, Future, Stream, StreamController, StreamSubscription;
import 'dart:io' show Platform, stderr;

import 'semaphore_identity.dart' show SemaphoreIdentity;
import 'utils/late_final_property.dart' show LateProperty;

enum NATIVE_SEMAPHORE_OPERATION {
  instantiate,

  /*Open*/
  open,
  willAttemptOpenAcrossProcesses,
  attemptingOpenAcrossProcesses,
  openAcrossProcesses,
  attemptedOpenAcrossProcesses,
  openAttemptAcrossProcessesSucceeded,
  willAttemptOpenReentrantToIsolate,
  attemptingOpenReentrantToIsolate,
  openReentrantToIsolate,
  attemptedOpenReentrantToIsolate,
  openAttemptReentrantToIsolateSucceeded,

  /*Lock*/
  lock,
  willAttemptLockAcrossProcesses,
  attemptingLockAcrossProcesses,
  lockAcrossProcesses,
  attemptedLockAcrossProcesses,
  lockAttemptAcrossProcessesSucceeded,
  willAttemptLockReentrantToIsolate,
  attemptingLockReentrantToIsolate,
  lockReentrantToIsolate,
  attemptedLockReentrantToIsolate,
  lockAttemptReentrantToIsolateSucceeded,

  /*Unlock*/
  unlock,
  willAttemptUnlockAcrossProcesses,
  attemptingUnlockAcrossProcesses,
  unlockAcrossProcesses,
  attemptedUnlockAcrossProcesses,
  unlockAttemptAcrossProcessesSucceeded,
  willAttemptUnlockReentrantToIsolate,
  attemptingUnlockReentrantToIsolate,
  unlockReentrantToIsolate,
  attemptedUnlockReentrantToIsolate,
  unlockAttemptReentrantToIsolateSucceeded,

  /*Close*/
  close,
  willAttemptCloseAcrossProcesses,
  attemptingCloseAcrossProcesses,
  closeAcrossProcesses,
  attemptedCloseAcrossProcesses,
  closeAttemptAcrossProcessesSucceeded,
  willAttemptCloseReentrantToIsolate,
  attemptingCloseReentrantToIsolate,
  closeReentrantToIsolate,
  attemptedCloseReentrantToIsolate,
  closeAttemptReentrantToIsolateSucceeded,

  /*Unlink*/
  unlink,
  willAttemptUnlinkAcrossProcesses,
  attemptingUnlinkAcrossProcesses,
  unlinkAcrossProcesses,
  attemptedUnlinkAcrossProcesses,
  unlinkAttemptAcrossProcessesSucceeded,
  willAttemptUnlinkReentrantToIsolate,
  attemptingUnlinkReentrantToIsolate,
  unlinkReentrantToIsolate,
  attemptedUnlinkReentrantToIsolate,
  unlinkAttemptReentrantToIsolateSucceeded,

  /*Unknown*/
  unknown;

  @override
  String toString() {
    switch (this) {
      /*Instantiate */
      case NATIVE_SEMAPHORE_OPERATION.instantiate:
        return 'instantiate()';
      /*Open*/
      case NATIVE_SEMAPHORE_OPERATION.open:
        return 'open()';
      case NATIVE_SEMAPHORE_OPERATION.willAttemptOpenReentrantToIsolate:
        return 'willAttemptOpenReentrantToIsolate()';
      case NATIVE_SEMAPHORE_OPERATION.attemptingOpenReentrantToIsolate:
        return 'attemptingOpenReentrantToIsolate()';
      case NATIVE_SEMAPHORE_OPERATION.openReentrantToIsolate:
        return 'openReentrantToIsolate()';
      case NATIVE_SEMAPHORE_OPERATION.attemptedOpenReentrantToIsolate:
        return 'attemptedOpenReentrantToIsolate()';
      case NATIVE_SEMAPHORE_OPERATION.openAttemptReentrantToIsolateSucceeded:
        return 'openAttemptReentrantToIsolateSucceeded()';
      case NATIVE_SEMAPHORE_OPERATION.willAttemptOpenAcrossProcesses:
        return 'willAttemptOpenAcrossProcesses()';
      case NATIVE_SEMAPHORE_OPERATION.attemptingOpenAcrossProcesses:
        return 'attemptingOpenAcrossProcesses()';
      case NATIVE_SEMAPHORE_OPERATION.openAcrossProcesses:
        return 'openAcrossProcesses()';
      case NATIVE_SEMAPHORE_OPERATION.attemptedOpenAcrossProcesses:
        return 'attemptedOpenAcrossProcesses()';
      case NATIVE_SEMAPHORE_OPERATION.openAttemptAcrossProcessesSucceeded:
        return 'openAttemptAcrossProcessesSucceeded()';
      /*Lock*/
      case NATIVE_SEMAPHORE_OPERATION.lock:
        return 'lock()';
      case NATIVE_SEMAPHORE_OPERATION.willAttemptLockReentrantToIsolate:
        return 'willAttemptLockReentrantToIsolate()';
      case NATIVE_SEMAPHORE_OPERATION.attemptingLockReentrantToIsolate:
        return 'attemptingLockReentrantToIsolate()';
      case NATIVE_SEMAPHORE_OPERATION.lockReentrantToIsolate:
        return 'lockReentrantToIsolate()';
      case NATIVE_SEMAPHORE_OPERATION.attemptedLockReentrantToIsolate:
        return 'attemptedLockReentrantToIsolate()';
      case NATIVE_SEMAPHORE_OPERATION.lockAttemptReentrantToIsolateSucceeded:
        return 'lockAttemptReentrantToIsolateSucceeded()';
      case NATIVE_SEMAPHORE_OPERATION.willAttemptLockAcrossProcesses:
        return 'willAttemptLockAcrossProcesses()';
      case NATIVE_SEMAPHORE_OPERATION.attemptingLockAcrossProcesses:
        return 'attemptingLockAcrossProcesses()';
      case NATIVE_SEMAPHORE_OPERATION.lockAcrossProcesses:
        return 'lockAcrossProcesses()';
      case NATIVE_SEMAPHORE_OPERATION.attemptedLockAcrossProcesses:
        return 'attemptedLockAcrossProcesses()';
      case NATIVE_SEMAPHORE_OPERATION.lockAttemptAcrossProcessesSucceeded:
        return 'lockAttemptAcrossProcessesSucceeded()';
      /*Unlock*/
      case NATIVE_SEMAPHORE_OPERATION.willAttemptUnlockAcrossProcesses:
        return 'willAttemptUnlockAcrossProcesses()';
      case NATIVE_SEMAPHORE_OPERATION.attemptingUnlockAcrossProcesses:
        return 'attemptingUnlockAcrossProcesses()';
      case NATIVE_SEMAPHORE_OPERATION.unlockAcrossProcesses:
        return 'unlockAcrossProcesses()';
      case NATIVE_SEMAPHORE_OPERATION.attemptedUnlockAcrossProcesses:
        return 'attemptedUnlockAcrossProcesses()';
      case NATIVE_SEMAPHORE_OPERATION.unlockAttemptAcrossProcessesSucceeded:
        return 'unlockAttemptAcrossProcessesSucceeded()';
      case NATIVE_SEMAPHORE_OPERATION.willAttemptUnlockReentrantToIsolate:
        return 'willAttemptUnlockReentrantToIsolate()';
      case NATIVE_SEMAPHORE_OPERATION.attemptingUnlockReentrantToIsolate:
        return 'attemptingUnlockReentrantToIsolate()';
      case NATIVE_SEMAPHORE_OPERATION.unlockReentrantToIsolate:
        return 'unlockReentrantToIsolate()';
      case NATIVE_SEMAPHORE_OPERATION.attemptedUnlockReentrantToIsolate:
        return 'attemptedUnlockReentrantToIsolate()';
      case NATIVE_SEMAPHORE_OPERATION.unlockAttemptReentrantToIsolateSucceeded:
        return 'unlockAttemptReentrantToIsolateSucceeded()';
      /*Close*/
      case NATIVE_SEMAPHORE_OPERATION.close:
        return 'close()';
      case NATIVE_SEMAPHORE_OPERATION.willAttemptCloseAcrossProcesses:
        return 'willAttemptCloseAcrossProcesses()';
      case NATIVE_SEMAPHORE_OPERATION.attemptingCloseAcrossProcesses:
        return 'attemptingCloseAcrossProcesses()';
      case NATIVE_SEMAPHORE_OPERATION.closeAcrossProcesses:
        return 'closeAcrossProcesses()';
      case NATIVE_SEMAPHORE_OPERATION.attemptedCloseAcrossProcesses:
        return 'attemptedCloseAcrossProcesses()';
      case NATIVE_SEMAPHORE_OPERATION.closeAttemptAcrossProcessesSucceeded:
        return 'closeAttemptAcrossProcessesSucceeded()';
      case NATIVE_SEMAPHORE_OPERATION.willAttemptCloseReentrantToIsolate:
        return 'willAttemptCloseReentrantToIsolate()';
      case NATIVE_SEMAPHORE_OPERATION.attemptingCloseReentrantToIsolate:
        return 'attemptingCloseReentrantToIsolate()';
      case NATIVE_SEMAPHORE_OPERATION.closeReentrantToIsolate:
        return 'closeReentrantToIsolate()';
      case NATIVE_SEMAPHORE_OPERATION.attemptedCloseReentrantToIsolate:
        return 'attemptedCloseReentrantToIsolate()';
      case NATIVE_SEMAPHORE_OPERATION.closeAttemptReentrantToIsolateSucceeded:
        return 'closeAttemptReentrantToIsolateSucceeded()';
      /*Unlink*/
      case NATIVE_SEMAPHORE_OPERATION.unlink:
        return 'unlink()';
      case NATIVE_SEMAPHORE_OPERATION.willAttemptUnlinkAcrossProcesses:
        return 'willAttemptUnlinkAcrossProcesses()';
      case NATIVE_SEMAPHORE_OPERATION.attemptingUnlinkAcrossProcesses:
        return 'attemptingUnlinkAcrossProcesses()';
      case NATIVE_SEMAPHORE_OPERATION.unlinkAcrossProcesses:
        return 'unlinkAcrossProcesses()';
      case NATIVE_SEMAPHORE_OPERATION.attemptedUnlinkAcrossProcesses:
        return 'attemptedUnlinkAcrossProcesses()';
      case NATIVE_SEMAPHORE_OPERATION.unlinkAttemptAcrossProcessesSucceeded:
        return 'unlinkAttemptAcrossProcessesSucceeded()';
      case NATIVE_SEMAPHORE_OPERATION.willAttemptUnlinkReentrantToIsolate:
        return 'willAttemptUnlinkReentrantToIsolate()';
      case NATIVE_SEMAPHORE_OPERATION.attemptingUnlinkReentrantToIsolate:
        return 'attemptingUnlinkReentrantToIsolate()';
      case NATIVE_SEMAPHORE_OPERATION.unlinkReentrantToIsolate:
        return 'unlinkReentrantToIsolate()';
      case NATIVE_SEMAPHORE_OPERATION.attemptedUnlinkReentrantToIsolate:
        return 'attemptedUnlinkReentrantToIsolate()';
      case NATIVE_SEMAPHORE_OPERATION.unlinkAttemptReentrantToIsolateSucceeded:
        return 'unlinkAttemptReentrantToIsolateSucceeded()';
      default:
        throw Exception('Unknown Native Semaphore Operation');
    }
  }

  static NATIVE_SEMAPHORE_OPERATION fromString(String value) {
    switch (value) {
      /*Instantiate */
      case 'instantiate()':
        return NATIVE_SEMAPHORE_OPERATION.instantiate;
      /*Open */
      case 'open()':
        return NATIVE_SEMAPHORE_OPERATION.open;
      case 'willAttemptOpenReentrantToIsolate()':
        return NATIVE_SEMAPHORE_OPERATION.willAttemptOpenReentrantToIsolate;
      case 'attemptingOpenReentrantToIsolate()':
        return NATIVE_SEMAPHORE_OPERATION.attemptingOpenReentrantToIsolate;
      case 'openReentrantToIsolate()':
        return NATIVE_SEMAPHORE_OPERATION.openReentrantToIsolate;
      case 'attemptedOpenReentrantToIsolate()':
        return NATIVE_SEMAPHORE_OPERATION.attemptedOpenReentrantToIsolate;
      case 'openAttemptReentrantToIsolateSucceeded()':
        return NATIVE_SEMAPHORE_OPERATION.openAttemptReentrantToIsolateSucceeded;
      case 'willAttemptOpenAcrossProcesses()':
        return NATIVE_SEMAPHORE_OPERATION.willAttemptOpenAcrossProcesses;
      case 'attemptingOpenAcrossProcesses()':
        return NATIVE_SEMAPHORE_OPERATION.attemptingOpenAcrossProcesses;
      case 'openAcrossProcesses()':
        return NATIVE_SEMAPHORE_OPERATION.openAcrossProcesses;
      case 'attemptedOpenAcrossProcesses()':
        return NATIVE_SEMAPHORE_OPERATION.attemptedOpenAcrossProcesses;
      case 'openAttemptAcrossProcessesSucceeded()':
        return NATIVE_SEMAPHORE_OPERATION.openAttemptAcrossProcessesSucceeded;
      /*Lock */
      case 'lock()':
        return NATIVE_SEMAPHORE_OPERATION.lock;
      case 'willAttemptLockReentrantToIsolate()':
        return NATIVE_SEMAPHORE_OPERATION.willAttemptLockReentrantToIsolate;
      case 'attemptingLockReentrantToIsolate()':
        return NATIVE_SEMAPHORE_OPERATION.attemptingLockReentrantToIsolate;
      case 'lockReentrantToIsolate()':
        return NATIVE_SEMAPHORE_OPERATION.lockReentrantToIsolate;
      case 'attemptedLockReentrantToIsolate()':
        return NATIVE_SEMAPHORE_OPERATION.attemptedLockReentrantToIsolate;
      case 'lockAttemptReentrantToIsolateSucceeded()':
        return NATIVE_SEMAPHORE_OPERATION.lockAttemptReentrantToIsolateSucceeded;
      case 'willAttemptLockAcrossProcesses()':
        return NATIVE_SEMAPHORE_OPERATION.willAttemptLockAcrossProcesses;
      case 'attemptingLockAcrossProcesses()':
        return NATIVE_SEMAPHORE_OPERATION.attemptingLockAcrossProcesses;
      case 'lockAcrossProcesses()':
        return NATIVE_SEMAPHORE_OPERATION.lockAcrossProcesses;
      case 'attemptedLockAcrossProcesses()':
        return NATIVE_SEMAPHORE_OPERATION.attemptedLockAcrossProcesses;
      case 'lockAttemptAcrossProcessesSucceeded()':
        return NATIVE_SEMAPHORE_OPERATION.lockAttemptAcrossProcessesSucceeded;
      /*Unlock */
      case 'unlock()':
        return NATIVE_SEMAPHORE_OPERATION.unlock;
      case 'willAttemptUnlockAcrossProcesses()':
        return NATIVE_SEMAPHORE_OPERATION.willAttemptUnlockAcrossProcesses;
      case 'attemptingUnlockAcrossProcesses()':
        return NATIVE_SEMAPHORE_OPERATION.attemptingUnlockAcrossProcesses;
      case 'unlockAcrossProcesses()':
        return NATIVE_SEMAPHORE_OPERATION.unlockAcrossProcesses;
      case 'attemptedUnlockAcrossProcesses()':
        return NATIVE_SEMAPHORE_OPERATION.attemptedUnlockAcrossProcesses;
      case 'unlockAttemptAcrossProcessesSucceeded()':
        return NATIVE_SEMAPHORE_OPERATION.unlockAttemptAcrossProcessesSucceeded;
      case 'willAttemptUnlockReentrantToIsolate()':
        return NATIVE_SEMAPHORE_OPERATION.willAttemptUnlockReentrantToIsolate;
      case 'attemptingUnlockReentrantToIsolate()':
        return NATIVE_SEMAPHORE_OPERATION.attemptingUnlockReentrantToIsolate;
      case 'unlockReentrantToIsolate()':
        return NATIVE_SEMAPHORE_OPERATION.unlockReentrantToIsolate;
      case 'attemptedUnlockReentrantToIsolate()':
        return NATIVE_SEMAPHORE_OPERATION.attemptedUnlockReentrantToIsolate;
      case 'unlockAttemptReentrantToIsolateSucceeded()':
        return NATIVE_SEMAPHORE_OPERATION.unlockAttemptReentrantToIsolateSucceeded;
      /*Close */
      case 'close()':
        return NATIVE_SEMAPHORE_OPERATION.close;
      case 'willAttemptCloseAcrossProcesses()':
        return NATIVE_SEMAPHORE_OPERATION.willAttemptCloseAcrossProcesses;
      case 'attemptingCloseAcrossProcesses()':
        return NATIVE_SEMAPHORE_OPERATION.attemptingCloseAcrossProcesses;
      case 'closeAcrossProcesses()':
        return NATIVE_SEMAPHORE_OPERATION.closeAcrossProcesses;
      case 'attemptedCloseAcrossProcesses()':
        return NATIVE_SEMAPHORE_OPERATION.attemptedCloseAcrossProcesses;
      case 'closeAttemptAcrossProcessesSucceeded()':
        return NATIVE_SEMAPHORE_OPERATION.closeAttemptAcrossProcessesSucceeded;
      case 'willAttemptCloseReentrantToIsolate()':
        return NATIVE_SEMAPHORE_OPERATION.willAttemptCloseReentrantToIsolate;
      case 'attemptingCloseReentrantToIsolate()':
        return NATIVE_SEMAPHORE_OPERATION.attemptingCloseReentrantToIsolate;
      case 'closeReentrantToIsolate()':
        return NATIVE_SEMAPHORE_OPERATION.closeReentrantToIsolate;
      case 'attemptedCloseReentrantToIsolate()':
        return NATIVE_SEMAPHORE_OPERATION.attemptedCloseReentrantToIsolate;
      case 'closeAttemptReentrantToIsolateSucceeded()':
        return NATIVE_SEMAPHORE_OPERATION.closeAttemptReentrantToIsolateSucceeded;
      /*Unlink */
      case 'unlink()':
        return NATIVE_SEMAPHORE_OPERATION.unlink;
      case 'willAttemptUnlinkAcrossProcesses()':
        return NATIVE_SEMAPHORE_OPERATION.willAttemptUnlinkAcrossProcesses;
      case 'attemptingUnlinkAcrossProcesses()':
        return NATIVE_SEMAPHORE_OPERATION.attemptingUnlinkAcrossProcesses;
      case 'unlinkAcrossProcesses()':
        return NATIVE_SEMAPHORE_OPERATION.unlinkAcrossProcesses;
      case 'attemptedUnlinkAcrossProcesses()':
        return NATIVE_SEMAPHORE_OPERATION.attemptedUnlinkAcrossProcesses;
      case 'unlinkAttemptAcrossProcessesSucceeded()':
        return NATIVE_SEMAPHORE_OPERATION.unlinkAttemptAcrossProcessesSucceeded;
      case 'willAttemptUnlinkReentrantToIsolate()':
        return NATIVE_SEMAPHORE_OPERATION.willAttemptUnlinkReentrantToIsolate;
      case 'attemptingUnlinkReentrantToIsolate()':
        return NATIVE_SEMAPHORE_OPERATION.attemptingUnlinkReentrantToIsolate;
      case 'unlinkReentrantToIsolate()':
        return NATIVE_SEMAPHORE_OPERATION.unlinkReentrantToIsolate;
      case 'attemptedUnlinkReentrantToIsolate()':
        return NATIVE_SEMAPHORE_OPERATION.attemptedUnlinkReentrantToIsolate;
      case 'unlinkAttemptReentrantToIsolateSucceeded()':
        return NATIVE_SEMAPHORE_OPERATION.unlinkAttemptReentrantToIsolateSucceeded;
      /*Unknown */
      default:
        throw Exception('Unknown Native Semaphore Operation');
    }
  }
}

typedef NativeSemaphoreProcessOperationStatusStateSynchronizeFunctionType<I extends SemaphoreIdentity, NSPOSS extends NativeSemaphoreProcessOperationStatusState, NSPOS extends NativeSemaphoreProcessOperationStatus<I, NSPOSS>> = Future<NSPOS> Function<I extends SemaphoreIdentity, NSPOSS extends NativeSemaphoreProcessOperationStatusState, NSPOS extends NativeSemaphoreProcessOperationStatus<I, NSPOSS>>({required String hash, required NATIVE_SEMAPHORE_OPERATION operation, dynamic state, DateTime? timestamp, bool reentrant, required NSPOS status, ({NSPOS status, NATIVE_SEMAPHORE_OPERATION expected_operation, dynamic expected_state})? verification, R Function<R>(NSPOS status, NATIVE_SEMAPHORE_OPERATION expected_operation, R expected_state)? verifier});

class NativeSemaphoreProcessOperationStatusState {
  final String hash;
  final String tracer;
  final String name;
  final String process;
  final String isolate;

  String get identifier => [name, isolate, process].join('_');
  final bool reentrant;

  late final Duration took;

  late final DateTime timestamp;

  dynamic state;

  NATIVE_SEMAPHORE_OPERATION operation;

  LateProperty<bool> completed = LateProperty<bool>(initial: false, name: 'completed');

  /* This will complete with the NativeSemaphoreProcessOperationStatusState that preceded it i.e. if the owner of the completer is attemptingOpenAcrossProcesses then the completer will complete with willAttemptOpenAcrossProcesses */
  /* If it is a succeeded event then it will complete with the initial event that kicked it off i.e. openAttemptAcrossProcessesSucceeded  will complete with willAttemptOpenAcrossProcesses  */
  late Completer<NativeSemaphoreProcessOperationStatusState> completer = Completer<NativeSemaphoreProcessOperationStatusState>();

  NativeSemaphoreProcessOperationStatusState({required NATIVE_SEMAPHORE_OPERATION this.operation, DateTime? timestamp, required String this.hash, required bool this.reentrant, required String this.tracer, required String this.name, required String this.process, required String this.isolate, required dynamic this.state}) {
    this.timestamp = timestamp ?? DateTime.now();
  }

  @override
  toString() => 'NativeSemaphoreProcessOperationStatusState(tracer: $tracer, name: $name, process: $process, isolate: $isolate, timestamp: $timestamp, state: $state, operation: $operation, completer.isComplete: ${completer.isCompleted})';
}

class NativeSemaphoreProcessOperationStatus<I extends SemaphoreIdentity, NSPOSS extends NativeSemaphoreProcessOperationStatusState> {
  late final StreamController<NativeSemaphoreProcessOperationStatusState> _controller = StreamController<NativeSemaphoreProcessOperationStatusState>(sync: true);

  late final Stream<NativeSemaphoreProcessOperationStatusState> _broadcast = _controller.stream.asBroadcastStream();

  late final StreamSubscription<NativeSemaphoreProcessOperationStatusState> notifications;

  late final I identity;

  final List<NativeSemaphoreProcessOperationStatusState> synchronizations = [];

  late final void Function(NativeSemaphoreProcessOperationStatusState _state) callback = (NativeSemaphoreProcessOperationStatusState _state) => {};

  late final void Function(List<NativeSemaphoreProcessOperationStatusState?> _state) finalizer = (List<NativeSemaphoreProcessOperationStatusState?> _state) {
    // print('$tracer Finalizer: ${_state.toString()}');
  };

  late String Function() tracerFn;

  String get tracer => tracerFn();

  late final String name = identity.name.get;
  late final String process = identity.process;
  late final String isolate = identity.isolate;

  Map<String, Future<NativeSemaphoreProcessOperationStatusState>> memoized_completers = {};

  Future<NativeSemaphoreProcessOperationStatusState> future({required NATIVE_SEMAPHORE_OPERATION operation, required String hash}) {
    String key = [hash, operation.name].join('_');
    return memoized_completers.containsKey(key) ? memoized_completers[key]! : memoized_completers.putIfAbsent(key, () => _broadcast.firstWhere((NativeSemaphoreProcessOperationStatusState state) => state.hash == hash && state.completed.get));
  }

  NSPOS synchronize<I extends SemaphoreIdentity, NSPOSS extends NativeSemaphoreProcessOperationStatusState, NSPOS extends NativeSemaphoreProcessOperationStatus<I, NSPOSS>>({required String hash, required NATIVE_SEMAPHORE_OPERATION operation, dynamic state = null, bool reentrant = false, DateTime? timestamp, required NSPOS status, ({NSPOS status, NATIVE_SEMAPHORE_OPERATION expected_operation, dynamic expected_state})? verification, R Function<R>(NSPOS status, NATIVE_SEMAPHORE_OPERATION expected_operation, R expected_state)? verifier}) {
    // print(Platform.lineTerminator);
    // print(Platform.lineTerminator);
    // print(Platform.lineTerminator);

    // print('$tracer Previous: ${previous.nullable}');
    // print('$tracer Current: ${current.nullable}');
    // print('$tracer Synchronizing $hash $operation');

    NativeSemaphoreProcessOperationStatusState inbound_status_state = NativeSemaphoreProcessOperationStatusState(tracer: tracer, name: name, process: process, isolate: isolate, operation: operation, hash: hash, state: state, reentrant: true) as NSPOSS;

    synchronizations.add(inbound_status_state);

    // if (verification != null && verifier != null) verifier(verification.status, verification.expected_operation, verification.expected_state);

    NativeSemaphoreProcessOperationStatusState incomplete_previous_status_state = synchronizations.firstWhere((synchronization) => synchronization.hash == hash && !synchronization.completed.isSet, orElse: () => inbound_status_state);

    if (incomplete_previous_status_state != inbound_status_state) {
      incomplete_previous_status_state.completed.set(true);
      incomplete_previous_status_state.completer.complete(inbound_status_state);
      incomplete_previous_status_state.took = inbound_status_state.timestamp.difference(incomplete_previous_status_state.timestamp);
      memoized_completers.putIfAbsent([hash, inbound_status_state.operation.name].join('_'), () => inbound_status_state.completer.future);
      _controller.add(inbound_status_state);
      memoized_completers.putIfAbsent([hash, incomplete_previous_status_state.operation.name].join('_'), () => incomplete_previous_status_state.completer.future);
      _controller.add(incomplete_previous_status_state);
      // print('$tracer Completed Incomplete Operation ${incomplete_previous_status_state.hash} ${incomplete_previous_status_state.operation} ${incomplete_previous_status_state.took.inMilliseconds / 1000}s');
    }

    if (inbound_status_state.operation.name.endsWith('Succeeded')) {
      // print('$tracer Completing');

      NativeSemaphoreProcessOperationStatusState completed_initial_status_state = synchronizations.firstWhere((synchronization) => synchronization.hash == hash && synchronization.operation.name.startsWith("attempting"), orElse: () => inbound_status_state);

      print('$tracer $completed_initial_status_state');

      if (completed_initial_status_state != inbound_status_state) {
        inbound_status_state.completed.set(true);
        inbound_status_state.took = inbound_status_state.timestamp.difference(completed_initial_status_state.timestamp);
        inbound_status_state.completer.complete(inbound_status_state);
        memoized_completers.putIfAbsent([hash, inbound_status_state.operation.name].join('_'), () => inbound_status_state.completer.future);
        // print('$tracer Completed ${inbound_status_state.hash} ${inbound_status_state.operation} ${inbound_status_state.took.inMilliseconds / 1000}s ${inbound_status_state.completed}');
        _controller.add(inbound_status_state);
      }
    }

    if (inbound_status_state.operation.name.startsWith("instantiate")) {
      inbound_status_state.completed.set(true);
      inbound_status_state.took = DateTime.now().difference(inbound_status_state.timestamp);
      inbound_status_state.completer.complete(inbound_status_state);
      memoized_completers.putIfAbsent([hash, inbound_status_state.operation.name].join('_'), () => inbound_status_state.completer.future);
      // print('$tracer Completed Instantiate ${synchronizations.where((element) => element.operation.name.startsWith('instantiate')).length} ${inbound_status_state.hash} ${inbound_status_state.operation} ${inbound_status_state.took.inMilliseconds / 1000}s ${inbound_status_state.completed}');
      _controller.add(inbound_status_state);
    }

    // print(Platform.lineTerminator);
    // print(Platform.lineTerminator);
    // print(Platform.lineTerminator);

    return status;
  }

  Map<String, bool> memoized_completions = {};

  bool completed({required String hash, required List<NATIVE_SEMAPHORE_OPERATION> operations}) {
    String key = [hash, ...operations.map((operation) => operation.name)].join('_');

    if (memoized_completions.containsKey(key) && memoized_completions[hash] is bool) return memoized_completions[hash]!;

    Iterable<NativeSemaphoreProcessOperationStatusState> completions = synchronizations.where((status) {
      return status.hash == hash && operations.any((operation) => status.operation == operation) && status.completed.get;
    });

    bool _completed = completions.isNotEmpty && completions.every((status) => status.completed.get);

    return _completed ? memoized_completions.putIfAbsent(key, () => _completed) : _completed;
  }

  Map<String, bool> memoized_reentrancies = {};

  bool reentrant({required String hash, required int depth}) {
    String key = [hash, NATIVE_SEMAPHORE_OPERATION.instantiate.name].join('_');
    if (memoized_reentrancies.containsKey(key) && memoized_reentrancies[hash] is bool) return memoized_reentrancies[hash]!;

    Iterable<NativeSemaphoreProcessOperationStatusState> reentrancies = synchronizations.where((status) {
      return status.operation == NATIVE_SEMAPHORE_OPERATION.instantiate && status.completed.get;
    });

    bool _completed = (reentrancies.length > 1 && depth > 0) && reentrancies.isNotEmpty && reentrancies.every((status) => status.completed.get);
    // print('$tracer depth ${depth} isReentrant and Completed: $hash $_completed total reentrancies is at ${reentrancies.length - 1} (one subtracted for the root)');
    return _completed ? memoized_reentrancies.putIfAbsent(key, () => _completed) : _completed;
  }

  NativeSemaphoreProcessOperationStatus({required String Function() this.tracerFn, required I this.identity, NSPOSS? willAttempt = null, NSPOSS? attempting = null, NSPOSS? attempted = null, NSPOSS? attemptSucceeded = null}) {
    notifications = _broadcast.listen(callback, onError: stderr.writeln, onDone: () => finalizer(synchronizations), cancelOnError: true);
  }

  @override
  String toString() => 'NativeSemaphoreProcessOperationStatus(tracer: $tracer, name: $name, process: $process, isolate: $isolate, controller: $_controller, broadcast: $_broadcast, synchronizations: ${synchronizations.length})';
}

class NativeSemaphoreProcessOperationStatuses<I extends SemaphoreIdentity, NSPOSS extends NativeSemaphoreProcessOperationStatusState, NSPOS extends NativeSemaphoreProcessOperationStatus<I, NSPOSS>> {
  static final List<NativeSemaphoreProcessOperationStatusState> all = [];

  static int depth(String identifier) {
    int instantiations = 0;
    int opens = 0;
    int locks = 0;
    int unlocks = 0;
    int closes = 0;
    int unlinks = 0;

    for (NativeSemaphoreProcessOperationStatusState status in all) {
      if (status.identifier != identifier) continue;
      switch (status.operation) {
        case NATIVE_SEMAPHORE_OPERATION.instantiate:
          instantiations++;
          break;
        case NATIVE_SEMAPHORE_OPERATION.willAttemptOpenAcrossProcesses:
          opens++;
          break;
        case NATIVE_SEMAPHORE_OPERATION.willAttemptLockAcrossProcesses:
          locks++;
          break;
        case NATIVE_SEMAPHORE_OPERATION.willAttemptUnlockAcrossProcesses:
          unlocks++;
          break;
        case NATIVE_SEMAPHORE_OPERATION.willAttemptCloseAcrossProcesses:
          closes++;
          break;
        case NATIVE_SEMAPHORE_OPERATION.willAttemptUnlinkAcrossProcesses:
          unlinks++;
          break;
        default:
          continue;
      }
    }

    String usage = '''
      Failed to synchronize the semaphore operations. Please ensure reentrant conforms to the following:
      
      String name = 'SEMAPHORE';
      int depth = 4; // i.e. one root process lock and 3 reentrant locks
      final NS sem = NativeSemaphore.instantiate(name: name);
      // Ensure opening and locking before leveraging reentrant/nested locks
      sem..open()..lock();

      // Recursive function to unlock and close the semaphore
      void _recursiveUnlockAndClose(NativeSemaphore sem, int currentDepth) {
        if (currentDepth == 0) return;
        // Be sure to unlock, close, and unlink at the current depth before moving returning up the recursive stack
        sem..unlock()..close()..unlink();
      }

      // Recursive function to open, lock, and then call itself if depth > 0
      void _recursiveOpenAndLock(String name, int currentDepth) {
        final NS sem = NativeSemaphore.instantiate(name: name);
        // Ensure opening and locking before going further into the recursive stack
        sem..open()..lock();

        // Recursive call
        _recursiveOpenAndLock(name, currentDepth - 1);

        // Unlock and close in the reverse order of locking, pass in sem reference
        _recursiveUnlockAndClose(sem, currentDepth);
      }

      _recursiveOpenAndLock(name, depth);
      
      // Be sure to unlock, close, and unlink at the root process level after all reentrant semaphores have been locked and unlocked, etc.
      sem..unlock()..close()..unlink();
      
      
      Here is what this can be visualized as:
      
      Depth: 0        1        2        3        4
      ----------------------------------------------
      instantiate
      open
      lock
                instantiate
                open
                lock
                          instantiate
                          open
                          lock
                                    instantiate
                                    open
                                    lock
                                              instantiate
                                              open
                                              lock
                                              unlock
                                              close
                                              unlink
                                    unlock
                                    close
                                    unlink
                          unlock
                          close
                          unlink
                unlock
                close
                unlink
      unlock
      close
      unlink
    ''';

    ((instantiations + opens) / 2) == instantiations || (throw Exception(usage));
    ((closes + unlinks) / 2) == closes ||
        (throw Exception("Missing ${closes > unlinks ? "reentrant unlink() call" : unlocks > closes ? "reentrant close() call" : "potentially reentrant unlock() call"}" +
            Platform.lineTerminator * 2 +
            usage));

    // print('Statuses: Depth: ${(((instantiations + opens) / 2) - ((closes + unlinks) / 2)).toInt()}  instantiations ${instantiations} opens $opens locks $locks unlocks $unlocks closes $closes unlinks $unlinks');

    return (((instantiations + opens) / 2) - ((closes + unlinks) / 2)).toInt();
  }

  late String Function() tracerFn;

  String get tracer => tracerFn();

  late final I identity;

  late final StreamController<NativeSemaphoreProcessOperationStatusState> _notifications = StreamController<NativeSemaphoreProcessOperationStatusState>(sync: true);

  late final Stream<NativeSemaphoreProcessOperationStatusState> _broadcast = _notifications.stream.asBroadcastStream();

  Stream<NativeSemaphoreProcessOperationStatusState> get notifications => _broadcast;

  late final NSPOS instantiated = NativeSemaphoreProcessOperationStatus<I, NSPOSS>(identity: identity, tracerFn: () => tracer) as NSPOS;

  late final NSPOS opened = NativeSemaphoreProcessOperationStatus<I, NSPOSS>(identity: identity, tracerFn: () => tracer) as NSPOS;

  late final NSPOS locked = NativeSemaphoreProcessOperationStatus<I, NSPOSS>(identity: identity, tracerFn: () => tracer) as NSPOS;

  late final NSPOS unlocked = NativeSemaphoreProcessOperationStatus<I, NSPOSS>(identity: identity, tracerFn: () => tracer) as NSPOS;

  late final NSPOS closed = NativeSemaphoreProcessOperationStatus<I, NSPOSS>(identity: identity, tracerFn: () => tracer) as NSPOS;

  late final NSPOS unlinked = NativeSemaphoreProcessOperationStatus<I, NSPOSS>(identity: identity, tracerFn: () => tracer) as NSPOS;

  NSPOS lookup(NATIVE_SEMAPHORE_OPERATION operation) {
    if (operation.name.toLowerCase().contains('instantiate')) return instantiated;
    if (operation.name.toLowerCase().contains('open')) return opened;
    /* lock has to go below unlock because lock also matches on 'unlock' */
    if (operation.name.toLowerCase().contains('unlock')) return unlocked;
    if (operation.name.toLowerCase().contains('lock')) return locked;
    if (operation.name.toLowerCase().contains('close')) return closed;
    if (operation.name.toLowerCase().contains('unlink')) return unlinked;
    throw Exception('Unknown operation $operation');
  }

  void synchronize({required String hash, required NATIVE_SEMAPHORE_OPERATION operation, dynamic state = null, bool reentrant = false, DateTime? timestamp, ({NSPOS status, NATIVE_SEMAPHORE_OPERATION expected_operation, dynamic expected_state})? verification, R Function<R>(NSPOS status, NATIVE_SEMAPHORE_OPERATION expected_operation, R expected_state)? verifier}) => all.add(lookup(operation).synchronize<I, NSPOSS, NSPOS>(hash: hash, operation: operation, state: state, timestamp: timestamp ?? DateTime.now(), reentrant: reentrant, status: lookup(operation), verification: verification, verifier: verifier ?? verify).synchronizations.last);

  R verify<R>(NSPOS status, NATIVE_SEMAPHORE_OPERATION expected_operation, R expected_state) {
    // if (status.current.isSet && status.current.get.operation != expected_operation) throw Exception('The current operation ${status.current.get.operation} does not match the expected operation $expected_operation previous is ${status.previous.get.operation}.');
    // if (status.current.isSet && status.current.get.state != expected_state) throw Exception('The current state ${status.current.get.state} does not match the expected state $expected_state.');
    return expected_state;
  }

  NativeSemaphoreProcessOperationStatuses({required I this.identity, required String Function() this.tracerFn});
}
