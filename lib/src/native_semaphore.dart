import 'dart:ffi' show Finalizable;
import 'dart:io' show Directory, File, Platform;

import 'package:meta/meta.dart' show protected;
import 'package:runtime_native_semaphores/src/utils/XXHash64.dart';
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
    /* Native Semaphore */
    NS extends NativeSemaphore<I, IS, CU, CD, CT, CTS, CTR, CTRS, PNSO, PNSOS>
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
    PNSOS extends PersistedNativeSemaphoreOperations<PNSO>
/* formatting guard comment */
    > implements Finalizable {
  static late final dynamic __instances;

  late PNSOS _operations;

  ({bool isSet, PNSOS? get}) get operations => LatePropertyAssigned<PNSOS>(() => _operations) ?  (isSet: true, get: _operations) : (isSet: false, get: null);

  late PNSO _operation;

  ({bool isSet, PNSO? get}) get operation => LatePropertyAssigned<PNSO>(() => _operation) ?  (isSet: true, get: _operation) : (isSet: false, get: null);

  dynamic get _instances => NativeSemaphore.__instances;

  bool verbose;

  late final String name;

  late final CTR counter;

  I get identity => counter.identity;

  bool waiting = false;

  final Directory cache = Directory('${Directory.systemTemp.path}${Platform.pathSeparator}runtime_native_semaphores')..createSync(recursive: true);

  late final File temp = File('${cache.path}${Platform.pathSeparator}${identity.uuid}.semaphore.txt')..createSync(recursive: true)..writeAsStringSync(PersistedNativeSemaphoreOperations().serialize(), flush: true);

  @protected
  late final bool hasOpened;

  @protected
  late final bool hasClosed;

  // If closed is assigned then opened is the opposite
  bool get opened => LatePropertyAssigned<bool>(() => hasClosed)
      ? !hasClosed
      // If opened is assigned then we return _opened otherwise false
      : LatePropertyAssigned<bool>(() => hasOpened)
          ? hasOpened
          : false;

  bool get closed => LatePropertyAssigned<bool>(() => hasClosed) && !opened ? hasClosed : false;

  @protected
  late final bool hasUnlinked;

  bool get unlinked => LatePropertyAssigned<bool>(() => hasUnlinked) ? !opened && closed && hasUnlinked : false;

  // identities are always bound to a unique counter and thus the identity for the counter is the identity for the semaphore
  // late final I identity = counter.identity;

  // get locked i.e. the count of the semaphore
  bool get locked {
    int isolates = counter.counts.isolate.get();
    int processes = counter.counts.process.get();
    return isolates > 0 || processes > 0;
  }

  // if we are reentrant internally
  bool get reentrant => counter.counts.isolate.get() > 1;

  NativeSemaphore({required String this.name, required CTR this.counter, this.verbose = false});

  // TODO maybe a rehydrate method? or instantiate takes in a "from process" flag i.e. to attempt to find and rehydrate the semaphore from another process/all processes
  static NativeSemaphore<I, IS, CU, CD, CT, CTS, CTR, CTRS, PNSO, PNSOS> instantiate<
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
      /* Native Semaphore */
      NS extends NativeSemaphore<I, IS, CU, CD, CT, CTS, CTR, CTRS, PNSO, PNSOS>,
      /*Native Semaphores*/
      NSS extends NativeSemaphores<I, IS, CU, CD, CT, CTS, CTR, CTRS, PNSO, PNSOS, NS>
      /* formatting guard comment */
      >({required String name, I? identity, CTR? counter, bool verbose = false}) {
    if (!LatePropertyAssigned<NSS>(() => __instances)) {
      __instances = NativeSemaphores<I, IS, CU, CD, CT, CTS, CTR, CTRS, PNSO, PNSOS, NS>();
      if (verbose) print('Setting NativeSemaphore._instances: ${__instances.toString()}');
    }

    return (__instances as NSS).has<NS>(name: name)
        ? (__instances as NSS).get(name: name)
        : (__instances as NSS).register(
            name: name,
            semaphore: Platform.isWindows
                ? WindowsSemaphore(
                    name: name,
                    counter: counter ??
                        SemaphoreCounter.instantiate<I, CU, CD, CT, CTS, CTR, CTRS>(
                          identity: identity ??
                              SemaphoreIdentity.instantiate<I, IS>(
                                name: name,
                              ) as I,
                        ),
                    verbose: verbose,
                  ) as NS
                : UnixSemaphore(
                    name: name,
                    counter: counter ??
                        SemaphoreCounter.instantiate<I, CU, CD, CT, CTS, CTR, CTRS>(
                          identity: identity ??
                              SemaphoreIdentity.instantiate<I, IS>(
                                name: name,
                              ) as I,
                        ) as CTR,
                    verbose: verbose,
                  ) as NS,
          );
  }

  @protected
  bool willAttemptPersist() {
    if (verbose) print('Evaluating [willAttemptPersist()] will persist NativeSemaphore metadata to disk at PATH: [${temp.path}]');

    _operations = PersistedNativeSemaphoreOperations.rehydrate<PNSO, PNSOS>(serialized: temp.readAsStringSync(), rehydrate_: PersistedNativeSemaphoreOperation.rehydrate, verbose: verbose);

    // TODO maybe some checks here?
    if (verbose) print('[willAttemptPersist()] Operations on PersistedNativeSemaphoreOperations: [${Platform.lineTerminator}${operations.get?.iterable.map((operation) => operation.toString()).join(','+Platform.lineTerminator)} ${Platform.lineTerminator}] ${Platform.lineTerminator}');

    return true;
  }

  @protected
  bool persist({required NATIVE_SEMAPHORE_OPERATION status}) {
    if (!willAttemptPersist()) return false;

    if (verbose) print('[persist()] Persisting $name with status: ${status}');

    print('[persist()] opened: $opened');

    DateTime timestamp = DateTime.now();

    temp.writeAsStringSync((_operations..add(operation: _operation = PersistedNativeSemaphoreOperation(name: name, uuid: identity.uuid, isolate: identity.isolate, process: identity.process, operation: status,timestamp: timestamp, address: opened ? identity.address : -1, elapsed: operation.isSet ? timestamp.difference(operation.get!.timestamp) : null, verbose: verbose, counts: (isolate: counter.counts.isolate.get(), process: counter.counts.process.get()), locked: locked, closed: closed, reentrant: reentrant, unlinked: unlinked, waiting: waiting) as PNSO)).serialize(), flush: true);

    return persistAttemptSucceeded();
  }

  @protected
  bool persistAttemptSucceeded() {
    if (verbose) print('[persistAttemptSucceeded()] Successfully persisted NativeSemaphore metadata to disk at location ${temp.path}');

    return temp.readAsStringSync() == _operations.serialize() && _operations.toString() == PersistedNativeSemaphoreOperations.rehydrate<PNSO, PNSOS>(serialized: temp.readAsStringSync(), rehydrate_: PersistedNativeSemaphoreOperation.rehydrate).toString() || (throw Exception('Failed to persist NativeSemaphore metadata to disk. Operations are not the same.'));
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

  @protected
  bool willAttemptUnlockReentrantToIsolate() => throw UnimplementedError();

  @protected
  bool unlockReentrantToIsolate() => throw UnimplementedError();

  @protected
  bool unlockAttemptReentrantToIsolateSucceeded() => throw UnimplementedError();

  bool unlock() => throw UnimplementedError();

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
