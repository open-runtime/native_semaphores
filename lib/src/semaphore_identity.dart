import 'dart:developer' show Service;
import 'dart:io' show Directory, File, FileSystemEntity, Platform, pid;
import 'dart:isolate' show Isolate;
import 'package:runtime_native_semaphores/runtime_native_semaphores.dart';
import 'package:runtime_native_semaphores/src/utils/late_final_property.dart';

import 'persisted_native_semaphore_operation.dart';
import 'utils/late_property_assigned.dart' show LatePropertyAssigned;

class SemaphoreIdentities<I extends SemaphoreIdentity> {
  static String prefix = 'runtime_native_semaphores';

  static final List<dynamic> __instances = List.empty(growable: true);

  List<dynamic> get _instances => __instances;

  List<I> get all => List.unmodifiable(_instances);

  List<I> get external => all.where((identity) => identity.external).toList();

  List<I> get internal => all.where((identity) => !identity.external).toList();

  bool has<T>({required String name, required String process, required String isolate}) => _instances.any((identity) => (identity as I).name.get == name && identity.process == process && identity.isolate == isolate);

  // Returns the semaphore identity for the given identifier as a singleton
  I get({required String name, required String process, required String isolate}) => _instances.firstWhere((instance) => (instance as I).name.get == name && instance.isolate == isolate && instance.process == process, orElse: () => (throw Exception('Failed to get semaphore identity for $name. It doesn\'t exist.')));

  I register({required I identity}) {
    print("Registering semaphore identity for name: ${identity.name.get}, ${identity.tracer.isEmpty ? '' : 'Tracer ${identity.tracer}' }, isolate: ${identity.isolate}, process: ${identity.process}.");

    if(has(name: identity.name.get, process: identity.process, isolate: identity.isolate)) {
      print('Semaphore identity already registered for name: ${identity.name.get}, ${identity.tracer.isEmpty ? '' : 'Tracer ${identity.tracer}' }, isolate: ${identity.isolate}, process: ${identity.process}.');
      return get(name: identity.name.get, process: identity.process, isolate: identity.isolate);
    }

    _instances.add(identity);

    return identity;
  }

  void delete({required String name, required String process, required String isolate}) {
    has(name:name, process: process, isolate: isolate) || (throw Exception('Failed to delete semaphore identity for $name. It doesn\'t exist.'));
    _instances.remove(get(name:name, process: process, isolate: isolate));
  }
}

class SemaphoreIdentity {

  late final _isolate;

  String get isolate => _isolate;

  late final _process;

  String get process => _process;

  static late final __identities;

  SemaphoreIdentities<I> instances<I extends SemaphoreIdentity>() => __identities;

  String get prefix => SemaphoreIdentities.prefix;

  //  Gets set when the semaphore is opened
  late final int _address;

  int get address => _address;

  set address(int value) => !LatePropertyAssigned<int>(() => _address) ? _address = value : _address;

  final LateProperty<String> name = LateProperty<String>(name: 'name', updatable: false);

  late String Function() tracerFn;
  String get tracer => tracerFn();

  // helper property to know if it has been registered inside of a named semaphore instance
  late final bool _registered;

  bool get registered => !LatePropertyAssigned<int>(() => _registered) ? false : _registered;

  String get identifier => [name.get, isolate, process].join('_');

  late final Directory cache = Directory('${Directory.systemTemp.path}${Platform.pathSeparator}runtime_native_semaphores${Platform.pathSeparator}$name')..createSync(recursive: true);

  late final File temp = File('${cache.path}${Platform.pathSeparator}process_${process}_isolate_${isolate}.semaphore.txt')..createSync(recursive: true)..writeAsStringSync(PersistedNativeSemaphoreOperations().serialize(), flush: true);

  bool verbose;

  late final bool external;

  SemaphoreIdentity({required String name, required String Function() this.tracerFn, String? isolate, String? process, bool this.external = false, bool this.verbose = false}) {
    name = name.replaceFirst('Global\\', '').replaceFirst('Local\\', '');
    // check if identifier has invalid characters
    if (name.contains(RegExp(r'[\\/:*?"<>|]'))) throw ArgumentError('Identifier contains invalid characters.');
    this.name.set(name);
    // this.tracer = tracer ?? '';
    _isolate = isolate ?? (Service.getIsolateId(Isolate.current)?.toString() ?? Isolate.current.hashCode.toString()).replaceFirst('isolates${Platform.pathSeparator}', '');
    _process = process ?? pid.toString();
  }

  static SemaphoreIdentity instantiate<
      /*  Identity */
      I extends SemaphoreIdentity,
      /* Semaphore Identities */
      IS extends SemaphoreIdentities<I>
      /* formatting guard comment */
      >({required String name, required String Function() tracerFn, String? isolate, String? process, bool external = false,  bool verbose = false}) {
    // TODO singleton identity?
        if (!LatePropertyAssigned<IS>(() => __identities)) __identities = SemaphoreIdentities<I>();

    return (__identities as IS).register(identity: SemaphoreIdentity(name: name, tracerFn: tracerFn, isolate: isolate, process: process, external: external, verbose: verbose) as I);
  }

  // Associates an external semaphore from a different process to this processes semaphore identities
  SemaphoreIdentity track<
  /*  Identity */
  I extends SemaphoreIdentity,
  /* Semaphore Identities */
  IS extends SemaphoreIdentities<I>
  /* formatting guard comment */
  >({required String name, required String Function() tracerFn, String? tracer, String? isolate,  String? process,  bool verbose = false}) {
    // if(verbose) print('Tracking semaphore identity for name: $name, ${tracer?.isEmpty ?? true ? '' : 'Tracer $tracer' } isolate: $isolate, process: $process.');
    return instantiate(name: name, tracerFn: () => tracerFn(),  isolate: isolate, process: process, external: true, verbose: verbose);
  }


  bool dispose() => throw UnimplementedError('Dispose not implemented');

  @override
  String toString() => 'SemaphoreIdentity(name: $name, isolate: $isolate, process: $process)';
}
