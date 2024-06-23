import 'dart:async' show Future;
import 'dart:io' show File, Platform, Process, ProcessResult;

import 'package:runtime_native_semaphores/runtime_native_semaphores.dart'
    show NativeSemaphore;
import 'package:safe_int_id/safe_int_id.dart' show safeIntId;
import 'package:test/expect.dart';
import 'package:test/test.dart'
    show  equals,  expect, group, isTrue, setUp, test;

String processRequest(Map<String, dynamic> request) {
  // Implement your logic here
  return 'Processed from parent: ${request['data']}';
}

void main() async {
  String process_name =
      'bin${Platform.pathSeparator}test${Platform.pathSeparator}primary_semaphore${Platform.isWindows ? '.exe' : ''}';

  setUp(() async {
    File primary_semaphore_executable = File(process_name);

    if (!primary_semaphore_executable.existsSync()) {
      ProcessResult compiling_primary_semaphore_executable =
          Process.runSync('dart', [
        'compile',
        'exe',
        'bin${Platform.pathSeparator}test${Platform.pathSeparator}primary_semaphore.dart',
        '-o',
        process_name
      ]);

      print(
          'Successfully compiled primary_semaphore_executable: ${compiling_primary_semaphore_executable.stdout}');

      primary_semaphore_executable.existsSync() ||
          (throw Exception("Primary semaphore executable should exist."));
    } else {
      print(
          'Primary semaphore was found and already compiled. Be sure you haven\'t made changes and need to compile again.');
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
        Process.run(process_name,
            [name, /*lock delay */ '0', /* unlock delay */ '4', 'first']),
        // Secondary process with lock delay of 2 i.e. 2 seconds into the first processes unlock delay
        Process.run(process_name,
            [name, /*lock delay */ '2', /* unlock delay */ '0', 'second'])
      ]);

      // Start with unlock delay of 2
      ProcessResult running_primary_semaphore_executable = processes.first;
      // Start with unlock delay of 4
      ProcessResult running_secondary_semaphore_executable = processes.last;

      print(
          '${Platform.lineTerminator}Primary Process:${Platform.lineTerminator}${Platform.lineTerminator} ${running_primary_semaphore_executable.stdout} ${Platform.lineTerminator}');
      print(
          '${Platform.lineTerminator}Secondary Process:${Platform.lineTerminator}${Platform.lineTerminator} ${running_secondary_semaphore_executable.stdout} ${Platform.lineTerminator}${Platform.lineTerminator}');

      // use regex to parse the number [x] out of this return string "Child Process first 55852 Locking semaphore with name 44314234863597_named_sem took: [3] seconds"
      RegExp lock_time = RegExp(
          r"Locking semaphore with name \d+_named_sem took: \[(\d+)\] seconds");

      int? primary_lock_time = int.tryParse(lock_time
              .firstMatch(running_primary_semaphore_executable.stdout as String)
              ?.group(1) ??
          '-1');
      int? secondary_lock_time = int.tryParse(lock_time
              .firstMatch(
                  running_secondary_semaphore_executable.stdout as String)
              ?.group(1) ??
          '-1');

      print('primary_lock_time: $primary_lock_time seconds to lock');
      print('secondary_lock_time: $secondary_lock_time seconds to lock');

      expect(primary_lock_time, equals(anyOf([3, 4])));
      expect(secondary_lock_time, equals(anyOf([4, 5, 6])));

      expect(sem.close(), isTrue);
      expect(sem.unlink(), isTrue);
    });
  });
}
