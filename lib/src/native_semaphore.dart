import 'dart:async' show Future, FutureOr, StreamController;
import 'dart:ffi' show Finalizable;
import 'dart:io' show File, FileSystemEntity, Platform;

import 'package:meta/meta.dart' show protected, visibleForTesting;
import 'package:runtime_native_semaphores/src/persisted_native_semaphore_metadata.dart' show PersistedNativeSemaphoreAccessor, PersistedNativeSemaphoreMetadata;

import '../runtime_native_semaphores.dart' show SemaphoreCount, SemaphoreCountDeletion, SemaphoreCountUpdate, SemaphoreCounter, SemaphoreCounters, SemaphoreCounts, SemaphoreIdentities, SemaphoreIdentity, UnixSemaphore, WindowsSemaphore;
import 'native_semaphore_operations.dart' show NATIVE_SEMAPHORE_OPERATION, NativeSemaphoreProcessOperationStatus, NativeSemaphoreProcessOperationStatusState, NativeSemaphoreProcessOperationStatuses;
import 'native_semaphores.dart' show NativeSemaphores;
import 'persisted_native_semaphore_operation.dart' show PersistedNativeSemaphoreOperation, PersistedNativeSemaphoreOperations;
import 'utils/late_final_property.dart' show LateProperty;

abstract class NativeSemError extends Error {
  final bool critical;
  final int code;
  final String message;
  final String? identifier;
  late final String? description = toString();

  NativeSemError(this.code, this.message, this.identifier, [this.critical = true]);

  @override
  String toString() => 'NativeSemaphoreError: [Critical: $critical Error: $identifier Code: $code]: $message';
}

class NativeSemaphore<I extends SemaphoreIdentity, IS extends SemaphoreIdentities<I>, CU extends SemaphoreCountUpdate, CD extends SemaphoreCountDeletion, CT extends SemaphoreCount<CU, CD>, CTS extends SemaphoreCounts<CU, CD, CT>, NSPOSS extends NativeSemaphoreProcessOperationStatusState, NSPOS extends NativeSemaphoreProcessOperationStatus<I, NSPOSS>, NSPOSES extends NativeSemaphoreProcessOperationStatuses<I, NSPOSS, NSPOS>, CTR extends SemaphoreCounter<I, CU, CD, CT, CTS, NSPOSS, NSPOS, NSPOSES>, CTRS extends SemaphoreCounters<I, CU, CD, CT, CTS, NSPOSS, NSPOS, NSPOSES, CTR>, PNSO extends PersistedNativeSemaphoreOperation, PNSOS extends PersistedNativeSemaphoreOperations<PNSO>, PNSA extends PersistedNativeSemaphoreAccessor> implements Finalizable {
  static final LateProperty<dynamic> semaphores = LateProperty<dynamic>(name: 'semaphores', updatable: false);

  NS all<I extends SemaphoreIdentity, IS extends SemaphoreIdentities<I>, CU extends SemaphoreCountUpdate, CD extends SemaphoreCountDeletion, CT extends SemaphoreCount<CU, CD>, CTS extends SemaphoreCounts<CU, CD, CT>, NSPOSS extends NativeSemaphoreProcessOperationStatusState, NSPOS extends NativeSemaphoreProcessOperationStatus<I, NSPOSS>, NSPOSES extends NativeSemaphoreProcessOperationStatuses<I, NSPOSS, NSPOS>, CTR extends SemaphoreCounter<I, CU, CD, CT, CTS, NSPOSS, NSPOS, NSPOSES>, CTRS extends SemaphoreCounters<I, CU, CD, CT, CTS, NSPOSS, NSPOS, NSPOSES, CTR>, PNSO extends PersistedNativeSemaphoreOperation, PNSOS extends PersistedNativeSemaphoreOperations<PNSO>, PNSA extends PersistedNativeSemaphoreAccessor, NS extends NativeSemaphore<I, IS, CU, CD, CT, CTS, NSPOSS, NSPOS, NSPOSES, CTR, CTRS, PNSO, PNSOS, PNSA>>() => semaphores.casted<NS>();

  late String Function() tracerFn;

  String get tracer => tracerFn();

  final LateProperty<PNSOS> operations = LateProperty<PNSOS>(name: 'operations');

  final LateProperty<PNSO> operation = LateProperty<PNSO>(name: 'operation');

  final LateProperty<String> _hash = LateProperty<String>(name: 'hash', updatable: false);

  final LateProperty<int> _depth = LateProperty<int>(name: 'depth', updatable: false);

  int get depth => _depth.isSet ? _depth.get : _depth.set(NativeSemaphoreProcessOperationStatuses.depth(identity.identifier)).get;

  // String get hash => _hash.isSet ? _hash.get : _hash.set(xxh64.string('${identity.name}-$depth').hex()).get;
  String get hash => _hash.isSet ? _hash.get : _hash.set('${identity.identifier}-$depth').get;

  // Log Stream for the semaphore
  final StreamController<String> logs = StreamController<String>();

  bool verbose;

  late final CTR counter;

  NSPOSES get statuses => counter.statuses;

  I get identity => counter.identity;

  bool waiting = false;

  Map<String, PNSO> preceeding = {};

  Map<String, PNSA> predecessors = {};

  /* Use caution as an unknown or never resolving future can occur i.e. you await future(unlockedAcrossIsolateSucceeded) but that never happens as you might be reentrant use unlockedFuture or similar instead */
  @protected
  Future<NSPOSS> future(NATIVE_SEMAPHORE_OPERATION operation) => statuses.lookup(operation).future(hash: hash, operation: operation) as Future<NSPOSS>;

  // If the semaphore is currently reentrant
  bool get reentrant => statuses.instantiated.reentrant(hash: hash, depth: depth);

