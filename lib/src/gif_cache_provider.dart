import 'dart:typed_data';

abstract class GifCacheProvider {
  Future<Uint8List?> get(String key);
  void set(String key, Uint8List data);
}

class MemoryCacheProvider extends GifCacheProvider {
  final Map<String, Uint8List> _cache = {};

  @override
  Future<Uint8List?> get(String key) async {
    return _cache[key];
  }

  @override
  void set(String key, Uint8List data) {
    _cache[key] = data;
  }
}
