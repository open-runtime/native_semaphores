import 'dart:async' show Completer, Future, FutureOr, Stream, StreamController, StreamSubscription;
import 'dart:ffi' show Finalizable;
import 'dart:io' show File, FileSystemEntity, Platform, stderr;

import 'package:meta/meta.dart' show protected;
import 'package:runtime_native_semaphores/src/persisted_native_semaphore_metadata.dart' show PersistedNativeSemaphoreAccessor, PersistedNativeSemaphoreMetadata;
import '../runtime_native_semaphores.dart'
    show
        LatePropertyAssigned,
        SemaphoreCount,
        SemaphoreCountDeletion,
        SemaphoreCountUpdate,
        SemaphoreCounter,
        SemaphoreCounters,
        SemaphoreCounts,
        SemaphoreIdentities,
        SemaphoreIdentity,
        UnixSemaphore,
        WindowsSemaphore;
import 'persisted_native_semaphore_operation.dart' show NATIVE_SEMAPHORE_OPERATION, PersistedNativeSemaphoreOperation, PersistedNativeSemaphoreOperations;

// A wrapper to track the instances of the native semaphore
class NativeSemaphores<
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
    NSPOSES extends NativeSemaphoreProcessOperationStatuses<I, NSPOSS, NSPOS>,
    NS extends NativeSemaphore<I, IS, CU, CD, CT, CTS, CTR, CTRS, PNSO, PNSOS, PNSA, NSPOSS, NSPOS, NSPOSES>> {
  static final Map<String, dynamic> __instantiations = {};

  final Map<String, dynamic> _instantiations = NativeSemaphores.__instantiations;

  Map<String, dynamic> get all => Map.unmodifiable(_instantiations);

  bool has<T>({required String name}) => _instantiations.containsKey(name) && _instantiations[name] is T;

  // Returns the semaphore identity for the given identifier as a singleton
  NS get({required String name}) => _instantiations[name] ?? (throw Exception('Failed to get semaphore counter for $name. It doesn\'t exist.'));

  NS register({required String name, required NS semaphore}) {
    (_instantiations.containsKey(name) || semaphore != _instantiations[name]) ||
        (throw Exception('Failed to register semaphore counter for $name. It already exists or is not the same as the inbound identity being passed.'));

    return _instantiations.putIfAbsent(name, () => semaphore);
  }

  void delete({required String name}) {
    _instantiations.containsKey(name) || (throw Exception('Failed to delete semaphore counter for $name. It doesn\'t exist.'));
    _instantiations.remove(name);
  }

  String toString() => 'NativeSemaphores(all: ${all.toString()})';
}

