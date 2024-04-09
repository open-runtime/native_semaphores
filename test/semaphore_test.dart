import 'dart:ffi' show Pointer;
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:ffi/ffi.dart' show StringUtf16Pointer, malloc;
import 'package:runtime_native_semaphores/ffi/windows.dart';
import 'package:runtime_native_semaphores/semaphore.dart';
import 'package:safe_int_id/safe_int_id.dart' show safeIntId;

import 'package:test/test.dart'
    show
        TestOn,
        contains,
        equals,
        everyElement,
        expect,
        group,
        isA,
        isNonZero,
        isTrue,
        isZero,
        setUp,
        tearDown,
        test,
        throwsA;

void main() {
  group('Testing Cross-Isolate Named Semaphore', () {
    test('Several Isolates Accessing Same Named Semaphore, waiting random durations and then unlocking.', () async {
      Future<bool> spawn_isolate(String name, int id) async {
        // The entry point for the isolate
        void isolate_entrypoint(SendPort sender) {
          NativeSemaphore sem = NativeSemaphore(identifier: name);

          // Lock
          bool locked = sem.lock();
          locked || (throw Exception("Lock in isolate $id should have succeeded"));

          sleep(Duration(milliseconds: Random().nextInt(1000)));

          // Unlock
          bool unlocked = sem.unlock();
          unlocked || (throw Exception("Unlock in isolate $id should have succeeded"));

          // Dispose
          bool disposed = sem.dispose();
          disposed || (throw Exception("Dispose in isolate $id should have succeeded"));

          sender.send(true);
        }

        // Create a receive port to get messages from the isolate
        final ReceivePort receiver = ReceivePort();

        // Spawn the isolate
        await Isolate.spawn(isolate_entrypoint, receiver.sendPort);

        // Wait for the isolate to send its message
        return await receiver.first;
      }

      String name = '/${safeIntId.getId()}-named-sem';

      // Spawn the first helper isolate
      final result_one = spawn_isolate(name, 1);
      final result_two = spawn_isolate(name, 2);
      final result_three = spawn_isolate(name, 3);
      final result_four = spawn_isolate(name, 4);

      // Wait for both isolates to complete their work
      final outcomes = await Future.wait([result_one, result_two, result_three, result_four]);

      expect(outcomes, everyElement(equals(true)));
    });
  });
}
