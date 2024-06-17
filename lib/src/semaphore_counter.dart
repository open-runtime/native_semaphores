import 'package:meta/meta.dart' show protected;

import 'native_semaphore_operations.dart';
import 'semaphore_identity.dart' show SemaphoreIdentity;
import 'utils/late_property_assigned.dart' show LatePropertyAssigned;

class SemaphoreCountUpdate {
  // Updated for parent identifier
  final String identifier;

  // Updated from a specific count
  final int? from;

  // Updated to a specific count
  final int to;

  SemaphoreCountUpdate({required String this.identifier, int? this.from = null, required int this.to});
}

class SemaphoreCountDeletion {
  // Deleted for parent identifier
  final String identifier;

  // Deleted at a specific count
  final int? at;

  SemaphoreCountDeletion({required String this.identifier, int? this.at = null});
}

class SemaphoreCount<CU extends SemaphoreCountUpdate, CD extends SemaphoreCountDeletion> {
  static final Map<String, int?> __counts = {};

  bool verbose;

  @protected
  Map<String, int?> get counts => SemaphoreCount.__counts;

  Map<String, int?> get all => Map.unmodifiable(counts);

  late final String identifier;

  final String forProperty;

  SemaphoreCount({required String identifier, required String this.forProperty, int value = 0, bool this.verbose = false}) {
    this.identifier = identifier + "_for_$forProperty";
    update(value: value);
  }

  int get() => counts[identifier] ?? (throw Exception('Failed to get semaphore count for $identifier.'));

  @protected
  CU update({required int value}) {
    CU _update = SemaphoreCountUpdate(identifier: identifier, from: counts.putIfAbsent(identifier, () => null) ?? counts[identifier], to: counts[identifier] = value) as CU;

    if (verbose) _update.from == null ? print("Semaphore count for $identifier initialized to ${_update.to}.") : print("Semaphore count for $identifier updated from ${_update.from} to ${_update.to}.");

    return _update;
  }

  CD delete() {
    CD _deletion = SemaphoreCountDeletion(identifier: identifier, at: counts.remove(identifier)) as CD;

    if (verbose) _deletion.at == null ? print("Semaphore count for $identifier does not exist.") : print("Semaphore count for $identifier deleted with final count at ${_deletion.at}.");

    return _deletion;
  }

  // todo? (total - count) <= 1 || (throw Exception('Failed to increment semaphore count.'));
  CU increment() => update(value: get() + 1);

  // todo? (count - total) <= 1 || (throw Exception('Failed to decrement semaphore count.'));
  CU decrement() => update(value: get() - 1);
}

class SemaphoreCounts<
/* Count Update */
    CU extends SemaphoreCountUpdate,
/* Count Deletion */
    CD extends SemaphoreCountDeletion,
/* Semaphore Count */
    CT extends SemaphoreCount<CU, CD>
/* formatting guard comment */
    > {
  late final CT instantiated;

  late final CT opened;

  late final CT reentrant;

  late final CT closed;

  late final CT unlinked;

  // Updated by reentrant locks and unlocks
  // Subsequent locks and unlocks will increment and decrement the _isolate count
  late final CT isolate_locks;

  // Updated by external lock requests i.e. read from shared memory or file locks/counting
  // Potentially _processes would include _isolate?
  // Initially I'll implement as the initial lock will increment the process count
  // and the final unlock will decrement the process count
  late final CT process_locks;

  // todo maybe add a global/semaphore name counter? i.e. letting me know how many locks are currently active including processes and reentrant isolates
  // todo maybe on a caller level i.e. specific to recursion as they would all have the same call trace identity?

  SemaphoreCounts({required CT isolate_locks, required CT process_locks, required CT reentrant, required CT opened, required CT closed, required CT unlinked, required CT instantiated}) {
    this.instantiated = instantiated;
    this.opened = opened;
    this.reentrant = reentrant;
    this.isolate_locks = isolate_locks;
    this.process_locks = process_locks;
    this.closed = closed;
    this.unlinked = unlinked;
  }
}

// A wrapper to track the instances of the semaphore counter
// TODO refactor to be the same as the semaphore identity
class SemaphoreCounters<
/*  Identity */
    I extends SemaphoreIdentity,
/* Count Update */
    CU extends SemaphoreCountUpdate,
/* Count Deletion */
    CD extends SemaphoreCountDeletion,
/* Semaphore Count */
    CT extends SemaphoreCount<CU, CD>,
