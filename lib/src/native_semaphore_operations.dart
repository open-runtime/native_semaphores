import 'dart:async' show Completer, Future, Stream, StreamController, StreamSubscription;
import 'dart:io' show File, FileMode, Platform, stderr;

import 'package:runtime_native_semaphores/src/utils/XXHash64.dart' show JSON;
import 'utils/list_extensions.dart' show NullableLastWhere;

import 'semaphore_identity.dart' show SemaphoreIdentity;
import 'utils/late_final_property.dart' show LateProperty;

enum NATIVE_SEMAPHORE_OPERATION_STEPS {
  instantiate,
  willAttempt,
  attempting,
  attempted,
  succeeded,
  unknown;

  @override
  String toString() {
    switch (this) {
      case NATIVE_SEMAPHORE_OPERATION_STEPS.instantiate:
        return 'instantiate';
      case NATIVE_SEMAPHORE_OPERATION_STEPS.willAttempt:
        return 'willAttempt';
      /*Case sensitive*/
      case NATIVE_SEMAPHORE_OPERATION_STEPS.attempting:
        return 'attempting';
      case NATIVE_SEMAPHORE_OPERATION_STEPS.attempted:
        return 'attempted';
      case NATIVE_SEMAPHORE_OPERATION_STEPS.succeeded:
        return 'Succeeded';
      /*Case sensitive*/
      default:
        return 'unknown';
    }
  }

  static NATIVE_SEMAPHORE_OPERATION_STEPS fromString(String value) {
    switch (value) {
      case 'instantiate':
        return NATIVE_SEMAPHORE_OPERATION_STEPS.instantiate;
      case 'willAttempt':
        /*Case sensitive*/
        return NATIVE_SEMAPHORE_OPERATION_STEPS.willAttempt;
      case 'attempting':
        return NATIVE_SEMAPHORE_OPERATION_STEPS.attempting;
      case 'attempted':
        return NATIVE_SEMAPHORE_OPERATION_STEPS.attempted;
      case 'Succeeded':
        /*Case sensitive*/
        return NATIVE_SEMAPHORE_OPERATION_STEPS.succeeded;
      default:
        return NATIVE_SEMAPHORE_OPERATION_STEPS.unknown;
    }
  }
}

