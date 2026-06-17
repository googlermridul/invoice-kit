class IdGenerator {
  IdGenerator._();
  static String create([String prefix = 'id']) =>
      '${prefix}_${DateTime.now().microsecondsSinceEpoch}';
}