/* Semaphore Counts */
    CTS extends SemaphoreCounts<CU, CD, CT>,
    NSPOSS extends NativeSemaphoreProcessOperationStatusState,
    NSPOS extends NativeSemaphoreProcessOperationStatus<I, NSPOSS>,
    NSPOSES extends NativeSemaphoreProcessOperationStatuses<I, NSPOSS, NSPOS>,
/* Semaphore Counter */
    CTR extends SemaphoreCounter<I, CU, CD, CT, CTS, NSPOSS, NSPOS, NSPOSES>
/* formatting guard comment */
    > {
  static final Map<String, dynamic> __counters = {};

  Map<String, dynamic> get _counters => SemaphoreCounters.__counters;

  Map<String, CTR> get all => Map.unmodifiable(_counters as Map<String, CTR>);

  bool has<T>({required I identity}) => _counters.containsKey(identity.identifier) && _counters[identity.identifier] is T;

  // Returns the semaphore identity for the given identifier as a singleton
  CTR get({required I identity}) => _counters[identity.identifier] ?? (throw Exception('Failed to get semaphore counter for ${identity.identifier}. It doesn\'t exist.'));

  CTR register({required I identity, required CTR counter}) {
    (_counters.containsKey(identity.identifier) || counter != _counters[identity.identifier]) || (throw Exception('Failed to register semaphore counter for ${identity.identifier}. It already exists or is not the same as the inbound identity being passed.'));

    return _counters.putIfAbsent(identity.identifier, () => counter);
  }

  void delete({required I identity}) {
    _counters.containsKey(identity.identifier) || (throw Exception('Failed to delete semaphore counter for ${identity.identifier}. It doesn\'t exist.'));
    _counters.remove(identity.identifier);
  }
}

// Enum to represent types of operations i.e. LOCK, UNLOCK, CREATE, DISPOSE
class SemaphoreCounter<
/*  Identity */
    I extends SemaphoreIdentity,
    CU extends SemaphoreCountUpdate,
    CD extends SemaphoreCountDeletion,
/* Semaphore Count */
    CT extends SemaphoreCount<CU, CD>,
/* Semaphore Counts */
    CTS extends SemaphoreCounts<CU, CD, CT>,
    NSPOSS extends NativeSemaphoreProcessOperationStatusState,
    NSPOS extends NativeSemaphoreProcessOperationStatus<I, NSPOSS>,
    NSPOSES extends NativeSemaphoreProcessOperationStatuses<I, NSPOSS, NSPOS>
