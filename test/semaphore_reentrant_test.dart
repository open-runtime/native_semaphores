import 'dart:io' show Platform, sleep;
import 'dart:isolate' show Isolate, ReceivePort, SendPort;
import 'dart:math' show Random;

import 'package:chalkdart/chalk.dart';
import 'package:runtime_native_semaphores/runtime_native_semaphores.dart' show NativeSemaphore;
import 'package:runtime_native_semaphores/src/native_semaphore_operations.dart';
import 'package:runtime_native_semaphores/src/native_semaphore_types.dart' show NS;
import 'package:safe_int_id/safe_int_id.dart' show safeIntId;
import 'package:test/test.dart' show equals, everyElement, expect, group, test;

void main() {
  List<Chalk> colors = [chalk.blue, chalk.cyan, chalk.green, chalk.yellow, chalk.brightBlue, chalk.brightCyan, chalk.brightGreen, chalk.brightRed, chalk.brightYellow, chalk.brightWhite, chalk.brightBlack];

  group('Testing Reentrant Semaphores within a single isolate', () {
    test('Testing top level semaphore behavior as baseline.', () async {
      String name = '${safeIntId.getId()}_named_sem';
      String tracer = chalk.brightMagenta('Root Semaphore');

      // Create a new native semaphore
      final NS sem = NativeSemaphore.instantiate(name: name, tracerFn: () => tracer);
      print(tracer);

      expect(sem.opened, equals(false));

      bool opened = sem.open();

      expect(opened, equals(true));
      expect(sem.opened, equals(true));
      expect(sem.closed, equals(false));

      // expect sem to be locked
      expect(sem.locked, equals(false));
      bool locked = sem.lock();
      print(locked.toString() + " LOCKED");

      expect(locked, equals(true));
      expect(sem.locked, equals(true));
      expect(sem.counter.counts.process_locks.get(), equals(1));

      // unlock the semaphore
      expect(sem.unlocked, equals(false));
      bool unlocked = sem.unlock();

      expect(unlocked, equals(true));
      expect(sem.unlocked, equals(true));
      expect(sem.locked, equals(false));
      expect(sem.counter.counts.process_locks.get(), equals(0));

      // close the semaphore
      expect(sem.closed, equals(false));
      bool closed = sem.close();


      expect(closed, equals(true));
      expect(sem.opened, equals(true));
      expect(sem.closed, equals(true));

      expect(sem.unlinked, equals(false));
      bool unlinked = sem.unlink();
      expect(unlinked, equals(true));
      expect(sem.closed, equals(true));
      expect(sem.unlinked, equals(true));
    });

    test('Reentrant & Recursive', () async {
      int depth = 0; // i.e. one process lock and 3 reentrant locks
      String name = '${safeIntId.getId()}_named_sem';
      String tracer = chalk.brightMagenta('Root Semaphore');
      final NS sem = NativeSemaphore.instantiate(name: name, tracerFn: () => tracer);

      print(tracer);

      sem.statuses.identity.tracerFn() == tracer || (throw Exception("Tracer should be $tracer but is ${sem.statuses.identity.tracerFn()}"));
      sem.statuses.instantiated.tracerFn() == tracer || (throw Exception("Tracer should be $tracer but is ${sem.statuses.instantiated.tracerFn()}"));
      sem.statuses.opened.tracerFn() == tracer || (throw Exception("Tracer should be $tracer but is ${sem.statuses.opened.tracerFn()}"));
      sem.statuses.locked.tracerFn() == tracer || (throw Exception("Tracer should be $tracer but is ${sem.statuses.locked.tracerFn()}"));
      sem.statuses.unlocked.tracerFn() == tracer || (throw Exception("Tracer should be $tracer but is ${sem.statuses.unlocked.tracerFn()}"));
      sem.statuses.closed.tracerFn() == tracer || (throw Exception("Tracer should be $tracer but is ${sem.statuses.closed.tracerFn()}"));
      sem.statuses.unlinked.tracerFn() == tracer || (throw Exception("Tracer should be $tracer but is ${sem.statuses.unlinked.tracerFn()}"));

      sem
        ..open()
        ..lock();

      // Function to unlock and close the semaphore
      void _recursiveUnlockAndClose(NativeSemaphore sem, int currentDepth) {
        if (currentDepth == 5) return;
        String tracer = colors[sem.depth]('Semaphore at depth ${sem.depth}');
        print(Platform.lineTerminator * 10);
        print(colors[sem.depth]("UNLOCKING AND CLOSING AND UNLINKING AT ") + tracer + " " + ("=" * 100));
        print(Platform.lineTerminator * 10);
        print(NativeSemaphoreProcessOperationStatuses.depth(sem.identity.name.get));
        print(tracer);

        sem.statuses.identity.tracerFn = () => tracer;
        sem.statuses.instantiated.tracerFn = () => tracer;
        sem.statuses.opened.tracerFn = () => tracer;
        sem.statuses.locked.tracerFn = () => tracer;
        sem.statuses.unlocked.tracerFn = () => tracer;
        sem.statuses.closed.tracerFn = () => tracer;
        sem.statuses.unlinked.tracerFn = () => tracer;

        sem.statuses.identity.tracerFn() == tracer || (throw Exception("Tracer should be $tracer but is ${sem.statuses.identity.tracerFn()}"));
        sem.statuses.instantiated.tracerFn() == tracer || (throw Exception("Tracer should be $tracer but is ${sem.statuses.instantiated.tracerFn()}"));
        sem.statuses.opened.tracerFn() == tracer || (throw Exception("Tracer should be $tracer but is ${sem.statuses.opened.tracerFn()}"));
        sem.statuses.locked.tracerFn() == tracer || (throw Exception("Tracer should be $tracer but is ${sem.statuses.locked.tracerFn()}"));
        sem.statuses.unlocked.tracerFn() == tracer || (throw Exception("Tracer should be $tracer but is ${sem.statuses.unlocked.tracerFn()}"));
        sem.statuses.closed.tracerFn() == tracer || (throw Exception("Tracer should be $tracer but is ${sem.statuses.closed.tracerFn()}"));
        sem.statuses.unlinked.tracerFn() == tracer || (throw Exception("Tracer should be $tracer but is ${sem.statuses.unlinked.tracerFn()}"));

        expect(sem.unlocked, false);
        bool unlocked = sem.unlock();
        expect(unlocked, equals(true));
        expect(sem.unlocked, true);

        expect(sem.closed, false);
        bool closed = sem.close();
        expect(closed, true);
        expect(sem.closed, true);

        expect(sem.unlinked, false);
        bool unlinked = sem.unlink();
        expect(unlinked, true);
        expect(sem.unlinked, true);
      }

      // Recursive function to open, lock, and then call itself if depth > 0
      void _recursiveOpenAndLock(String name, int currentDepth) {
        if (currentDepth == 5) return;
        String tracer = colors[currentDepth]('Semaphore at depth $currentDepth');
        print(Platform.lineTerminator * 10);
        print(colors[currentDepth]("OPENING AND LOCKING AT ") + tracer + " " + ("=" * 100));
        print(Platform.lineTerminator * 10);

        final NS sem = NativeSemaphore.instantiate(name: name, tracerFn: () => tracer);
        print(tracer);

        sem.statuses.identity.tracerFn() == tracer || (throw Exception("Tracer should be $tracer but is ${sem.statuses.identity.tracerFn()}"));
        sem.statuses.instantiated.tracerFn() == tracer || (throw Exception("Tracer should be $tracer but is ${sem.statuses.instantiated.tracerFn()}"));
        sem.statuses.opened.tracerFn() == tracer || (throw Exception("Tracer should be $tracer but is ${sem.statuses.opened.tracerFn()}"));
        sem.statuses.locked.tracerFn() == tracer || (throw Exception("Tracer should be $tracer but is ${sem.statuses.locked.tracerFn()}"));
        sem.statuses.unlocked.tracerFn() == tracer || (throw Exception("Tracer should be $tracer but is ${sem.statuses.unlocked.tracerFn()}"));
        sem.statuses.closed.tracerFn() == tracer || (throw Exception("Tracer should be $tracer but is ${sem.statuses.closed.tracerFn()}"));
        sem.statuses.unlinked.tracerFn() == tracer || (throw Exception("Tracer should be $tracer but is ${sem.statuses.unlinked.tracerFn()}"));

        expect(sem.opened, false);
        bool opened = sem.open();
        expect(opened, equals(true));

        expect(sem.unlocked, false);
        expect(sem.locked, false);
        bool locked = sem.lock();
        expect(locked, equals(true));
        expect(sem.unlocked, equals(false));
        expect(sem.locked, equals(true));
        expect(sem.counter.counts.process_locks.get(), equals(1));
        expect(sem.counter.counts.isolate_locks.get(), equals(currentDepth));

        sleep(Duration(milliseconds: Random().nextInt(1000)));

        // Recursive call
        _recursiveOpenAndLock(name, currentDepth + 1);

        // Unlock and close in the reverse order of locking
        _recursiveUnlockAndClose(sem, currentDepth);
      }

      // await Future.delayed(Duration(seconds: 2));

      print(Platform.lineTerminator * 10);
      print("=" * 100);
      print(Platform.lineTerminator * 10);

      // Generate a unique name for the semaphore
      // Start the recursive locking and unlocking process
      _recursiveOpenAndLock(name, ++depth);

      // await Future.delayed(Duration(seconds: 2));

      print(tracer);

      sem.statuses.identity.tracerFn = () => tracer;
      sem.statuses.instantiated.tracerFn = () => tracer;
      sem.statuses.opened.tracerFn = () => tracer;
      sem.statuses.locked.tracerFn = () => tracer;
      sem.statuses.unlocked.tracerFn = () => tracer;
      sem.statuses.closed.tracerFn = () => tracer;
      sem.statuses.unlinked.tracerFn = () => tracer;

      sem.statuses.instantiated.tracerFn() == tracer || (throw Exception("Tracer should be $tracer but is ${sem.statuses.instantiated.tracerFn()}"));
      sem.statuses.identity.tracerFn() == tracer || (throw Exception("Tracer should be $tracer but is ${sem.statuses.identity.tracerFn()}"));
      sem.statuses.instantiated.tracerFn() == tracer || (throw Exception("Tracer should be $tracer but is ${sem.statuses.instantiated.tracerFn()}"));
      sem.statuses.opened.tracerFn() == tracer || (throw Exception("Tracer should be $tracer but is ${sem.statuses.opened.tracerFn()}"));
      sem.statuses.locked.tracerFn() == tracer || (throw Exception("Tracer should be $tracer but is ${sem.statuses.locked.tracerFn()}"));
      sem.statuses.unlocked.tracerFn() == tracer || (throw Exception("Tracer should be $tracer but is ${sem.statuses.unlocked.tracerFn()}"));
      sem.statuses.closed.tracerFn() == tracer || (throw Exception("Tracer should be $tracer but is ${sem.statuses.closed.tracerFn()}"));
      sem.statuses.unlinked.tracerFn() == tracer || (throw Exception("Tracer should be $tracer but is ${sem.statuses.unlinked.tracerFn()}"));

      expect(sem.counter.counts.process_locks.get(), equals(1));
      expect(sem.counter.counts.isolate_locks.get(), equals(0));

      expect(sem.locked, true);
      expect(sem.unlocked, false);
      expect(sem.unlock(), true);
      expect(sem.unlocked, true);
      expect(sem.closed, false);
      expect(sem.close(), true);
      expect(sem.closed, true);
      expect(sem.unlinked, false);
      expect(sem.unlink(), true);
      expect(sem.unlinked, true);

      expect(sem.counter.counts.process_locks.get(), equals(0));
      expect(sem.locked, equals(false));

      print(Platform.lineTerminator * 10);

      (<NativeSemaphoreProcessOperationStatusState>[]..addAll(NativeSemaphoreProcessOperationStatuses.all)).where((element) => element.operation.name.contains("instantiate") || element.operation.name.contains("Succeeded")).map((e) => [e.tracer, e.hash, e.operation, "state: ${e.state}", "completed: ${e.completed.get}", "reentrant: ${e.reentrant}"]).forEach(print);
    });

    test('Reentrant Behavior Across Several Isolates', () async {
      Future<bool> spawn_isolate(String name, int id) async {
        // The entry point for the isolate
        void isolate_entrypoint(SendPort sender) {
          // Captures the call frame here, put right right inside the method entrypoint

          int depth = 0;

          // Function to unlock and close the semaphore
          void _recursiveUnlockAndClose(NativeSemaphore sem, int currentDepth) {
            if (currentDepth == 5) return;
            String tracer = colors[currentDepth +  (2 * id)]('Semaphore at depth ${sem.depth} in isolate $id');
            print(Platform.lineTerminator * 10);
            print(colors[currentDepth +  (2 * id)]("UNLOCKING AND CLOSING AND UNLINKING AT ") + tracer + " " + ("=" * 100));
            print(Platform.lineTerminator * 10);
            print(NativeSemaphoreProcessOperationStatuses.depth(sem.identity.name.get));
            print(tracer);

            sem.statuses.identity.tracerFn = () => tracer;
            sem.statuses.instantiated.tracerFn = () => tracer;
            sem.statuses.opened.tracerFn = () => tracer;
            sem.statuses.locked.tracerFn = () => tracer;
            sem.statuses.unlocked.tracerFn = () => tracer;
            sem.statuses.closed.tracerFn = () => tracer;
            sem.statuses.unlinked.tracerFn = () => tracer;

            sem.statuses.identity.tracerFn() == tracer || (throw Exception("Tracer should be $tracer but is ${sem.statuses.identity.tracerFn()}"));
            sem.statuses.instantiated.tracerFn() == tracer || (throw Exception("Tracer should be $tracer but is ${sem.statuses.instantiated.tracerFn()}"));
            sem.statuses.opened.tracerFn() == tracer || (throw Exception("Tracer should be $tracer but is ${sem.statuses.opened.tracerFn()}"));
            sem.statuses.locked.tracerFn() == tracer || (throw Exception("Tracer should be $tracer but is ${sem.statuses.locked.tracerFn()}"));
            sem.statuses.unlocked.tracerFn() == tracer || (throw Exception("Tracer should be $tracer but is ${sem.statuses.unlocked.tracerFn()}"));
            sem.statuses.closed.tracerFn() == tracer || (throw Exception("Tracer should be $tracer but is ${sem.statuses.closed.tracerFn()}"));
            sem.statuses.unlinked.tracerFn() == tracer || (throw Exception("Tracer should be $tracer but is ${sem.statuses.unlinked.tracerFn()}"));

            // final NS sem = NativeSemaphore.instantiate(name: name, tracerFn: () => tracer);
            // print(tracer);
            bool unlocked = sem.unlock();
            unlocked || (throw Exception("Unlock in isolate $id should have succeeded ${sem.identity.identifier}"));

            sem.counter.counts.isolate_locks.get() == currentDepth - (currentDepth - sem.counter.counts.isolate_locks.get()) || (throw Exception("Unlock in isolate $id should have succeeded"));

            bool closed = sem.close();
            closed || (throw Exception("Close in isolate $id should have succeeded"));

            bool unlinked = sem.unlink();
            unlinked || (throw Exception("Unlink in isolate $id should have succeeded"));
          }

          // Recursive function to open, lock, and then call itself if depth > 0
          void _recursiveOpenAndLock(String _name, int currentDepth) {
            if (currentDepth == 5) return;
            String tracer = colors[currentDepth +  (2 * id)]('Semaphore at depth ${currentDepth} in isolate $id');
            print(Platform.lineTerminator * 10);
            print(colors[currentDepth +  (2 * id)]("OPENING AND LOCKING AT ") + tracer + " " + ("=" * 100));
            print(Platform.lineTerminator * 10);

            final NS sem = NativeSemaphore.instantiate(name: name, tracerFn: () => tracer);
            print(tracer);

            sem.statuses.identity.tracerFn() == tracer || (throw Exception("Tracer should be $tracer but is ${sem.statuses.identity.tracerFn()}"));
            sem.statuses.instantiated.tracerFn() == tracer || (throw Exception("Tracer should be $tracer but is ${sem.statuses.instantiated.tracerFn()}"));
            sem.statuses.opened.tracerFn() == tracer || (throw Exception("Tracer should be $tracer but is ${sem.statuses.opened.tracerFn()}"));
            sem.statuses.locked.tracerFn() == tracer || (throw Exception("Tracer should be $tracer but is ${sem.statuses.locked.tracerFn()}"));
            sem.statuses.unlocked.tracerFn() == tracer || (throw Exception("Tracer should be $tracer but is ${sem.statuses.unlocked.tracerFn()}"));
            sem.statuses.closed.tracerFn() == tracer || (throw Exception("Tracer should be $tracer but is ${sem.statuses.closed.tracerFn()}"));
            sem.statuses.unlinked.tracerFn() == tracer || (throw Exception("Tracer should be $tracer but is ${sem.statuses.unlinked.tracerFn()}"));

            bool opened = sem.open();
            opened || (throw Exception("Open in isolate $id should have succeeded"));
            sem.opened || (throw Exception("Open in isolate $id should have succeeded"));

            bool locked = sem.lock();
            locked || (throw Exception("Lock in isolate $id should have succeeded"));
            sem.locked || (throw Exception("Lock in isolate $id should have succeeded"));
            sem.counter.counts.process_locks.get() == 1 || (throw Exception("Lock in isolate $id should have succeeded"));

            // Recursive call
            _recursiveOpenAndLock(name, currentDepth + 1);

            sleep(Duration(milliseconds: Random().nextInt(1000)));

            // Unlock and close in the reverse order of locking
            _recursiveUnlockAndClose(sem, currentDepth);
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
      final result_zero = spawn_isolate(name, 0);
      final result_one = spawn_isolate(name, 1);
      final result_two = spawn_isolate(name, 2);
      final result_three = spawn_isolate(name, 3);

      // Wait for both isolates to complete their work
      final outcomes = await Future.wait([result_zero, result_one, result_two, result_three]);

      String tracer = chalk.brightMagenta('Root Semaphore');
      final NS sem = NativeSemaphore.instantiate(name: name, tracerFn: () => tracer);
      print(tracer);

      final disposed = (sem
            ..open()
            ..close())
          .unlink();

      expect(disposed, equals(true));
      expect(outcomes, everyElement(equals(true)));
    });
  });
}