enum NATIVE_SEMAPHORE_OPERATIONS {
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
      case NATIVE_SEMAPHORE_OPERATIONS.instantiate:
        return 'instantiate()';
      /*Open*/
      case NATIVE_SEMAPHORE_OPERATIONS.open:
        return 'open()';
      case NATIVE_SEMAPHORE_OPERATIONS.willAttemptOpenReentrantToIsolate:
        return 'willAttemptOpenReentrantToIsolate()';
      case NATIVE_SEMAPHORE_OPERATIONS.attemptingOpenReentrantToIsolate:
        return 'attemptingOpenReentrantToIsolate()';
      case NATIVE_SEMAPHORE_OPERATIONS.openReentrantToIsolate:
        return 'openReentrantToIsolate()';
      case NATIVE_SEMAPHORE_OPERATIONS.attemptedOpenReentrantToIsolate:
        return 'attemptedOpenReentrantToIsolate()';
      case NATIVE_SEMAPHORE_OPERATIONS.openAttemptReentrantToIsolateSucceeded:
        return 'openAttemptReentrantToIsolateSucceeded()';
      case NATIVE_SEMAPHORE_OPERATIONS.willAttemptOpenAcrossProcesses:
        return 'willAttemptOpenAcrossProcesses()';
      case NATIVE_SEMAPHORE_OPERATIONS.attemptingOpenAcrossProcesses:
        return 'attemptingOpenAcrossProcesses()';
      case NATIVE_SEMAPHORE_OPERATIONS.openAcrossProcesses:
        return 'openAcrossProcesses()';
      case NATIVE_SEMAPHORE_OPERATIONS.attemptedOpenAcrossProcesses:
        return 'attemptedOpenAcrossProcesses()';
      case NATIVE_SEMAPHORE_OPERATIONS.openAttemptAcrossProcessesSucceeded:
        return 'openAttemptAcrossProcessesSucceeded()';
      /*Lock*/
      case NATIVE_SEMAPHORE_OPERATIONS.lock:
        return 'lock()';
      case NATIVE_SEMAPHORE_OPERATIONS.willAttemptLockReentrantToIsolate:
        return 'willAttemptLockReentrantToIsolate()';
      case NATIVE_SEMAPHORE_OPERATIONS.attemptingLockReentrantToIsolate:
        return 'attemptingLockReentrantToIsolate()';
      case NATIVE_SEMAPHORE_OPERATIONS.lockReentrantToIsolate:
        return 'lockReentrantToIsolate()';
      case NATIVE_SEMAPHORE_OPERATIONS.attemptedLockReentrantToIsolate:
        return 'attemptedLockReentrantToIsolate()';
      case NATIVE_SEMAPHORE_OPERATIONS.lockAttemptReentrantToIsolateSucceeded:
        return 'lockAttemptReentrantToIsolateSucceeded()';
      case NATIVE_SEMAPHORE_OPERATIONS.willAttemptLockAcrossProcesses:
        return 'willAttemptLockAcrossProcesses()';
      case NATIVE_SEMAPHORE_OPERATIONS.attemptingLockAcrossProcesses:
        return 'attemptingLockAcrossProcesses()';
      case NATIVE_SEMAPHORE_OPERATIONS.lockAcrossProcesses:
        return 'lockAcrossProcesses()';
      case NATIVE_SEMAPHORE_OPERATIONS.attemptedLockAcrossProcesses:
        return 'attemptedLockAcrossProcesses()';
      case NATIVE_SEMAPHORE_OPERATIONS.lockAttemptAcrossProcessesSucceeded:
        return 'lockAttemptAcrossProcessesSucceeded()';
      /*Unlock*/
      case NATIVE_SEMAPHORE_OPERATIONS.willAttemptUnlockAcrossProcesses:
        return 'willAttemptUnlockAcrossProcesses()';
      case NATIVE_SEMAPHORE_OPERATIONS.attemptingUnlockAcrossProcesses:
        return 'attemptingUnlockAcrossProcesses()';
      case NATIVE_SEMAPHORE_OPERATIONS.unlockAcrossProcesses:
        return 'unlockAcrossProcesses()';
      case NATIVE_SEMAPHORE_OPERATIONS.attemptedUnlockAcrossProcesses:
        return 'attemptedUnlockAcrossProcesses()';
      case NATIVE_SEMAPHORE_OPERATIONS.unlockAttemptAcrossProcessesSucceeded:
        return 'unlockAttemptAcrossProcessesSucceeded()';
      case NATIVE_SEMAPHORE_OPERATIONS.willAttemptUnlockReentrantToIsolate:
        return 'willAttemptUnlockReentrantToIsolate()';
      case NATIVE_SEMAPHORE_OPERATIONS.attemptingUnlockReentrantToIsolate:
        return 'attemptingUnlockReentrantToIsolate()';
      case NATIVE_SEMAPHORE_OPERATIONS.unlockReentrantToIsolate:
        return 'unlockReentrantToIsolate()';
      case NATIVE_SEMAPHORE_OPERATIONS.attemptedUnlockReentrantToIsolate:
        return 'attemptedUnlockReentrantToIsolate()';
      case NATIVE_SEMAPHORE_OPERATIONS.unlockAttemptReentrantToIsolateSucceeded:
        return 'unlockAttemptReentrantToIsolateSucceeded()';
      /*Close*/
      case NATIVE_SEMAPHORE_OPERATIONS.close:
        return 'close()';
      case NATIVE_SEMAPHORE_OPERATIONS.willAttemptCloseAcrossProcesses:
        return 'willAttemptCloseAcrossProcesses()';
      case NATIVE_SEMAPHORE_OPERATIONS.attemptingCloseAcrossProcesses:
        return 'attemptingCloseAcrossProcesses()';
      case NATIVE_SEMAPHORE_OPERATIONS.closeAcrossProcesses:
        return 'closeAcrossProcesses()';
      case NATIVE_SEMAPHORE_OPERATIONS.attemptedCloseAcrossProcesses:
        return 'attemptedCloseAcrossProcesses()';
      case NATIVE_SEMAPHORE_OPERATIONS.closeAttemptAcrossProcessesSucceeded:
        return 'closeAttemptAcrossProcessesSucceeded()';
      case NATIVE_SEMAPHORE_OPERATIONS.willAttemptCloseReentrantToIsolate:
        return 'willAttemptCloseReentrantToIsolate()';
      case NATIVE_SEMAPHORE_OPERATIONS.attemptingCloseReentrantToIsolate:
        return 'attemptingCloseReentrantToIsolate()';
      case NATIVE_SEMAPHORE_OPERATIONS.closeReentrantToIsolate:
        return 'closeReentrantToIsolate()';
      case NATIVE_SEMAPHORE_OPERATIONS.attemptedCloseReentrantToIsolate:
        return 'attemptedCloseReentrantToIsolate()';
      case NATIVE_SEMAPHORE_OPERATIONS.closeAttemptReentrantToIsolateSucceeded:
        return 'closeAttemptReentrantToIsolateSucceeded()';
      /*Unlink*/
      case NATIVE_SEMAPHORE_OPERATIONS.unlink:
        return 'unlink()';
      case NATIVE_SEMAPHORE_OPERATIONS.willAttemptUnlinkAcrossProcesses:
        return 'willAttemptUnlinkAcrossProcesses()';
      case NATIVE_SEMAPHORE_OPERATIONS.attemptingUnlinkAcrossProcesses:
        return 'attemptingUnlinkAcrossProcesses()';
      case NATIVE_SEMAPHORE_OPERATIONS.unlinkAcrossProcesses:
        return 'unlinkAcrossProcesses()';
      case NATIVE_SEMAPHORE_OPERATIONS.attemptedUnlinkAcrossProcesses:
        return 'attemptedUnlinkAcrossProcesses()';
      case NATIVE_SEMAPHORE_OPERATIONS.unlinkAttemptAcrossProcessesSucceeded:
        return 'unlinkAttemptAcrossProcessesSucceeded()';
      case NATIVE_SEMAPHORE_OPERATIONS.willAttemptUnlinkReentrantToIsolate:
        return 'willAttemptUnlinkReentrantToIsolate()';
      case NATIVE_SEMAPHORE_OPERATIONS.attemptingUnlinkReentrantToIsolate:
        return 'attemptingUnlinkReentrantToIsolate()';
      case NATIVE_SEMAPHORE_OPERATIONS.unlinkReentrantToIsolate:
        return 'unlinkReentrantToIsolate()';
      case NATIVE_SEMAPHORE_OPERATIONS.attemptedUnlinkReentrantToIsolate:
        return 'attemptedUnlinkReentrantToIsolate()';
      case NATIVE_SEMAPHORE_OPERATIONS.unlinkAttemptReentrantToIsolateSucceeded:
        return 'unlinkAttemptReentrantToIsolateSucceeded()';
      default:
        throw Exception('Unknown Native Semaphore Operation');
    }
  }

  static NATIVE_SEMAPHORE_OPERATIONS fromString(String value) {
    switch (value) {
      /*Instantiate */
      case 'instantiate()':
        return NATIVE_SEMAPHORE_OPERATIONS.instantiate;
      /*Open */
      case 'open()':
        return NATIVE_SEMAPHORE_OPERATIONS.open;
      case 'willAttemptOpenReentrantToIsolate()':
        return NATIVE_SEMAPHORE_OPERATIONS.willAttemptOpenReentrantToIsolate;
      case 'attemptingOpenReentrantToIsolate()':
        return NATIVE_SEMAPHORE_OPERATIONS.attemptingOpenReentrantToIsolate;
      case 'openReentrantToIsolate()':
        return NATIVE_SEMAPHORE_OPERATIONS.openReentrantToIsolate;
      case 'attemptedOpenReentrantToIsolate()':
        return NATIVE_SEMAPHORE_OPERATIONS.attemptedOpenReentrantToIsolate;
      case 'openAttemptReentrantToIsolateSucceeded()':
        return NATIVE_SEMAPHORE_OPERATIONS.openAttemptReentrantToIsolateSucceeded;
      case 'willAttemptOpenAcrossProcesses()':
        return NATIVE_SEMAPHORE_OPERATIONS.willAttemptOpenAcrossProcesses;
      case 'attemptingOpenAcrossProcesses()':
        return NATIVE_SEMAPHORE_OPERATIONS.attemptingOpenAcrossProcesses;
      case 'openAcrossProcesses()':
        return NATIVE_SEMAPHORE_OPERATIONS.openAcrossProcesses;
      case 'attemptedOpenAcrossProcesses()':
        return NATIVE_SEMAPHORE_OPERATIONS.attemptedOpenAcrossProcesses;
      case 'openAttemptAcrossProcessesSucceeded()':
        return NATIVE_SEMAPHORE_OPERATIONS.openAttemptAcrossProcessesSucceeded;
      /*Lock */
      case 'lock()':
        return NATIVE_SEMAPHORE_OPERATIONS.lock;
      case 'willAttemptLockReentrantToIsolate()':
        return NATIVE_SEMAPHORE_OPERATIONS.willAttemptLockReentrantToIsolate;
      case 'attemptingLockReentrantToIsolate()':
        return NATIVE_SEMAPHORE_OPERATIONS.attemptingLockReentrantToIsolate;
      case 'lockReentrantToIsolate()':
        return NATIVE_SEMAPHORE_OPERATIONS.lockReentrantToIsolate;
      case 'attemptedLockReentrantToIsolate()':
        return NATIVE_SEMAPHORE_OPERATIONS.attemptedLockReentrantToIsolate;
      case 'lockAttemptReentrantToIsolateSucceeded()':
        return NATIVE_SEMAPHORE_OPERATIONS.lockAttemptReentrantToIsolateSucceeded;
      case 'willAttemptLockAcrossProcesses()':
        return NATIVE_SEMAPHORE_OPERATIONS.willAttemptLockAcrossProcesses;
      case 'attemptingLockAcrossProcesses()':
        return NATIVE_SEMAPHORE_OPERATIONS.attemptingLockAcrossProcesses;
      case 'lockAcrossProcesses()':
        return NATIVE_SEMAPHORE_OPERATIONS.lockAcrossProcesses;
      case 'attemptedLockAcrossProcesses()':
        return NATIVE_SEMAPHORE_OPERATIONS.attemptedLockAcrossProcesses;
      case 'lockAttemptAcrossProcessesSucceeded()':
        return NATIVE_SEMAPHORE_OPERATIONS.lockAttemptAcrossProcessesSucceeded;
      /*Unlock */
      case 'unlock()':
        return NATIVE_SEMAPHORE_OPERATIONS.unlock;
      case 'willAttemptUnlockAcrossProcesses()':
        return NATIVE_SEMAPHORE_OPERATIONS.willAttemptUnlockAcrossProcesses;
      case 'attemptingUnlockAcrossProcesses()':
        return NATIVE_SEMAPHORE_OPERATIONS.attemptingUnlockAcrossProcesses;
      case 'unlockAcrossProcesses()':
        return NATIVE_SEMAPHORE_OPERATIONS.unlockAcrossProcesses;
      case 'attemptedUnlockAcrossProcesses()':
        return NATIVE_SEMAPHORE_OPERATIONS.attemptedUnlockAcrossProcesses;
      case 'unlockAttemptAcrossProcessesSucceeded()':
        return NATIVE_SEMAPHORE_OPERATIONS.unlockAttemptAcrossProcessesSucceeded;
      case 'willAttemptUnlockReentrantToIsolate()':
        return NATIVE_SEMAPHORE_OPERATIONS.willAttemptUnlockReentrantToIsolate;
      case 'attemptingUnlockReentrantToIsolate()':
        return NATIVE_SEMAPHORE_OPERATIONS.attemptingUnlockReentrantToIsolate;
      case 'unlockReentrantToIsolate()':
        return NATIVE_SEMAPHORE_OPERATIONS.unlockReentrantToIsolate;
      case 'attemptedUnlockReentrantToIsolate()':
        return NATIVE_SEMAPHORE_OPERATIONS.attemptedUnlockReentrantToIsolate;
      case 'unlockAttemptReentrantToIsolateSucceeded()':
        return NATIVE_SEMAPHORE_OPERATIONS.unlockAttemptReentrantToIsolateSucceeded;
      /*Close */
      case 'close()':
        return NATIVE_SEMAPHORE_OPERATIONS.close;
      case 'willAttemptCloseAcrossProcesses()':
        return NATIVE_SEMAPHORE_OPERATIONS.willAttemptCloseAcrossProcesses;
      case 'attemptingCloseAcrossProcesses()':
        return NATIVE_SEMAPHORE_OPERATIONS.attemptingCloseAcrossProcesses;
      case 'closeAcrossProcesses()':
        return NATIVE_SEMAPHORE_OPERATIONS.closeAcrossProcesses;
      case 'attemptedCloseAcrossProcesses()':
        return NATIVE_SEMAPHORE_OPERATIONS.attemptedCloseAcrossProcesses;
      case 'closeAttemptAcrossProcessesSucceeded()':
        return NATIVE_SEMAPHORE_OPERATIONS.closeAttemptAcrossProcessesSucceeded;
      case 'willAttemptCloseReentrantToIsolate()':
        return NATIVE_SEMAPHORE_OPERATIONS.willAttemptCloseReentrantToIsolate;
      case 'attemptingCloseReentrantToIsolate()':
        return NATIVE_SEMAPHORE_OPERATIONS.attemptingCloseReentrantToIsolate;
      case 'closeReentrantToIsolate()':
        return NATIVE_SEMAPHORE_OPERATIONS.closeReentrantToIsolate;
      case 'attemptedCloseReentrantToIsolate()':
        return NATIVE_SEMAPHORE_OPERATIONS.attemptedCloseReentrantToIsolate;
      case 'closeAttemptReentrantToIsolateSucceeded()':
        return NATIVE_SEMAPHORE_OPERATIONS.closeAttemptReentrantToIsolateSucceeded;
      /*Unlink */
      case 'unlink()':
        return NATIVE_SEMAPHORE_OPERATIONS.unlink;
      case 'willAttemptUnlinkAcrossProcesses()':
        return NATIVE_SEMAPHORE_OPERATIONS.willAttemptUnlinkAcrossProcesses;
      case 'attemptingUnlinkAcrossProcesses()':
        return NATIVE_SEMAPHORE_OPERATIONS.attemptingUnlinkAcrossProcesses;
      case 'unlinkAcrossProcesses()':
        return NATIVE_SEMAPHORE_OPERATIONS.unlinkAcrossProcesses;
      case 'attemptedUnlinkAcrossProcesses()':
        return NATIVE_SEMAPHORE_OPERATIONS.attemptedUnlinkAcrossProcesses;
      case 'unlinkAttemptAcrossProcessesSucceeded()':
        return NATIVE_SEMAPHORE_OPERATIONS.unlinkAttemptAcrossProcessesSucceeded;
      case 'willAttemptUnlinkReentrantToIsolate()':
        return NATIVE_SEMAPHORE_OPERATIONS.willAttemptUnlinkReentrantToIsolate;
      case 'attemptingUnlinkReentrantToIsolate()':
        return NATIVE_SEMAPHORE_OPERATIONS.attemptingUnlinkReentrantToIsolate;
      case 'unlinkReentrantToIsolate()':
        return NATIVE_SEMAPHORE_OPERATIONS.unlinkReentrantToIsolate;
      case 'attemptedUnlinkReentrantToIsolate()':
        return NATIVE_SEMAPHORE_OPERATIONS.attemptedUnlinkReentrantToIsolate;
      case 'unlinkAttemptReentrantToIsolateSucceeded()':
        return NATIVE_SEMAPHORE_OPERATIONS.unlinkAttemptReentrantToIsolateSucceeded;
      /*Unknown */
      default:
        throw Exception('Unknown Native Semaphore Operation');
    }
  }

  bool isStep(NATIVE_SEMAPHORE_OPERATION_STEPS step) => toString().contains(step.toString());
}

