library runtime_native_semaphores.semaphore;

import 'dart:ffi' show AbiSpecificIntegerPointer, Char, Finalizable, NativeType, Pointer;
import 'dart:io' show Platform, sleep;

import 'package:ffi/ffi.dart';

// import '../runtime_native_semaphores.dart'
//     show NativeSemaphoreStatus, NATIVE_SEMAPHORE_STATUS, SemaphoreCounter, SemaphoreIdentity;
import '../runtime_native_semaphores.dart';
import 'ffi/unix.dart'
    show
        MODE_T_PERMISSIONS,
        UnixSemLimits,
        UnixSemOpenError,
        UnixSemOpenMacros,
        errno,
        sem_close,
        sem_open,
        sem_post,
        sem_t,
        sem_trywait,
        sem_unlink,
        sem_wait;
import 'ffi/windows.dart'
    show
        CloseHandle,
        CreateSemaphoreW,
        LPCWSTR,
        ReleaseSemaphore,
        WaitForSingleObject,
        WindowsCreateSemaphoreWMacros,
        WindowsReleaseSemaphoreMacros,
        WindowsWaitForSingleObjectMacros;
import 'utils/later_property_set.dart';

part 'unix_semaphore.dart';
part 'windows_semaphore.dart';

// A wrapper to track the instances of the native semaphore
class NativeSemaphores<
    /*  Identity */
    I extends SemaphoreIdentity,
    /* Semaphore Identities */
    IS extends SemaphoreIdentities<I>,
    /* Semaphore Count */
    CT extends SemaphoreCount,
    /* Semaphore Counts */
    CTS extends SemaphoreCounts<CT>,
    /* Semaphore Counter */
    CTR extends SemaphoreCounter<I, CT, CTS>,
    /* Semaphore Counter */
    CTRS extends SemaphoreCounters<I, CT, CTS, CTR>,
    /* Native Semaphore */
    NS extends NativeSemaphore<I, IS, CT, CTS, CTR, CTRS>
    /* formatting guard comment */
    > {
  static final Map<String, dynamic> _semaphores = {};

  Map<String, NS> get all => Map.unmodifiable(_semaphores as Map<String, NS>);

  bool has<T>({required String name}) => _semaphores.containsKey(name) && _semaphores[name] is T;

  // Returns the semaphore identity for the given identifier as a singleton
  NS get({required String name}) =>
      _semaphores[name] ?? (throw Exception('Failed to get semaphore counter for $name. It doesn\'t exist.'));

  NS register({required String name, required NS semaphore}) {
    (_semaphores.containsKey(name) || semaphore != _semaphores[name]) ||
        (throw Exception(
            'Failed to register semaphore counter for $name. It already exists or is not the same as the inbound identity being passed.'));

    return _semaphores.putIfAbsent(name, () => semaphore);
  }

  void delete({required String name}) {
    _semaphores.containsKey(name) ||
        (throw Exception('Failed to delete semaphore counter for $name. It doesn\'t exist.'));
    _semaphores.remove(name);
  }
}

