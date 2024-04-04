import 'dart:ffi' show Finalizable;
import 'dart:io' show Platform;

part 'windows_semaphore.dart';
part 'unix_semaphore.dart';

sealed class NativeSemaphore implements Finalizable {
  final String identifier;

  int get address => throw UnimplementedError(
      "Class Property Getter 'address' in Sealed Abstract Class 'NamedLock' is Unimplemented.");

  NativeSemaphore._({required String this.identifier});

  factory NativeSemaphore({required String identifier}) =>
      Platform.isWindows ? _WindowsSemaphore(identifier: identifier) : _UnixSemaphore(identifier: identifier);

  bool acquire() => throw UnimplementedError();

  bool lock() => throw UnimplementedError();

  bool unlock() => throw UnimplementedError();

  bool dispose() => throw UnimplementedError();

  String toString() => throw UnimplementedError();
}