typedef NativeSemaphoreProcessOperationStatusStateSynchronizeFunctionType<I extends SemaphoreIdentity, NSPOSS extends NativeSemaphoreProcessOperationStatusState, NSPOS extends NativeSemaphoreProcessOperationStatus<I, NSPOSS>> = Future<NSPOS> Function<I extends SemaphoreIdentity, NSPOSS extends NativeSemaphoreProcessOperationStatusState, NSPOS extends NativeSemaphoreProcessOperationStatus<I, NSPOSS>>({required String hash, required NATIVE_SEMAPHORE_OPERATIONS operation, dynamic state, DateTime? timestamp, bool reentrant, required NSPOS status, ({NSPOS status, NATIVE_SEMAPHORE_OPERATIONS expected_operation, dynamic expected_state})? verification, R Function<R>(NSPOS status, NATIVE_SEMAPHORE_OPERATIONS expected_operation, R expected_state)? verifier});

class NativeSemaphoreProcessOperationStatusState {
  final String hash;
  final String tracer;
  final String name;
  final String process;
  final String isolate;
  final bool external;

  // TODO external boolean
  String get identifier => [name, isolate, process].join('_');

  final bool reentrant;

  bool waiting = false;

  late final LateProperty<Duration> took = LateProperty<Duration>(name: 'duration', updatable: false);