class NativeSemaphore<
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
    NSPOSS extends NativeSemaphoreProcessOperationStatusState,
    NSPOS extends NativeSemaphoreProcessOperationStatus<I, NSPOSS>,
    NSPOSES extends NativeSemaphoreProcessOperationStatuses<I, NSPOSS, NSPOS>> implements Finalizable {
  static late final dynamic __semaphores;

  late PNSOS _operations;

  ({bool isSet, PNSOS? get}) get operations => LatePropertyAssigned<PNSOS>(() => _operations) ? (isSet: true, get: _operations) : (isSet: false, get: null);

  late PNSO _operation;

  ({bool isSet, PNSO? get}) get operation => LatePropertyAssigned<PNSO>(() => _operation) ? (isSet: true, get: _operation) : (isSet: false, get: null);

  late final NSPOSES statuses = NativeSemaphoreProcessOperationStatuses<I, NSPOSS, NSPOS>(identity: identity) as NSPOSES;

  NativeSemaphore<I, IS, CU, CD, CT, CTS, CTR, CTRS, PNSO, PNSOS, PNSA, NSPOSS, NSPOS, NSPOSES> all<
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
          NSPOSS extends NativeSemaphoreProcessOperationStatusState,
          NSPOS extends NativeSemaphoreProcessOperationStatus<I, NSPOSS>,
          NSPOSES extends NativeSemaphoreProcessOperationStatuses<I, NSPOSS, NSPOS>,
          NS extends NativeSemaphore<I, IS, CU, CD, CT, CTS, CTR, CTRS, PNSO, PNSOS, PNSA, NSPOSS, NSPOS, NSPOSES>>() =>
      __semaphores;

  // Log Stream for the semaphore
  final StreamController<String> logs = StreamController<String>();

  bool verbose;

  late final CTR counter;

  I get identity => counter.identity;

  bool waiting = false;

  @protected
  Map<String, PNSO> preceeding = {};

  Map<String, PNSA> predecessors = {};

  @protected
  late final bool hasOpened;

  // If the semaphore has been opened
  bool get opened => LatePropertyAssigned<bool>(() => hasOpened) ? hasOpened : false;

  // If the semaphore is currently open
  bool get isOpen => opened && !closed && !unlinked;

  // If the semaphore is currently locked
  bool get locked {
    int isolates = counter.counts.isolate.get();
    int processes = counter.counts.process.get();
    return isolates > 0 || processes > 0;
  }

  // If the semaphore is currently reentrant
  bool get reentrant => counter.counts.isolate.get() > 1;

  // If the semaphore is currently locked (helper getter for api alignment)
  bool get isLocked => locked;

  @protected
  late final bool hasUnlocked;

  bool get unlocked => LatePropertyAssigned<bool>(() => hasUnlocked) ? hasUnlocked : false;

  // If the semaphore is currently unlocked
  bool isUnlocked() => unlocked;

  @protected
  late final bool hasClosed;

  // If the semaphore has been closed
  bool get closed => LatePropertyAssigned<bool>(() => hasClosed) ? hasClosed : false;

  // If the semaphore is currently closed
  bool get isClosed => !locked && closed;

  @protected
  late final bool hasUnlinked;

  // If the semaphore has been unlinked
  bool get unlinked => LatePropertyAssigned<bool>(() => hasUnlinked) ? closed && hasUnlinked : false;

  // If the semaphore is currently unlinked
  bool get isUnlinked => isClosed && unlinked;

  NativeSemaphore({required CTR this.counter, this.verbose = false});

  // TODO maybe a rehydrate method? or instantiate takes in a "from process" flag i.e. to attempt to find and rehydrate the semaphore from another process/all processes
  static NativeSemaphore<I, IS, CU, CD, CT, CTS, CTR, CTRS, PNSO, PNSOS, PNSA, NSPOSS, NSPOS, NSPOSES> instantiate<
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
          NSPOSES extends NativeSemaphoreProcessOperationStatuses<I, NSPOSS, NSPOS>,
          NS extends NativeSemaphore<I, IS, CU, CD, CT, CTS, CTR, CTRS, PNSO, PNSOS, PNSA, NSPOSS, NSPOS, NSPOSES>,
          NSS extends NativeSemaphores<I, IS, CU, CD, CT, CTS, CTR, CTRS, PNSO, PNSOS, PNSA, PNSM, NSPOSS, NSPOS, NSPOSES, NS>>(
      {required String name, String tracer = '', I? identity, CTR? counter, bool verbose = false}) {
    if (!LatePropertyAssigned<NSS>(() => __semaphores)) {
      __semaphores = NativeSemaphores<I, IS, CU, CD, CT, CTS, CTR, CTRS, PNSO, PNSOS, PNSA, PNSM, NSPOSS, NSPOS, NSPOSES, NS>();
      if (verbose) print('Setting NativeSemaphore._instances: ${__semaphores.toString()}');
    }

    return (__semaphores as NSS).has<NS>(name: name)
        ? ((__semaphores as NSS).get(name: name)..identity.tracer = tracer)
        : (__semaphores as NSS).register(
            name: name,
            semaphore: Platform.isWindows
                ? WindowsSemaphore(
                    counter: counter ??
                        SemaphoreCounter.instantiate<I, CU, CD, CT, CTS, CTR, CTRS>(
                          identity: identity ??
                              SemaphoreIdentity.instantiate<I, IS>(
                                tracer: tracer,
                                name: name,
                                verbose: verbose,
                              ) as I,
                        ),
                    verbose: verbose,
                  ) as NS
                : UnixSemaphore(
                    counter: counter ??
                        SemaphoreCounter.instantiate<I, CU, CD, CT, CTS, CTR, CTRS>(
                          identity: identity ??
                              SemaphoreIdentity.instantiate<I, IS>(
                                tracer: tracer,
                                name: name,
                                verbose: verbose,
                              ) as I,
                        ) as CTR,
                    verbose: verbose,
                  ) as NS,
          );
  }

  // TLDR - Synchronize the semaphore identity across the OS
  // This function will effectively create additional semaphore identities on it's __instances property
  // Synchronize should be called right after the semaphore has acquired the lock across processes i.e. in lockAttemptAcrossProcessesSucceeded() to prevent race conditions - if it is only called after the lock is acquired then the holding process of the lock should be
  // safe to update the file as no other locks currently have the lock
  bool synchronize() {
    // Find the temp directory for the semaphore name and list all of it's child files
    final List<FileSystemEntity> files = identity.cache.listSync(recursive: false).toList();

    identity.tracer == operation.get?.tracer || (throw Exception('The tracer ${identity.tracer} does not match the operation tracer ${operation.get?.tracer}.'));

    List<({String tracer, NATIVE_SEMAPHORE_OPERATION operation, DateTime created, String process})> accessors = [];

    // List each of the files
    // the file names are as follows process_4535_isolate_495686829.semaphore
    // We rehydrate all persisted operations from other semaphore processes
    // We sort them based on the timestamp of the operation i.e. last operation is the most recent
    // we really only care about the last operations where the operation was willAttemptLockAcrossProcesses, lockAcrossProcesses, or lockAttemptAcrossProcessesSucceeded,
    List<PNSO> from_cache = files
        .where((file) => !file.path.contains(identity.process) && !file.path.contains(identity.isolate))
        .map((file) =>
            PersistedNativeSemaphoreOperations.rehydrate<PNSO, PNSOS>(serialized: File(file.path).readAsStringSync(), rehydrate_: PersistedNativeSemaphoreOperation.rehydrate)
                .iterable
                .last)
        .toList()
      ..sort((PNSO a, PNSO b) => b.created.compareTo(a.created));

    for (final (int index, PNSO __operation) in from_cache
        .where((__operation) =>
            operation.get!.created.isAfter(__operation.created) &&
            operation.get?.operation == NATIVE_SEMAPHORE_OPERATION.willAttemptLockAcrossProcesses &&
            (__operation.operation == NATIVE_SEMAPHORE_OPERATION.willAttemptLockAcrossProcesses ||
                __operation.operation == NATIVE_SEMAPHORE_OPERATION.lockAttemptAcrossProcessesSucceeded))
        .indexed) {
      if (__operation.name != identity.name) throw Exception('The semaphore name ${__operation.name} does not match the current semaphore name ${identity.name}.');

      CTR _counter = counter.track<I, CU, CD, CT, CTS, CTR, CTRS>(
        identity: identity.track<I, IS>(
          tracer: __operation.tracer,
          name: __operation.name,
          process: __operation.process,
          isolate: __operation.isolate,
          verbose: false,
        ) as I,
        counts: __operation.counts,
        verbose: false,
      ) as CTR;

      logs.add(
          'DEBUG: NativeSemaphore [synchronize()] Tracer: ${__operation.tracer}: Process: ${__operation.process} | Isolate: ${__operation.isolate} | Operation: ${__operation.operation} | Created: ${__operation.created} | Locked: ${__operation.locked} | Waiting: ${__operation.waiting} | Unlocked: ${__operation.unlinked} | Closed: ${__operation.closed} | Unlinked: ${__operation.unlinked}');

      preceeding.putIfAbsent(__operation.identifier, () => __operation);
      preceeding[__operation.identifier] = __operation;
    }

    for (final (int index, PNSO __operation) in (preceeding.values.toList()..sort((PNSO a, PNSO b) => b.created.compareTo(a.created))).indexed) {
      predecessors[__operation.identifier] = PersistedNativeSemaphoreAccessor(
        operation: __operation.operation,
        elapsed: operation.get!.created.difference(__operation.created),
        identifier: __operation.identifier,
        tracer: __operation.tracer,
        isolate: __operation.isolate,
        process: __operation.process,
        address: __operation.address,
        opened: __operation.opened,
        unlocked: __operation.unlocked,
        waiting: __operation.waiting,
        locked: __operation.locked,
        closed: __operation.closed,
        reentrant: __operation.reentrant,
        unlinked: __operation.unlinked,
        position: index,
      ) as PNSA;
    }

    logs.add(
        'NOTIFICATION: Predecessors ${predecessors.values.toList().map((PNSA __accessor) => 'waiting_on: [${__accessor.tracer}] ${identity.identifier} ${__accessor.identifier} at position: [${__accessor.position}] for duration: [${__accessor.elapsed.inMilliseconds / 1000}]s').join(' | ')}');

    return true;
  }

  @protected
  bool willAttemptPersist() {
    if (verbose) print('Evaluating [willAttemptPersist()] will persist NativeSemaphore metadata to disk at PATH: [${identity.temp.path}]');

    _operations = PersistedNativeSemaphoreOperations.rehydrate<PNSO, PNSOS>(
        serialized: identity.temp.readAsStringSync(), rehydrate_: PersistedNativeSemaphoreOperation.rehydrate, verbose: verbose);

    // TODO maybe some checks here?
    if (verbose)
      print(
          '[willAttemptPersist()] Total Operations on PersistedNativeSemaphoreOperations: ${_operations.iterable.length}' /*[${Platform.lineTerminator}${operations.get?.iterable.map((operation) => operation.toString()).join(','+Platform.lineTerminator)} ${Platform.lineTerminator}] ${Platform.lineTerminator}*/);

    return true;
  }

  @protected
  bool persist({required NATIVE_SEMAPHORE_OPERATION status, bool sync = false}) {
    if (!willAttemptPersist()) return false;

    if (verbose) print('[persist()] Persisting name: ${identity.name} tracer: ${identity.tracer} with status: ${status}');

    DateTime created = DateTime.now();

    logs.add('STATE: ${identity.tracer} opened: $opened, locked: $locked, unlocked: $unlocked, closed: $closed, reentrant: $reentrant, unlinked: $unlinked, waiting: $waiting');

    // logs.add(
    //     'DEBUG: ${identity.tracer} operation: $status opened: $opened, locked: $locked, unlocked: $unlocked, closed: $closed, reentrant: $reentrant, unlinked: $unlinked, waiting: $waiting');

    identity.temp.writeAsStringSync(
        (_operations
              ..add(
                  operation: _operation = PersistedNativeSemaphoreOperation(
                      name: identity.name,
                      tracer: identity.tracer,
                      identifier: identity.identifier,
                      isolate: identity.isolate,
                      process: identity.process,
                      operation: status,
                      created: created,
                      address: opened ? identity.address : -1,
                      elapsed: operation.isSet ? created.difference(operation.get!.created) : null,
                      verbose: verbose,
                      counts: (isolate: counter.counts.isolate.get(), process: counter.counts.process.get()),
                      opened: opened,
                      unlocked: unlocked,
                      locked: locked,
                      closed: closed,
                      reentrant: reentrant,
                      unlinked: unlinked,
                      waiting: waiting) as PNSO))
            .serialize(),
        flush: true);

    return persistAttemptSucceeded() && sync ? synchronize() : true;
  }

  @protected
  bool persistAttemptSucceeded() {
    if (verbose) print('[persistAttemptSucceeded()] Successfully persisted NativeSemaphore metadata to disk at location ${identity.temp.path}');

    bool returnable = identity.temp.readAsStringSync() == _operations.serialize() &&
            _operations.toString() ==
                PersistedNativeSemaphoreOperations.rehydrate<PNSO, PNSOS>(serialized: identity.temp.readAsStringSync(), rehydrate_: PersistedNativeSemaphoreOperation.rehydrate)
                    .toString() ||
        (throw Exception('Failed to persist NativeSemaphore metadata to disk. Operations are not the same.'));

    return returnable;
  }

  @protected
  bool willAttemptOpen() => throw UnimplementedError();

  @protected
  bool openAttemptSucceeded() => throw UnimplementedError();

  bool open() => throw UnimplementedError();

  // Returns a boolean condition
  @protected
  bool willAttemptLockReentrantToIsolate() => throw UnimplementedError();

  @protected
  bool lockReentrantToIsolate() => throw UnimplementedError();

  @protected
  bool lockAttemptReentrantToIsolateSucceeded() => throw UnimplementedError();

  @protected
  bool willAttemptLockAcrossProcesses() => throw UnimplementedError();

  @protected
  bool lockAcrossProcesses({bool blocking = true, Duration? timeout}) => throw UnimplementedError();

  @protected
  bool lockAttemptAcrossProcessesSucceeded({required int attempt}) => throw UnimplementedError();

  @protected
  bool willAttemptUnlockAcrossProcesses() => throw UnimplementedError();

  @protected
  bool unlockAcrossProcesses() => throw UnimplementedError();

  @protected
  bool unlockAttemptAcrossProcessesSucceeded({required int attempt}) => throw UnimplementedError();

  bool lock({bool blocking = true}) => throw UnimplementedError();

  Future<bool> lockWithDelay({bool blocking = true, Duration? delay, FutureOr Function()? before, FutureOr Function()? after}) async => throw UnimplementedError();

  @protected
  bool willAttemptUnlockReentrantToIsolate() => throw UnimplementedError();

  @protected
  bool unlockReentrantToIsolate() => throw UnimplementedError();

  @protected
  bool unlockAttemptReentrantToIsolateSucceeded() => throw UnimplementedError();

  bool unlock() => throw UnimplementedError();

  Future<bool> unlockWithDelay({Duration? delay, FutureOr Function()? before, FutureOr Function()? after}) async => throw UnimplementedError();

  @protected
  bool willAttemptClose() => throw UnimplementedError();

  @protected
  bool closeAttemptSucceeded({required int attempt}) => throw UnimplementedError();

  bool close() => throw UnimplementedError();

  @protected
  bool willAttemptUnlink() => throw UnimplementedError();

  // Unlinked will be internal as there is no such thing as unlinking on Windows
  @protected
  bool unlinkAttemptSucceeded({required int attempt}) => throw UnimplementedError();

  bool unlink() => throw UnimplementedError();

  String toString() => throw UnimplementedError();
}

