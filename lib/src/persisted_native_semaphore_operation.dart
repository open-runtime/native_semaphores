import 'dart:convert' show JsonDecoder, JsonEncoder;
import 'dart:io';

import 'package:runtime_native_semaphores/src/utils/XXHash64.dart';

enum NATIVE_SEMAPHORE_OPERATION {
  willAttemptOpen,
  attemptingOpen,
  open,
  attemptedOpen,
  // TODO
  // willAttemptOpenAcrossProcesses,
  // attemptingOpenAcrossProcesses,
  // openAcrossProcesses,
  // attemptedOpenAcrossProcesses,
  // openAttemptAcrossProcessesSucceeded,

  openAttemptSucceeded,
  willAttemptLockReentrantToIsolate,
  lockReentrantToIsolate,
  lockAttemptReentrantToIsolateSucceeded,
  willAttemptLockAcrossProcesses,
  attemptingLockAcrossProcesses,
  lockAcrossProcesses,
  attemptedLockAcrossProcesses,
  lockAttemptAcrossProcessesSucceeded,
  willAttemptUnlockAcrossProcesses,
  attemptingUnlockAcrossProcesses,
  unlockAcrossProcesses,
  attemptedUnlockAcrossProcesses,
  unlockAttemptAcrossProcessesSucceeded,
  willAttemptUnlockReentrantToIsolate,
  unlockReentrantToIsolate,
  unlockAttemptReentrantToIsolateSucceeded,


  willAttemptClose,
  attemptingClose,
  close,
  attemptedClose,
  closeAttemptSucceeded,

  // TODO
  // willAttemptCloseAcrossProcesses,
  // attemptingCloseAcrossProcesses,
  // closeAcrossProcesses,
  // attemptedCloseAcrossProcesses,
  // closeAttemptAcrossProcessesSucceeded,

  willAttemptUnlink,
  attemptingUnlink,
  unlink,
  attemptedUnlink,
  unlinkAttemptSucceeded,

  // TODO
  // willAttemptUnlinkAcrossProcesses,
  // attemptingUnlinkAcrossProcesses,
  // unlinkAcrossProcesses,
  // attemptedUnlinkAcrossProcesses,
  // unlinkAttemptAcrossProcessesSucceeded,

  unknown;