  late final DateTime timestamp;

  dynamic state;

  NATIVE_SEMAPHORE_OPERATIONS operation;

  LateProperty<bool> completed = LateProperty<bool>(initial: false, name: 'completed', updatable: false);

  /* This will complete with the NativeSemaphoreProcessOperationStatusState that preceded it i.e. if the owner of the completer is attemptingOpenAcrossProcesses then the completer will complete with willAttemptOpenAcrossProcesses */
  /* If it is a succeeded event then it will complete with the initial event that kicked it off i.e. openAttemptAcrossProcessesSucceeded  will complete with willAttemptOpenAcrossProcesses  */
  late Completer<NativeSemaphoreProcessOperationStatusState> completer = Completer<NativeSemaphoreProcessOperationStatusState>();

  NativeSemaphoreProcessOperationStatusState({required NATIVE_SEMAPHORE_OPERATIONS this.operation, DateTime? timestamp, required String this.hash, required bool this.reentrant, required String this.tracer, required String this.name, required String this.process, required String this.isolate, required dynamic this.state, bool this.external = false, bool this.waiting = false}) {
    this.timestamp = timestamp ?? DateTime.now();
  }

  @override
  toString() => 'NativeSemaphoreProcessOperationStatusState(tracer: $tracer, name: $name, process: $process, isolate: $isolate, timestamp: $timestamp, state: $state, operation: $operation, completer.isComplete: ${completer.isCompleted})';

