import 'package:hive_flutter/hive_flutter.dart';

/// Hive box wrapper. Use for typed key/value storage of cacheable models.
class HiveStorageService {
  HiveStorageService._(this._boxes);

  factory HiveStorageService.fromBoxes(Map<String, Box<dynamic>> boxes) => HiveStorageService._(boxes);

  static HiveStorageService? _instance;

  /// Access the most recently initialised instance.
  static HiveStorageService get current {
    final i = _instance;
    if (i == null) {
      throw StateError('HiveStorageService not initialised yet.');
    }
    return i;
  }

  final Map<String, Box<dynamic>> _boxes;

  static Future<HiveStorageService> initialize({String subDir = 'hive'}) async {
    await Hive.initFlutter(subDir);
    final svc = HiveStorageService._({});
    _instance = svc;
    return svc;
  }

  Future<Box<T>> openBox<T>(String name) async {
    if (_boxes.containsKey(name)) return _boxes[name]! as Box<T>;
    final box = await Hive.openBox<T>(name);
    _boxes[name] = box;
    return box;
  }

  Box<T> box<T>(String name) {
    final box = _boxes[name];
    if (box == null) {
      throw StateError('Box $name has not been opened.');
    }
    return box as Box<T>;
  }

  Future<void> close() async {
    for (final box in _boxes.values) {
      await box.close();
    }
    _boxes.clear();
  }
}
