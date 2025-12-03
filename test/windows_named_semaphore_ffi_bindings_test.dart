@TestOn('windows')
import 'dart:ffi' show Pointer;
import 'dart:io' show sleep;
import 'dart:isolate' show Isolate, ReceivePort, SendPort;
import 'dart:math' show Random;

import 'package:ffi/ffi.dart' show StringUtf16Pointer, malloc;
import 'package:runtime_native_semaphores/src/ffi/windows.dart'
    show
        CloseHandle,
        CreateSemaphoreW,
        LPCWSTR,
        ReleaseSemaphore,
        WaitForSingleObject,
        WindowsCreateSemaphoreWMacros,
        WindowsReleaseSemaphoreMacros,
        WindowsWaitForSingleObjectMacros;
import 'package:safe_int_id/safe_int_id.dart' show safeIntId;

import 'package:test/test.dart' show TestOn, equals, everyElement, expect, group, isNonZero, isTrue, isZero, test;

void main() {
  group('Semaphore tests', () {
    test('Single Thread: Open, Close, Unlink Semaphore', () {
      LPCWSTR name = ('Global\\${safeIntId.getId()}_named_sem'.toNativeUtf16());

      int address = CreateSemaphoreW(WindowsCreateSemaphoreWMacros.NULL.address, 0, 1, name);
      final sem = Pointer.fromAddress(address);

      // expect sem_open to not be WindowsCreateSemaphoreWMacros.SEM_FAILED
      expect(sem.address != WindowsCreateSemaphoreWMacros.SEM_FAILED.address, isTrue);

      final int released = ReleaseSemaphore(
        sem.address,
        WindowsReleaseSemaphoreMacros.RELEASE_COUNT_RECOMMENDED,
        WindowsReleaseSemaphoreMacros.PREVIOUS_RELEASE_COUNT_RECOMMENDED,
      );
      expect(released, isNonZero); // 0 indicates failure, 1 indicates success

      final int closed = CloseHandle(sem.address);
      expect(closed, isNonZero); // 0 indicates failure, 1 indicates success

      malloc.free(name);
    });

    test('Single Thread: Throw Semaphore Name Error with Invalid Characters ', () {
      // Anything over 250 chars including the leading Global\ will be too long to fit into a the 260 int which is MAX_PATH
      LPCWSTR name = ('Global\\${'x<>:"/\\|?*' * WindowsCreateSemaphoreWMacros.MAX_PATH}'.toNativeUtf16());

      int address = CreateSemaphoreW(
        WindowsCreateSemaphoreWMacros.NULL.address,
        WindowsCreateSemaphoreWMacros.INITIAL_VALUE_RECOMMENDED,
        WindowsCreateSemaphoreWMacros.MAXIMUM_VALUE_RECOMMENDED,
        name,
      );

      final sem = Pointer.fromAddress(address);

      expect(sem.address == WindowsCreateSemaphoreWMacros.SEM_FAILED.address, isTrue);

      // We shouldn't be able to release the semaphore because it was never opened due to an invalid name
      final int released = ReleaseSemaphore(
        sem.address,
        WindowsReleaseSemaphoreMacros.RELEASE_COUNT_RECOMMENDED,
        WindowsReleaseSemaphoreMacros.PREVIOUS_RELEASE_COUNT_RECOMMENDED,
      );
      expect(released, isZero); // 0 indicates failure, 1 indicates success

      // We shouldn't be able to close the semaphore because it was never opened due to an invalid name
      final int closed = CloseHandle(sem.address);
      expect(closed, isZero); // 0 indicates failure, 1 indicates success

      malloc.free(name);
    });

    test('Single Thread: Open, Lock, Unlock, and Close Semaphore', () {
      LPCWSTR name = ('Global\\${safeIntId.getId()}_named_sem'.toNativeUtf16());

      int address = CreateSemaphoreW(
        WindowsCreateSemaphoreWMacros.NULL.address,
        WindowsCreateSemaphoreWMacros.INITIAL_VALUE_RECOMMENDED,
        WindowsCreateSemaphoreWMacros.MAXIMUM_VALUE_RECOMMENDED,
        name,
      );

      final sem = Pointer.fromAddress(address);

      // expect sem_open to not be WindowsCreateSemaphoreWMacros.SEM_FAILED
      expect(sem.address != WindowsCreateSemaphoreWMacros.SEM_FAILED.address, isTrue);

      final int locked = WaitForSingleObject(sem.address, WindowsWaitForSingleObjectMacros.TIMEOUT_RECOMMENDED);
      expect(locked, equals(WindowsWaitForSingleObjectMacros.WAIT_OBJECT_0));

      final int released = ReleaseSemaphore(
        sem.address,
        WindowsReleaseSemaphoreMacros.RELEASE_COUNT_RECOMMENDED,
        WindowsReleaseSemaphoreMacros.PREVIOUS_RELEASE_COUNT_RECOMMENDED,
      );
      expect(released, isNonZero); // 0 indicates failure, 1 indicates success

      final int closed = CloseHandle(sem.address);
      expect(closed, isNonZero); // 0 indicates failure, 1 indicates success

      malloc.free(name);
    });

    test('Single Thread: Try to throw an error by calling `CloseHandle` twice.', () {
      LPCWSTR name = ('Global\\${safeIntId.getId()}_named_sem'.toNativeUtf16());

      int address = CreateSemaphoreW(
        WindowsCreateSemaphoreWMacros.NULL.address,
        WindowsCreateSemaphoreWMacros.INITIAL_VALUE_RECOMMENDED,
        WindowsCreateSemaphoreWMacros.MAXIMUM_VALUE_RECOMMENDED,
        name,
      );
      final sem = Pointer.fromAddress(address);

      // expect sem_open to not be WindowsCreateSemaphoreWMacros.SEM_FAILED
      expect(sem.address != WindowsCreateSemaphoreWMacros.SEM_FAILED.address, isTrue);

      final int locked = WaitForSingleObject(sem.address, WindowsWaitForSingleObjectMacros.TIMEOUT_RECOMMENDED);
      expect(locked, equals(WindowsWaitForSingleObjectMacros.WAIT_OBJECT_0));

      final int released = ReleaseSemaphore(
        sem.address,
        WindowsReleaseSemaphoreMacros.RELEASE_COUNT_RECOMMENDED,
        WindowsReleaseSemaphoreMacros.PREVIOUS_RELEASE_COUNT_RECOMMENDED,
      );
      expect(released, isNonZero); // 1 indicates success

      final int closed = CloseHandle(sem.address);
      expect(closed, isNonZero); // 1 indicates success

      final int closed_twice = CloseHandle(sem.address);
      expect(closed_twice, isZero); // 0 indicates failure

      malloc.free(name);
    });
  });

  group('Testing Cross-Isolate Named Semaphore', () {
    test(
      'Two Isolates Accessing Same Named Semaphore, one locks for a 3 second Duration, the other waits to lock and then unlocks',
      () async {
        Future<bool> spawn_primary_isolate(String name) async {
          // The entry point for the isolate
          void primary_isolate_entrypoint(SendPort sender) {
            LPCWSTR _name = (name.toNativeUtf16());

            int address = CreateSemaphoreW(
              WindowsCreateSemaphoreWMacros.NULL.address,
              WindowsCreateSemaphoreWMacros.INITIAL_VALUE_RECOMMENDED,
              WindowsCreateSemaphoreWMacros.MAXIMUM_VALUE_RECOMMENDED,
              _name,
            );
            final sem = Pointer.fromAddress(address);

            sem.address != WindowsCreateSemaphoreWMacros.SEM_FAILED.address ||
                (throw Exception("CreateSemaphoreW in primary isolate should have succeeded, got ${sem.address}"));

            final int locked = WaitForSingleObject(sem.address, WindowsWaitForSingleObjectMacros.TIMEOUT_RECOMMENDED);

            // Should be signaled with 0 i.e. WAIT_OBJECT_0
            locked.isEven || (throw Exception("Primary Thread should have locked and returned 0, got $locked"));

            locked == WindowsWaitForSingleObjectMacros.WAIT_OBJECT_0 ||
                (throw Exception("Primary Thread should have locked and returned WAIT_OBJECT_0, got $locked"));

            // Waiting in primary isolate for 3 seconds.
            sleep(Duration(seconds: 3));

            // Unlock
            final int released = ReleaseSemaphore(
              sem.address,
              WindowsReleaseSemaphoreMacros.RELEASE_COUNT_RECOMMENDED,
              WindowsReleaseSemaphoreMacros.PREVIOUS_RELEASE_COUNT_RECOMMENDED,
            );
            released.isOdd ||
                (throw Exception("ReleaseSemaphore in primary isolate should have expected 1, got $released"));

            // Close & expect 0
            final int closed = CloseHandle(sem.address);
            closed.isOdd || (throw Exception("CloseHandle in primary isolate should have expected 1, got $closed"));

            sender.send(true);
            malloc.free(_name);
          }

          // Create a receive port to get messages from the isolate
          final ReceivePort receiver = ReceivePort();

          // Spawn the isolate
          await Isolate.spawn(primary_isolate_entrypoint, receiver.sendPort);

          // Wait for the isolate to send its message
          return await receiver.first;
        }

        Future<bool> spawn_secondary_isolate(String name) async {
          // The entry point for the isolate
          void secondary_isolate_entrypoint(SendPort sender) {
            LPCWSTR _name = (name.toNativeUtf16());

            int address = CreateSemaphoreW(
              WindowsCreateSemaphoreWMacros.NULL.address,
              WindowsCreateSemaphoreWMacros.INITIAL_VALUE_RECOMMENDED,
              WindowsCreateSemaphoreWMacros.MAXIMUM_VALUE_RECOMMENDED,
              _name,
            );
            final sem = Pointer.fromAddress(address);

            sem.address != WindowsCreateSemaphoreWMacros.SEM_FAILED.address ||
                (throw Exception("CreateSemaphoreW in secondary isolate should have succeeded, got ${sem.address}"));

            final int locked = WaitForSingleObject(sem.address, WindowsWaitForSingleObjectMacros.TIMEOUT_RECOMMENDED);

            locked.isEven || (throw Exception("Secondary Thread should have locked and returned 0, got $locked"));

            // Unlock
            final int released = ReleaseSemaphore(
              sem.address,
              WindowsReleaseSemaphoreMacros.RELEASE_COUNT_RECOMMENDED,
              WindowsReleaseSemaphoreMacros.PREVIOUS_RELEASE_COUNT_RECOMMENDED,
            );
            released.isOdd ||
                (throw Exception("ReleaseSemaphore in secondary isolate should have expected 1, got $released"));

            // Close
            final int closed = CloseHandle(sem.address);
            closed.isOdd || (throw Exception("CloseHandle in secondary isolate should have expected 1, got $closed"));

            sender.send(true);
            malloc.free(_name);
          }

          // Create a receive port to get messages from the isolate
          final ReceivePort receiver = ReceivePort();

          // Spawn the isolate
          await Isolate.spawn(secondary_isolate_entrypoint, receiver.sendPort);

          // Wait for the isolate to send its message
          return await receiver.first;
        }

        String name = '/${safeIntId.getId()}_named_sem';

        // Spawn the first helper isolate
        final result_one = spawn_primary_isolate(name);
        sleep(Duration(milliseconds: 250));
        final result_two = spawn_secondary_isolate(name);

        // Wait for both isolates to complete their work
        final outcomes = await Future.wait([result_one, result_two]);

        LPCWSTR _name = (name.toNativeUtf16());
        final int closed = CloseHandle(_name.address);

        expect(closed, equals(0));
        expect(outcomes, everyElement(equals(true)));
      },
    );

    test(
      'Two Isolates Accessing Same Named Semaphore, one locks for a 3 second Duration, the other WaitForSingleObject fails, and then WaitForSingleObject completes properly after a duration.',
      () async {
        Future<bool> spawn_primary_isolate(String name) async {
          // The entry point for the isolate
          void primary_isolate_entrypoint(SendPort sender) {
            LPCWSTR _name = (name.toNativeUtf16());

            int address = CreateSemaphoreW(
              WindowsCreateSemaphoreWMacros.NULL.address,
              WindowsCreateSemaphoreWMacros.INITIAL_VALUE_RECOMMENDED,
              WindowsCreateSemaphoreWMacros.MAXIMUM_VALUE_RECOMMENDED,
              _name,
            );
            final sem = Pointer.fromAddress(address);

            sem.address != WindowsCreateSemaphoreWMacros.SEM_FAILED.address ||
                (throw Exception("CreateSemaphoreW in primary isolate should have succeeded, got ${sem.address}"));

            final int locked = WaitForSingleObject(sem.address, WindowsWaitForSingleObjectMacros.TIMEOUT_RECOMMENDED);

            locked.isEven ||
                (throw Exception("Thread (primary isolate) should have locked and returned 0, got $locked"));

            sleep(Duration(seconds: 1));

            // Unlock
            final int released = ReleaseSemaphore(
              sem.address,
              WindowsReleaseSemaphoreMacros.RELEASE_COUNT_RECOMMENDED,
              WindowsReleaseSemaphoreMacros.PREVIOUS_RELEASE_COUNT_RECOMMENDED,
            );
            released.isOdd ||
                (throw Exception("ReleaseSemaphore in primary isolate should have expected 1, got $released"));

            // Close
            final int closed = CloseHandle(sem.address);
            closed.isOdd || (throw Exception("CloseHandle in primary isolate should have expected 1, got $closed"));

            sender.send(true);
            malloc.free(_name);
          }

          // Create a receive port to get messages from the isolate
          final ReceivePort receiver = ReceivePort();

          // Spawn the isolate
          await Isolate.spawn(primary_isolate_entrypoint, receiver.sendPort);

          // Wait for the isolate to send its message
          return await receiver.first;
        }

        Future<bool> spawn_secondary_isolate(String name) async {
          // The entry point for the isolate
          void secondary_isolate_entrypoint(SendPort sender) {
            LPCWSTR _name = (name.toNativeUtf16());

            int address = CreateSemaphoreW(
              WindowsCreateSemaphoreWMacros.NULL.address,
              WindowsCreateSemaphoreWMacros.INITIAL_VALUE_RECOMMENDED,
              WindowsCreateSemaphoreWMacros.MAXIMUM_VALUE_RECOMMENDED,
              _name,
            );

            final sem = Pointer.fromAddress(address);

            sem.address != WindowsCreateSemaphoreWMacros.SEM_FAILED.address ||
                (throw Exception("CreateSemaphoreW in secondary isolate should have succeeded, got ${sem.address}"));

            int waited = WaitForSingleObject(sem.address, WindowsWaitForSingleObjectMacros.TIMEOUT_ZERO);

            waited == WindowsWaitForSingleObjectMacros.WAIT_TIMEOUT ||
                (throw Exception("WaitForSingleObject in secondary isolate should have expected 258, got $waited"));

            // await 2 seconds and try again
            sleep(Duration(seconds: 2));

            int successfully_trywaited = WaitForSingleObject(
              sem.address,
              WindowsWaitForSingleObjectMacros.TIMEOUT_ZERO,
            );
            successfully_trywaited.isEven ||
                (throw Exception(
                  "second call to WaitForSingleObject in secondary isolate should have expected 0, got $successfully_trywaited",
                ));

            // Release
            final int released = ReleaseSemaphore(
              sem.address,
              WindowsReleaseSemaphoreMacros.RELEASE_COUNT_RECOMMENDED,
              WindowsReleaseSemaphoreMacros.PREVIOUS_RELEASE_COUNT_RECOMMENDED,
            );
            released.isOdd ||
                (throw Exception("ReleaseSemaphore in secondary isolate should have expected 0, got $released"));

            // Close
            final int closed = CloseHandle(sem.address);
            closed.isOdd || (throw Exception("CloseHandle in secondary isolate should have expected 1, got $closed"));

            sender.send(true);
            malloc.free(_name);
          }

          // Create a receive port to get messages from the isolate
          final ReceivePort receiver = ReceivePort();

          // Spawn the isolate
          await Isolate.spawn(secondary_isolate_entrypoint, receiver.sendPort);

          // Wait for the isolate to send its message
          return await receiver.first;
        }

        String name = '/${safeIntId.getId()}_named_sem';

        // Spawn the first helper isolate
        final result_one = spawn_primary_isolate(name);
        sleep(Duration(milliseconds: 250));
        final result_two = spawn_secondary_isolate(name);

        // Wait for both isolates to complete their work
        final outcomes = await Future.wait([result_one, result_two]);

        LPCWSTR _name = (name.toNativeUtf16());
        final int closed = CloseHandle(_name.address);

        expect(closed, equals(0));
        expect(outcomes, everyElement(equals(true)));
      },
    );

    test('Several Isolates Accessing Same Named Semaphore, waiting random durations and then unlocking.', () async {
      Future<bool> spawn_isolate(String name, int sem_open_value, int id) async {
        // The entry point for the isolate
        void isolate_entrypoint(SendPort sender) {
          LPCWSTR _name = (name.toNativeUtf16());

          int address = CreateSemaphoreW(
            WindowsCreateSemaphoreWMacros.NULL.address,
            WindowsCreateSemaphoreWMacros.INITIAL_VALUE_RECOMMENDED,
            WindowsCreateSemaphoreWMacros.MAXIMUM_VALUE_RECOMMENDED,
            _name,
          );
          final sem = Pointer.fromAddress(address);

          sem.address != WindowsCreateSemaphoreWMacros.SEM_FAILED.address ||
              (throw Exception("CreateSemaphoreW in isolate $id should have succeeded, got ${sem.address}"));

          final int locked = WaitForSingleObject(sem.address, WindowsWaitForSingleObjectMacros.TIMEOUT_RECOMMENDED);

          locked.isEven || (throw Exception("Thread $id should have locked and returned 0, got $locked"));

          sleep(Duration(milliseconds: Random().nextInt(1000)));

          // Unlock
          final int released = ReleaseSemaphore(
            sem.address,
            WindowsReleaseSemaphoreMacros.RELEASE_COUNT_RECOMMENDED,
            WindowsReleaseSemaphoreMacros.PREVIOUS_RELEASE_COUNT_RECOMMENDED,
          );
          released.isOdd || (throw Exception("ReleaseSemaphore in isolate $id should have expected 1, got $released"));

          // Close
          final int closed = CloseHandle(sem.address);
          closed.isOdd || (throw Exception("CloseHandle in isolate $id should have expected 1, got $closed"));

          sender.send(true);
          malloc.free(_name);
        }

        // Create a receive port to get messages from the isolate
        final ReceivePort receiver = ReceivePort();

        // Spawn the isolate
        await Isolate.spawn(isolate_entrypoint, receiver.sendPort);

        // Wait for the isolate to send its message
        return await receiver.first;
      }

      String name = '/${safeIntId.getId()}_named_sem';

      int sem_open_value = 1;
      // Spawn the first helper isolate
      final result_one = spawn_isolate(name, sem_open_value, 1);
      final result_two = spawn_isolate(name, sem_open_value, 2);
      final result_three = spawn_isolate(name, sem_open_value, 3);
      final result_four = spawn_isolate(name, sem_open_value, 4);

      // Wait for both isolates to complete their work
      final outcomes = await Future.wait([result_one, result_two, result_three, result_four]);

      LPCWSTR _name = (name.toNativeUtf16());
      final int closed = CloseHandle(_name.address);

      expect(closed, equals(0));
      expect(outcomes, everyElement(equals(true)));
    });
  });
}