  String get serialized => JSON.encode({
        'operation': operation.toString(),
        'took': took.nullable?.inMilliseconds,
        'waiting': waiting,
        'state': state.toString(),
        'completed': completed.get,
        'tracer': tracer,
        'reentrant': reentrant,
        'hash': hash,
        'name': name,
        'process': process,
        'isolate': isolate,
        'external': external,
        'timestamp': timestamp.toString(),
      });

  persist({required File temp, bool newline = true}) => temp.writeAsStringSync((newline ? Platform.lineTerminator : '') + serialized, mode: FileMode.append, flush: true);
}

class NativeSemaphoreProcessOperationStatus<I extends SemaphoreIdentity, NSPOSS extends NativeSemaphoreProcessOperationStatusState> {
  late final StreamController<NativeSemaphoreProcessOperationStatusState> _controller = StreamController<NativeSemaphoreProcessOperationStatusState>(sync: true);

  late final Stream<NativeSemaphoreProcessOperationStatusState> _broadcast = _controller.stream.asBroadcastStream();

  late final StreamSubscription<NativeSemaphoreProcessOperationStatusState> notifications;

  late final I identity;

  final List<NativeSemaphoreProcessOperationStatusState> synchronizations = [];

  late final void Function(NativeSemaphoreProcessOperationStatusState _state) callback = (NativeSemaphoreProcessOperationStatusState _state) => { print(_state.toString() + _state.tracer)};