class NativeSemaphore<
    /*  Identity */
    I extends SemaphoreIdentity,
    /* Semaphore Identities */
    IS extends SemaphoreIdentities<I>,
    /* Semaphore Count */
    CT extends SemaphoreCount,
    /* Semaphore Counts */
    CTS extends SemaphoreCounts<CT>,
    /* Semaphore Counter */
    CTR extends SemaphoreCounter<I, CT, CTS>,
    /* Semaphore Counter */
    CTRS extends SemaphoreCounters<I, CT, CTS, CTR>
    /* formatting guard comment */
    > implements Finalizable {
  static late final dynamic _instances;

  static bool verbose = true;

  late final String name;

  late final CTR counter;

  I get identity => counter.identity;

  late final bool _opened;

  late final bool _closed;

  // If closed is assigned then opened is the opposite
  bool get opened => LatePropertyAssigned<bool>(() => _closed)
      ? !_closed
      // If opened is assigned then we return _opened otherwise false
      : LatePropertyAssigned<bool>(() => _opened)
          ? _opened
          : false;

  bool get closed => LatePropertyAssigned<bool>(() => _closed) && !opened ? _closed : false;

  late final bool _unlinked;

  bool get unlinked => LatePropertyAssigned<bool>(() => _unlinked) ? !opened && closed && _unlinked : false;

  // identities are always bound to a unique counter and thus the identity for the counter is the identity for the semaphore
  // late final I identity = counter.identity;

  // get locked i.e. the count of the semaphore
  bool get locked => throw UnimplementedError();

  // if we are reentrant internally
  bool get reentrant => throw UnimplementedError();

  NativeSemaphore._({required String this.name, required CTR this.counter});

  factory NativeSemaphore({required String name, required CTR counter}) {
    return Platform.isWindows
        ? _WindowsSemaphore<I, IS, CT, CTS, CTR, CTRS>(name: name, counter: counter)
        : _UnixSemaphore<I, IS, CT, CTS, CTR, CTRS>(name: name, counter: counter);
  }

  // TODO maybe a rehydrate method? or instantiate takes in a "from process" flag i.e. to attempt to find and rehydrate the semaphore from another process/all processes

  static NativeSemaphore<I, IS, CT, CTS, CTR, CTRS> instantiate<
      /*  Identity */
      I extends SemaphoreIdentity,
      /* Semaphore Identities */
      IS extends SemaphoreIdentities<I>,
      /* Semaphore Count */
      CT extends SemaphoreCount,
      /* Semaphore Counts */
      CTS extends SemaphoreCounts<CT>,
      /* Semaphore Counter i.e. this class */
      CTR extends SemaphoreCounter<I, CT, CTS>,
      /* Semaphore Counters */
      CTRS extends SemaphoreCounters<I, CT, CTS, CTR>,
      /* Native Semaphore */
      NS extends NativeSemaphore<I, IS, CT, CTS, CTR, CTRS>,
      /*Native Semaphores*/
      NSS extends NativeSemaphores<I, IS, CT, CTS, CTR, CTRS, NS>
      /* formatting guard comment */
      >({required String name, I? identity, CTR? counter}) {
    if (!LatePropertyAssigned<NSS>(() => NativeSemaphore._instances)) {
      // print('Setting NativeSemaphore._instances');
      // print(LatePropertyAssigned<NSS>(() => NativeSemaphore._instances));
      NativeSemaphore._instances = NativeSemaphores<I, IS, CT, CTS, CTR, CTRS, NS>();
      // print(NSS == NativeSemaphore._instances);
      // print(NSS);
      // print(NativeSemaphore._instances);
      if (NativeSemaphore.verbose) print('Setting NativeSemaphore._instances: ${NativeSemaphore._instances}');
    }

    return (NativeSemaphore._instances as NSS).has<NS>(name: name)
        ? (NativeSemaphore._instances as NSS).get(name: name)
        : (NativeSemaphore._instances as NSS).register(
            name: name,
            semaphore: NativeSemaphore(
              name: name,
              counter: counter ??
                  SemaphoreCounter.instantiate<I, CT, CTS, CTR, CTRS>(
                    identity: identity ??
                        SemaphoreIdentity.instantiate<I, IS>(
                          name: name,
                        ) as I,
                  ),
            ) as NS,
          );
  }

  bool _willAttemptOpen() => throw UnimplementedError();
  bool open() => throw UnimplementedError();
  bool _openAttemptSucceeded() => throw UnimplementedError();

  // Returns a boolean condition
  bool _willAttemptLockReentrantToIsolate() => throw UnimplementedError();
  bool _lockReentrantToIsolate() => throw UnimplementedError();
  bool _lockAttemptReentrantToIsolateSucceeded() => throw UnimplementedError();

  bool _willAttemptLockAcrossProcesses() => throw UnimplementedError();
  bool _lockAcrossProcesses({bool blocking = true}) => throw UnimplementedError();
  bool _lockAttemptAcrossProcessesSucceeded({required int attempt}) => throw UnimplementedError();

  bool lock({bool blocking = true}) => throw UnimplementedError();

  bool _willAttemptUnlockAcrossProcesses() => throw UnimplementedError();
  bool _unlockAcrossProcesses() => throw UnimplementedError();
  bool _unlockAttemptAcrossProcessesSucceeded({required int attempt}) => throw UnimplementedError();

  bool _willAttemptUnlockReentrantToIsolate() => throw UnimplementedError();
  bool _unlockReentrantToIsolate() => throw UnimplementedError();
  bool _unlockAttemptReentrantToIsolateSucceeded() => throw UnimplementedError();

  bool unlock() => throw UnimplementedError();

  bool _willAttemptClose() => throw UnimplementedError();
  bool close() => throw UnimplementedError();
  bool _closeAttemptSucceeded({required int attempt}) => throw UnimplementedError();

  bool _willAttemptUnlink() => throw UnimplementedError();
  // Unlinked will be internal as there is no such thing as unlinking on Windows
  bool _unlink() => throw UnimplementedError();
  bool _unlinkAttemptSucceeded({required int attempt}) => throw UnimplementedError();
  bool unlink() => throw UnimplementedError();

  String toString() => throw UnimplementedError();
}
