import 'dart:io' show sleep;
import 'dart:isolate' show Isolate, ReceivePort, SendPort;
import 'dart:math' show Random;

import 'package:runtime_native_semaphores/runtime_native_semaphores.dart' show NativeSemaphore;
import 'package:runtime_native_semaphores/src/native_semaphore_types.dart' show NS;
import 'package:safe_int_id/safe_int_id.dart' show safeIntId;

import 'package:test/test.dart' show equals, everyElement, expect, group, test;

void main() {
  group('Testing Reentrant Semaphores within a single isolate', () {
    test('Testing top level semaphore behavior as baseline.', () async {
      String name = '${safeIntId.getId()}_named_sem';

      // Create a new native semaphore
      final NS sem = NativeSemaphore.instantiate(name: name);

      print('Semaphore: $sem');

      expect(sem.opened, equals(false));

      bool opened = sem.open();

      expect(opened, equals(true));
      expect(sem.opened, equals(true));
      expect(sem.closed, equals(false));

      // expect sem to be locked
      expect(sem.locked, equals(false));

      bool locked = sem.lock();

      expect(locked, equals(true));
      expect(sem.locked, equals(true));
      expect(sem.counter.counts.process.get(), equals(1));

      // unlock the semaphore
      bool unlocked = sem.unlock();

      expect(unlocked, equals(true));
      expect(sem.locked, equals(false));
      expect(sem.counter.counts.process.get(), equals(0));

      bool closed = sem.close();

      expect(closed, equals(true));
      expect(sem.closed, equals(true));
      expect(sem.opened, equals(false));

      bool unlinked = sem.unlink();
      expect(unlinked, equals(true));
      expect(sem.closed, equals(true));
      expect(sem.unlinked, equals(true));
    });

    test('Testing top level semaphore behavior as baseline.', () {
      int depth = 4; // i.e. one process lock and 3 reentrant locks
      String name = '${safeIntId.getId()}_named_sem';
      // SemaphoreIdentity identity = SemaphoreIdentity.instantiate(name: name);
      // SemaphoreCounter counter = SemaphoreCounter.instantiate(identity: identity);

      // Function to unlock and close the semaphore
      void _recursiveUnlockAndClose(String name, int currentDepth) {
        if (currentDepth <= 0) return;

        final NS sem = NativeSemaphore.instantiate(name: name);

        bool unlocked = sem.unlock();
        expect(unlocked, equals(true));

        bool closed = sem.close();
        expect(closed, equals(currentDepth == depth ? true : false));
        expect(sem.closed, equals(currentDepth == depth ? true : false));

        bool unlinked = sem.unlink();
        expect(unlinked, equals(currentDepth == depth ? true : false));
        expect(sem.unlinked, equals(currentDepth == depth ? true : false));
      }

      // Recursive function to open, lock, and then call itself if depth > 0
      void _recursiveOpenAndLock(String name, int currentDepth) {
        if (currentDepth <= 0) return;

        final NS sem = NativeSemaphore.instantiate(name: name);
        bool opened = sem.open();
        expect(opened, equals(true));

        bool locked = sem.lock();
        expect(locked, equals(true));
        expect(sem.locked, equals(true));
        expect(sem.counter.counts.process.get(), equals(1));

        expect(
          sem.counter.counts.isolate.get(),
          equals(currentDepth - (currentDepth - sem.counter.counts.isolate.get())),
        );

        sleep(Duration(milliseconds: Random().nextInt(1000)));

        // Recursive call
        _recursiveOpenAndLock(name, currentDepth - 1);

        // Unlock and close in the reverse order of locking
        _recursiveUnlockAndClose(name, currentDepth);
      }

      // Generate a unique name for the semaphore
      // Start the recursive locking and unlocking process
      _recursiveOpenAndLock(name, depth);

      final NS sem = NativeSemaphore.instantiate(name: name);
      expect(sem.counter.counts.process.get(), equals(0));
      expect(sem.counter.counts.isolate.get(), equals(0));
      expect(sem.locked, equals(false));
      expect(sem.closed, equals(true));
      expect(sem.unlinked, equals(true));
    });

    test('Reentrant Behavior Across Several Isolates', () async {
      Future<bool> spawn_isolate(String name, int id) async {
        // The entry point for the isolate
        void isolate_entrypoint(SendPort sender) {
          // Captures the call frame here, put right right inside the method entrypoint

          int depth = 4; // i.e. one process lock and 3 reentrant locks

          // Function to unlock and close the semaphore
          void _recursiveUnlockAndClose(String _name, int currentDepth) {
            if (currentDepth <= 0) return;

            final NS sem = NativeSemaphore.instantiate(name: _name);

            bool unlocked = sem.unlock();
            unlocked || (throw Exception("Unlock in isolate $id should have succeeded ${sem.identity.uuid}"));

            sem.counter.counts.isolate.get() == currentDepth - (currentDepth - sem.counter.counts.isolate.get()) ||
                (throw Exception("Unlock in isolate $id should have succeeded"));

            bool closed = sem.close();
            if (currentDepth == depth)
              closed || (throw Exception("Close in isolate $id should have succeeded"));
            else
              !closed || (throw Exception("Close in isolate $id should have failed"));

            bool unlinked = sem.unlink();
            if (currentDepth == depth)
              unlinked || (throw Exception("Unlink in isolate $id should have succeeded"));
            else
              !unlinked || (throw Exception("Unlink in isolate $id should have failed"));
          }

          // Recursive function to open, lock, and then call itself if depth > 0
          void _recursiveOpenAndLock(String _name, int currentDepth) {
            if (currentDepth <= 0) return;

            final NS sem = NativeSemaphore.instantiate(name: _name);
            bool opened = sem.open();
            opened || (throw Exception("Open in isolate $id should have succeeded"));
            sem.opened || (throw Exception("Open in isolate $id should have succeeded"));

            bool locked = sem.lock();
            locked || (throw Exception("Lock in isolate $id should have succeeded"));
            sem.locked || (throw Exception("Lock in isolate $id should have succeeded"));
            sem.counter.counts.process.get() == 1 || (throw Exception("Lock in isolate $id should have succeeded"));

            sleep(Duration(milliseconds: Random().nextInt(1000)));

            // Recursive call
            _recursiveOpenAndLock(_name, currentDepth - 1);

            // Unlock and close in the reverse order of locking
            _recursiveUnlockAndClose(_name, currentDepth);
          }

          // Generate a unique name for the semaphore
          // Start the recursive locking and unlocking process
          _recursiveOpenAndLock(name, depth);

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