  @override
  String toString() {
    switch (this) {
      case NATIVE_SEMAPHORE_OPERATION.willAttemptOpen:
        return 'willAttemptOpen()';
      case NATIVE_SEMAPHORE_OPERATION.attemptingOpen:
        return 'attemptingOpen()';
      case NATIVE_SEMAPHORE_OPERATION.open:
        return 'open()';
      case NATIVE_SEMAPHORE_OPERATION.attemptedOpen:
        return 'attemptedOpen()';
      case NATIVE_SEMAPHORE_OPERATION.openAttemptSucceeded:
        return 'openAttemptSucceeded()';
      case NATIVE_SEMAPHORE_OPERATION.willAttemptLockReentrantToIsolate:
        return 'willAttemptLockReentrantToIsolate()';
      case NATIVE_SEMAPHORE_OPERATION.lockReentrantToIsolate:
        return 'lockReentrantToIsolate()';
      case NATIVE_SEMAPHORE_OPERATION.lockAttemptReentrantToIsolateSucceeded:
        return 'lockAttemptReentrantToIsolateSucceeded()';
      case NATIVE_SEMAPHORE_OPERATION.willAttemptLockAcrossProcesses:
        return 'willAttemptLockAcrossProcesses()';
      case NATIVE_SEMAPHORE_OPERATION.attemptingLockAcrossProcesses:
        return 'attemptingLockAcrossProcesses()';
      case NATIVE_SEMAPHORE_OPERATION.lockAcrossProcesses:
        return 'lockAcrossProcesses()';
      case NATIVE_SEMAPHORE_OPERATION.attemptedLockAcrossProcesses:
        return 'attemptedLockAcrossProcesses()';
      case NATIVE_SEMAPHORE_OPERATION.lockAttemptAcrossProcessesSucceeded:
        return 'lockAttemptAcrossProcessesSucceeded()';
      case NATIVE_SEMAPHORE_OPERATION.willAttemptUnlockAcrossProcesses:
        return 'willAttemptUnlockAcrossProcesses()';
      case NATIVE_SEMAPHORE_OPERATION.attemptingUnlockAcrossProcesses:
        return 'attemptingUnlockAcrossProcesses()';
      case NATIVE_SEMAPHORE_OPERATION.unlockAcrossProcesses:
        return 'unlockAcrossProcesses()';
      case NATIVE_SEMAPHORE_OPERATION.attemptedUnlockAcrossProcesses:
        return 'attemptedUnlockAcrossProcesses()';
      case NATIVE_SEMAPHORE_OPERATION.unlockAttemptAcrossProcessesSucceeded:
        return 'unlockAttemptAcrossProcessesSucceeded()';
      case NATIVE_SEMAPHORE_OPERATION.willAttemptUnlockReentrantToIsolate:
        return 'willAttemptUnlockReentrantToIsolate()';
      case NATIVE_SEMAPHORE_OPERATION.unlockReentrantToIsolate:
        return 'unlockReentrantToIsolate()';
      case NATIVE_SEMAPHORE_OPERATION.unlockAttemptReentrantToIsolateSucceeded:
        return 'unlockAttemptReentrantToIsolateSucceeded()';
      case NATIVE_SEMAPHORE_OPERATION.willAttemptClose:
        return 'willAttemptClose()';
      case NATIVE_SEMAPHORE_OPERATION.attemptingClose:
        return 'attemptingClose()';
      case NATIVE_SEMAPHORE_OPERATION.close:
        return 'close()';
      case NATIVE_SEMAPHORE_OPERATION.attemptedClose:
        return 'attemptedClose()';
      case NATIVE_SEMAPHORE_OPERATION.closeAttemptSucceeded:
        return 'closeAttemptSucceeded()';
      case NATIVE_SEMAPHORE_OPERATION.willAttemptUnlink:
        return 'willAttemptUnlink()';
      case NATIVE_SEMAPHORE_OPERATION.attemptingUnlink:
        return 'attemptingUnlink()';
      case NATIVE_SEMAPHORE_OPERATION.unlink:
        return 'unlink()';
      case NATIVE_SEMAPHORE_OPERATION.attemptedUnlink:
        return 'attemptedUnlink()';
      case NATIVE_SEMAPHORE_OPERATION.unlinkAttemptSucceeded:
        return 'unlinkAttemptSucceeded()';
      case NATIVE_SEMAPHORE_OPERATION.unknown:
        return 'unknown';
      default:
        return NATIVE_SEMAPHORE_OPERATION.unknown.toString();
    }
  }

