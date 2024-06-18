extension NullableLastWhere<E extends Object> on List<E> {
  /// The non-`null` elements of this iterable.
  ///
  /// The same elements as this iterable, except that `null` values
  /// are omitted.
  T? nullableLastWhere<T extends E?>(bool test(E element), {E orElse()?}){
    try {
      return this.lastWhere((E element) => test(element), orElse: orElse) as T?;
    } on StateError catch (_) {
      return null;
    }
  }

  T? nullableLastSatisfies<T extends E?>(bool test(T? element)){
    return test(this.lastOrNull as T) ? this.last as T : null;
  }
}