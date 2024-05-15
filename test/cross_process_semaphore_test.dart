import 'dart:async' show Future, StreamController, StreamIterator, StreamSink, StreamSubscription, StreamTransformer;
import 'dart:convert' show jsonDecode, jsonEncode, utf8;
import 'dart:io' show File, Process, ProcessResult, ProcessSignal, ProcessStartMode, pid, sleep, stdin, stdout;
import 'dart:isolate' show Isolate, ReceivePort, SendPort;
import 'dart:math' show Random;

import 'package:runtime_native_semaphores/runtime_native_semaphores.dart' show NativeSemaphore;
import 'package:safe_int_id/safe_int_id.dart' show safeIntId;
import 'package:runtime_native_semaphores/src/native_semaphore_types.dart' show NS;
import 'package:test/test.dart' show Timeout, equals, everyElement, expect, group, isTrue, setUp, test;

String processRequest(Map<String, dynamic> request) {
  // Implement your logic here
  return 'Processed from parent: ${request['data']}';
}

void main() async {

  String process_name = 'bin/test/primary_semaphore';

  setUp(() async {

    File primary_semaphore_executable = File(process_name);

    if(!primary_semaphore_executable.existsSync()) {

      ProcessResult compiling_primary_semaphore_executable = await Process.run('dart', ['compile', 'exe', 'bin/test/primary_semaphore.dart', '-o', process_name]);

      print('Successfully compiled primary_semaphore_executable: ${compiling_primary_semaphore_executable.stdout}');

      primary_semaphore_executable.existsSync() || (throw Exception("Primary semaphore executable should exist."));
    } else {
      print('Primary semaphore was found and already compiled. Be sure you haven\'t made changes and need to compile again.');
    }
  });


  group('Testing Cross-Process Named Semaphore', () {
    test('Several Processes Coordinated Leveraging Named Locks', () async {
      String name = '${safeIntId.getId()}_named_sem';

      final NativeSemaphore sem = NativeSemaphore.instantiate(name: name)
        ..open()
        ..lock();

      Future.delayed(Duration(seconds: 4), () => sem.unlock());

      // It takes about 1 second rounded up to spin up each process here i.e. the first lock should take about 3 seconds to acquire given the delay above
      // The second process should take about 5 seconds to acquire the lock given the unlock delay of 4 seconds of the first process and the roughly 1 second it takes to spin up the first process
      List<ProcessResult> processes = await Future.wait([
        // Initial process with lock delay of 0 locks right away
        Process.run(process_name, [name, /*lock delay */ '0', /* unlock delay */ '4', 'first'], runInShell: true),
        // Secondary process with lock delay of 2 i.e. 2 seconds into the first processes unlock delay
        Process.run(process_name, [name, /*lock delay */ '2', /* unlock delay */ '0', 'second'], runInShell: true)
      ]);

      // Start with unlock delay of 2
      ProcessResult running_primary_semaphore_executable = processes.first;
      // Start with unlock delay of 4
      ProcessResult running_secondary_semaphore_executable = processes.last;

      // use regex to parse the number [x] out of this return string "Child Process first 55852 Locking semaphore with name 44314234863597_named_sem took: [3] seconds"
      RegExp lock_time = RegExp(r"Locking semaphore with name \d+_named_sem took: \[(\d+)\] seconds");

      int? primary_lock_time = int.tryParse(lock_time.firstMatch(running_primary_semaphore_executable.stdout)?.group(1) ?? '-1');
      int? secondary_lock_time = int.tryParse(lock_time.firstMatch(running_secondary_semaphore_executable.stdout)?.group(1) ?? '-1');

      print('primary_lock_time: $primary_lock_time seconds to lock');
      print('secondary_lock_time: $secondary_lock_time seconds to lock');

      expect(primary_lock_time, equals(3));
      expect(secondary_lock_time, equals(5));

      expect(sem.close(), isTrue);
      expect(sem.unlink(), isTrue);

    }, timeout: Timeout(Duration(seconds: 60)));
  });
}