  late final void Function(List<NativeSemaphoreProcessOperationStatusState?> _state) finalizer = (List<NativeSemaphoreProcessOperationStatusState?> _state) {};

  late String Function() tracerFn;

  String get tracer => tracerFn();

  late final String name = identity.name.get;
  late final String process = identity.process;
  late final String isolate = identity.isolate;

  Map<String, Future<NativeSemaphoreProcessOperationStatusState>> memoized_completers = {};

  Future<NativeSemaphoreProcessOperationStatusState> getFuture({required NATIVE_SEMAPHORE_OPERATIONS operation, required String hash}) => Future.sync(() => [hash, operation.name].join('_')).then((key) => memoized_completers.containsKey(key) ? memoized_completers[key]! : memoized_completers.putIfAbsent(key, () => _broadcast.firstWhere((NativeSemaphoreProcessOperationStatusState state) => state.hash == hash && state.completed.get)));

  bool persist<I extends SemaphoreIdentity, NSPOSS extends NativeSemaphoreProcessOperationStatusState, NSPOS extends NativeSemaphoreProcessOperationStatus<I, NSPOSS>>({required NSPOSS inbound, ({NSPOSS? previous, NSPOSS? initial})? completed}) {
    // Roll-up?
    print((completed?.previous?.completed.updates.toString() ?? '') + " completed previous updates" + (completed?.previous?.operation.toString() ?? '') + tracer);
    print(inbound.completed.updates.toString() + " completed inbound updates" + inbound.operation.toString() + tracer);
    print((completed?.initial?.completed.updates.toString() ?? '') + " completed initial updates" + (completed?.initial?.operation.toString() ?? '') + tracer);
    print([(completed?.previous == inbound), (completed?.previous == completed?.initial), (completed?.initial == inbound), (completed?.previous), (completed?.initial)]);

    bool newline = !inbound.operation.isStep(NATIVE_SEMAPHORE_OPERATION_STEPS.instantiate);
    completed?.previous?.persist(temp: identity.temp, newline: newline);
    inbound.persist(temp: identity.temp, newline: newline);
    completed?.initial?.persist(temp: identity.temp, newline: newline);

    return true;
  }

  /// Synchronizes the state of semaphore operations, ensuring correct tracking and completion of each operation.
  ///
  /// This method manages the lifecycle of semaphore operations by creating a new status state for each operation,
  /// adding it to the list of synchronizations, and handling the completion of previous operations. It supports
  /// various semaphore operations such as instantiate, open, lock, unlock, close, and unlink, including their
  /// reentrant and cross-process variants.
  ///
  /// The method ensures that operations are marked as completed when appropriate, and it updates the state
  /// transitions accordingly. For operations that end with "Succeeded", it finds the initial status state that
  /// started the operation and marks it as completed. For "instantiate" operations, it marks the status state
  /// as completed immediately. This synchronization mechanism is crucial for maintaining the integrity and
  /// consistency of semaphore operations, especially in complex scenarios involving nested or reentrant operations.
  ///
  /// - **hash:** The unique operation identifier.
  /// - **operation:** The type of semaphore operation.
  /// - **state:** Optional state associated with the operation.
  /// - **reentrant:** Whether the operation is reentrant (default: false).
  /// - **timestamp:** Optional timestamp of the operation.
  /// - **status:** The current operation status.
  /// - **verification:** An optional verification function.
  /// - **verifier:** An optional verifier function.

