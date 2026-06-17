extension IterableX<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }

  Map<K, List<T>> groupBy<K>(K Function(T) key) {
    final map = <K, List<T>>{};
    for (final element in this) {
      map.putIfAbsent(key(element), () => <T>[]).add(element);
    }
    return map;
  }

  Map<K, T> associateBy<K>(K Function(T) key) =>
      {for (final e in this) key(e): e};
}
