// Minimal in-memory Fake for Hive Box<T> used in tests.
// Covers only the APIs exercised by our data sources and services.
// Other Box APIs fall back to noSuchMethod.
import 'package:hive/hive.dart';

class FakeBox<T> implements Box<T> {
  final String _name;
  final Map<dynamic, T> _store = <dynamic, T>{};

  FakeBox([this._name = 'fake_box']);

  @override
  String get name => _name;

  @override
  bool get isOpen => true;

  @override
  int get length => _store.length;

  @override
  bool get isEmpty => _store.isEmpty;

  @override
  bool get isNotEmpty => _store.isNotEmpty;

  @override
  Iterable<T> get values => _store.values;

  @override
  Iterable get keys => _store.keys;

  @override
  T? get(key, {T? defaultValue}) => _store[key] ?? defaultValue;

  @override
  Future<void> put(key, T value) async {
    _store[key] = value;
  }

  @override
  Future<void> delete(key) async {
    _store.remove(key);
  }

  @override
  Future<int> clear() async {
    final count = _store.length;
    _store.clear();
    return count;
  }

  // Unused Box APIs fall back here during tests.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


