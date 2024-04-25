// class Singleton<T> {
//   static final Map<dynamic, dynamic> _instances = {};
//
//   T instance(Type type, String identifier) {
//     String key = _key(type, identifier);
//     _instances[key] ??= Singleton._();
//     return _instances[key] as T;
//   }
//
//   String _key(Type type, String identifier) {
//     return '$type::$identifier';
//   }
//
//   void delete(Type type, String identifier) {
//     String key = _key(type, identifier);
//     dynamic instance = _instances.remove(key);
//     instance is T || (throw Exception('Failed to delete instance for $key.'));
//   }
// }
