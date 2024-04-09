import 'dart:ffi' show AbiSpecificIntegerPointer, Char, Finalizable, NativeType, Pointer;
import 'dart:io' show Platform;

import 'package:ffi/ffi.dart';
import 'package:runtime_native_semaphores/ffi/unix.dart';
import 'package:runtime_native_semaphores/ffi/windows.dart';

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
