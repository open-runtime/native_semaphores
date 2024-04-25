// import 'dart:io' show sleep;
// import 'dart:isolate' show Isolate, ReceivePort, SendPort;
// import 'dart:math' show Random;
//
// import 'package:runtime_native_semaphores/runtime_native_semaphores.dart' show NativeSemaphore;
// // import 'package:runtime_native_semaphores/src/semaphore_counter.dart' show SemaphoreCurrentThreadCounter;
// import 'package:runtime_native_semaphores/src/semaphore_identity.dart' show SemaphoreIdentity;
// import 'package:safe_int_id/safe_int_id.dart' show safeIntId;
// import 'package:test/test.dart' show equals, expect, group, isNot, test;
//
// void main() {
//   group('SemaphoreIdentity Tests', () {
//     // Create singleton of semaphore identifier class
//     test('Semaphore identifier can be set and retrieved', () {
//       String name = '${safeIntId.getId()}_named_sem';
//       final identifiers = SemaphoreIdentity(semaphore: name);
//       expect(identifiers.semaphore, equals(name));
//     });
//
//     test('Isolate identifier is not null and is a valid string', () async {
//       Future<String> spawn_isolate(String name, int id) async {
//         // CapturedCallFrame _frame = CapturedCallFrame();
//         // The entry point for the isolate
//         void isolate_entrypoint(SendPort sender) {
//           // Create the Identity
//           SemaphoreIdentity isolate_identity = SemaphoreIdentity(semaphore: name);
//
//           // Create the Counter
//           SemaphoreCurrentThreadCounter<SemaphoreIdentity> counter =
//               SemaphoreCurrentThreadCounter<SemaphoreIdentity>(identity: isolate_identity);
//
//           // Create the Semaphore
//           NativeSemaphore sem =
//               NativeSemaphore<SemaphoreIdentity, SemaphoreCurrentThreadCounter<SemaphoreIdentity>>(counter: counter);
//
//           // Lock
//           bool locked = sem.lock();
//           locked || (throw Exception("Lock in isolate $id should have returned true"));
//
//           sleep(Duration(milliseconds: Random().nextInt(10000)));
//
//           // Unlock
//           bool unlocked = sem.unlock();
//           unlocked || (throw Exception("Unlock in isolate $id should have returned false"));
//
//           bool closed = sem.close();
//           closed || (throw Exception("Close in isolate $id should have returned true"));
//
//           bool unlinked = sem.unlink();
//           unlinked || (throw Exception("Unlink in isolate $id should have returned true"));
//
//           sender.send(isolate_identity.toString());
//
//           bool disposed_thread_identifiers = isolate_identity.dispose();
//
//           disposed_thread_identifiers ||
//               (throw Exception("Dispose of Semaphore Identifiers in isolate $id should have succeeded"));
//         }
//
//         // Create a receive port to get messages from the isolate
//         final ReceivePort receiver = ReceivePort();
//
//         // Spawn the isolate
//         await Isolate.spawn(isolate_entrypoint, receiver.sendPort);
//
//         // Wait for the isolate to send its message
//         return await receiver.first;
//       }
//
//       String name = '${safeIntId.getId()}_named_sem';
//
//       // We do this once ever i.e. at the initialization of any given semaphore instance
//       SemaphoreIdentity parent_identity = SemaphoreIdentity(semaphore: name);
//
//       // Spawn the first helper isolate
//       final thread_identifiers = await spawn_isolate(name, 1);
//
//       expect(parent_identity.toString(), isNot(equals(thread_identifiers)));
//       // expect(actual, matcher)
//     });
//
//     // Testing fromCall() might require a more complex setup or mocking to simulate different stack traces.
//     // This is an advanced topic and might not be directly achievable without refactoring the code for better testability.
//   });
// }