  /// Returns the provided [status] after synchronization.
  NSPOS synchronize<I extends SemaphoreIdentity, NSPOSS extends NativeSemaphoreProcessOperationStatusState, NSPOS extends NativeSemaphoreProcessOperationStatus<I, NSPOSS>>({
    required String hash,
    required NATIVE_SEMAPHORE_OPERATIONS operation,
    dynamic state = null,
    bool reentrant = false,
    DateTime? timestamp,
    required NSPOS status,
    /*({NSPOS status, NATIVE_SEMAPHORE_OPERATIONS expected_operation, dynamic expected_state})? verification, R Function<R>(NSPOS status, NATIVE_SEMAPHORE_OPERATIONS expected_operation, R expected_state)? verifier*/
  }) {
    NSPOSS inbound_status_state = NativeSemaphoreProcessOperationStatusState(tracer: tracer, name: name, process: process, isolate: isolate, operation: operation, hash: hash, state: state, reentrant: reentrant, waiting: /*for attemptingLockAcrossProcesses waiting is effectively true*/ operation == NATIVE_SEMAPHORE_OPERATIONS.attemptingLockAcrossProcesses && state is bool && /* state is false */ !state) as NSPOSS;

    NSPOSS? completable_previous_status_state = synchronizations.nullableLastSatisfies<NSPOSS?>((synchronization) => synchronization?.hash == hash && !(synchronization?.completed.isSet ?? true) && !(synchronization?.completed.get ?? true)) ?? synchronizations.nullableLastWhere<NSPOSS?>((synchronization) => synchronization.hash == hash && !synchronization.completed.isSet && !synchronization.completed.get);

    NSPOSS? completed_initial_status_state;

    synchronizations.add(inbound_status_state);
    _controller.add(inbound_status_state);

    if (completable_previous_status_state == null || completable_previous_status_state != inbound_status_state) {
      if (completable_previous_status_state is NSPOSS) {
        // Add the completed status first
        completable_previous_status_state.completed.set(true);
        memoized_completers.putIfAbsent([hash, completable_previous_status_state.operation.name].join('_'), () => completable_previous_status_state.completer.future);

        if (completable_previous_status_state.operation.isStep(NATIVE_SEMAPHORE_OPERATION_STEPS.willAttempt))
          inbound_status_state.took.set(DateTime.now().difference(completable_previous_status_state.timestamp));

        if (completable_previous_status_state.operation.isStep(NATIVE_SEMAPHORE_OPERATION_STEPS.attempting))
          inbound_status_state.took.set(DateTime.now().difference(completable_previous_status_state.timestamp));

        inbound_status_state.persist(temp: identity.temp);

        // Add the completed previous status state to the controller
        completable_previous_status_state.persist(temp: identity.temp);
        completable_previous_status_state.completer.complete(inbound_status_state);
        _controller.add(completable_previous_status_state);
      }

      memoized_completers.putIfAbsent([hash, inbound_status_state.operation.name].join('_'), () => inbound_status_state.completer.future);

      if (inbound_status_state.operation.isStep(NATIVE_SEMAPHORE_OPERATION_STEPS.instantiate)) {
        inbound_status_state.completed.set(true);
        inbound_status_state.took.set(DateTime.now().difference(inbound_status_state.timestamp));
        // if it is the initial state then complete it immediately with itself
        inbound_status_state.persist(temp: identity.temp, newline: false);
        inbound_status_state.completer.complete(inbound_status_state);
        _controller.add(/* i.e. instantiated */ inbound_status_state);
      }

      if (inbound_status_state.operation.isStep(NATIVE_SEMAPHORE_OPERATION_STEPS.succeeded)) {
        NSPOSS? __completed_initial_status_state = synchronizations.nullableLastSatisfies<NSPOSS?>((synchronization) => synchronization?.hash == hash && (synchronization?.operation.isStep(NATIVE_SEMAPHORE_OPERATION_STEPS.willAttempt) ?? false)) ?? synchronizations.nullableLastWhere<NSPOSS?>((synchronization) => synchronization.hash == hash && synchronization.operation.isStep(NATIVE_SEMAPHORE_OPERATION_STEPS.willAttempt));

        if (__completed_initial_status_state is NSPOSS && __completed_initial_status_state != inbound_status_state) {
          /* i.e. willAttempt*/ completed_initial_status_state = __completed_initial_status_state;
          inbound_status_state.completed.set(true);
          inbound_status_state.took.set(inbound_status_state.timestamp.difference(completed_initial_status_state.timestamp));
          inbound_status_state.persist(temp: identity.temp);
          inbound_status_state.completer.complete(inbound_status_state);
          _controller.add( /* i.e. AttemptSucceeded */inbound_status_state);
        }
      }
    }

    return status;
  }

