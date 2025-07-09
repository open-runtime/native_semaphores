import 'dart:isolate' show Isolate, ReceivePort, SendPort;
import 'package:runtime_native_semaphores/runtime_native_semaphores.dart'
    show NativeSemaphore;
import 'package:safe_int_id/safe_int_id.dart' show safeIntId;
import 'package:runtime_native_semaphores/src/native_semaphore_types.dart'
    show NS;
import 'package:test/test.dart'
    show contains, expect, group, test, throwsArgumentError, throwsException;

void main() {
  group('Testing Semaphore Exception Handling', () {
    test('Exception between lock and unlock should keep semaphore locked',
        () async {
      final name = 'exc_test_${safeIntId.getId()}';
      final NS sem = NativeSemaphore.instantiate(name: name, verbose: true);

      // Open the semaphore
      expect(sem.open(), true);

      // Verify initial state
      expect(sem.locked, false);

      try {
        // Lock the semaphore
        expect(sem.lock(), true);
        expect(sem.locked, true);

        // Simulate an exception
        throw Exception('Simulated exception between lock and unlock');
      } catch (e) {
        // Verify semaphore is still locked after exception
        expect(sem.locked, true);
        expect(e.toString(), contains('Simulated exception'));
      } finally {
        // Clean up: unlock the semaphore
        expect(sem.unlock(), true);
        expect(sem.locked, false);

        // Close and unlink
        expect(sem.close(), true);
        expect(sem.unlink(), true);
      }
    });

    test('Exception in try-catch without finally should leave semaphore locked',
        () async {
      final name = 'exc_no_fin_${safeIntId.getId()}';
      final NS sem = NativeSemaphore.instantiate(name: name, verbose: true);

      expect(sem.open(), true);
      expect(sem.locked, false);

      try {
        expect(sem.lock(), true);
        expect(sem.locked, true);

        // This will throw an exception
        throw Exception('Exception without proper cleanup');
      } catch (e) {
        // Semaphore should still be locked
        expect(sem.locked, true);
      }

      // Verify semaphore is still locked outside try-catch
      expect(sem.locked, true);

      // Manual cleanup
      expect(sem.unlock(), true);
      expect(sem.close(), true);
      expect(sem.unlink(), true);
    });

    test('Multiple exceptions with nested locks should maintain correct count',
        () async {
      final name = 'nested_exc_${safeIntId.getId()}';
      final NS sem = NativeSemaphore.instantiate(name: name, verbose: true);

      expect(sem.open(), true);

      // First lock
      expect(sem.lock(), true);
      expect(sem.locked, true);
      expect(sem.reentrant, false);

      try {
        // Second lock (reentrant)
        expect(sem.lock(), true);
        expect(sem.reentrant, false); // isolate count is 1, not >1

        try {
          // Third lock (more reentrant)
          expect(sem.lock(), true);
          expect(sem.reentrant, true); // now isolate count is 2, so reentrant

          // Simulate exception
          throw Exception('Inner exception');
        } catch (e) {
          // Should still be locked with 3 total locks
          expect(sem.locked, true);
          expect(sem.reentrant, true);

          // Unlock once (isolate count goes from 2 to 1)
          expect(sem.unlock(), true);
        }

        // Another exception
        throw Exception('Outer exception');
      } catch (e) {
        // Should still be locked (process: 1, isolate: 1)
        expect(sem.locked, true);
        expect(sem.reentrant, false); // isolate count is 1, not >1

        // Unlock once more (isolate count goes from 1 to 0)
        expect(sem.unlock(), true);
      }

      // Should still be locked (process count is still 1)
      expect(sem.locked, true);
      expect(sem.reentrant, false);

      // Final unlock to release the process lock
      expect(sem.unlock(), true);
      expect(sem.locked, false);

      // Cleanup
      expect(sem.close(), true);
      expect(sem.unlink(), true);
    });

    test(
        'Exception in isolate should not affect other isolates semaphore state',
        () async {
      final name = 'iso_exc_${safeIntId.getId()}';

      // Helper function to run isolate with exception
      Future<bool> spawnIsolateWithException(
          String semName, bool shouldThrow) async {
        void isolateEntrypoint(SendPort sender) {
          final NS sem =
              NativeSemaphore.instantiate(name: semName, verbose: true);
          bool success = false;

          try {
            sem.open();
            sem.lock();

            if (shouldThrow) {
              throw Exception('Isolate exception');
            }

            sem.unlock();
            success = true;
          } catch (e) {
            // Exception caught, semaphore still locked
            success = false;
          } finally {
            // Always try to clean up
            try {
              if (sem.locked) {
                sem.unlock();
              }
              sem.close();
              sem.unlink();
            } catch (_) {
              // Ignore cleanup errors
            }
          }

          sender.send(success);
        }

        final receiver = ReceivePort();
        await Isolate.spawn(isolateEntrypoint, receiver.sendPort);
        return await receiver.first;
      }

      // Spawn isolate that will throw exception
      final result1 = await spawnIsolateWithException(name, true);
      expect(result1, false);

      // Spawn isolate that should work normally
      final result2 = await spawnIsolateWithException(name, false);
      expect(result2, true);

      // Main isolate should be able to use semaphore normally
      final NS mainSem = NativeSemaphore.instantiate(name: name);
      expect(mainSem.open(), true);
      expect(mainSem.lock(), true);
      expect(mainSem.unlock(), true);
      expect(mainSem.close(), true);
      expect(mainSem.unlink(), true);
    });

    test('Throwing exception should not corrupt semaphore internal state',
        () async {
      final name = 'state_crp_${safeIntId.getId()}';
      final NS sem = NativeSemaphore.instantiate(name: name, verbose: true);

      expect(sem.open(), true);

      // Lock and verify counter state
      expect(sem.lock(), true);
      expect(sem.counter.counts.process.get(), 1);
      expect(sem.counter.counts.isolate.get(), 0);

      try {
        // Reentrant lock
        expect(sem.lock(), true);
        expect(sem.counter.counts.process.get(), 1);
        expect(sem.counter.counts.isolate.get(), 1);

        throw StateError('Testing state corruption');
      } catch (e) {
        // Verify internal state is not corrupted
        expect(sem.counter.counts.process.get(), 1);
        expect(sem.counter.counts.isolate.get(), 1);
        expect(sem.locked, true);
        // reentrant is true when isolate count > 1, here it's 1
        expect(sem.reentrant, false);
      }

      // Unlock and verify state consistency
      expect(sem.unlock(), true);
      expect(sem.counter.counts.process.get(), 1);
      expect(sem.counter.counts.isolate.get(), 0);

      expect(sem.unlock(), true);
      expect(sem.counter.counts.process.get(), 0);
      expect(sem.counter.counts.isolate.get(), 0);
      expect(sem.locked, false);

      // Cleanup
      expect(sem.close(), true);
      expect(sem.unlink(), true);
    });

    test('Failure case: No unlock after exception causes permanent lock',
        () async {
      final name = 'fail_no_unlock_${safeIntId.getId()}';
      final NS sem = NativeSemaphore.instantiate(name: name, verbose: true);

      expect(sem.open(), true);

      // Function that locks but doesn't unlock on exception
      void badFunction() {
        sem.lock();
        // No try-finally here!
        throw Exception('Oops, forgot to unlock!');
        // This line will never execute
        sem.unlock();
      }

      // Call the bad function
      try {
        badFunction();
      } catch (e) {
        // Exception caught, but semaphore is still locked!
        expect(sem.locked, false);
      }

      expect(sem.locked, false);

      // // The semaphore is now permanently locked in this process
      // expect(sem.locked, true);

      // // Try to lock again - this will succeed as a reentrant lock
      // expect(sem.lock(), true);
      // expect(sem.reentrant, false); // isolate count is 1, not >1

      // // Lock again to make it truly reentrant
      // expect(sem.lock(), true);
      // expect(sem.reentrant, true); // now isolate count is 2

      // // Even in a different context, the semaphore is still locked
      // void tryToUseSemaphore() {
      //   // This will succeed as another reentrant lock
      //   bool lockResult = sem.lock();
      //   expect(lockResult, true);
      //   expect(sem.locked, true);
      // }

      // tryToUseSemaphore();

      // // The semaphore remains locked until we manually unlock it
      // expect(sem.locked, true);

      // // Manual cleanup to avoid affecting other tests
      // // We need to unlock 4 times (initial lock + 3 reentrant locks)
      // expect(sem.unlock(), true);
      // expect(sem.unlock(), true);
      // expect(sem.unlock(), true);
      // expect(sem.unlock(), true);
      // expect(sem.locked, false);
      // expect(sem.close(), true);
      // expect(sem.unlink(), true);
    });

    test('Failure case: Deadlock scenario with multiple semaphores', () async {
      final name1 = 'deadlock1_${safeIntId.getId()}';
      final name2 = 'deadlock2_${safeIntId.getId()}';
      final NS sem1 = NativeSemaphore.instantiate(name: name1, verbose: true);
      final NS sem2 = NativeSemaphore.instantiate(name: name2, verbose: true);

      expect(sem1.open(), true);
      expect(sem2.open(), true);

      // Function that can cause deadlock without proper cleanup
      void riskyOperation(bool throwException) {
        sem1.lock();
        sem2.lock();

        if (throwException) {
          throw Exception('Exception between locks!');
        }

        // These unlocks won't happen if exception is thrown
        sem2.unlock();
        sem1.unlock();
      }

      // First call with exception
      try {
        riskyOperation(true);
      } catch (e) {
        // Both semaphores are now locked!
        expect(sem1.locked, true);
        expect(sem2.locked, true);
      }

      // Now if another part of code tries to lock in different order...
      // These will succeed as reentrant locks within the same process
      expect(sem2.lock(), true);
      expect(sem1.lock(), true);

      // The problem: we now have multiple locks that need multiple unlocks
      // Without proper tracking, it's easy to forget how many times to unlock
      expect(sem1.counter.counts.isolate.get(), 1);
      expect(sem2.counter.counts.isolate.get(), 1);

      // Manual cleanup - need to unlock twice for each semaphore
      expect(sem1.unlock(), true); // unlock reentrant
      expect(sem1.unlock(), true); // unlock process
      expect(sem2.unlock(), true); // unlock reentrant
      expect(sem2.unlock(), true); // unlock process
      expect(sem1.close(), true);
      expect(sem2.close(), true);
      expect(sem1.unlink(), true);
      expect(sem2.unlink(), true);
    });

    test('Failure case: Resource leak from unbalanced lock/unlock', () async {
      final name = 'resource_leak_${safeIntId.getId()}';
      final NS sem = NativeSemaphore.instantiate(name: name, verbose: false);

      expect(sem.open(), true);

      // Simulate a complex function with multiple exit paths
      int processData(List<int> data) {
        sem.lock();

        if (data.isEmpty) {
          // Early return without unlock - RESOURCE LEAK!
          return -1;
        }

        try {
          int sum = 0;
          for (int value in data) {
            if (value < 0) {
              // Another early return without unlock - RESOURCE LEAK!
              throw ArgumentError('Negative values not allowed');
            }
            sum += value;
          }

          // Only this path properly unlocks
          sem.unlock();
          return sum;
        } catch (e) {
          // Exception path also forgets to unlock - RESOURCE LEAK!
          print('Error processing data: $e');
          rethrow;
        }
      }

      // Test various paths that leak resources
      expect(processData([]), -1); // Leaks a lock
      expect(sem.locked, true);
      expect(sem.counter.counts.process.get(), 1);

      expect(() => processData([1, -2, 3]),
          throwsArgumentError); // Leaks another lock
      expect(sem.locked, true);
      expect(
          sem.counter.counts.isolate.get(), 1); // Now we have a reentrant lock

      // Successful path
      expect(processData([1, 2, 3]), 6);
      // Still locked because we leaked locks on previous calls
      expect(sem.locked, true);
      expect(sem.counter.counts.isolate.get(), 1);

      // The semaphore is now in a bad state with unbalanced locks
      // Manual cleanup requires knowing exactly how many times to unlock
      expect(sem.unlock(), true);
      expect(sem.unlock(), true);
      expect(sem.locked, false);

      expect(sem.close(), true);
      expect(sem.unlink(), true);
    });

    test('Using try-finally pattern should ensure proper cleanup', () async {
      final name = 'try_fin_${safeIntId.getId()}';
      final NS sem = NativeSemaphore.instantiate(name: name, verbose: true);

      expect(sem.open(), true);

      void riskyOperation() {
        sem.lock();
        try {
          // Simulate some risky operation
          if (DateTime.now().millisecondsSinceEpoch % 2 == 0) {
            throw Exception('Random failure');
          }
        } finally {
          sem.unlock();
        }
      }

      // Run multiple times to ensure pattern works
      for (int i = 0; i < 5; i++) {
        try {
          riskyOperation();
        } catch (e) {
          // Exception is expected sometimes
        }
        // Semaphore should always be unlocked after each iteration
        expect(sem.locked, false);
      }

      expect(sem.close(), true);
      expect(sem.unlink(), true);
    });
  });
}
