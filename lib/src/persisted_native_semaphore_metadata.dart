import 'dart:convert' show JsonDecoder, JsonEncoder;
import 'dart:io';

import 'package:runtime_native_semaphores/src/persisted_native_semaphore_operation.dart';
import 'package:runtime_native_semaphores/src/utils/XXHash64.dart';

class PersistedNativeSemaphoreAccessor {
  /* The isolate ID */
  final String isolate;

  /* The process ID */
  final String process;

  /* The address of the semaphore */
  final int address;

  /* If the accessor is waiting to acquire the semaphore */
  final bool waiting;

  final bool opened;

  /* If the accessor is currently holding the semaphore */
  final bool locked;

  /* If the accessor is reentrant */
  final bool reentrant;

  /* If the accessor has unlocked the semaphore */
  final bool unlocked;

  /* If the accessor is closed */
  final bool closed;

  /* If the accessor is unlinked */
  final bool unlinked;

  /* The position in the queue to lock the semaphore i.e. 0 is the holder, 1 is on deck, etc. */
  final int position;

  /* The last operation performed by the accessor */
  final NATIVE_SEMAPHORE_OPERATION operation;

  /* How much time it has been since it's last operation in microseconds  */
  final Duration elapsed;

  final String identifier;

  final String tracer;

  PersistedNativeSemaphoreAccessor(
      {required this.identifier,
      required this.isolate,
      required this.process,
      required this.address,
      required this.opened,
      required this.waiting,
      required this.locked,
      required this.unlocked,
      required this.reentrant,
      required this.closed,
      required this.unlinked,
      required this.position,
      required this.operation,
      required this.elapsed,
      String this.tracer = ''});

  Map<String, dynamic> asMap() => {
        'uuid': identifier,
        'tracer': tracer,
        'isolate': isolate,
        'process': process,
        'address': address,
        'opened': opened,
        'waiting': waiting,
        'locked': locked,
        'reentrant': reentrant,
        'unlocked': unlocked,
        'closed': closed,
        'unlinked': unlinked,
        'position': position,
        'operation': operation.toString(),
        'elapsed': elapsed.inMicroseconds
      };
}

class PersistedNativeSemaphoreMetadata<PNSA extends PersistedNativeSemaphoreAccessor> {
  late final String name;

  late final DateTime created;

  // A list of all the processes/isolates that have opened the semaphore, if they are waiting to lock and or if they are the current holder, along with its statuses, and position among all accessors i.e. if it is position 0 it is currently holding the lock, if it is position 1 it is waiting to acquire the lock, etc.
  late final List<PNSA> accessors;

  // Information about which isolate, process, and address the semaphore is currently locked on and how long it has been locked
  late final PNSA holder;

  // Last synchronization time, this may need to go on accessors as well
  late DateTime synchronized;

  PersistedNativeSemaphoreMetadata(
      {required String this.name, required List<PNSA> this.accessors, required PNSA this.holder, DateTime? created, required DateTime synchronized, bool verbose = false})
      : created = created ?? DateTime.now();

  @override
  String toString() => 'PersistedNativeSemaphoreMetadata(name: $name, created: $created, accessors: $accessors, holder: $holder, synchronized: $synchronized)';

  Map<String, dynamic> asMap() => {
        'name': name,
        'created': created.toIso8601String(),
        'accessors': accessors.map((accessor) => accessor.asMap()).toList(),
        'holder': holder.asMap(),
        'synchronized': synchronized.toIso8601String()
      };

  String serialize() => JSON.encode(asMap());

  static PNSM rehydrate<PNSA extends PersistedNativeSemaphoreAccessor, PNSM extends PersistedNativeSemaphoreMetadata<PNSA>>(
      {required /*Note this can be a map here because the parent class will encode into JSON, it can also be a string if used directly */ dynamic serialized}) {
    final Map<String, dynamic> data = serialized is String ? JSON.decode(serialized) : serialized;

    return PersistedNativeSemaphoreMetadata(
        name: data['name'],
        created: DateTime.parse(data['created']),
        accessors: data['accessors']
            .map((accessor) => PersistedNativeSemaphoreAccessor(
                identifier: accessor['uuid'],
                isolate: accessor['isolate'],
                process: accessor['process'],
                address: accessor['address'],
                opened: accessor['opened'],
                waiting: accessor['waiting'],
                locked: accessor['locked'],
                reentrant: accessor['reentrant'],
                unlocked: accessor['unlocked'],
                closed: accessor['closed'],
                unlinked: accessor['unlinked'],
                position: accessor['position'],
                operation: NATIVE_SEMAPHORE_OPERATION.fromString(accessor['operation']),
                elapsed: Duration(microseconds: accessor['elapsed'])))
            .toList(),
        holder: PersistedNativeSemaphoreAccessor(
            identifier: data['holder']['uuid'],
            isolate: data['holder']['isolate'],
            process: data['holder']['process'],
            address: data['holder']['address'],
            opened: data['holder']['opened'],
            waiting: data['holder']['waiting'],
            locked: data['holder']['locked'],
            reentrant: data['holder']['reentrant'],
            unlocked: data['holder']['unlocked'],
            closed: data['holder']['closed'],
            unlinked: data['holder']['unlinked'],
            position: data['holder']['position'],
            operation: NATIVE_SEMAPHORE_OPERATION.fromString(data['holder']['operation']),
            elapsed: Duration(microseconds: data['holder']['elapsed'])),
        synchronized: DateTime.parse(data['synchronized'])) as PNSM;
  }
}
