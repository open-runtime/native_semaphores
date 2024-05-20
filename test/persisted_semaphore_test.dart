import 'dart:isolate' show Isolate, ReceivePort, SendPort;
import 'dart:math' show Random;

import 'package:runtime_native_semaphores/runtime_native_semaphores.dart';
import 'package:runtime_native_semaphores/src/persisted_native_semaphore_operation.dart';
import 'package:runtime_native_semaphores/src/semaphore_counter.dart'
    show SemaphoreCount, SemaphoreCountDeletion, SemaphoreCountUpdate, SemaphoreCounter, SemaphoreCounters, SemaphoreCounts;
import 'package:runtime_native_semaphores/src/semaphore_identity.dart' show SemaphoreIdentities, SemaphoreIdentity;
import 'package:safe_int_id/safe_int_id.dart' show safeIntId;

import 'package:test/test.dart' show equals, everyElement, expect, group, isNot, test;

typedef I = SemaphoreIdentity;
typedef IS = SemaphoreIdentities<I>;
typedef CU = SemaphoreCountUpdate;
typedef CD = SemaphoreCountDeletion;
typedef CT = SemaphoreCount<CU, CD>;
typedef CTS = SemaphoreCounts<CU, CD, CT>;
typedef CTR = SemaphoreCounter<I, CU, CD, CT, CTS>;
typedef CTRS = SemaphoreCounters<I, CU, CD, CT, CTS, CTR>;
typedef PNSO = PersistedNativeSemaphoreOperation;
typedef PNSOS = PersistedNativeSemaphoreOperations<PNSO>;
typedef NS = NativeSemaphore<I, IS, CU, CD, CT, CTS, CTR, CTRS, PNSO, PNSOS>;

void main() {
  group('Testing Persisted Native Semaphore from current thread', () {
    test('Create Native Semaphore, Call open(), and verify that the file exists.', () async {
      String name = 'tested_named_sem';

      NativeSemaphore semaphore = NativeSemaphore.instantiate(name: name, verbose: true);

      // Expect the cache directory to exist
      expect(semaphore.cache.existsSync(), equals(true));

      // Expect the temp file to exist
      expect(semaphore.temp.existsSync(), equals(true));

      // Expect operations to not be set
      expect(semaphore.operations.isSet, equals(false));
      expect(semaphore.operations.get, equals(null));

      // Expect operation to also not be set
      expect(semaphore.operations.isSet, equals(false));
      expect(semaphore.operations.get, equals(null));

      // Open the semaphore
      bool opened = semaphore.open();

      // Expect the semaphore to be opened
      expect(opened, equals(true));

      // Expect the operations to be set
      expect(semaphore.operations.isSet, equals(true));
      expect(semaphore.operations.get, isNot(equals(null)));

      // Expect the operation to be set
      expect(semaphore.operations.isSet, equals(true));
      expect(semaphore.operations.get, isNot(equals(null)));

      // Read the operations from disk and compare
      PNSOS operations = PersistedNativeSemaphoreOperations.rehydrate(serialized: semaphore.temp.readAsStringSync(), rehydrate_: PersistedNativeSemaphoreOperation.rehydrate);

      // there should be 3 operations for an open call
      expect(operations.iterable.length, equals(3));
      expect(semaphore.operations.get?.indexed, equals(operations.indexed));
      expect(semaphore.operations.get.toString(), equals(operations.toString()));

      // Lock the semaphore
      bool locked = semaphore.lock();
      expect(locked, equals(true));

      // Examine operations
      operations = PersistedNativeSemaphoreOperations.rehydrate(serialized: semaphore.temp.readAsStringSync(), rehydrate_: PersistedNativeSemaphoreOperation.rehydrate);

      expect(operations.iterable.length, equals(6));
      expect(semaphore.operations.get?.indexed, equals(operations.indexed));
      expect(semaphore.operations.get.toString(), equals(operations.toString()));

      // Shutdown
      semaphore..unlock()..close()..unlink();

    });

  });
}