class NativeSemaphoreProcessOperationStatusState {
  final Completer<NativeSemaphoreProcessOperationStatusState> completer = Completer<NativeSemaphoreProcessOperationStatusState>();

  final FutureOr<void> Function(NativeSemaphoreProcessOperationStatusState event)? callback;
  void Function(NativeSemaphoreProcessOperationStatusState _state)? finalizer;

  late final StreamController<NativeSemaphoreProcessOperationStatusState> _controller = StreamController<NativeSemaphoreProcessOperationStatusState>(sync: true);

  late final Stream<NativeSemaphoreProcessOperationStatusState> _broadcast =
      _controller.stream.asBroadcastStream();

  late final StreamSubscription<NativeSemaphoreProcessOperationStatusState> notifications;

  final String tracer;
  final String name;
  final String process;
  final String isolate;

  late final bool _completed;

  ({bool isSet, bool? get}) get completed =>
      LatePropertyAssigned<bool>(() => _completed) ? (isSet: true, get: _completed) : (isSet: false, get: null);

  // late Completer<NativeSemaphoreProcessOperationStatusState> _completer;
  //
  // ({bool isSet, Completer<NativeSemaphoreProcessOperationStatusState>? get}) get completer =>
  //     LatePropertyAssigned<Completer<NativeSemaphoreProcessOperationStatusState>>(() => _completer) ? (isSet: true, get: _completer) : (isSet: false, get: null);

