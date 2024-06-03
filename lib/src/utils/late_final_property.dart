import 'package:meta/meta.dart' show protected;
import 'late_property_assigned.dart' show LatePropertyAssigned;

class LateProperty<T> {
  late final LateProperty<T>? reference;

  final String? name;

  @protected
  final T? initial;

  @protected
  late final T once;

  @protected
  late T updating;

  @protected
  final bool updatable;

  bool get isSet => LatePropertyAssigned<T>(() => updatable ? updating : once);

  T? get getter => isSet ? updatable ? updating : once : initial;

  // TODO completer for async

  LateProperty({T? this.initial = null, bool this.updatable = true, String this.name = ''});

  ({T get, T? nullable, bool succeeded, String? name}) set(T _) =>
      (succeeded: !updatable ? !(isSet || !((once = _) is T)) : (updating = _) is T, name: name, get: get, nullable: nullable);

  T? get nullable => isSet ? getter : initial;

  T get get => getter != null && getter is T ? getter! as T : (throw 'Property is not set use nullable instead.');

  TA casted<TA>() => get as TA;

  @override
  String toString() {
    return '[$name | initial: $initial, getter: ${isSet ? getter : 'unset'}, isSet: $isSet]';
  }
}