  // If the semaphore has been opened
  bool get opened => statuses.opened.completed(hash: hash, operations: [NATIVE_SEMAPHORE_OPERATION.openAttemptReentrantToIsolateSucceeded, NATIVE_SEMAPHORE_OPERATION.openAttemptAcrossProcessesSucceeded]);
  Future<NSPOSS> get openedFuture => statuses.lookup(reentrant ? NATIVE_SEMAPHORE_OPERATION.openAttemptReentrantToIsolateSucceeded : NATIVE_SEMAPHORE_OPERATION.openAttemptAcrossProcessesSucceeded).future(hash: hash, operation: reentrant ? NATIVE_SEMAPHORE_OPERATION.openAttemptReentrantToIsolateSucceeded : NATIVE_SEMAPHORE_OPERATION.openAttemptAcrossProcessesSucceeded) as Future<NSPOSS>;

  // If the semaphore is currently locked
  bool get locked => !unlocked && statuses.locked.completed(hash: hash, operations: [NATIVE_SEMAPHORE_OPERATION.lockAttemptReentrantToIsolateSucceeded, NATIVE_SEMAPHORE_OPERATION.lockAttemptAcrossProcessesSucceeded]);
  Future<NSPOSS> get lockedFuture => statuses.lookup(reentrant ? NATIVE_SEMAPHORE_OPERATION.lockAttemptReentrantToIsolateSucceeded : NATIVE_SEMAPHORE_OPERATION.lockAttemptAcrossProcessesSucceeded).future(hash: hash, operation: reentrant ? NATIVE_SEMAPHORE_OPERATION.lockAttemptReentrantToIsolateSucceeded : NATIVE_SEMAPHORE_OPERATION.lockAttemptAcrossProcessesSucceeded) as Future<NSPOSS>;

  // Note that this will only be true when the process is locked
  bool get unlocked => statuses.unlocked.completed(hash: hash, operations: [NATIVE_SEMAPHORE_OPERATION.unlockAttemptAcrossProcessesSucceeded, NATIVE_SEMAPHORE_OPERATION.unlockAttemptReentrantToIsolateSucceeded]);
  Future<NSPOSS> get unlockedFuture => statuses.lookup(reentrant ? NATIVE_SEMAPHORE_OPERATION.unlockAttemptReentrantToIsolateSucceeded : NATIVE_SEMAPHORE_OPERATION.unlockAttemptAcrossProcessesSucceeded).future(hash: hash, operation: reentrant ? NATIVE_SEMAPHORE_OPERATION.unlockAttemptReentrantToIsolateSucceeded : NATIVE_SEMAPHORE_OPERATION.unlockAttemptAcrossProcessesSucceeded) as Future<NSPOSS>;

  // If the semaphore has been closed
  bool get closed => statuses.closed.completed(hash: hash, operations: [NATIVE_SEMAPHORE_OPERATION.closeAttemptReentrantToIsolateSucceeded, NATIVE_SEMAPHORE_OPERATION.closeAttemptAcrossProcessesSucceeded]);
  Future<NSPOSS> get closedFuture => statuses.lookup(reentrant ? NATIVE_SEMAPHORE_OPERATION.closeAttemptReentrantToIsolateSucceeded : NATIVE_SEMAPHORE_OPERATION.closeAttemptAcrossProcessesSucceeded).future(hash: hash, operation: reentrant ? NATIVE_SEMAPHORE_OPERATION.closeAttemptReentrantToIsolateSucceeded : NATIVE_SEMAPHORE_OPERATION.closeAttemptAcrossProcessesSucceeded) as Future<NSPOSS>;

  // If the semaphore has been unlinked
  bool get unlinked => statuses.unlinked.completed(hash: hash, operations: [NATIVE_SEMAPHORE_OPERATION.unlinkAttemptReentrantToIsolateSucceeded, NATIVE_SEMAPHORE_OPERATION.unlinkAttemptAcrossProcessesSucceeded]);
  Future<NSPOSS> get unlinkedFuture => statuses.lookup(reentrant ? NATIVE_SEMAPHORE_OPERATION.unlinkAttemptReentrantToIsolateSucceeded : NATIVE_SEMAPHORE_OPERATION.unlinkAttemptAcrossProcessesSucceeded).future(hash: hash, operation: reentrant ? NATIVE_SEMAPHORE_OPERATION.unlinkAttemptReentrantToIsolateSucceeded : NATIVE_SEMAPHORE_OPERATION.unlinkAttemptAcrossProcessesSucceeded) as Future<NSPOSS>;

  NativeSemaphore({required String Function() this.tracerFn, required CTR this.counter, this.verbose = false}) {
    instantiation();
  }

  // TODO maybe a rehydrate method? or instantiate takes in a "from process" flag i.e. to attempt to find and rehydrate the semaphore from another process/all processes
  static NS instantiate<I extends SemaphoreIdentity, IS extends SemaphoreIdentities<I>, CU extends SemaphoreCountUpdate, CD extends SemaphoreCountDeletion, CT extends SemaphoreCount<CU, CD>, CTS extends SemaphoreCounts<CU, CD, CT>, NSPOSS extends NativeSemaphoreProcessOperationStatusState, NSPOS extends NativeSemaphoreProcessOperationStatus<I, NSPOSS>, NSPOSES extends NativeSemaphoreProcessOperationStatuses<I, NSPOSS, NSPOS>, CTR extends SemaphoreCounter<I, CU, CD, CT, CTS, NSPOSS, NSPOS, NSPOSES>, CTRS extends SemaphoreCounters<I, CU, CD, CT, CTS, NSPOSS, NSPOS, NSPOSES, CTR>, PNSO extends PersistedNativeSemaphoreOperation, PNSOS extends PersistedNativeSemaphoreOperations<PNSO>, PNSA extends PersistedNativeSemaphoreAccessor, PNSM extends PersistedNativeSemaphoreMetadata<PNSA>, NS extends NativeSemaphore<I, IS, CU, CD, CT, CTS, NSPOSS, NSPOS, NSPOSES, CTR, CTRS, PNSO, PNSOS, PNSA>,
      NSS extends NativeSemaphores<I, IS, CU, CD, CT, CTS, NSPOSS, NSPOS, NSPOSES, CTR, CTRS, PNSO, PNSOS, PNSA, PNSM, NS>>({required String name, required String Function() tracerFn, I? identity, CTR? counter, bool verbose = false}) {
    semaphores.set(NativeSemaphores<I, IS, CU, CD, CT, CTS, NSPOSS, NSPOS, NSPOSES, CTR, CTRS, PNSO, PNSOS, PNSA, PNSM, NS>());

    // TODO if they pass in a counter we need to verify it is the same on on existing semaphores in NativeSemaphores
    CTR _counter = (counter ??
        SemaphoreCounter.instantiate<I, CU, CD, CT, CTS, NSPOSS, NSPOS, NSPOSES, CTR, CTRS>(
          tracerFn: () => tracerFn(),
          identity: (identity ??
              SemaphoreIdentity.instantiate<I, IS>(
                tracerFn: () => tracerFn(),
                name: name,
                verbose: verbose,
              ) as I)
            ..tracerFn = () => tracerFn(),
        ) as CTR)
      ..tracerFn = () => tracerFn();

    /* semaphores will be instances based on their reentrant depth */
    NS semaphore = Platform.isWindows ? WindowsSemaphore(tracerFn: () => tracerFn(), counter: _counter..tracerFn = () => tracerFn(), verbose: verbose) as NS : UnixSemaphore(tracerFn: () => tracerFn(), counter: _counter..tracerFn = () => tracerFn(), verbose: verbose) as NS;

    return (semaphores.casted<NSS>()).register(semaphore: semaphore);
  }