  late List<({DateTime timestamp, dynamic value, Completer<NativeSemaphoreProcessOperationStatusState> completer})> synchronizations = [];

  late DateTime timestamp;

  late final Duration took;

  dynamic value;

  late final NATIVE_SEMAPHORE_OPERATION _operation;

  ({bool isSet, NATIVE_SEMAPHORE_OPERATION? get}) get operation =>
      LatePropertyAssigned<NATIVE_SEMAPHORE_OPERATION>(() => _operation) ? (isSet: true, get: _operation) : (isSet: false, get: null);

  NativeSemaphoreProcessOperationStatusState(
      {required String this.tracer,
      required String this.name,
      required String this.process,
      required String this.isolate,
      required void Function(NativeSemaphoreProcessOperationStatusState _state) this.callback,
      void Function(NativeSemaphoreProcessOperationStatusState _state)? this.finalizer}) {
    notifications = _broadcast.listen(callback, onError: stderr.writeln, onDone: () => finalizer is Function ? finalizer!(this) : null, cancelOnError: true);
  }

  Future<NSPOS> synchronize<I extends SemaphoreIdentity, NSPOSS extends NativeSemaphoreProcessOperationStatusState, NSPOS extends NativeSemaphoreProcessOperationStatus<I, NSPOSS>>({required NATIVE_SEMAPHORE_OPERATION operation, dynamic value = null, DateTime? timestamp, required NSPOS status, ({NSPOS status , NATIVE_SEMAPHORE_OPERATION expected_operation, dynamic expected_value})? verification, R Function<R>(NSPOS status ,NATIVE_SEMAPHORE_OPERATION expected_operation, R expected_value)? verifier}) {
    if(this.operation.isSet && _operation != operation) throw Exception('The operation $operation is set and does not match the current operation $_operation.');
    !this.operation.isSet ? _operation = operation : null;

    synchronizations.add((timestamp: timestamp ?? DateTime.now(), value: value, completer: Completer<NativeSemaphoreProcessOperationStatusState>()));

    //  TODO add completer here?
    _controller.add(this..timestamp = synchronizations.last.timestamp..value = synchronizations.last.value);

    // print('$tracer ${operation} $isolate Synchronizations Length: ${synchronizations.length}');
    // TODO resolve previous state when the value is true and
    // print('$tracer Synchronized: ${operation} $isolate $value ${synchronizations.length}');

    if(verification != null && verifier != null) verifier(verification.status, verification.expected_operation, verification.expected_value);
    return Future.value(status);
  }

