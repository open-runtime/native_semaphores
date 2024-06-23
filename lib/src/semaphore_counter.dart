import 'package:meta/meta.dart' show protected;
import 'semaphore_identity.dart' show SemaphoreIdentity;
import 'utils/late_property_assigned.dart' show LatePropertyAssigned;

class SemaphoreCountUpdate {
  // Updated for parent identifier
  final String identifier;
  // Updated from a specific count
  final int? from;
  // Updated to a specific count
  final int to;

  SemaphoreCountUpdate({required String this.identifier, required int this.to, int? this.from = null});
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

  SemaphoreCount({required String identifier, required String this.forProperty, bool this.verbose = false}) {
    this.identifier = identifier + "_for_$forProperty";
    update(value: 0);
  }

  int get() => counts[identifier] ?? (throw Exception('Failed to get semaphore count for $identifier.'));

  @protected
  CU update({required int value}) {
    CU _update = SemaphoreCountUpdate(identifier: identifier, from: counts.putIfAbsent(identifier, () => null) ?? counts[identifier], to: counts[identifier] = value) as CU;

    if (verbose)
      _update.from == null
          ? print("Semaphore count for $identifier initialized to ${_update.to}.")
          : print("Semaphore count for $identifier updated from ${_update.from} to ${_update.to}.");

    return _update;
  }

  CD delete() {
    CD _deletion = SemaphoreCountDeletion(identifier: identifier, at: counts.remove(identifier)) as CD;

    if (verbose)
      _deletion.at == null ? print("Semaphore count for $identifier does not exist.") : print("Semaphore count for $identifier deleted with final count at ${_deletion.at}.");

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
  // Updated by reentrant locks and unlocks
  // Subsequent locks and unlocks will increment and decrement the _isolate count
  late final CT isolate;

  // Updated by external lock requests i.e. read from shared memory or file locks/counting
  // Potentially _processes would include _isolate?
  // Initially I'll implement as the initial lock will increment the process count
  // and the final unlock will decrement the process count
  late final CT process;
  // todo maybe add a global/semaphore name counter? i.e. letting me know how many locks are currently active including processes and reentrant isolates
  // todo maybe on a caller level i.e. specific to recursion as they would all have the same call trace identity?

  SemaphoreCounts({required CT isolate, required CT process}) {
    this.isolate = isolate;
    this.process = process;
  }
}

// A wrapper to track the instances of the semaphore counter
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
    /* Semaphore Counter */
    CTR extends SemaphoreCounter<I, CU, CD, CT, CTS>
    /* formatting guard comment */
    > {
  static final Map<String, dynamic> __counters = {};

  Map<String, dynamic> get _counters => SemaphoreCounters.__counters;

  Map<String, CTR> get all => Map.unmodifiable(_counters as Map<String, CTR>);

  bool has<T>({required String identifier}) => _counters.containsKey(identifier) && _counters[identifier] is T;

  // Returns the semaphore identity for the given identifier as a singleton
  CTR get({required String identifier}) => _counters[identifier] as CTR? ?? (throw Exception('Failed to get semaphore counter for $identifier. It doesn\'t exist.'));

  CTR register({required String identifier, required CTR counter}) {
    (_counters.containsKey(identifier) || counter != _counters[identifier]) ||
        (throw Exception('Failed to register semaphore counter for $identifier. It already exists or is not the same as the inbound identity being passed.'));

    return _counters.putIfAbsent(identifier, () => counter) as CTR;
  }

  void delete({required String identifier}) {
    _counters.containsKey(identifier) || (throw Exception('Failed to delete semaphore counter for $identifier. It doesn\'t exist.'));
    _counters.remove(identifier);
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
    CTS extends SemaphoreCounts<CU, CD, CT>
    /* formatting guard comment */
    > {
  static late final dynamic __instances;

  // ignore: unused_element
  dynamic get _instances => SemaphoreCounter.__instances;

  late final String identifier;
  late final I identity;
  late final CTS counts;

  SemaphoreCounter({required String this.identifier, required I this.identity, required CTS this.counts});

  static SemaphoreCounter<I, CU, CD, CT, CTS> instantiate<
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
      /* Semaphore Counter i.e. this class */
      CTR extends SemaphoreCounter<I, CU, CD, CT, CTS>,
      /* Semaphore Counters */
      CTRS extends SemaphoreCounters<I, CU, CD, CT, CTS, CTR>
      /* formatting guard comment */
      >({required I identity}) {
    if (!LatePropertyAssigned<CTRS>(() => __instances)) __instances = SemaphoreCounters<I, CU, CD, CT, CTS, CTR>();

    return (__instances as CTRS).has<CTR>(identifier: identity.name)
        ? (__instances as CTRS).get(identifier: identity.name)
        : (__instances as CTRS).register(
            identifier: identity.name,
            counter: SemaphoreCounter<I, CU, CD, CT, CTS>(
              identity: identity,
              counts: (SemaphoreCounts<CU, CD, CT>(
                // Super important to pass the forProperty as the name of the property that the counter is set on
                isolate: SemaphoreCount(identifier: identity.name, forProperty: 'isolate') as CT,
                process: SemaphoreCount(identifier: identity.name, forProperty: 'process') as CT,
              ) as CTS),
              identifier: identity.name,
            ) as CTR,
          );
  }
}
