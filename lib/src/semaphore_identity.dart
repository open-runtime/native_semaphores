import 'dart:developer' show Service;
import 'dart:io' show Directory, File, Platform, pid;
import 'dart:isolate' show Isolate;
import 'utils/late_property_assigned.dart' show LatePropertyAssigned;

class SemaphoreIdentities<I extends SemaphoreIdentity> {
  static String prefix = 'runtime_native_semaphores';

  static String get isolate {
    String? _isolate = Service.getIsolateId(Isolate.current)?.toString();
    return (_isolate ?? Isolate.current.hashCode.toString()).replaceFirst('isolates${Platform.pathSeparator}', '');
  }

  static final String process = pid.toString();

  static final Map<String, dynamic> __identities = {};

  Map<String, dynamic> get _identities => SemaphoreIdentities.__identities;

  Map<String, I> get all => Map.unmodifiable(_identities as Map<String, I>);

  bool has<T>({required String name}) => _identities.containsKey(name) && _identities[name] is T;

  // Returns the semaphore identity for the given identifier as a singleton
  I get({required String name}) => _identities[name] ?? (throw Exception('Failed to get semaphore identity for $name. It doesn\'t exist.'));

  I register({required String name, required I identity}) {
    (_identities.containsKey(name) || identity != _identities[name]) ||
        (throw Exception('Failed to register semaphore identity for $name. It already exists or is not the same as the inbound identity being passed.'));

    return _identities.putIfAbsent(name, () => identity);
  }

  void delete({required String name}) {
    _identities.containsKey(name) || (throw Exception('Failed to delete semaphore identity for $name. It doesn\'t exist.'));
    _identities.remove(name);
  }
}

class SemaphoreIdentity {
  static late final dynamic __instances;

  dynamic get _instances => SemaphoreIdentity.__instances;

  String get prefix => SemaphoreIdentities.prefix;

  String get isolate => SemaphoreIdentities.isolate;

  String get process => SemaphoreIdentities.process;

  //  Gets set when the semaphore is opened
  late final int _address;

  int get address => _address;

  set address(int value) => !LatePropertyAssigned<int>(() => _address) ? _address = value : _address;

  late final String _name;

  String get name => _name;

  // helper property to know if it has been registered inside of a named semaphore instance
  late final bool _registered;

  bool get registered => !LatePropertyAssigned<int>(() => _registered) ? false : _registered;

  String get uuid => [name, isolate, process].join('_');

  SemaphoreIdentity({required String name}) {
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
    if (!LatePropertyAssigned<IS>(() => __instances)) __instances = SemaphoreIdentities<I>();

    return (__instances as IS).has<I>(name: name) ? (__instances as IS).get(name: name) : (__instances as IS).register(name: name, identity: SemaphoreIdentity(name: name) as I);
  }

  bool dispose() => throw UnimplementedError('Dispose not implemented');

  @override
  String toString() => 'SemaphoreIdentity(name: $name, isolate: $isolate, process: $process)';
}
