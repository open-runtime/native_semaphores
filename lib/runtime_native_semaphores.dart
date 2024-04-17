import 'dart:async';
import 'dart:ffi' show AbiSpecificIntegerPointer, Char, Finalizable, NativeType, Pointer;
import 'dart:io' show Platform, sleep;
import 'dart:math';

import "package:ffi/ffi.dart" show StringUtf16Pointer, StringUtf8Pointer, malloc;
import 'package:runtime_native_semaphores/src/ffi/unix.dart'
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
import 'package:runtime_native_semaphores/src/ffi/windows.dart'
    show
        CloseHandle,
        CreateSemaphoreW,
        LPCWSTR,
        ReleaseSemaphore,
        WaitForSingleObject,
        WindowsCreateSemaphoreWMacros,
        WindowsReleaseSemaphoreMacros,
        WindowsWaitForSingleObjectMacros;
import 'package:runtime_native_semaphores/src/semaphore_metadata.dart';
import 'package:runtime_native_semaphores/src/semaphore_identity.dart' show CapturedCallFrame, SemaphoreIdentity;

part 'src/windows_semaphore.dart';
part 'src/unix_semaphore.dart';

typedef NativeSemaphoreExecutionType<R> = R Function();

class NativeSemaphoreGuardedExecution<R> {
  // TODO Completer?
  final completer = Completer<R>();

  final NativeSemaphoreExecutionType<R> _callable;

  final String _identifier;

  String get identifier => _identifier;

  late final R value;

  bool? successful;

  dynamic _error;

  void set error(dynamic error) => error != null ? successful = !((_error = error) != null) : null;

  dynamic get error => _error;

  late final NativeSemaphore guardian;

  // Identifier is the name of the semaphore
  // Callable is the function to be executed
  NativeSemaphoreGuardedExecution({required String identifier, required NativeSemaphoreExecutionType<R> callable})
      : _callable = callable,
        _identifier = identifier;

  NativeSemaphoreGuardedExecution<R> execute({required NativeSemaphore guardian}) {
    print("executing guarded code");
    try {
      final R returnable = _callable();
      print('Returnable: $returnable');

      returnable is Future
          ? (value = returnable)
              .then((_returnable) => successful = (completer..complete(_returnable)).isCompleted)
              .catchError((e) => error = e)
          : successful = (completer..complete(value = returnable)).isCompleted;
    } catch (e) {
      error = e;
      print('Error: $error');
    }

    return this;
  }
}

enum NATIVE_SEMAPHORE_OPERATION_STATUS {
  ATTEMPTING_LOCK,
  LOCKED,
  ATTEMPTING_UNLOCK,
  UNLOCKED,
  ATTEMPTING_INITIALIZATION,
  INITIALIZED,
  ATTEMPTING_CLOSE,
  CLOSED,
  ATTEMPTING_UNLINK,
  UNLINKED,
  ATTEMPTING_DISPOSAL,
  DISPOSED
}

sealed class NativeSemaphore implements Finalizable {
  final SemaphoreIdentity _identity;

  SemaphoreIdentity get identity => _identity;

  static final SemaphoreMetadata metadata = SemaphoreMetadata();

  bool _locked = false;

  get locked {
    return _locked;
  }

  bool _disposed = false;

  get disposed {
    return _disposed;
  }

  int get address => throw UnimplementedError(
      "Class Property Getter 'address' in Sealed Abstract Class 'NamedLock' is Unimplemented.");

  NativeSemaphore._({required SemaphoreIdentity identity}) : _identity = identity;

  factory NativeSemaphore({required SemaphoreIdentity identity}) =>
      Platform.isWindows ? _WindowsSemaphore(identity: identity) : _UnixSemaphore(identity: identity);

  bool lock({bool blocking = true}) => throw UnimplementedError();

  bool unlock() => throw UnimplementedError();

  bool dispose() => throw UnimplementedError();

  String toString() => throw UnimplementedError();

  // Guard and execute some code with the lock held and released it the internal execution completes
  static NativeSemaphoreGuardedExecution<T> guard<T>(NativeSemaphoreGuardedExecution<T> execution,
      {Duration timeout = const Duration(seconds: 5), bool autoDispose = true, CapturedCallFrame? frame}) {
    DateTime now = DateTime.now();

    SemaphoreIdentity identity =
        SemaphoreIdentity(semaphore: execution.identifier, frame: frame ?? CapturedCallFrame());

    NativeSemaphore guardian = NativeSemaphore(identity: identity);

    Duration _sleep = Duration(milliseconds: 2);
    int _attempt = 1;

    print('Guardian: $guardian');
    print('Guardian Status: ${guardian.locked}');

    while (!guardian.locked) {
      // TODO implement a backoff strategy
      // Exit if the timeout has been exceeded already or if the sleep time is greater than 40% of the timeout
      // TODO subtract sleep from timeout now.subtract(_sleep)
      if (DateTime.now().difference(now) > timeout) {
        execution.error = Exception('Failed to acquire lock within $timeout.');
        // This will throw because error sets successful to false
        (execution.successful ?? false) || (throw Exception('Failed to execute guarded code: ${execution.error}'));
      }

      if (guardian.lock(blocking: false)) {
        print('Guardian Locked: ${guardian.locked}');

        execution.execute(guardian: guardian);

        guardian.unlock() || (throw Exception('Failed to unlock semaphore after successful guarded code execution.'));

        (autoDispose && guardian.dispose()) ||
            (throw Exception('Failed to dispose semaphore after successful guarded code execution.'));

        // Try successful at the end to aggressively unlock and dispose of the semaphore
        (execution.successful ?? false) || (throw Exception('Failed to execute guarded code: ${execution.error}'));

        return execution;
      } else {
        sleep(_sleep);
        _sleep = Duration(milliseconds: (_sleep.inMilliseconds + _attempt * 10).clamp(5, 500));
        print('Sleeping for ${_sleep.inMilliseconds} milliseconds next time.');
        _attempt++;
      }
    }

    return execution;
  }
}
