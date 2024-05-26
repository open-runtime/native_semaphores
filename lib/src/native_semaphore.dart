import 'dart:async';
import 'dart:ffi' show Finalizable;
import 'dart:io' show File, FileSystemEntity, Platform;

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
/*  Identity */
    I extends SemaphoreIdentity,
/* Semaphore Identities */
    IS extends SemaphoreIdentities<I>,
/* Count Update */
    CU extends SemaphoreCountUpdate,
/* Count Deletion */
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
    PNSA extends PersistedNativeSemaphoreAccessor,
/* Native Semaphore */
    NS extends NativeSemaphore<I, IS, CU, CD, CT, CTS, CTR, CTRS, PNSO, PNSOS, PNSA>
/* formatting guard comment */
    > {
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
/*  Identity */
    I extends SemaphoreIdentity,
/* Semaphore Identities */
    IS extends SemaphoreIdentities<I>,
/* Count Update */
    CU extends SemaphoreCountUpdate,
/* Count Deletion */
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
/* Persisted Native Semaphore Operations  */
    PNSOS extends PersistedNativeSemaphoreOperations<PNSO>,
/* Persisted Native Semaphore Accessor */
    PNSA extends PersistedNativeSemaphoreAccessor
/* formatting guard comment */
    > implements Finalizable {
  static late final dynamic __semaphores;

  late PNSOS _operations;

  ({bool isSet, PNSOS? get}) get operations => LatePropertyAssigned<PNSOS>(() => _operations) ? (isSet: true, get: _operations) : (isSet: false, get: null);

  late PNSO _operation;

  ({bool isSet, PNSO? get}) get operation => LatePropertyAssigned<PNSO>(() => _operation) ? (isSet: true, get: _operation) : (isSet: false, get: null);

  NativeSemaphore<I, IS, CU, CD, CT, CTS, CTR, CTRS, PNSO, PNSOS, PNSA> all<
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
          NS extends NativeSemaphore<I, IS, CU, CD, CT, CTS, CTR, CTRS, PNSO, PNSOS, PNSA>>() =>
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
  static NativeSemaphore<I, IS, CU, CD, CT, CTS, CTR, CTRS, PNSO, PNSOS, PNSA> instantiate<
      /*  Identity */
      I extends SemaphoreIdentity,
      /* Semaphore Identities */
      IS extends SemaphoreIdentities<I>,
      /* Count Update */
      CU extends SemaphoreCountUpdate,
      /* Count Deletion */
      CD extends SemaphoreCountDeletion,
      /* Semaphore Count */
      CT extends SemaphoreCount<CU, CD>,
      /* Semaphore Counts */
      CTS extends SemaphoreCounts<CU, CD, CT>,
      /* Semaphore Counter i.e. this class */
      CTR extends SemaphoreCounter<I, CU, CD, CT, CTS>,
      /* Semaphore Counters */
      CTRS extends SemaphoreCounters<I, CU, CD, CT, CTS, CTR>,
      /* Persisted Native Semaphore Operation */
      PNSO extends PersistedNativeSemaphoreOperation,
      /* Persisted Native Semaphore Operations  */
      PNSOS extends PersistedNativeSemaphoreOperations<PNSO>,
      /* Persisted Native Semaphore Accessor */
      PNSA extends PersistedNativeSemaphoreAccessor,
      /* Persisted Native Semaphore Metadata */
      PNSM extends PersistedNativeSemaphoreMetadata<PNSA>,
      /* Native Semaphore */
      NS extends NativeSemaphore<I, IS, CU, CD, CT, CTS, CTR, CTRS, PNSO, PNSOS, PNSA>,
      /*Native Semaphores*/
      NSS extends NativeSemaphores<I, IS, CU, CD, CT, CTS, CTR, CTRS, PNSO, PNSOS, PNSA, NS>
      /* formatting guard comment */
      >({required String name, String tracer = '', I? identity, CTR? counter, bool verbose = false}) {
    if (!LatePropertyAssigned<NSS>(() => __semaphores)) {
      __semaphores = NativeSemaphores<I, IS, CU, CD, CT, CTS, CTR, CTRS, PNSO, PNSOS, PNSA, NS>();
      if (verbose) print('Setting NativeSemaphore._instances: ${__semaphores.toString()}');
    }

    return (__semaphores as NSS).has<NS>(name: name)
        ? (__semaphores as NSS).get(name: name)
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
