import 'dart:io' show Directory, File, Platform;

// import '../runtime_native_semaphores.dart' show NATIVE_SEMAPHORE_OPERATION_STATUS;
import 'package:runtime_native_semaphores/runtime_native_semaphores.dart';

import 'semaphore_identity.dart' show SemaphoreIdentity;
import 'singleton.dart';
import 'utils/later_property_set.dart';

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

class SemaphoreCount {
  static final Map<String, int?> _counts = {};
  static Map<String, int?> get all => Map.unmodifiable(_counts);

  late final String identifier;

  final String forProperty;

  SemaphoreCount({required String identifier, required String this.forProperty}) {
    this.identifier = identifier + "_for_$forProperty";
    _update(value: 0);
  }

  int get() => _counts[identifier] ?? (throw Exception('Failed to get semaphore count for $identifier.'));

  SemaphoreCountUpdate _update({required int value}) {
    SemaphoreCountUpdate _update = SemaphoreCountUpdate(
        identifier: identifier,
        from: _counts.putIfAbsent(identifier, () => null) ?? _counts[identifier],
        to: _counts[identifier] = value);

    if (NativeSemaphore.verbose)
      _update.from == null
          ? print("Semaphore count for $identifier initialized to ${_update.to}.")
          : print("Semaphore count for $identifier updated from ${_update.from} to ${_update.to}.");

    return _update;
  }

  SemaphoreCountDeletion delete() {
    SemaphoreCountDeletion _deletion = SemaphoreCountDeletion(identifier: identifier, at: _counts.remove(identifier));

    if (NativeSemaphore.verbose)
      _deletion.at == null
          ? print("Semaphore count for $identifier does not exist.")
          : print("Semaphore count for $identifier deleted with final count at ${_deletion.at}.");

    return _deletion;
  }

  // todo? (total - count) <= 1 || (throw Exception('Failed to increment semaphore count.'));
  SemaphoreCountUpdate increment() => _update(value: get() + 1);

  // todo? (count - total) <= 1 || (throw Exception('Failed to decrement semaphore count.'));
  SemaphoreCountUpdate decrement() => _update(value: get() - 1);
}

class SemaphoreCounts<
    /* Semaphore Count */
    CT extends SemaphoreCount
    /* Singleton Semaphore Count */
    /* SCT extends Singleton<CT> */
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
    /* Semaphore Identities */
    // IS extends SemaphoreIdentities<I>,
    /* Semaphore Count */
    CT extends SemaphoreCount,
    /* Semaphore Counts */
    CTS extends SemaphoreCounts<CT>,
    /* Semaphore Counter */
    CTR extends SemaphoreCounter<I, CT, CTS>
    /* formatting guard comment */
    > {
  static final Map<String, dynamic> _counters = {};
  Map<String, CTR> get all => Map.unmodifiable(_counters as Map<String, CTR>);

  bool has<T>({required String identifier}) => _counters.containsKey(identifier) && _counters[identifier] is T;

  // Returns the semaphore identity for the given identifier as a singleton
  CTR get({required String identifier}) =>
      _counters[identifier] ?? (throw Exception('Failed to get semaphore counter for $identifier. It doesn\'t exist.'));

  CTR register({required String identifier, required CTR counter}) {
    (_counters.containsKey(identifier) || counter != _counters[identifier]) ||
        (throw Exception(
            'Failed to register semaphore counter for $identifier. It already exists or is not the same as the inbound identity being passed.'));

    return _counters.putIfAbsent(identifier, () => counter);
  }

  void delete({required String identifier}) {
    _counters.containsKey(identifier) ||
        (throw Exception('Failed to delete semaphore counter for $identifier. It doesn\'t exist.'));
    _counters.remove(identifier);
  }
}

// Enum to represent types of operations i.e. LOCK, UNLOCK, CREATE, DISPOSE
class SemaphoreCounter<
    /*  Identity */
    I extends SemaphoreIdentity,
    /* Semaphore Identities */
    // IS extends SemaphoreIdentities<I>,
    /* Semaphore Count */
    CT extends SemaphoreCount,
    /* Semaphore Counts */
    CTS extends SemaphoreCounts<CT>
    /* formatting guard comment */
    > {
  static late final dynamic _instances;
  // static late final dynamic _identities;

  // final IS identities = _identities as IS;
  // final CTS counts = _counts as CTS;

  late final String identifier;
  late final I identity;
  late final CTS counts;

  SemaphoreCounter._({required String this.identifier, required I this.identity, required CTS this.counts});

  static SemaphoreCounter<I, CT, CTS> instantiate<
      /*  Identity */
      I extends SemaphoreIdentity,
      /* Semaphore Identities */
      // IS extends SemaphoreIdentities<I>,
      /* Semaphore Count */
      CT extends SemaphoreCount,
      /* Semaphore Counts */
      CTS extends SemaphoreCounts<CT>,
      /* Semaphore Counter i.e. this class */
      CTR extends SemaphoreCounter<I, CT, CTS>,
      /* Semaphore Counters */
      CTRS extends SemaphoreCounters<I, CT, CTS, CTR>
      /* formatting guard comment */
      >({required I identity}) {
    if (!LatePropertyAssigned<CTRS>(() => SemaphoreCounter._instances))
      SemaphoreCounter._instances = SemaphoreCounters<I, CT, CTS, CTR>();

    return (SemaphoreCounter._instances as CTRS).has<CTR>(identifier: identity.name)
        ? (SemaphoreCounter._instances as CTRS).get(identifier: identity.name)
        : (SemaphoreCounter._instances as CTRS).register(
            identifier: identity.name,
            counter: SemaphoreCounter<I, CT, CTS>._(
              identity: identity,
              counts: (SemaphoreCounts<CT>(
                // Super important to pass the forProperty as the name of the property that the counter is set on
                isolate: SemaphoreCount(identifier: identity.name, forProperty: 'isolate') as CT,
                process: SemaphoreCount(identifier: identity.name, forProperty: 'process') as CT,
              ) as CTS),
              identifier: identity.name,
            ) as CTR,
          );
  }
}