  // TLDR - Synchronize the semaphore identity across the OS
  // This function will effectively create additional semaphore identities on it's __instances property
  // Synchronize should be called right after the semaphore has acquired the lock across processes i.e. in lockAttemptAcrossProcessesSucceeded() to prevent race conditions - if it is only called after the lock is acquired then the holding process of the lock should be
  // safe to update the file as no other locks currently have the lock
  bool synchronize() {
    // Find the temp directory for the semaphore name and list all of it's child files
    final List<FileSystemEntity> files = identity.cache.listSync(recursive: false).toList();

    tracer == operation.get.tracer || (throw Exception('The tracer ${tracer} does not match the operation tracer ${operation.get.tracer}.'));

    // List<({String tracer, NATIVE_SEMAPHORE_OPERATION operation, DateTime created, String process})> accessors = [];

    // List each of the files
    // the file names are as follows process_4535_isolate_495686829.semaphore
    // We rehydrate all persisted operations from other semaphore processes
    // We sort them based on the timestamp of the operation i.e. last operation is the most recent
    // we really only care about the last operations where the operation was willAttemptLockAcrossProcesses, lockAcrossProcesses, or lockAttemptAcrossProcessesSucceeded,
    List<PNSO> from_cache = files.where((file) => !file.path.contains(identity.process) && !file.path.contains(identity.isolate)).map((file) => PersistedNativeSemaphoreOperations.rehydrate<PNSO, PNSOS>(serialized: File(file.path).readAsStringSync(), rehydrate_: PersistedNativeSemaphoreOperation.rehydrate).iterable.last).toList()..sort((PNSO a, PNSO b) => b.created.compareTo(a.created));

    for (final (int _, PNSO __operation) in from_cache.where((__operation) => operation.get.created.isAfter(__operation.created) && operation.get.operation == NATIVE_SEMAPHORE_OPERATION.willAttemptLockAcrossProcesses && (__operation.operation == NATIVE_SEMAPHORE_OPERATION.willAttemptLockAcrossProcesses || __operation.operation == NATIVE_SEMAPHORE_OPERATION.lockAttemptAcrossProcessesSucceeded)).indexed) {
      if (__operation.name != identity.name) throw Exception('The semaphore name ${__operation.name} does not match the current semaphore name ${identity.name}.');

      CTR _ = counter.track<I, CU, CD, CT, CTS, NSPOSS, NSPOS, NSPOSES, CTR, CTRS>(
        tracerFn: () => __operation.tracer,
        identity: identity.track<I, IS>(
          tracerFn: () => __operation.tracer,
          tracer: __operation.tracer,
          name: __operation.name,
          process: __operation.process,
          isolate: __operation.isolate,
          verbose: false,
        ) as I,
        counts: __operation.counts,
        verbose: false,
      ) as CTR;

      // logs.add('DEBUG: NativeSemaphore [synchronize()] Tracer: ${__operation.tracer}: Process: ${__operation.process} | Isolate: ${__operation.isolate} | Operation: ${__operation.operation} | Created: ${__operation.created} | Locked: ${__operation.locked} | Waiting: ${__operation.waiting} | Unlocked: ${__operation.unlinked} | Closed: ${__operation.closed} | Unlinked: ${__operation.unlinked}');

      preceeding.putIfAbsent(__operation.identifier, () => __operation);
      preceeding[__operation.identifier] = __operation;
    }

    for (final (int index, PNSO __operation) in (preceeding.values.toList()..sort((PNSO a, PNSO b) => b.created.compareTo(a.created))).indexed) {
      predecessors[__operation.identifier] = PersistedNativeSemaphoreAccessor(
        operation: __operation.operation,
        elapsed: operation.get.created.difference(__operation.created),
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

    // logs.add('NOTIFICATION: Predecessors ${predecessors.values.toList().map((PNSA __accessor) => 'waiting_on: [${__accessor.tracer}] ${identity.identifier} ${__accessor.identifier} at position: [${__accessor.position}] for duration: [${__accessor.elapsed.inMilliseconds / 1000}]s').join(' | ')}');

    return true;
  }

  @protected
  bool persist({/* TODO change to operation */ required NATIVE_SEMAPHORE_OPERATION operation, bool sync = false, DateTime? created}) {
    operations.set(PersistedNativeSemaphoreOperations.rehydrate<PNSO, PNSOS>(serialized: identity.temp.readAsStringSync(), rehydrate_: PersistedNativeSemaphoreOperation.rehydrate, verbose: verbose)).succeeded || (throw Exception('Failed to rehydrate operations from temp file.'));

    created ??= DateTime.now();

    identity.temp.writeAsStringSync(
        (operations.get
              ..add(
                  operation: this
                      .operation
                      .set(
                        PersistedNativeSemaphoreOperation(
                          name: identity.name.get,
                          tracer: tracer,
                          identifier: identity.identifier,
                          isolate: identity.isolate,
                          process: identity.process,
                          operation: operation,
                          created: created,
                          address: opened ? identity.address : -1,
                          elapsed: this.operation.isSet ? created.difference(this.operation.get.created) : null,
                          verbose: verbose,
                          counts: (instantiated: counter.counts.instantiated.get(), isolate_locks: counter.counts.isolate_locks.get(), process_locks: counter.counts.process_locks.get(), reentrant: counter.counts.reentrant.get(), unlinked: counter.counts.unlinked.get(), opened: counter.counts.opened.get(), closed: counter.counts.closed.get()),
                          opened: opened,
                          unlocked: unlocked,
                          locked: locked,
                          closed: closed,
                          reentrant: reentrant,
                          unlinked: unlinked,
                          waiting: waiting,
                        ) as PNSO,
                      )
                      .get))
            .serialize(),
        flush: true);

    // TODO probably should persist and sync based on not only the operation name but also operation state
    return persistAttemptSucceeded() && sync ? synchronize() : true;
  }

  @protected
  bool persistAttemptSucceeded() => identity.temp.readAsStringSync() == operations.get.serialize() && operations.get.toString() == PersistedNativeSemaphoreOperations.rehydrate<PNSO, PNSOS>(serialized: identity.temp.readAsStringSync(), rehydrate_: PersistedNativeSemaphoreOperation.rehydrate).toString() || (throw Exception('Failed to persist NativeSemaphore metadata to disk. Operations are not the same.'));

  @protected
  bool instantiation({bool state = true, bool persisted = false}) {
    NATIVE_SEMAPHORE_OPERATION operation = NATIVE_SEMAPHORE_OPERATION.instantiate;
    /* TODO Move inside of synchronize */
    statuses.synchronize(hash: hash, operation: operation, state: state, verification: (status: statuses.opened, expected_operation: operation, expected_state: state));
    if (state) !persisted || persist(operation: operation) || (throw Exception('Failed to persist operation status to temp file.'));
    return state;
  }

  /*Opening Methods*/
  bool open() => (openAcrossProcesses() || openReentrantToIsolate());

  @visibleForTesting
  @protected
  bool willAttemptOpenReentrantToIsolate({bool? state, bool persisted = false}) {
    state = state ?? !opened || /* we may or may not be reentrant yet as this is evaluated based on lock counts */ reentrant;
    NATIVE_SEMAPHORE_OPERATION operation = NATIVE_SEMAPHORE_OPERATION.willAttemptOpenReentrantToIsolate;
    /* TODO Move inside of synchronize */
    statuses.synchronize(hash: hash, operation: operation, state: state, verification: (status: statuses.opened, expected_operation: operation, expected_state: state));
    if (state) !persisted || persist(operation: operation) || (throw Exception('Failed to persist operation status to temp file.'));
    return state;
  }

  @visibleForTesting
  @protected
  bool attemptingOpenReentrantToIsolate({bool? state, bool persisted = false}) {
    state = state ?? true;
    NATIVE_SEMAPHORE_OPERATION operation = NATIVE_SEMAPHORE_OPERATION.attemptingOpenReentrantToIsolate;
    /* TODO Move inside of synchronize */
    statuses.synchronize(hash: hash, operation: operation, state: state, verification: (status: statuses.opened, expected_operation: operation, expected_state: state));
    if (state) !persisted || persist(operation: operation) || (throw Exception('Failed to persist operation status to temp file.'));
    return state;
  }

  @visibleForTesting
  @protected
  bool openReentrantToIsolate() {
    if (!willAttemptOpenReentrantToIsolate()) return false;
    attemptingOpenReentrantToIsolate(state: true);
    attemptedOpenReentrantToIsolate(state: true);
    return openAttemptReentrantToIsolateSucceeded();
  }

  @visibleForTesting
  @protected
  bool attemptedOpenReentrantToIsolate({bool? state, bool persisted = false}) {
    state = state ?? true;
    NATIVE_SEMAPHORE_OPERATION operation = NATIVE_SEMAPHORE_OPERATION.attemptedOpenReentrantToIsolate;
    /*TODO Move inside of synchronize */
    statuses.synchronize(hash: hash, operation: operation, state: state, verification: (status: statuses.opened, expected_operation: operation, expected_state: state));
    if (state) !persisted || persist(operation: operation) || (throw Exception('Failed to persist operation status to temp file.'));
    return state;
  }

  @visibleForTesting
  @protected
  bool openAttemptReentrantToIsolateSucceeded({bool state = true, bool persisted = false}) {
    if (state)
      counter.counts
        ..opened.increment()
        ..reentrant.increment();
    NATIVE_SEMAPHORE_OPERATION operation = NATIVE_SEMAPHORE_OPERATION.openAttemptReentrantToIsolateSucceeded;
    /*TODO Move inside of synchronize */
    statuses.synchronize(hash: hash, operation: operation, state: state, verification: (status: statuses.opened, expected_operation: operation, expected_state: state));
    if (state) !persisted || persist(operation: operation) || (throw Exception('Failed to persist operation status to temp file.'));
    return state;
  }

  @visibleForTesting
  @protected
  bool willAttemptOpenAcrossProcesses({bool? state, bool persisted = true}) {
    // state is either passed or true if not opened yet
    state = state ?? !opened && !reentrant;
    NATIVE_SEMAPHORE_OPERATION operation = NATIVE_SEMAPHORE_OPERATION.willAttemptOpenAcrossProcesses;
    /*TODO Move inside of synchronize */
    statuses.synchronize(hash: hash, operation: operation, state: state, verification: (status: statuses.opened, expected_operation: operation, expected_state: state));
    if (state) !persisted || persist(operation: operation) || (throw Exception('Failed to persist operation status to temp file.'));
    return state;
  }

  @visibleForTesting
  @protected
  bool attemptingOpenAcrossProcesses({bool? state, bool persisted = true}) {
    state = state ?? !opened && !reentrant;
    NATIVE_SEMAPHORE_OPERATION operation = NATIVE_SEMAPHORE_OPERATION.attemptingOpenAcrossProcesses;
    /*TODO Move inside of synchronize */
    statuses.synchronize(hash: hash, operation: operation, state: state, verification: (status: statuses.opened, expected_operation: operation, expected_state: state));
    if (state) !persisted || persist(operation: operation) || (throw Exception('Failed to persist operation status to temp file.'));
    return state;
  }

  @visibleForTesting
  @protected
  bool openAcrossProcesses() => throw UnimplementedError();

  @visibleForTesting
  @protected
  bool attemptedOpenAcrossProcesses({bool? state, bool persisted = false}) {
    state = state ?? true;
    NATIVE_SEMAPHORE_OPERATION operation = NATIVE_SEMAPHORE_OPERATION.attemptedOpenAcrossProcesses;
    /*TODO Move inside of synchronize */
    statuses.synchronize(hash: hash, operation: operation, state: state, verification: (status: statuses.opened, expected_operation: operation, expected_state: state));
    if (state) !persisted || persist(operation: operation) || (throw Exception('Failed to persist operation status to temp file.'));
    return state;
  }

  /* TODO potentially pass along error details */
  @visibleForTesting
  @protected
  bool openAttemptAcrossProcessesSucceeded({bool? state, bool persisted = true}) {
    state = state ?? true;
    if (state) counter.counts.opened.increment();
    NATIVE_SEMAPHORE_OPERATION operation = NATIVE_SEMAPHORE_OPERATION.openAttemptAcrossProcessesSucceeded;
    statuses.synchronize(hash: hash, operation: operation, state: state, verification: (status: statuses.opened, expected_operation: operation, expected_state: state));
    if (state) persist(operation: operation) || (throw Exception('Failed to persist operation status to temp file.'));
    return state;
  }

  /* Locking */
  bool lock({bool blocking = true, Duration? timeout}) => (lockAcrossProcesses(blocking: blocking) || lockReentrantToIsolate()) == locked;

  Future<bool> lockWithDelay({bool blocking = true, Duration? delay, FutureOr Function()? before, FutureOr Function()? after}) async => throw UnimplementedError();

  @visibleForTesting
  @protected
  bool willAttemptLockReentrantToIsolate({bool? state, bool persisted = false}) {
    // if we're above 0 then we can lock reentrant to isolate and we are reentrant
    state = state ?? !locked;
    NATIVE_SEMAPHORE_OPERATION operation = NATIVE_SEMAPHORE_OPERATION.willAttemptLockReentrantToIsolate;
    if (state) !persisted || persist(operation: operation) || (throw Exception('Failed to persist operation status to temp file.'));
    statuses.synchronize(hash: hash, operation: operation, state: state, verification: (status: statuses.locked, expected_operation: operation, expected_state: state));
    return state;
  }

  @protected
  bool attemptingLockReentrantToIsolate({required bool state, bool persisted = false}) {
    NATIVE_SEMAPHORE_OPERATION operation = NATIVE_SEMAPHORE_OPERATION.attemptingLockReentrantToIsolate;
    if (state) !persisted || persist(operation: operation) || (throw Exception('Failed to persist operation status to temp file.'));
    statuses.synchronize(hash: hash, operation: operation, state: true, verification: (status: statuses.locked, expected_operation: operation, expected_state: true));
    return true;
  }

  @protected
  bool attemptedLockReentrantToIsolate({required bool state, bool persisted = false}) {
    NATIVE_SEMAPHORE_OPERATION operation = NATIVE_SEMAPHORE_OPERATION.attemptedLockReentrantToIsolate;
    if (state) !persisted || persist(operation: operation) || (throw Exception('Failed to persist operation status to temp file.'));
    statuses.synchronize(hash: hash, operation: operation, state: true, verification: (status: statuses.locked, expected_operation: operation, expected_state: true));
    return true;
  }

  @protected
  bool lockReentrantToIsolate() {
    if (!willAttemptLockReentrantToIsolate()) return false;
    attemptingLockReentrantToIsolate(state: true);
    attemptedLockReentrantToIsolate(state: true);
    return lockAttemptReentrantToIsolateSucceeded();
  }

  @protected
  bool lockAttemptReentrantToIsolateSucceeded({bool state = true, bool persisted = false}) {
    if (state) counter.counts.isolate_locks.increment();
    NATIVE_SEMAPHORE_OPERATION operation = NATIVE_SEMAPHORE_OPERATION.lockAttemptReentrantToIsolateSucceeded;
    if (state) !persisted || persist(operation: operation) || (throw Exception('Failed to persist operation status to temp file.'));
    statuses.synchronize(hash: hash, operation: operation, state: state, verification: (status: statuses.locked, expected_operation: operation, expected_state: state));
    return state;
  }

  @protected
  bool willAttemptLockAcrossProcesses({bool? state}) {
    if (!opened) throw Exception('Failed [willAttemptLockAcrossProcesses()]: IDENTITY: ${identity.identifier} REASON: Cannot lock semaphore that has not been opened.');
    /* if the process counts is zero then we will attempt lock across processes */
    state = state ?? counter.counts.process_locks.get() == 0;
    NATIVE_SEMAPHORE_OPERATION operation = NATIVE_SEMAPHORE_OPERATION.willAttemptLockAcrossProcesses;
    /* Persist if state is true */
    statuses.synchronize(hash: hash, operation: operation, state: state, verification: (status: statuses.locked, expected_operation: operation, expected_state: state));
    !state || persist(operation: operation, sync: true) || (throw Exception('Failed to persist operation status to temp file.'));
    return state;
  }

  @protected
  bool attemptingLockAcrossProcesses({bool? state}) {
    state = state ?? true;
    NATIVE_SEMAPHORE_OPERATION operation = NATIVE_SEMAPHORE_OPERATION.attemptingLockAcrossProcesses;
    /* Persist if state is true */
    statuses.synchronize(hash: hash, operation: operation, state: state, verification: (status: statuses.locked, expected_operation: operation, expected_state: state));
    !state || persist(operation: operation, sync: true) || (throw Exception('Failed to persist operation status to temp file.'));
    return state;
  }

  @protected
  bool lockAcrossProcesses({bool blocking = true, Duration? timeout}) => throw UnimplementedError();

  @protected
  bool attemptedLockAcrossProcesses({required int attempt, bool? state}) {
    state = state ?? true;
    NATIVE_SEMAPHORE_OPERATION operation = NATIVE_SEMAPHORE_OPERATION.attemptedLockAcrossProcesses;
    /* Persist if state is true */
    statuses.synchronize(hash: hash, operation: operation, state: state, verification: (status: statuses.locked, expected_operation: operation, expected_state: state));
    !state || persist(operation: operation, sync: true) || (throw Exception('Failed to persist operation status to temp file.'));
    return state;
  }

  /* TODO potentially pass along error details */
  @protected
  bool lockAttemptAcrossProcessesSucceeded<E extends NativeSemError>({required int attempt, bool? state, E? error}) {
    state = state ?? true;
    counter.counts.process_locks.increment();
    NATIVE_SEMAPHORE_OPERATION operation = NATIVE_SEMAPHORE_OPERATION.lockAttemptAcrossProcessesSucceeded;
    // TODO probably should persist and sync based on not only the operation name but also operation state
    /* Persist if state is true */
    !state || persist(operation: operation, sync: true) || (throw Exception('Failed to persist operation status to temp file.'));
    statuses.synchronize(hash: hash, operation: operation, state: state, verification: (status: statuses.locked, expected_operation: operation, expected_state: state));
    return state;
  }

  /* Unlocking */
  bool unlock() {
    return unlockAcrossProcesses() || unlockReentrantToIsolate();
  }

  Future<bool> unlockWithDelay({Duration? delay, FutureOr Function()? before, FutureOr Function()? after}) async => throw UnimplementedError();

  @visibleForTesting
  @protected
  bool willAttemptUnlockAcrossProcesses({bool? state}) {
    state = state ?? locked && !reentrant;
    NATIVE_SEMAPHORE_OPERATION operation = NATIVE_SEMAPHORE_OPERATION.willAttemptUnlockAcrossProcesses;
    /* If the state is true we persist */
    statuses.synchronize(hash: hash, operation: operation, state: state, verification: (status: statuses.unlocked, expected_operation: operation, expected_state: state));
    !state || persist(operation: operation) || (throw Exception('Failed to persist operation status to temp file.'));
    return state;
  }

  @visibleForTesting
  @protected
  bool attemptingUnlockAcrossProcesses({bool? state, bool persisted = false}) {
    state = state ?? locked && !reentrant;
    NATIVE_SEMAPHORE_OPERATION operation = NATIVE_SEMAPHORE_OPERATION.attemptingUnlockAcrossProcesses;
    statuses.synchronize(hash: hash, operation: operation, state: state, verification: (status: statuses.unlocked, expected_operation: operation, expected_state: state));
    if (state) !persisted || persist(operation: operation) || (throw Exception('Failed to persist operation status to temp file.'));
    return state;
  }

  @visibleForTesting
  @protected
  bool unlockAcrossProcesses() => throw UnimplementedError();

  @visibleForTesting
  @protected
  bool attemptedUnlockAcrossProcesses({required int attempt, bool? state, bool persisted = false}) {
    state = state ?? true;
    NATIVE_SEMAPHORE_OPERATION operation = NATIVE_SEMAPHORE_OPERATION.attemptedUnlockAcrossProcesses;
    statuses.synchronize(hash: hash, operation: operation, state: state, verification: (status: statuses.unlocked, expected_operation: operation, expected_state: state));
    if (state) !persisted || persist(operation: operation) || (throw Exception('Failed to persist operation status to temp file.'));
    return state;
  }

  /* TODO potentially pass along error details */
  @visibleForTesting
  @protected
  bool unlockAttemptAcrossProcessesSucceeded<E extends NativeSemError>({required int attempt, bool? state, E? error}) {
    state = state ?? false;
    if (state) counter.counts.process_locks.decrement();
    NATIVE_SEMAPHORE_OPERATION operation = NATIVE_SEMAPHORE_OPERATION.unlockAttemptAcrossProcessesSucceeded;
    statuses.synchronize(hash: hash, operation: operation, state: state, verification: (status: statuses.unlocked, expected_operation: operation, expected_state: state));
    if (state) persist(operation: operation) || (throw Exception('Failed to persist operation status to temp file.'));
    return state;
  }

  @visibleForTesting
  @protected
  bool willAttemptUnlockReentrantToIsolate({bool? state, bool persisted = false}) {
    state = state ?? locked && reentrant;
    NATIVE_SEMAPHORE_OPERATION operation = NATIVE_SEMAPHORE_OPERATION.willAttemptUnlockReentrantToIsolate;
    statuses.synchronize(hash: hash, operation: operation, state: state, verification: (status: statuses.unlocked, expected_operation: operation, expected_state: state));
    if (state) !persisted || persist(operation: operation) || (throw Exception('Failed to persist operation status to temp file.'));
    return state;
  }

  @visibleForTesting
  @protected
  bool attemptingUnlockReentrantToIsolate({required bool state, bool persisted = false}) {
    NATIVE_SEMAPHORE_OPERATION operation = NATIVE_SEMAPHORE_OPERATION.attemptingUnlockReentrantToIsolate;
    statuses.synchronize(hash: hash, operation: operation, state: state, verification: (status: statuses.unlocked, expected_operation: operation, expected_state: state));
    if (state) !persisted || persist(operation: operation) || (throw Exception('Failed to persist operation status to temp file.'));
    return state;
  }

  @visibleForTesting
  @protected
  bool unlockReentrantToIsolate() {
    if (!willAttemptUnlockReentrantToIsolate()) return false;
    attemptingUnlockReentrantToIsolate(state: true);
    attemptedUnlockReentrantToIsolate(state: true);
    return unlockAttemptReentrantToIsolateSucceeded();
  }

  @visibleForTesting
  @protected
  bool attemptedUnlockReentrantToIsolate({required bool state, bool persisted = false}) {
    NATIVE_SEMAPHORE_OPERATION operation = NATIVE_SEMAPHORE_OPERATION.attemptedUnlockReentrantToIsolate;
    statuses.synchronize(hash: hash, operation: operation, state: state, verification: (status: statuses.unlocked, expected_operation: operation, expected_state: state));
    if (state) !persisted || persist(operation: operation) || (throw Exception('Failed to persist operation status to temp file.'));
    return state;
  }

  @visibleForTesting
  @protected
  bool unlockAttemptReentrantToIsolateSucceeded({bool state = true, bool persisted = false}) {
    if (state) counter.counts.isolate_locks.decrement();
    NATIVE_SEMAPHORE_OPERATION operation = NATIVE_SEMAPHORE_OPERATION.unlockAttemptReentrantToIsolateSucceeded;
    statuses.synchronize(hash: hash, operation: operation, state: state, verification: (status: statuses.unlocked, expected_operation: operation, expected_state: state));
    if (state) !persisted || persist(operation: operation) || (throw Exception('Failed to persist operation status to temp file.'));
    return state;
  }

  /* Closing */
  bool close() => closeAcrossProcesses() || closeReentrantToIsolate();

  @protected
  bool closeAcrossProcesses() => throw UnimplementedError();

  @protected
  bool closeReentrantToIsolate() {
    if (!willAttemptCloseReentrantToIsolate()) return false;
    attemptingCloseReentrantToIsolate(state: true);
    attemptedCloseReentrantToIsolate(state: true);
    return closeAttemptReentrantToIsolateSucceeded();
  }

  @visibleForTesting
  @protected
  bool willAttemptCloseAcrossProcesses({bool? state}) {
    !locked || (throw Exception('Failed [willAttemptCloseAcrossProcesses()]: IDENTITY: ${identity.identifier} REASON: Cannot close semaphore that has not been unlocked.'));
    state = state ?? !locked && !closed && !reentrant;
    NATIVE_SEMAPHORE_OPERATION operation = NATIVE_SEMAPHORE_OPERATION.willAttemptCloseAcrossProcesses;
    statuses.synchronize(hash: hash, operation: operation, state: state, verification: (status: statuses.closed, expected_operation: operation, expected_state: state));
    !state || persist(operation: operation) || (throw Exception('Failed to persist operation status to temp file.'));
    return state;
  }

  @visibleForTesting
  @protected
  bool attemptingCloseAcrossProcesses({required bool state, bool persisted = true}) {
    NATIVE_SEMAPHORE_OPERATION operation = NATIVE_SEMAPHORE_OPERATION.attemptingCloseAcrossProcesses;
    statuses.synchronize(hash: hash, operation: operation, state: state, verification: (status: statuses.closed, expected_operation: operation, expected_state: state));
    if (state) !persisted || persist(operation: operation) || (throw Exception('Failed to persist operation status to temp file.'));
    return state;
  }

  @protected
  bool attemptedCloseAcrossProcesses({required int attempt, bool? state}) {
    state = state ?? true;
    NATIVE_SEMAPHORE_OPERATION operation = NATIVE_SEMAPHORE_OPERATION.attemptedCloseAcrossProcesses;
    statuses.synchronize(hash: hash, operation: operation, state: state, verification: (status: statuses.closed, expected_operation: operation, expected_state: state));
    if (state) persist(operation: operation) || (throw Exception('Failed to persist operation status to temp file.'));
    return state;
  }

  /* TODO potentially pass along error details */
  @protected
  bool closeAttemptAcrossProcessesSucceeded<E extends NativeSemError>({required int attempt, bool? state, E? error}) {
    state = state ?? true;
    if (state) counter.counts.closed.increment();
    NATIVE_SEMAPHORE_OPERATION operation = NATIVE_SEMAPHORE_OPERATION.closeAttemptAcrossProcessesSucceeded;
    statuses.synchronize(hash: hash, operation: operation, state: true, verification: (status: statuses.closed, expected_operation: operation, expected_state: true));
    if (state) persist(operation: operation) || (throw Exception('Failed to persist operation status to temp file.'));
    return state;
  }

  @protected
  bool willAttemptCloseReentrantToIsolate({bool? state, bool persisted = false}) {
    state = state ?? !locked && !closed && reentrant;
    NATIVE_SEMAPHORE_OPERATION operation = NATIVE_SEMAPHORE_OPERATION.willAttemptCloseReentrantToIsolate;
    statuses.synchronize(hash: hash, operation: operation, state: state, verification: (status: statuses.closed, expected_operation: operation, expected_state: state));
    if (state) !persisted || persist(operation: operation) || (throw Exception('Failed to persist operation status to temp file.'));
    return state;
  }

  @protected
  bool attemptingCloseReentrantToIsolate({required bool state, bool persisted = false}) {
    NATIVE_SEMAPHORE_OPERATION operation = NATIVE_SEMAPHORE_OPERATION.attemptingCloseReentrantToIsolate;
    statuses.synchronize(hash: hash, operation: operation, state: state, verification: (status: statuses.closed, expected_operation: operation, expected_state: state));
    if (state) !persisted || persist(operation: operation) || (throw Exception('Failed to persist operation status to temp file.'));
    return state;
  }

  @protected
  bool attemptedCloseReentrantToIsolate({required bool state, bool persisted = false}) {
    NATIVE_SEMAPHORE_OPERATION operation = NATIVE_SEMAPHORE_OPERATION.attemptedCloseReentrantToIsolate;
    statuses.synchronize(hash: hash, operation: operation, state: state, verification: (status: statuses.closed, expected_operation: operation, expected_state: state));
    if (state) !persisted || persist(operation: operation) || (throw Exception('Failed to persist operation status to temp file.'));
    return state;
  }

  @protected
  bool closeAttemptReentrantToIsolateSucceeded({bool state = true, bool persisted = false}) {
    if (state) counter.counts.closed.increment();
    NATIVE_SEMAPHORE_OPERATION operation = NATIVE_SEMAPHORE_OPERATION.closeAttemptReentrantToIsolateSucceeded;
    statuses.synchronize(hash: hash, operation: operation, state: state, verification: (status: statuses.closed, expected_operation: operation, expected_state: state));
    if (state) !persisted || persist(operation: operation) || (throw Exception('Failed to persist operation status to temp file.'));
    return state;
  }

  /* Unlinking */
  bool unlink() => unlinkAcrossProcesses() || unlinkReentrantToIsolate();

  @protected
  bool willAttemptUnlinkAcrossProcesses({bool? state}) {
    closed || (throw Exception('Failed [willAttemptUnlinkAcrossProcesses()]: IDENTITY: ${identity.identifier} REASON: Cannot unlink semaphore that has not been closed.'));
    state = state ?? closed && !unlinked && !reentrant;
    NATIVE_SEMAPHORE_OPERATION operation = NATIVE_SEMAPHORE_OPERATION.willAttemptUnlinkAcrossProcesses;
    /* if the state is true we will persist it */
    statuses.synchronize(hash: hash, operation: operation, state: state, verification: (status: statuses.unlinked, expected_operation: operation, expected_state: state));
    !state || persist(operation: operation) || (throw Exception('Failed to persist operation status to temp file.'));
    return state;
  }

  @protected
  bool attemptingUnlinkAcrossProcesses({required bool state, bool persisted = false}) {
    NATIVE_SEMAPHORE_OPERATION operation = NATIVE_SEMAPHORE_OPERATION.attemptingUnlinkAcrossProcesses;
    statuses.synchronize(hash: hash, operation: operation, state: state, verification: (status: statuses.unlinked, expected_operation: operation, expected_state: state));
    if (state) !persisted || persist(operation: operation) || (throw Exception('Failed to persist operation status to temp file.'));
    return state;
  }

  @protected
  bool unlinkAcrossProcesses() => throw UnimplementedError();

  @protected
  bool attemptedUnlinkAcrossProcesses({required int attempt, bool? state}) {
    state = state ?? true;
    NATIVE_SEMAPHORE_OPERATION operation = NATIVE_SEMAPHORE_OPERATION.attemptedUnlinkAcrossProcesses;
    statuses.synchronize(hash: hash, operation: operation, state: state, verification: (status: statuses.unlinked, expected_operation: operation, expected_state: state));
    !state || persist(operation: operation) || (throw Exception('Failed to persist operation status to temp file.'));
    return state;
  }

  @protected
  bool unlinkAttemptAcrossProcessesSucceeded<E extends NativeSemError>({required int attempt, bool? state, E? error}) {
    state = state ?? true;
    NATIVE_SEMAPHORE_OPERATION operation = NATIVE_SEMAPHORE_OPERATION.unlinkAttemptAcrossProcessesSucceeded;
    statuses.synchronize(hash: hash, operation: operation, state: state, verification: (status: statuses.unlinked, expected_operation: operation, expected_state: state));
    !state || persist(operation: operation) || (throw Exception('Failed to persist operation status to temp file.'));
    return state;
  }

  @protected
  bool willAttemptUnlinkReentrantToIsolate({bool? state, bool persisted = false}) {
    state = state ?? closed && reentrant;
    NATIVE_SEMAPHORE_OPERATION operation = NATIVE_SEMAPHORE_OPERATION.willAttemptUnlinkReentrantToIsolate;
    statuses.synchronize(hash: hash, operation: operation, state: state, verification: (status: statuses.unlinked, expected_operation: operation, expected_state: state));
    if (state) !persisted || persist(operation: operation) || (throw Exception('Failed to persist operation status to temp file.'));
    return state;
  }

  @protected
  bool attemptingUnlinkReentrantToIsolate({required bool state, bool persisted = false}) {
    NATIVE_SEMAPHORE_OPERATION operation = NATIVE_SEMAPHORE_OPERATION.attemptingUnlinkReentrantToIsolate;
    statuses.synchronize(hash: hash, operation: operation, state: state, verification: (status: statuses.unlinked, expected_operation: operation, expected_state: state));
    if (state) !persisted || persist(operation: operation) || (throw Exception('Failed to persist operation status to temp file.'));
    return state;
  }

  @protected
  bool unlinkReentrantToIsolate() {
    if (!willAttemptUnlinkReentrantToIsolate()) return false;
    attemptingUnlinkReentrantToIsolate(state: true);
    attemptedUnlinkReentrantToIsolate(state: true);
    return unlinkAttemptReentrantToIsolateSucceeded();
  }

  @protected
  bool attemptedUnlinkReentrantToIsolate({required bool state, bool persisted = false}) {
    NATIVE_SEMAPHORE_OPERATION operation = NATIVE_SEMAPHORE_OPERATION.attemptedUnlinkReentrantToIsolate;
    statuses.synchronize(hash: hash, operation: operation, state: state, verification: (status: statuses.unlinked, expected_operation: operation, expected_state: state));
    if (state) !persisted || persist(operation: operation) || (throw Exception('Failed to persist operation status to temp file.'));
    return state;
  }

  @protected
  bool unlinkAttemptReentrantToIsolateSucceeded({bool state = true, bool persisted = false}) {
    NATIVE_SEMAPHORE_OPERATION operation = NATIVE_SEMAPHORE_OPERATION.unlinkAttemptReentrantToIsolateSucceeded;
    statuses.synchronize(hash: hash, operation: operation, state: state, verification: (status: statuses.unlinked, expected_operation: operation, expected_state: state));
    if (state) !persisted || persist(operation: operation) || (throw Exception('Failed to persist operation status to temp file.'));
    return state;
  }
}