  Map<String, bool> memoized_completions = {};

  bool isCompleted({required String hash, required List<NATIVE_SEMAPHORE_OPERATIONS> operations}) {
    String key = [hash, ...operations.map((operation) => operation.name)].join('_');

    if (memoized_completions.containsKey(key) && memoized_completions[hash] is bool) return memoized_completions[hash]!;

    Iterable<NativeSemaphoreProcessOperationStatusState> completions = synchronizations.where((status) {
      return status.hash == hash && operations.any((operation) => status.operation == operation) && status.completed.get;
    });

    bool _completed = completions.isNotEmpty && completions.every((status) => status.completed.get);

    return _completed ? memoized_completions.putIfAbsent(key, () => _completed) : _completed;
  }

  Map<String, bool> memoized_reentrancies = {};

  bool isReentrant({required String hash, required int depth}) {
    String key = [hash, NATIVE_SEMAPHORE_OPERATIONS.instantiate.name].join('_');
    if (memoized_reentrancies.containsKey(key) && memoized_reentrancies[hash] is bool) return memoized_reentrancies[hash]!;

    Iterable<NativeSemaphoreProcessOperationStatusState> reentrancies = synchronizations.where((status) {
      return status.operation == NATIVE_SEMAPHORE_OPERATIONS.instantiate && status.completed.get;
    });

    bool _completed = (reentrancies.length > 1 && depth > 0) && reentrancies.isNotEmpty && reentrancies.every((status) => status.completed.get);
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
        case NATIVE_SEMAPHORE_OPERATIONS.instantiate:
          instantiations++;
          break;
        case NATIVE_SEMAPHORE_OPERATIONS.willAttemptOpenAcrossProcesses:
          opens++;
          break;
        case NATIVE_SEMAPHORE_OPERATIONS.willAttemptLockAcrossProcesses:
          locks++;
          break;
        case NATIVE_SEMAPHORE_OPERATIONS.willAttemptUnlockAcrossProcesses:
          unlocks++;
          break;
        case NATIVE_SEMAPHORE_OPERATIONS.willAttemptCloseAcrossProcesses:
          closes++;
          break;
        case NATIVE_SEMAPHORE_OPERATIONS.willAttemptUnlinkAcrossProcesses:
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

  NSPOS lookup(NATIVE_SEMAPHORE_OPERATIONS operation) {
    if (operation.name.toLowerCase().contains('instantiate')) return instantiated;
    if (operation.name.toLowerCase().contains('open')) return opened;
    /* lock has to go below unlock because lock also matches on 'unlock' */
    if (operation.name.toLowerCase().contains('unlock')) return unlocked;
    if (operation.name.toLowerCase().contains('lock')) return locked;
    if (operation.name.toLowerCase().contains('close')) return closed;
    if (operation.name.toLowerCase().contains('unlink')) return unlinked;
    throw Exception('Unknown operation $operation');
  }

  void synchronize({
    required String hash,
    required NATIVE_SEMAPHORE_OPERATIONS operation,
    dynamic state = null,
    bool reentrant = false,
    DateTime? timestamp,
    /*({NSPOS status, NATIVE_SEMAPHORE_OPERATION expected_operation, dynamic expected_state})? verification, R Function<R>(NSPOS status, NATIVE_SEMAPHORE_OPERATION expected_operation, R expected_state)? verifier*/
  }) =>
      all.add(lookup(operation)
          .synchronize<I, NSPOSS, NSPOS>(
            hash: hash,
            operation: operation,
            state: state,
            timestamp: timestamp ?? DateTime.now(),
            reentrant: reentrant,
            status: lookup(operation), /*verification: verification, verifier: verifier ?? verify*/
          )
          .synchronizations
          .last);

  // R verify<R>(NSPOS status, NATIVE_SEMAPHORE_OPERATION expected_operation, R expected_state) {
  //   // if (status.current.isSet && status.current.get.operation != expected_operation) throw Exception('The current operation ${status.current.get.operation} does not match the expected operation $expected_operation previous is ${status.previous.get.operation}.');
  //   // if (status.current.isSet && status.current.get.state != expected_state) throw Exception('The current state ${status.current.get.state} does not match the expected state $expected_state.');
  //   return expected_state;
  // }

  NativeSemaphoreProcessOperationStatuses({required I this.identity, required String Function() this.tracerFn});
}
