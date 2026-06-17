class AsyncHelper {
  AsyncHelper._();

  /// Sleeps for [duration] — used in tests and demo flows.
  static Future<void> delay([Duration duration = const Duration(seconds: 1)]) =>
      Future.delayed(duration);
}
