library runtime_native_semaphores.semaphore;

import 'dart:ffi' show AbiSpecificIntegerPointer, Char, Finalizable, NativeType, Pointer;
import 'dart:io' show Platform, sleep;

import 'package:ffi/ffi.dart';
import 'package:meta/meta.dart';
import 'package:runtime_native_semaphores/src/unix_semaphore.dart';
import 'package:runtime_native_semaphores/src/windows_semaphore.dart';

// import '../runtime_native_semaphores.dart'
//     show NativeSemaphoreStatus, NATIVE_SEMAPHORE_STATUS, SemaphoreCounter, SemaphoreIdentity;
import '../runtime_native_semaphores.dart';

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
    /* Native Semaphore */
    NS extends NativeSemaphore<I, IS, CU, CD, CT, CTS, CTR, CTRS>
    /* formatting guard comment */
    > {
  static final Map<String, dynamic> __instantiations = {};

  final Map<String, dynamic> _instantiations = NativeSemaphores.__instantiations;

  Map<String, NS> get all => Map.unmodifiable(_instantiations as Map<String, NS>);

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
    CTRS extends SemaphoreCounters<I, CU, CD, CT, CTS, CTR>
    /* formatting guard comment */
    > implements Finalizable {
  static late final dynamic __instances;

  dynamic get _instances => NativeSemaphore.__instances;

  static bool verbose = true;

  late final String name;

  late final CTR counter;

  I get identity => counter.identity;

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

  late final bool hasUnlinked;

  bool get unlinked => LatePropertyAssigned<bool>(() => hasUnlinked) ? !opened && closed && hasUnlinked : false;

  // identities are always bound to a unique counter and thus the identity for the counter is the identity for the semaphore
  // late final I identity = counter.identity;

  // get locked i.e. the count of the semaphore
  bool get locked => throw UnimplementedError();

  // if we are reentrant internally
  // bool get reentrant => throw UnimplementedError();

  NativeSemaphore({required String this.name, required CTR this.counter});

  // TODO maybe a rehydrate method? or instantiate takes in a "from process" flag i.e. to attempt to find and rehydrate the semaphore from another process/all processes
  static NativeSemaphore<I, IS, CU, CD, CT, CTS, CTR, CTRS> instantiate<
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
      /* Native Semaphore */
      NS extends NativeSemaphore<I, IS, CU, CD, CT, CTS, CTR, CTRS>,
      /*Native Semaphores*/
      NSS extends NativeSemaphores<I, IS, CU, CD, CT, CTS, CTR, CTRS, NS>
      /* formatting guard comment */
      >({required String name, I? identity, CTR? counter}) {
    if (!LatePropertyAssigned<NSS>(() => __instances)) {
      __instances = NativeSemaphores<I, IS, CU, CD, CT, CTS, CTR, CTRS, NS>();
      if (NativeSemaphore.verbose) print('Setting NativeSemaphore._instances: ${__instances}');
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
                  ) as NS,
          );
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
  bool lockAcrossProcesses({bool blocking = true}) => throw UnimplementedError();
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
