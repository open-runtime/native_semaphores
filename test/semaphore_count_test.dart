import 'dart:isolate' show Isolate, ReceivePort, SendPort;
import 'dart:math' show Random;

import 'package:chalkdart/chalk.dart' show chalk;
import 'package:runtime_native_semaphores/src/native_semaphore_types.dart' show CD, CT, CTR, CTRS, CTS, CU, I, IS, NSPOS, NSPOSES, NSPOSS;
import 'package:runtime_native_semaphores/src/semaphore_counter.dart' show SemaphoreCounter, SemaphoreCounters;
import 'package:runtime_native_semaphores/src/semaphore_identity.dart' show SemaphoreIdentities, SemaphoreIdentity;
import 'package:safe_int_id/safe_int_id.dart' show safeIntId;
import 'package:test/test.dart' show equals, everyElement, expect, group, isNot, test;

void main() {
  group('Testing Semaphore Counters Within Current Thread', () {
    test('Create Counter and verify it is Singleton', () async {
      String name = '${safeIntId.getId()}_named_sem';

      // Create a new semaphore identity
      final SemaphoreIdentity identity = SemaphoreIdentity.instantiate<I, IS>(name: name, tracerFn: () => chalk.blue('Semaphore'));

      // Create a new semaphore counter
      final SemaphoreCounter counter = SemaphoreCounter.instantiate<I, CU, CD, CT, CTS, NSPOSS, NSPOS, NSPOSES, CTR, CTRS>(identity: identity, tracerFn: () => identity.tracerFn());

      // Verify the counter is a singleton
      expect(counter, equals(SemaphoreCounter.instantiate<I, CU, CD, CT, CTS, NSPOSS, NSPOS, NSPOSES, CTR, CTRS>(identity: identity, tracerFn: () => chalk.blue('Semaphore'))));

      // Verify the counter is registered
      expect(SemaphoreCounters<I, CU, CD, CT, CTS, NSPOSS, NSPOS, NSPOSES, CTR>().has<CTR>(identity: identity), equals(true));

      // Verify that identity is a singleton
      expect(identity, equals(SemaphoreIdentity.instantiate<I, IS>(name: name, tracerFn: () => chalk.blue('Semaphore'))));

      // Verify that the identity is registered
      expect(SemaphoreIdentities<I>().has<SemaphoreIdentity>(name: name, process: identity.process, isolate: identity.isolate), equals(true));

      // Verify the isolate count is 0
      expect(counter.counts.isolate_locks.get(), equals(0));

      // increment the isolate count
      expect(counter.counts.isolate_locks.increment().to, equals(1));

      expect(counter.counts.isolate_locks.increment().to, equals(2));

      expect(counter.counts.isolate_locks.get(), equals(2));

      // decrement the isolate count
      expect(counter.counts.isolate_locks.decrement().to, equals(1));

      expect(counter.counts.isolate_locks.get(), equals(1));

      // increment the process count
      expect(counter.counts.process_locks.increment().to, equals(1));
      expect(counter.counts.process_locks.increment().to, equals(2));

      expect(counter.counts.process_locks.get(), equals(2));

      // decrement the process count
      expect(counter.counts.process_locks.decrement().to, equals(1));
      expect(counter.counts.process_locks.decrement().to, equals(0));
      expect(counter.counts.process_locks.get(), equals(0));

      // verify the name is the same as the counter's name
      expect(counter.identity.name, equals(counter.identity.name));

      // Verify that the identity is the same as the counter's identity
      expect(counter.identity, equals(identity));

      // Verify the counter is a singleton
      // expect(counter, equals(SemaphoreCurrentThreadCounter<SemaphoreIdentity>(identity: identity)));
    });

    test("Verify that two counters with different names and identities have different count states within same isolate/thread", () {
      String name_one = '${safeIntId.getId()}_named_sem';
      String name_two = '${safeIntId.getId()}_named_sem';

      // Create a new semaphore identity
      final SemaphoreIdentity identity_one = SemaphoreIdentity.instantiate<I, IS>(name: name_one, tracerFn: () => chalk.blue('Semaphore'));
      final SemaphoreIdentity identity_two = SemaphoreIdentity.instantiate<I, IS>(name: name_two, tracerFn: () => chalk.green('Semaphore'));

      // Create a new semaphore counter
      final SemaphoreCounter counter_one = SemaphoreCounter.instantiate<I, CU, CD, CT, CTS, NSPOSS, NSPOS, NSPOSES, CTR, CTRS>(
        identity: identity_one,
        tracerFn: () => identity_one.tracerFn(),
      );

      final SemaphoreCounter counter_two = SemaphoreCounter.instantiate<I, CU, CD, CT, CTS, NSPOSS, NSPOS, NSPOSES, CTR, CTRS>(identity: identity_two, tracerFn: () => identity_two.tracerFn());

      // Verify the counter is a singleton
      expect(counter_one, equals(SemaphoreCounter.instantiate<I, CU, CD, CT, CTS, NSPOSS, NSPOS, NSPOSES, CTR, CTRS>(identity: identity_one, tracerFn: () => identity_one.tracerFn())));
      expect(counter_two, equals(SemaphoreCounter.instantiate<I, CU, CD, CT, CTS, NSPOSS, NSPOS, NSPOSES, CTR, CTRS>(identity: identity_two, tracerFn: () => identity_two.tracerFn())));

      expect(counter_one.counts.isolate_locks.get(), equals(0));
      expect(counter_one.counts.isolate_locks.increment().to, equals(1));

      expect(counter_two.counts.isolate_locks.get(), equals(0));
      expect(counter_two.counts.isolate_locks.increment().to, equals(1));

      expect(counter_one.counts.isolate_locks.increment().to, equals(2));
      expect(counter_one.counts.isolate_locks.get(), equals(2));

      expect(counter_two.counts.isolate_locks.increment().to, equals(2));
      expect(counter_two.counts.isolate_locks.get(), equals(2));

      expect(counter_one.counts.isolate_locks.decrement().to, equals(1));
      expect(counter_one.counts.isolate_locks.get(), equals(1));

      expect(counter_two.counts.isolate_locks.decrement().to, equals(1));
      expect(counter_two.counts.isolate_locks.get(), equals(1));

      expect(counter_one.counts.isolate_locks.decrement().to, equals(0));
      expect(counter_one.counts.isolate_locks.get(), equals(0));

      expect(counter_two.counts.isolate_locks.decrement().to, equals(0));
      expect(counter_two.counts.isolate_locks.get(), equals(0));

      // Verify that the two counters are different
      expect(counter_one, isNot(equals(counter_two)));

      // Verify that the two identities are different
      expect(identity_one, isNot(equals(identity_two)));

      // Verify that the uuids are different
      expect(identity_one.identifier, isNot(equals(identity_two.identifier)));

      // Verify that the identity is registered
      expect(SemaphoreIdentities<I>().has<SemaphoreIdentity>(name: name_one, isolate: identity_one.isolate, process: identity_one.process), equals(true));
      expect(SemaphoreIdentities<I>().has<SemaphoreIdentity>(name: name_two, isolate: identity_two.isolate, process: identity_two.process), equals(true));

      // Verify the counter is a singleton
      expect(SemaphoreCounters<I, CU, CD, CT, CTS, NSPOSS, NSPOS, NSPOSES, CTR>().has<CTR>(identity: identity_one), equals(true));
      expect(SemaphoreCounters<I, CU, CD, CT, CTS, NSPOSS, NSPOS, NSPOSES, CTR>().has<CTR>(identity: identity_one), equals(true));
    });

    test("Verify that across isolates the counters are different.", () async {
      String name = '${safeIntId.getId()}_named_sem';

      // Create a new semaphore identity
      final SemaphoreIdentity identity = SemaphoreIdentity.instantiate<I, IS>(name: name, tracerFn: () => chalk.blue('Semaphore'));

      // Create a new semaphore counter
      final SemaphoreCounter counter = SemaphoreCounter.instantiate<I, CU, CD, CT, CTS, NSPOSS, NSPOS, NSPOSES, CTR, CTRS>(identity: identity, tracerFn: () => identity.tracerFn());

      //increment the isolate count
      counter.counts.isolate_locks
        ..increment()
        ..increment()
        ..increment()
        ..decrement()
        ..increment()
        ..decrement()
        ..increment();

      Future<String> spawn_isolate(String name, int id) async {
        void isolate_entrypoint(SendPort sender) {
          // Create a new semaphore identity
          final SemaphoreIdentity _identity = SemaphoreIdentity.instantiate<I, IS>(name: name, tracerFn: () => chalk.green('Semaphore'));

          // Create a new semaphore counter
          final SemaphoreCounter _counter = SemaphoreCounter.instantiate<I, CU, CD, CT, CTS, NSPOSS, NSPOS, NSPOSES, CTR, CTRS>(identity: identity, tracerFn: () => identity.tracerFn());

          // increment the isolate count
          // loop for 100 times and increment the isolate count
          for (var i = 0; i < 200; i++) {
            if (i == Random().nextInt(100)) _counter.counts.isolate_locks.increment();
            if (i == Random().nextInt(200)) _counter.counts.isolate_locks.decrement();
            if (Random().nextBool()) _counter.counts.process_locks.increment();
          }

          sender.send("${_counter.tracer} ${_counter.counts.isolate_locks.get()}:${_identity.identifier}:${_counter.identity.identifier}");
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

      // split the results on :
      final split = outcomes.map((e) => e.split(":"));

      // print the results
      split.forEach((element) {
        print("Isolate Count: ${element[0]}");
        print("Isolate UUID: ${element[1]}");
        print("Counter UUID: ${element[2]}");
      });

      // Make sure that the isolate count is different for each isolate
      expect(outcomes, isNot(everyElement(equals(outcomes[0]))));
      // make sure that the isolate uuid differs for each isolate
      expect(outcomes, isNot(everyElement(equals(outcomes[1]))));
      // make sure that the counter uuid differs for each isolate
      expect(outcomes, isNot(everyElement(equals(outcomes[2]))));
    });
  });
}