  Future<NSPOS> complete<I extends SemaphoreIdentity, NSPOSS extends NativeSemaphoreProcessOperationStatusState, NSPOS extends NativeSemaphoreProcessOperationStatus<I, NSPOSS>>({required NATIVE_SEMAPHORE_OPERATION operation, dynamic value = null, DateTime? timestamp, required NSPOS status, ({NSPOS status , NATIVE_SEMAPHORE_OPERATION expected_operation, dynamic expected_value})? verification, R Function<R>(NSPOS status ,NATIVE_SEMAPHORE_OPERATION expected_operation, R expected_value)? verifier}) async {
    completed.isSet && completed.get is bool ? throw Exception('$tracer The operation $operation is already completed. ${synchronizations.length}') : _completed = true;
    print('$tracer Completing: ${operation} $isolate $value ${timestamp?.minute.toString()}m ${timestamp?.second.toString()}s  ${timestamp?.millisecond.toString()}ms');
    if (_controller.isClosed) throw Exception('$tracer The controller is closed.');
    if (completer.isCompleted) throw Exception('$tracer The completer is completed.');
    synchronize(operation: operation, value: value, timestamp: timestamp, status: status, verification: verification, verifier: verifier);
    await Future.wait([(completer..complete(this)).future, _controller.close(), notifications.cancel()]);
    return status;
  }

  @override
  toString() =>
      'NativeSemaphoreProcessOperationStatusState(tracer: $tracer, name: $name, process: $process, isolate: $isolate, timestamp: $timestamp, value: $value, operation: $operation, completer.isComplete: ${completer.isCompleted}, controller.isClosed: ${_controller.isClosed})';
}

class NativeSemaphoreProcessOperationStatus<I extends SemaphoreIdentity, NSPOSS extends NativeSemaphoreProcessOperationStatusState> {
  late final I identity;

  late NativeSemaphoreProcessOperationStatusState _previous;

  ({bool isSet, NativeSemaphoreProcessOperationStatusState? get}) get previous =>
      LatePropertyAssigned<NativeSemaphoreProcessOperationStatusState>(() => _previous) ? (isSet: true, get: _previous) : (isSet: false, get: null);

  late NativeSemaphoreProcessOperationStatusState _current;

  ({bool isSet, NativeSemaphoreProcessOperationStatusState? get}) get current =>
      LatePropertyAssigned<NativeSemaphoreProcessOperationStatusState>(() => _current) ? (isSet: true, get: _current) : (isSet: false, get: null);

