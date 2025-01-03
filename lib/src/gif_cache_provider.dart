import 'dart:typed_data';

abstract class GifCacheProvider {
  Future<Uint8List?> get(String key);
  Future<void> set(String key, Uint8List data);
  Future<void> clear();
}

class MemoryCacheProvider extends GifCacheProvider {
  final Map<String, Uint8List> _cache = {};

  @override
  Future<Uint8List?> get(String key) async {
    return _cache[key];
  }

  @override
  Future<void> set(String key, Uint8List data) async {
    _cache[key] = data;
  }

  @override
  Future<void> clear() async {
    _cache.clear();
  }
}
