import 'native_semaphore_operations.dart' show NATIVE_SEMAPHORE_OPERATIONS;
import 'utils/XXHash64.dart' show JSON, Utf8, xxh64;

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

  final NATIVE_SEMAPHORE_OPERATIONS operation;

  late final DateTime created;

  late final String identifier;

  late final int address;

  // Time since last operation
  late Duration elapsed;

  // Exclude elapsed and address from hash because it may make it hard to track
  late final String hash = xxh64.convert(Utf8.encode('$name$operation$created$identifier')).hex();

  String isolate;

  String process;

  ({int isolate_locks, int process_locks, int reentrant, int opened, int closed, int unlinked, int instantiated}) counts;

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
    required NATIVE_SEMAPHORE_OPERATIONS this.operation,
    ({int isolate_locks, int process_locks, int reentrant, int opened, int closed, int unlinked, int instantiated}) this.counts = (isolate_locks: 0, process_locks: 0, reentrant: 0, opened: 0, closed: 0, unlinked: 0, instantiated: 0),
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
        'counts': {'isolate_locks': counts.isolate_locks, 'process_locks': counts.process_locks, 'reentrant': counts.reentrant, 'opened': counts.opened, 'closed': counts.closed, 'unlinked': counts.unlinked, 'instantiated': counts.instantiated},
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
      operation: NATIVE_SEMAPHORE_OPERATIONS.fromString(data['operation']),
      created: DateTime.parse(data['created']),
      address: data['address'],
      waiting: data['waiting'],
      elapsed: Duration(microseconds: data['elapsed']),
      counts: (isolate_locks: data['counts']['isolate_locks'], process_locks: data['counts']['process_locks'], reentrant: data['counts']['reentrant'], opened: data['counts']['opened'], closed: data['counts']['closed'], unlinked: data['counts']['unlinked'], instantiated: data['counts']['instantiated']),
      opened: data['opened'],
      locked: data['locked'],
      unlocked: data['unlocked'],
      closed: data['closed'],
      unlinked: data['unlinked'],
      reentrant: data['reentrant'],
    ) as PNSO;
  }
}