/* formatting guard comment */
    > {
  static late final dynamic __counters;

  SemaphoreCounters<I, CU, CD, CT, CTS, NSPOSS, NSPOS, NSPOSES, CTR> all<I extends SemaphoreIdentity, CU extends SemaphoreCountUpdate, CD extends SemaphoreCountDeletion, CT extends SemaphoreCount<CU, CD>, CTS extends SemaphoreCounts<CU, CD, CT>, NSPOSS extends NativeSemaphoreProcessOperationStatusState, NSPOS extends NativeSemaphoreProcessOperationStatus<I, NSPOSS>, NSPOSES extends NativeSemaphoreProcessOperationStatuses<I, NSPOSS, NSPOS>, CTR extends SemaphoreCounter<I, CU, CD, CT, CTS, NSPOSS, NSPOS, NSPOSES>>() => __counters;

  late final NSPOSES statuses = NativeSemaphoreProcessOperationStatuses<I, NSPOSS, NSPOS>(identity: identity, tracerFn: () => tracer) as NSPOSES;

  late final String identifier;

  late String Function() tracerFn;

  String get tracer => tracerFn();

  late final I identity;

  late final CTS counts;

  bool verbose;

  bool external;

  SemaphoreCounter({required String this.identifier, required String Function() this.tracerFn, required I this.identity, required CTS this.counts, bool this.verbose = false, bool this.external = false});

  static SemaphoreCounter<I, CU, CD, CT, CTS, NSPOSS, NSPOS, NSPOSES> instantiate<
      /*  Identity */
      I extends SemaphoreIdentity,
      /* Count Update */
      CU extends SemaphoreCountUpdate,
      /* Count Deletion */
      CD extends SemaphoreCountDeletion,
      /* Semaphore Count */
      CT extends SemaphoreCount<CU, CD>,
      /* Semaphore Counts */
      CTS extends SemaphoreCounts<CU, CD, CT>,
      NSPOSS extends NativeSemaphoreProcessOperationStatusState,
      NSPOS extends NativeSemaphoreProcessOperationStatus<I, NSPOSS>,
      NSPOSES extends NativeSemaphoreProcessOperationStatuses<I, NSPOSS, NSPOS>,
      /* Semaphore Counter i.e. this class */
      CTR extends SemaphoreCounter<I, CU, CD, CT, CTS, NSPOSS, NSPOS, NSPOSES>,
      /* Semaphore Counters */
      CTRS extends SemaphoreCounters<I, CU, CD, CT, CTS, NSPOSS, NSPOS, NSPOSES, CTR>
      /* formatting guard comment */
      >({required I identity, required String Function() tracerFn, ({int instantiated, int process_locks, int isolate_locks, int reentrant, int opened, int closed, int unlinked}) counts = (isolate_locks: 0, process_locks: 0, reentrant: 0, opened: 0, closed: 0, unlinked: 0, instantiated: 0), bool external = false, bool verbose = false}) {

    if (!LatePropertyAssigned<CTRS>(() => __counters)) __counters = SemaphoreCounters<I, CU, CD, CT, CTS, NSPOSS, NSPOS, NSPOSES, CTR>();

    return (__counters as CTRS).has<CTR>(identity: identity)
        ? ((__counters as CTRS).get(identity: identity)..tracerFn = () => tracerFn())
        : (__counters as CTRS).register(
            identity: identity,
            counter: SemaphoreCounter<I, CU, CD, CT, CTS, NSPOSS, NSPOS, NSPOSES>(
              tracerFn: () => tracerFn(),
              identity: identity,
              external: external,
              counts: (SemaphoreCounts<CU, CD, CT>(
                // Super important to pass the forProperty as the name of the property that the counter is set on
                instantiated: SemaphoreCount(identifier: identity.identifier, forProperty: 'instantiated', value: counts.instantiated, verbose: verbose) as CT,
                opened: SemaphoreCount(identifier: identity.identifier, forProperty: 'opened', value: counts.opened, verbose: verbose) as CT,
                process_locks: SemaphoreCount(identifier: identity.identifier, forProperty: 'process_locks', value: counts.process_locks, verbose: verbose) as CT,
                isolate_locks: SemaphoreCount(identifier: identity.identifier, forProperty: 'isolate_locks', value: counts.isolate_locks, verbose: verbose) as CT,
                reentrant: SemaphoreCount(identifier: identity.identifier, forProperty: 'reentrant', value: counts.reentrant, verbose: verbose) as CT,
                closed: SemaphoreCount(identifier: identity.identifier, forProperty: 'closed', value: counts.closed, verbose: verbose) as CT,
                unlinked: SemaphoreCount(identifier: identity.identifier, forProperty: 'unlinked', value: counts.unlinked, verbose: verbose) as CT,
              ) as CTS),
              identifier: identity.identifier,
              verbose: verbose,
            ) as CTR,
          );
  }

  // track an external semaphore from a different process to this processes semaphore counters
  SemaphoreCounter<I, CU, CD, CT, CTS, NSPOSS, NSPOS, NSPOSES> track<
      /*  Identity */
      I extends SemaphoreIdentity,
      /* Count Update */
      CU extends SemaphoreCountUpdate,
      /* Count Deletion */
      CD extends SemaphoreCountDeletion,
      /* Semaphore Count */
      CT extends SemaphoreCount<CU, CD>,
      /* Semaphore Counts */
      CTS extends SemaphoreCounts<CU, CD, CT>,
      NSPOSS extends NativeSemaphoreProcessOperationStatusState,
      NSPOS extends NativeSemaphoreProcessOperationStatus<I, NSPOSS>,
      NSPOSES extends NativeSemaphoreProcessOperationStatuses<I, NSPOSS, NSPOS>,
      /* Semaphore Counter i.e. this class */
      CTR extends SemaphoreCounter<I, CU, CD, CT, CTS, NSPOSS, NSPOS, NSPOSES>,
      /* Semaphore Counters */
      CTRS extends SemaphoreCounters<I, CU, CD, CT, CTS, NSPOSS, NSPOS, NSPOSES, CTR>
      /* formatting guard comment */
      >({required I identity, required String Function() tracerFn, ({int instantiated, int process_locks, int isolate_locks, int reentrant, int opened, int closed, int unlinked}) counts = (isolate_locks: 0, process_locks: 0, reentrant: 0, opened: 0, closed: 0, unlinked: 0, instantiated: 0), bool external = false, bool verbose = false}) {
    return instantiate<I, CU, CD, CT, CTS, NSPOSS, NSPOS, NSPOSES, CTR, CTRS>(identity: identity, counts: counts, external: true, verbose: verbose, tracerFn: () => tracerFn());
  }
}