  static NATIVE_SEMAPHORE_OPERATION fromString(String value) {
    switch (value) {
      case 'willAttemptOpen()':
        return NATIVE_SEMAPHORE_OPERATION.willAttemptOpen;
      case 'attemptingOpen()':
        return NATIVE_SEMAPHORE_OPERATION.attemptingOpen;
      case 'open()':
        return NATIVE_SEMAPHORE_OPERATION.open;
      case 'attemptedOpen()':
        return NATIVE_SEMAPHORE_OPERATION.attemptedOpen;
      case 'openAttemptSucceeded()':
        return NATIVE_SEMAPHORE_OPERATION.openAttemptSucceeded;
      case 'willAttemptLockReentrantToIsolate()':
        return NATIVE_SEMAPHORE_OPERATION.willAttemptLockReentrantToIsolate;
      case 'lockReentrantToIsolate()':
        return NATIVE_SEMAPHORE_OPERATION.lockReentrantToIsolate;
      case 'lockAttemptReentrantToIsolateSucceeded()':
        return NATIVE_SEMAPHORE_OPERATION.lockAttemptReentrantToIsolateSucceeded;
      case 'willAttemptLockAcrossProcesses()':
        return NATIVE_SEMAPHORE_OPERATION.willAttemptLockAcrossProcesses;
      case 'attemptingLockAcrossProcesses()':
        return NATIVE_SEMAPHORE_OPERATION.attemptingLockAcrossProcesses;
      case 'lockAcrossProcesses()':
        return NATIVE_SEMAPHORE_OPERATION.lockAcrossProcesses;
      case 'attemptedLockAcrossProcesses()':
        return NATIVE_SEMAPHORE_OPERATION.attemptedLockAcrossProcesses;
      case 'lockAttemptAcrossProcessesSucceeded()':
        return NATIVE_SEMAPHORE_OPERATION.lockAttemptAcrossProcessesSucceeded;
      case 'willAttemptUnlockReentrantToIsolate()':
        return NATIVE_SEMAPHORE_OPERATION.willAttemptUnlockReentrantToIsolate;
      case 'unlockReentrantToIsolate()':
        return NATIVE_SEMAPHORE_OPERATION.unlockReentrantToIsolate;
      case 'unlockAttemptReentrantToIsolateSucceeded()':
        return NATIVE_SEMAPHORE_OPERATION.unlockAttemptReentrantToIsolateSucceeded;
      case 'willAttemptUnlockAcrossProcesses()':
        return NATIVE_SEMAPHORE_OPERATION.willAttemptUnlockAcrossProcesses;
      case 'attemptingUnlockAcrossProcesses()':
        return NATIVE_SEMAPHORE_OPERATION.attemptingUnlockAcrossProcesses;
      case 'attemptedUnlockAcrossProcesses()':
        return NATIVE_SEMAPHORE_OPERATION.attemptedUnlockAcrossProcesses;
      case 'unlockAcrossProcesses()':
        return NATIVE_SEMAPHORE_OPERATION.unlockAcrossProcesses;
      case 'unlockAttemptAcrossProcessesSucceeded()':
        return NATIVE_SEMAPHORE_OPERATION.unlockAttemptAcrossProcessesSucceeded;
      case 'willAttemptClose()':
        return NATIVE_SEMAPHORE_OPERATION.willAttemptClose;
      case 'attemptingClose()':
        return NATIVE_SEMAPHORE_OPERATION.attemptingClose;
      case 'close()':
        return NATIVE_SEMAPHORE_OPERATION.close;
      case 'attemptedClose()':
        return NATIVE_SEMAPHORE_OPERATION.attemptedClose;

      case 'closeAttemptSucceeded()':
        return NATIVE_SEMAPHORE_OPERATION.closeAttemptSucceeded;
      case 'willAttemptUnlink()':
        return NATIVE_SEMAPHORE_OPERATION.willAttemptUnlink;
      case 'attemptingUnlink()':
        return NATIVE_SEMAPHORE_OPERATION.attemptingUnlink;
      case 'unlink()':
        return NATIVE_SEMAPHORE_OPERATION.unlink;
      case 'attemptedUnlink()':
        return NATIVE_SEMAPHORE_OPERATION.attemptedUnlink;
      case 'unlinkAttemptSucceeded()':
        return NATIVE_SEMAPHORE_OPERATION.unlinkAttemptSucceeded;
      default:
        return NATIVE_SEMAPHORE_OPERATION.unknown;
    }
  }
}

class PersistedNativeSemaphoreOperations<PNSO extends PersistedNativeSemaphoreOperation> {
  static PNSOS rehydrate<PNSO extends PersistedNativeSemaphoreOperation, PNSOS extends PersistedNativeSemaphoreOperations<PNSO>>(
      {required String serialized, required PNSO Function({required dynamic serialized}) rehydrate_, bool verbose = false}) {
    if (verbose)
      print(
          'PersistedNativeSemaphoreOperations [rehydrate()]' /* serialized: ${Platform.lineTerminator}${Platform.lineTerminator} $serialized ${Platform.lineTerminator}${Platform.lineTerminator}*/);

    final Map<String, dynamic> data = JSON.decode(serialized);

    return PersistedNativeSemaphoreOperations<PNSO>(iterable: (data['operations'] as List<dynamic>).map((serialized_) => rehydrate_(serialized: serialized_)).toList()) as PNSOS;
  }

  late List<PNSO> iterable;

  late Map<String, int> indexed = Map.fromEntries(iterable.map((operation) => MapEntry(operation.hash, iterable.indexOf(operation))));

  PersistedNativeSemaphoreOperations({List<PNSO> this.iterable = const [], bool verbose = false});

  bool add({required PNSO operation}) {
    // TODO perhaps some more checks here?
    return (iterable..add(operation)).elementAt(indexed[operation.hash] = (iterable.length - 1)).hash == operation.hash ||
        (throw Exception('Failed to add operation to PersistedNativeSemaphoreOperations. It doesn\'t exist.'));
  }

