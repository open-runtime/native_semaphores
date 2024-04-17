import 'dart:developer';
import 'dart:io';
import 'dart:isolate';
import "package:stack_trace/stack_trace.dart";

import 'semaphore_metadata.dart';

typedef CaptureCallFrameResult = String;

class CapturedCallFrame {
  final Trace current = Trace.current(0);

  late final String caller = current.frames.take(5).map((e) => e.uri.hashCode).join("_");

  CapturedCallFrame();
}

class SemaphoreIdentity {
  static final Map<String, SemaphoreIdentity> identities = {};

  SemaphoreMetadata get metadata => SemaphoreMetadata();

  static const String _prefix = 'runtime_native_semaphores';

  static final String _isolate =
      (Service.getIsolateId(Isolate.current)?.toString() ?? (throw Exception('Failed to get isolate id')))
          .replaceAll("isolates", "")
          .substring(1);

  static final String _process = pid.toString();

  String get prefix => _prefix;

  String get isolate => _isolate;

  String get process => _process;

  late final CapturedCallFrame _frame;

  CapturedCallFrame get frame => _frame;

  late final String _caller = frame.caller;

  String get caller => _caller;

  late final String _semaphore;

  String get semaphore => _semaphore;

  late final bool _registered;

  bool get registered => _registered;

  String uuid() => [_semaphore, _isolate, _process, _caller].join('_');

  SemaphoreIdentity({required String semaphore, CapturedCallFrame? frame}) {
    _frame = frame ?? CapturedCallFrame();
    semaphore = semaphore.replaceFirst('Global\\', '').replaceFirst('Local\\', '');
    // check if identifier has invalid characters
    if (semaphore.contains(RegExp(r'[\\/:*?"<>|]'))) throw ArgumentError('Identifier contains invalid characters.');
    _semaphore = semaphore;

    _register();
  }

  bool _register() {
    return _registered =
        SemaphoreIdentity.identities.putIfAbsent(_semaphore, () => this) == metadata.register(identity: this);
  }

  // TODO potentially a dispose fromCall?
  bool dispose() {
    return SemaphoreIdentity.identities.remove(_semaphore) is SemaphoreIdentity;
  }

  @override
  String toString() {
    return 'SemaphoreIdentity(semaphore: $_semaphore, isolate: $_isolate, process: $_process, caller: $_caller)';
  }
}
