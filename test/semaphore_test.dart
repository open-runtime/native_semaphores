import 'dart:io' show sleep;
import 'dart:isolate' show Isolate, ReceivePort, SendPort;
import 'dart:math' show Random;

import 'package:runtime_native_semaphores/runtime_native_semaphores.dart' show NativeSemaphore;
import 'package:safe_int_id/safe_int_id.dart' show safeIntId;
import 'package:runtime_native_semaphores/src/native_semaphore_types.dart' show NS;
import 'package:test/test.dart' show equals, everyElement, expect, group, test;

void main() {
  group('Testing Cross-Isolate Named Semaphore', () {
    test('Several Isolates Accessing Same Named Semaphore, waiting random durations and then unlocking.', () async {
      Future<bool> spawn_isolate(String name, int id) async {
        // The entry point for the isolate
        void isolate_entrypoint(SendPort sender) {
          // Captures the call frame here, put right right inside the method entrypoint

          final NS sem = NativeSemaphore.instantiate(name: name, verbose: true);

          bool opened = sem.open();
          opened || (throw Exception("Open in isolate $id should have succeeded"));

          // Lock
          bool locked = sem.lock();
          locked || (throw Exception("Lock in isolate $id should have succeeded"));

          sleep(Duration(milliseconds: Random().nextInt(1000)));

          // Unlock
          bool unlocked = sem.unlock();
          unlocked || (throw Exception("Unlock in isolate $id should have succeeded ${sem.identity.uuid}"));

          // Close the semaphore
          bool closed = sem.close();
          closed || (throw Exception("Close in isolate $id should have succeeded"));

          // Unlink the semaphore
          bool unlink = sem.unlink();
          unlink || (throw Exception("Unlink in isolate $id should have succeeded"));

          sender.send(true);
        }

        // Create a receive port to get messages from the isolate
        final ReceivePort receiver = ReceivePort();

        // Spawn the isolate
        await Isolate.spawn(isolate_entrypoint, receiver.sendPort);

        // Wait for the isolate to send its message
        return await receiver.first;
      }

      String name = '${safeIntId.getId()}_named_sem';

      // Spawn the first helper isolate
      final result_one = spawn_isolate(name, 1);
      final result_two = spawn_isolate(name, 2);
      final result_three = spawn_isolate(name, 3);
      final result_four = spawn_isolate(name, 4);

      // Wait for both isolates to complete their work
      final outcomes = await Future.wait([result_one, result_two, result_three, result_four]);

      final NS sem = NativeSemaphore.instantiate(name: name);

      final disposed =
          (sem
                ..open()
                ..close())
              .unlink();

      expect(disposed, equals(true));
      expect(outcomes, everyElement(equals(true)));
    });
  });
}