  PNSOS merge<PNSOS extends PersistedNativeSemaphoreOperations<PNSO>>({required PNSOS operations}) {
    return PersistedNativeSemaphoreOperations<PNSO>(iterable: iterable..addAll(operations.iterable)) as PNSOS;
  }

  @override
  String toString() => 'PersistedNativeSemaphoreOperations(iterable: $iterable, indexed: $indexed)';

  String serialize() =>
      JSON.encode(Map<String, List<Map<String, dynamic>>>.fromEntries([MapEntry('operations', iterable.map((operation) => operation.asMap()).toList(growable: false))]));
}

class PersistedNativeSemaphoreOperation {
  late final String name;

  final NATIVE_SEMAPHORE_OPERATION operation;

  late final DateTime created;

  late final String identifier;

  late final int address;

  // Time since last operation
  late Duration elapsed;

  // Exclude elapsed and address from hash because it may make it hard to track
  late final String hash = xxh64.convert(Utf8.encode('$name$operation$created$identifier')).hex();

  String isolate;

  String process;

  ({int isolate, int process}) counts;

  bool opened;

  bool locked;

  bool closed;

  bool unlinked;

  bool reentrant;

  bool waiting;

  String tracer;

  bool unlocked;

  PersistedNativeSemaphoreOperation({
    required String this.identifier,
    required String this.name,
    required String this.isolate,
    required String this.process,
    required NATIVE_SEMAPHORE_OPERATION this.operation,
    ({int isolate, int process}) this.counts = (isolate: 0, process: 0),
    this.opened = false,
    this.locked = false,
    this.unlocked = false,
    this.closed = false,
    this.unlinked = false,
    this.reentrant = false,
    this.waiting = false,
    DateTime? created,
    int? address,
    Duration? elapsed,
    bool verbose = false,
    String this.tracer = '',
  })  : created = created ?? DateTime.now(),
        address = address ?? -1,
        elapsed = elapsed ?? Duration.zero;

  @override
  String toString() =>
      'PersistedNativeSemaphoreOperation(name: $name, tracer: $tracer, isolate: $isolate, process: $process, operation: $operation, created: $created, uuid: $identifier, address: $address, elapsed: $elapsed, hash: $hash, opened: $opened locked: $locked, unlocked: $unlocked closed: $closed, unlinked: $unlinked, reentrant: $reentrant, waiting: $waiting, counts: $counts)';

  Map<String, dynamic> asMap() => {
        'name': name,
        'tracer': tracer,
        'isolate': isolate,
        'process': process,
        'operation': operation.toString(),
        'created': created.toIso8601String(),
        'identifier': identifier,
        'address': address,
        'elapsed': elapsed.inMicroseconds,
        'counts': {'isolate': counts.isolate, 'process': counts.process},
        'opened': opened,
        'locked': locked,
        'unlocked': unlocked,
        'closed': closed,
        'unlinked': unlinked,
        'reentrant': reentrant,
        'waiting': waiting,
      };

  String serialize() => JSON.encode(asMap());

  static PNSO rehydrate<PNSO extends PersistedNativeSemaphoreOperation>(
      {required /*Note this can be a map here because the parent class will encode into JSON, it can also be a string if used directly */ dynamic serialized}) {
    final Map<String, dynamic> data = serialized is String ? JSON.decode(serialized) : serialized;

    return PersistedNativeSemaphoreOperation(
      identifier: data['identifier'],
      name: data['name'],
      tracer: data['tracer'],
      isolate: data['isolate'],
      process: data['process'],
      operation: NATIVE_SEMAPHORE_OPERATION.fromString(data['operation']),
      created: DateTime.parse(data['created']),
      address: data['address'],
      waiting: data['waiting'],
      elapsed: Duration(microseconds: data['elapsed']),
      counts: (isolate: data['counts']['isolate'], process: data['counts']['process']),
      opened: data['opened'],
      locked: data['locked'],
      unlocked: data['unlocked'],
      closed: data['closed'],
      unlinked: data['unlinked'],
      reentrant: data['reentrant'],
    ) as PNSO;
  }
}
