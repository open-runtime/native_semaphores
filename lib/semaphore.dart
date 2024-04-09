import 'dart:ffi' show AbiSpecificIntegerPointer, Char, Finalizable, NativeType, Pointer;
import 'dart:io' show Platform;

import "package:ffi/ffi.dart" show StringUtf16Pointer, StringUtf8Pointer, malloc;
import 'package:runtime_native_semaphores/ffi/unix.dart'
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
import 'package:runtime_native_semaphores/ffi/windows.dart'
    show
        CloseHandle,
        CreateSemaphoreW,
        LPCWSTR,
        ReleaseSemaphore,
        WaitForSingleObject,
        WindowsCreateSemaphoreWMacros,
        WindowsReleaseSemaphoreMacros,
        WindowsWaitForSingleObjectMacros;

part 'windows_semaphore.dart';
part 'unix_semaphore.dart';

sealed class NativeSemaphore implements Finalizable {
  final String identifier;

  int get address => throw UnimplementedError(
      "Class Property Getter 'address' in Sealed Abstract Class 'NamedLock' is Unimplemented.");

  NativeSemaphore._({required String this.identifier});

  factory NativeSemaphore({required String identifier}) =>
      Platform.isWindows ? _WindowsSemaphore(identifier: identifier) : _UnixSemaphore(identifier: identifier);

  bool lock({bool blocking = true}) => throw UnimplementedError();

  bool unlock() => throw UnimplementedError();

  bool dispose() => throw UnimplementedError();

  String toString() => throw UnimplementedError();
}
