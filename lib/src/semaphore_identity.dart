import 'dart:developer' show Service;
import 'dart:io' show pid;
import 'dart:isolate' show Isolate;

import 'package:runtime_native_semaphores/src/singleton.dart';

import 'utils/later_property_set.dart';

class SemaphoreIdentities<I extends SemaphoreIdentity> {
  static String prefix = 'runtime_native_semaphores';

  static final String isolate =
      (Service.getIsolateId(Isolate.current)?.toString() ?? (throw Exception('Failed to get isolate id')))
          .replaceAll("isolates", "")
          .substring(1);

  static final String process = pid.toString();

  static final Map<String, dynamic> _identities = {};

  Map<String, I> get all => Map.unmodifiable(_identities as Map<String, I>);

  bool has<T>({required String name}) => _identities.containsKey(name) && _identities[name] is T;

  // Returns the semaphore identity for the given identifier as a singleton
  I get({required String name}) =>
      _identities[name] ?? (throw Exception('Failed to get semaphore identity for $name. It doesn\'t exist.'));

  I register({required String name, required I identity}) {
    (_identities.containsKey(name) || identity != _identities[name]) ||
        (throw Exception(
            'Failed to register semaphore identity for $name. It already exists or is not the same as the inbound identity being passed.'));

    return _identities.putIfAbsent(name, () => identity);
  }

  void delete({required String name}) {
    _identities.containsKey(name) ||
        (throw Exception('Failed to delete semaphore identity for $name. It doesn\'t exist.'));
    _identities.remove(name);
  }
}

class SemaphoreIdentity {
  static late final dynamic _instances;

  // copy here so its immutable
  // Map<String, SemaphoreIdentity> get identities => Map.unmodifiable(SemaphoreIdentity._identities);

  String get prefix => SemaphoreIdentities.prefix;

  String get isolate => SemaphoreIdentities.isolate;

  String get process => SemaphoreIdentities.process;

  //  Gets set when the semaphore is opened
  late final String _address;

  String get address => _address;

  late final String _name;

  String get name => _name;

  // helper property to know if it has been registered inside of a named semaphore instance
  late final bool _registered;
  bool get registered => _registered;

  String get uuid => [name, isolate, process].join('_');

  // TODO this likely needs to be a factory as well
  SemaphoreIdentity._({required String name}) {
    name = name.replaceFirst('Global\\', '').replaceFirst('Local\\', '');
    // check if identifier has invalid characters
    if (name.contains(RegExp(r'[\\/:*?"<>|]'))) throw ArgumentError('Identifier contains invalid characters.');

    _name = name;
  }

  static SemaphoreIdentity instantiate<
      /*  Identity */
      I extends SemaphoreIdentity,
      /* Semaphore Identities */
      IS extends SemaphoreIdentities<I>
      /* formatting guard comment */
      >({required String name}) {
    if (!LatePropertyAssigned<IS>(() => SemaphoreIdentity._instances))
      SemaphoreIdentity._instances = SemaphoreIdentities<I>();
    // bool identities = LatePropertySet<IS>(() => SemaphoreCounter._identities);
    // if (!identities) SemaphoreCounter._identities = identities;

    return (SemaphoreIdentity._instances as IS).has<I>(name: name)
        ? (SemaphoreIdentity._instances as IS).get(name: name)
        : (SemaphoreIdentity._instances as IS).register(name: name, identity: SemaphoreIdentity._(name: name) as I);
  }

  bool dispose() {
    // Other cleanup here?
    // return SemaphoreIdentity._instances.remove(_semaphore) is SemaphoreIdentity;
    throw UnimplementedError('Dispose not implemented');
  }

  @override
  String toString() {
    return 'SemaphoreIdentity(name: $name, isolate: $isolate, process: $process)';
  }
}
