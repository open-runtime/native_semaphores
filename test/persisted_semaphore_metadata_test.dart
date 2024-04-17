// import 'dart:io' show sleep;
// import 'dart:isolate' show Isolate, ReceivePort, SendPort;
// import 'dart:math' show Random;

// import 'package:runtime_native_semaphores/runtime_native_semaphores.dart' show NativeSemaphore;
import 'package:runtime_native_semaphores/runtime_native_semaphores.dart' show NATIVE_SEMAPHORE_OPERATION_STATUS;
import 'package:runtime_native_semaphores/src/semaphore_metadata.dart' show SemaphoreMetadata;
import 'package:runtime_native_semaphores/src/semaphore_identity.dart' show CapturedCallFrame, SemaphoreIdentity;
import 'package:safe_int_id/safe_int_id.dart' show safeIntId;
import 'package:test/test.dart' show equals, expect, group, isNot, test;

void main() {
  group('PersistedSemaphoreMetadata Tests', () {
    // Create singleton of semaphore identifier class
    test('Test initial creation of Semaphore Identity and Persisted Semaphore Metadata', () {
      String name = '${safeIntId.getId()}_named_sem';
      final identity = SemaphoreIdentity(semaphore: name, frame: CapturedCallFrame());
      bool persisted =
          SemaphoreMetadata.persist(status: NATIVE_SEMAPHORE_OPERATION_STATUS.ATTEMPTING_LOCK, identity: identity);
      // final metadata = PersistedSemaphoreMetadata.persist(identity: identity)
      print('Creating metadata file in ${SemaphoreMetadata.root.path}');
      print(
          'Metadata file exists: ${SemaphoreMetadata.statuses.containsKey(identity.uuid())} at ${SemaphoreMetadata.statuses[identity.uuid()]?.path}');
      expect(persisted, equals(true));
      expect(identity.semaphore, equals(name));
    });

    // test('Isolate identifier is not null and is a valid string', () async {
    //   Future<String> spawn_isolate(String name, int id) async {
    //     CapturedCallFrame _frame = CapturedCallFrame();
    //     // The entry point for the isolate
    //     void isolate_entrypoint(SendPort sender) {
    //       SemaphoreIdentity identity = SemaphoreIdentity.fromUnknownCall(semaphore: name);
    //       NativeSemaphore sem = NativeSemaphore(identity: identity);
    //       SemaphoreIdentity thread_identifiers = SemaphoreIdentity.fromCall(semaphore: name, frame: _frame);
    //
    //       // Lock
    //       bool locked = sem.lock();
    //       locked || (throw Exception("Lock in isolate $id should have succeeded"));
    //
    //       sleep(Duration(milliseconds: Random().nextInt(1000)));
    //
    //       // Unlock
    //       bool unlocked = sem.unlock();
    //       unlocked || (throw Exception("Unlock in isolate $id should have succeeded"));
    //
    //       // Dispose
    //       bool disposed = sem.dispose();
    //       disposed || (throw Exception("Dispose in isolate $id should have succeeded"));
    //
    //       sender.send(thread_identifiers.toString());
    //
    //       bool disposed_thread_identifiers = thread_identifiers.dispose();
    //
    //       disposed_thread_identifiers ||
    //           (throw Exception("Dispose of Semaphore Identifiers in isolate $id should have succeeded"));
    //     }
    //
    //     // Create a receive port to get messages from the isolate
    //     final ReceivePort receiver = ReceivePort();
    //
    //     // Spawn the isolate
    //     await Isolate.spawn(isolate_entrypoint, receiver.sendPort);
    //
    //     // Wait for the isolate to send its message
    //     return await receiver.first;
    //   }
    //
    //   CapturedCallFrame frame = CapturedCallFrame();
    //
    //   String name = '${safeIntId.getId()}_named_sem';
    //
    //   // We do this once ever i.e. at the initialization of any given semaphore instance
    //   SemaphoreIdentity parent_identifiers = SemaphoreIdentity.fromCall(semaphore: name, frame: frame);
    //
    //   // Spawn the first helper isolate
    //   final thread_identifiers = await spawn_isolate(name, 1);
    //
    //   expect(parent_identifiers.toString(), isNot(equals(thread_identifiers)));
    //   // expect(actual, matcher)
    // });

    // Testing fromCall() might require a more complex setup or mocking to simulate different stack traces.
    // This is an advanced topic and might not be directly achievable without refactoring the code for better testability.
  });
}