  late final void Function(NativeSemaphoreProcessOperationStatusState _state) callback = (NativeSemaphoreProcessOperationStatusState _state) {
    if (current.isSet) _previous = _current;
    _current = _state;
    // TODO resolve previous state when the value is true and
  };

  late final void Function(NativeSemaphoreProcessOperationStatusState _state) finalizer = (NativeSemaphoreProcessOperationStatusState _state) {
    // print('$tracer Finalizer: ${_state.toString()}');
  };

  late String tracer = identity.tracer;
  late final String name = identity.name;
  late final String process = identity.process;
  late final String isolate = identity.isolate;

  late final NSPOSS willAttempt =
      NativeSemaphoreProcessOperationStatusState(tracer: tracer, name: name, process: process, isolate: isolate, callback: callback, finalizer: finalizer) as NSPOSS;
  late final NSPOSS attempting =
      NativeSemaphoreProcessOperationStatusState(tracer: tracer, name: name, process: process, isolate: isolate, callback: callback, finalizer: finalizer) as NSPOSS;
  late final NSPOSS attempted =
      NativeSemaphoreProcessOperationStatusState(tracer: tracer, name: name, process: process, isolate: isolate, callback: callback, finalizer: finalizer) as NSPOSS;
  late final NSPOSS attemptSucceeded =
      NativeSemaphoreProcessOperationStatusState(tracer: tracer, name: name, process: process, isolate: isolate, callback: callback, finalizer: finalizer) as NSPOSS;

  NativeSemaphoreProcessOperationStatus(
      {required I this.identity, NSPOSS? willAttempt = null, NSPOSS? attempting = null, NSPOSS? attempted = null, NSPOSS? attemptSucceeded = null});
}

