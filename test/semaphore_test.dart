import 'dart:io' show sleep;
import 'dart:isolate' show Isolate, ReceivePort, SendPort;
import 'dart:math' show Random;

import 'package:runtime_native_semaphores/runtime_native_semaphores.dart'
    show NativeSemaphore, NativeSemaphoreExecutionType, NativeSemaphoreGuardedExecution;
import 'package:runtime_native_semaphores/src/semaphore_identity.dart' show CapturedCallFrame, SemaphoreIdentity;
import 'package:safe_int_id/safe_int_id.dart' show safeIntId;

import 'package:test/test.dart' show equals, everyElement, expect, group, test;

void main() {
  group('Testing Cross-Isolate Named Semaphore', () {
    test('Several Isolates Accessing Same Named Semaphore, waiting random durations and then unlocking.', () async {
      Future<bool> spawn_isolate(String name, int id) async {
        // The entry point for the isolate
        void isolate_entrypoint(SendPort sender) {
          // Captures the call frame here, put right right inside the method entrypoint
          CapturedCallFrame frame = CapturedCallFrame();
          SemaphoreIdentity identity = SemaphoreIdentity(semaphore: name, frame: frame);
          NativeSemaphore sem = NativeSemaphore(identity: identity);

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

      String name = '${safeIntId.getId()}_named_sem';

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

  group('Testing Reentrant Named Semaphore Behavior', () {
    test('Several Isolates Accessing Same Named Semaphore, waiting random durations and then unlocking.', () async {
      String name = '${safeIntId.getId()}_named_sem';

      bool nested_lock() {
        // Captures the call frame here, put right right inside the method entrypoint
        CapturedCallFrame _frame = CapturedCallFrame();
        SemaphoreIdentity _identity = SemaphoreIdentity(semaphore: name, frame: _frame);
        NativeSemaphore _sem = NativeSemaphore(identity: _identity);

        // Lock
        bool locked = _sem.lock();
        locked ||
            (throw Exception(
                "Nested Lock should have succeeded with true as it is the second lock and therefore already locked"));

        sleep(Duration(milliseconds: Random().nextInt(1000)));

        // Unlock
        bool unlocked = _sem.unlock();
        !unlocked ||
            (throw Exception("Nested Unlock should have returned false as it will get unlocked on the upper level"));

        // Dispose
        bool disposed = _sem.dispose();
        !disposed ||
            (throw Exception("Nested Dispose should have returned false as it will get disposed on the upper level"));

        return true;
      }

      // Captures the call frame here, put right right inside the method entrypoint
      CapturedCallFrame frame = CapturedCallFrame();
      SemaphoreIdentity identity = SemaphoreIdentity(semaphore: name, frame: frame);
      NativeSemaphore sem = NativeSemaphore(identity: identity);

      // Lock
      bool locked = sem.lock();
      locked || (throw Exception("Parent Lock should have succeeded"));

      nested_lock();

      // Unlock
      bool unlocked = sem.unlock();
      unlocked || (throw Exception("Parent Unlock should have succeeded"));

      // Dispose
      bool disposed = sem.dispose();
      disposed || (throw Exception("Parent Dispose should have succeeded"));
    });

    test('Several Isolates Running Guard, waiting random durations and then unlocking.', () async {
      String name = '${safeIntId.getId()}_named_sem';

      bool nested_lock() {
        // Captures the call frame here, put right right inside the method entrypoint
        CapturedCallFrame _frame = CapturedCallFrame();
        SemaphoreIdentity _identity = SemaphoreIdentity(semaphore: name, frame: _frame);
        NativeSemaphore _sem = NativeSemaphore(identity: _identity);

        // Lock
        bool locked = _sem.lock();
        locked ||
            (throw Exception(
                "Nested Lock should have succeeded with true as it is the second lock and therefore already locked"));

        sleep(Duration(milliseconds: Random().nextInt(1000)));

        // Unlock
        bool unlocked = _sem.unlock();
        !unlocked ||
            (throw Exception("Nested Unlock should have returned false as it will get unlocked on the upper level"));

        // Dispose
        bool disposed = _sem.dispose();
        !disposed ||
            (throw Exception("Nested Dispose should have returned false as it will get disposed on the upper level"));

        return true;
      }

      Future<bool> spawn_isolate(String name, int id) async {
        // The entry point for the isolate
        void isolate_entrypoint(SendPort sender) {
          final NativeSemaphoreGuardedExecution<bool> returnable =
              NativeSemaphore.guard(NativeSemaphoreGuardedExecution<bool>(
                  identifier: name,
                  callable: () {
                    sleep(Duration(milliseconds: Random().nextInt(100)));
                    nested_lock();
                    return true;
                  }));

          sender.send(returnable.value);
        }

        // Create a receive port to get messages from the isolate
        final ReceivePort receiver = ReceivePort();

        // Spawn the isolate
        await Isolate.spawn(isolate_entrypoint, receiver.sendPort);

        // Wait for the isolate to send its message
        return await receiver.first;
      }

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
