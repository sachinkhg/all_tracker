import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Abstraction over Hive static calls to make services testable with fakes.
abstract class BoxProvider {
  Box<T> box<T>(String name);
  bool isBoxOpen(String name);
  Future<Box<T>> openBox<T>(String name);
}

class HiveBoxProvider implements BoxProvider {
  @override
  Box<T> box<T>(String name) => Hive.box<T>(name);

  @override
  bool isBoxOpen(String name) => Hive.isBoxOpen(name);

  @override
  Future<Box<T>> openBox<T>(String name) => Hive.openBox<T>(name);
}