class NativeSemaphoreProcessOperationStatuses<I extends SemaphoreIdentity, NSPOSS extends NativeSemaphoreProcessOperationStatusState,
    NSPOS extends NativeSemaphoreProcessOperationStatus<I, NSPOSS>> {
  static late final dynamic instance;

  late final I identity;

  late final StreamController<NativeSemaphoreProcessOperationStatusState> _notifications = StreamController<NativeSemaphoreProcessOperationStatusState>(sync: true);

  late final Stream<NativeSemaphoreProcessOperationStatusState> _broadcast = _notifications.stream.asBroadcastStream();

  Stream<NativeSemaphoreProcessOperationStatusState> get notifications => _broadcast;

  Map<NATIVE_SEMAPHORE_OPERATION, NSPOSS> synchronizations = {};

  late final NSPOS open = NativeSemaphoreProcessOperationStatus<I, NSPOSS>(identity: identity) as NSPOS;
  late final Future<List<NSPOSS>> opened = Future.wait<NSPOSS>([open.willAttempt.completer.future as Future<NSPOSS>, open.attempting.completer.future  as Future<NSPOSS>, open.attempted.completer.future  as Future<NSPOSS>, open.attemptSucceeded.completer.future  as Future<NSPOSS>]);

  late final NSPOS lock = NativeSemaphoreProcessOperationStatus<I, NSPOSS>(identity: identity) as NSPOS;
  late final Future<List<NSPOSS>> locked = Future.wait<NSPOSS>([lock.willAttempt.completer.future as Future<NSPOSS>, lock.attempting.completer.future  as Future<NSPOSS>, lock.attempted.completer.future  as Future<NSPOSS>, lock.attemptSucceeded.completer.future  as Future<NSPOSS>]);

  late final NSPOS unlock = NativeSemaphoreProcessOperationStatus<I, NSPOSS>(identity: identity) as NSPOS;
  late final Future<List<NSPOSS>> unlocked = Future.wait<NSPOSS>([unlock.willAttempt.completer.future as Future<NSPOSS>, unlock.attempting.completer.future  as Future<NSPOSS>, unlock.attempted.completer.future  as Future<NSPOSS>, unlock.attemptSucceeded.completer.future  as Future<NSPOSS>]);

  late final NSPOS close = NativeSemaphoreProcessOperationStatus<I, NSPOSS>(identity: identity) as NSPOS;
  late final Future<List<NSPOSS>> closed = Future.wait<NSPOSS>([close.willAttempt.completer.future as Future<NSPOSS>, close.attempting.completer.future  as Future<NSPOSS>, close.attempted.completer.future  as Future<NSPOSS>, close.attemptSucceeded.completer.future  as Future<NSPOSS>]);

  late final NSPOS unlink = NativeSemaphoreProcessOperationStatus<I, NSPOSS>(identity: identity) as NSPOS;
  late final Future<List<NSPOSS>> unlinked = Future.wait<NSPOSS>([unlink.willAttempt.completer.future as Future<NSPOSS>, unlink.attempting.completer.future  as Future<NSPOSS>, unlink.attempted.completer.future  as Future<NSPOSS>, unlink.attemptSucceeded.completer.future  as Future<NSPOSS>]);

  late final Future<List<NSPOSS>> all = Future.wait<List<NSPOSS>>([opened, locked, unlocked, closed, unlinked]).then((List<List<NSPOSS>> values) => values.expand((List<NSPOSS> value) => value).toList());

  Future<NSPOS> synchronize({required NATIVE_SEMAPHORE_OPERATION operation, dynamic value = null, DateTime? timestamp, ({NSPOS status , NATIVE_SEMAPHORE_OPERATION expected_operation, dynamic expected_value})? verification, R Function<R>(NSPOS status ,NATIVE_SEMAPHORE_OPERATION expected_operation, R expected_value)? verifier}) async {
    // print('${identity.tracer} Synchronizing: $operation $value');
    timestamp ??= DateTime.now();
    Future<NSPOS> Function(
            {required NATIVE_SEMAPHORE_OPERATION operation,
            dynamic value,
            DateTime? timestamp,
              R Function<R>(NSPOS status ,NATIVE_SEMAPHORE_OPERATION expected_operation, R expected_value)? verifier,
              ({NSPOS status ,NATIVE_SEMAPHORE_OPERATION expected_operation, dynamic expected_value})? verification,
              required Future<NSPOS> Function<I extends SemaphoreIdentity, NSPOSS extends NativeSemaphoreProcessOperationStatusState, NSPOS extends NativeSemaphoreProcessOperationStatus<I, NSPOSS>>({required NATIVE_SEMAPHORE_OPERATION operation, dynamic value, DateTime? timestamp, required NSPOS status, ({NSPOS status ,NATIVE_SEMAPHORE_OPERATION expected_operation, dynamic expected_value})? verification, R Function<R>(NSPOS status ,NATIVE_SEMAPHORE_OPERATION expected_operation, R expected_value)? verifier}) synchronizer,
              required NSPOS status}) _call =
        (
            {required NATIVE_SEMAPHORE_OPERATION operation,
            dynamic value,
            DateTime? timestamp,
              R Function<R>(NSPOS status ,NATIVE_SEMAPHORE_OPERATION expected_operation, R expected_value)? verifier,
              ({NSPOS status ,NATIVE_SEMAPHORE_OPERATION expected_operation, dynamic expected_value})? verification,
               required Future<NSPOS> Function<I extends SemaphoreIdentity, NSPOSS extends NativeSemaphoreProcessOperationStatusState, NSPOS extends NativeSemaphoreProcessOperationStatus<I, NSPOSS>>({required NATIVE_SEMAPHORE_OPERATION operation, dynamic value, DateTime? timestamp, required NSPOS status, ({NSPOS status ,NATIVE_SEMAPHORE_OPERATION expected_operation, dynamic expected_value})? verification, R Function<R>(NSPOS status ,NATIVE_SEMAPHORE_OPERATION expected_operation, R expected_value)? verifier}) synchronizer,
            required NSPOS status}) => synchronizer<I, NSPOSS, NSPOS>(operation: operation, value: value, timestamp: timestamp, status: status);

    switch (operation) {
      case NATIVE_SEMAPHORE_OPERATION.willAttemptOpen:
        // If open will attempt then we can complete the
        return _call(operation: operation, value: value, timestamp: timestamp, synchronizer: open.willAttempt.synchronize, status: open, verification: verification, verifier: verifier ??verify);
      case NATIVE_SEMAPHORE_OPERATION.attemptingOpen:
        return _call(operation: operation, value: value, timestamp: timestamp, synchronizer: open.attempting.synchronize, status: open, verification: verification, verifier: verifier ??verify);
      case NATIVE_SEMAPHORE_OPERATION.attemptedOpen:
        return _call(operation: operation, value: value, timestamp: timestamp, synchronizer: open.attempted.synchronize, status: open, verification: verification, verifier: verifier ??verify);
      case NATIVE_SEMAPHORE_OPERATION.openAttemptSucceeded:
        /* calling complete */ // TODO - call completer for other functions depending on the perceived state of value i.e. true then call complete, if false call synchronize
        return _call(operation: operation, value: value,timestamp: timestamp,  synchronizer: open.attemptSucceeded.complete, status: open, verification: verification, verifier: verifier ??verify);

      case NATIVE_SEMAPHORE_OPERATION.willAttemptLockAcrossProcesses:
        return _call(operation: operation, value: value, timestamp: timestamp, synchronizer: lock.willAttempt.synchronize, status: lock, verification: verification, verifier: verifier ??verify);
      case NATIVE_SEMAPHORE_OPERATION.attemptingLockAcrossProcesses:
        return _call(operation: operation, value: value, timestamp: timestamp, synchronizer: lock.attempting.synchronize, status: lock, verification: verification, verifier: verifier ??verify);
      case NATIVE_SEMAPHORE_OPERATION.attemptedLockAcrossProcesses:
        return _call(operation: operation, value: value,timestamp: timestamp,  synchronizer: lock.attempted.synchronize, status: lock, verification: verification, verifier: verifier ??verify);
      case NATIVE_SEMAPHORE_OPERATION.lockAttemptAcrossProcessesSucceeded:
        /* calling complete */
        return _call(operation: operation, value: value,timestamp: timestamp,  synchronizer: lock.attemptSucceeded.complete, status: lock, verification: verification, verifier: verifier ??verify);

      case NATIVE_SEMAPHORE_OPERATION.willAttemptUnlockAcrossProcesses:
        return _call(operation: operation, value: value, timestamp: timestamp, synchronizer: unlock.willAttempt.synchronize, status: unlock, verification: verification, verifier: verifier ??verify);
      case NATIVE_SEMAPHORE_OPERATION.attemptingUnlockAcrossProcesses:
        return _call(operation: operation, value: value,timestamp: timestamp,  synchronizer: unlock.attempting.synchronize, status: unlock, verification: verification, verifier: verifier ??verify);
      case NATIVE_SEMAPHORE_OPERATION.attemptedUnlockAcrossProcesses:
        return _call(operation: operation, value: value,timestamp: timestamp,  synchronizer: unlock.attempted.synchronize, status: unlock, verification: verification, verifier: verifier ??verify);
      case NATIVE_SEMAPHORE_OPERATION.unlockAttemptAcrossProcessesSucceeded:
        /* calling complete */
        return _call(operation: operation, value: value,timestamp: timestamp,  synchronizer: unlock.attemptSucceeded.complete, status: unlock, verification: verification, verifier: verifier ??verify);

      case NATIVE_SEMAPHORE_OPERATION.willAttemptClose:
        return _call(operation: operation, value: value, timestamp: timestamp, synchronizer: close.willAttempt.synchronize, status: close, verification: verification, verifier: verifier ??verify);
      case NATIVE_SEMAPHORE_OPERATION.attemptingClose:
        return _call(operation: operation, value: value, timestamp: timestamp, synchronizer: close.attempting.synchronize, status: close, verification: verification, verifier: verifier ??verify);
      case NATIVE_SEMAPHORE_OPERATION.attemptedClose:
        return _call(operation: operation, value: value,timestamp: timestamp,  synchronizer: close.attempted.synchronize, status: close, verification: verification, verifier: verifier ??verify);
      case NATIVE_SEMAPHORE_OPERATION.closeAttemptSucceeded:
        /* calling complete */
        return _call(operation: operation, value: value,timestamp: timestamp,  synchronizer: close.attemptSucceeded.complete, status: close, verification: verification, verifier: verifier ??verify);

      case NATIVE_SEMAPHORE_OPERATION.willAttemptUnlink:
        return _call(operation: operation, value: value, timestamp: timestamp, synchronizer: unlink.willAttempt.synchronize, status: unlink, verification: verification, verifier: verifier ??verify);
      case NATIVE_SEMAPHORE_OPERATION.attemptingUnlink:
        return _call(operation: operation, value: value,timestamp: timestamp,  synchronizer: unlink.attempting.synchronize, status: unlink, verification: verification, verifier: verifier ??verify);
      case NATIVE_SEMAPHORE_OPERATION.attemptedUnlink:
        return _call(operation: operation, value: value,timestamp: timestamp,  synchronizer: unlink.attempted.synchronize, status: unlink, verification: verification, verifier: verifier ??verify);
      case NATIVE_SEMAPHORE_OPERATION.unlinkAttemptSucceeded:
        /* calling complete */
        return _call(operation: operation, value: value, timestamp: timestamp,  synchronizer: unlink.attemptSucceeded.complete, status: unlink, verification: verification, verifier: verifier ??verify);
      default:
        throw Exception('Operation $operation is not supported on this instance.');
    }
  }


  R verify<R>(NSPOS status ,NATIVE_SEMAPHORE_OPERATION expected_operation, R expected_value) {
    if (status.current.isSet && status.current.get!.operation.get != expected_operation) throw Exception('The current operation ${status.current.get!.operation.get} does not match the expected operation $expected_operation previous is ${status.previous.get!.operation.get}.');
    if (status.current.isSet && status.current.get!.value != expected_value) throw Exception('The current value ${status.current.get!.value} does not match the expected value $expected_value.');
    return expected_value;
  }

  NativeSemaphoreProcessOperationStatuses({required I this.identity});

  // static NSPOSES instantiate<I extends SemaphoreIdentity, NSPOSS extends NativeSemaphoreProcessOperationStatusState, NSPOS extends NativeSemaphoreProcessOperationStatus<I, NSPOSS>,
  //     NSPOSES extends NativeSemaphoreProcessOperationStatuses<I, NSPOSS, NSPOS>>({required I identity}) {
  //   return !LatePropertyAssigned<NSPOSES>(() => NativeSemaphoreProcessOperationStatuses.instance as NSPOSES)
  //       ? NativeSemaphoreProcessOperationStatuses.instance = NativeSemaphoreProcessOperationStatuses<I, NSPOSS, NSPOS>(identity: identity) as NSPOSES
  //       : NativeSemaphoreProcessOperationStatuses.instance as NSPOSES;
  // }
}
