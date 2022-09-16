import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

///
/// Created by
///
/// ─▄▀─▄▀
/// ──▀──▀
/// █▀▀▀▀▀█▄
/// █░░░░░█─█
/// ▀▄▄▄▄▄▀▀
///
/// Rafaelbarbosatec
/// on 23/09/21

class GifFrame {
  final ImageInfo imageInfo;
  final Duration duration;

  GifFrame(this.imageInfo, this.duration);
}

final Map<String, List<GifFrame>> _cache = {};

class GifView extends StatefulWidget {
  final int? frameRate;
  final VoidCallback? onFinish;
  final VoidCallback? onStart;
  final ValueChanged<int>? onFrame;
  final ImageProvider image;
  final bool loop;
  final double? height;
  final double? width;
  final Widget? progress;
  final BoxFit? fit;
  final Color? color;
  final BlendMode? colorBlendMode;
  final AlignmentGeometry alignment;
  final ImageRepeat repeat;
  final Rect? centerSlice;
  final bool matchTextDirection;
  final bool invertColors;
  final FilterQuality filterQuality;
  final bool isAntiAlias;

  GifView.network(
    String url, {
    Key? key,
    this.frameRate,
    this.loop = true,
    this.height,
    this.width,
    this.progress,
    this.fit,
    this.color,
    this.colorBlendMode,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.centerSlice,
    this.matchTextDirection = false,
    this.invertColors = false,
    this.filterQuality = FilterQuality.low,
    this.isAntiAlias = false,
    this.onFinish,
    this.onStart,
    this.onFrame,
    double scale = 1.0,
    Map<String, String>? headers,
  })  : image = NetworkImage(url, scale: scale, headers: headers),
        super(key: key);

  GifView.asset(
    String asset, {
    Key? key,
    this.frameRate,
    this.loop = true,
    this.height,
    this.width,
    this.progress,
    this.fit,
    this.color,
    this.colorBlendMode,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.centerSlice,
    this.matchTextDirection = false,
    this.invertColors = false,
    this.filterQuality = FilterQuality.low,
    this.isAntiAlias = false,
    this.onFinish,
    this.onStart,
    this.onFrame,
    String? package,
    AssetBundle? bundle,
  })  : image = AssetImage(asset, package: package, bundle: bundle),
        super(key: key);

  GifView.memory(
    Uint8List bytes, {
    Key? key,
    this.frameRate = 15,
    this.loop = true,
    this.height,
    this.width,
    this.progress,
    this.fit,
    this.color,
    this.colorBlendMode,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.centerSlice,
    this.matchTextDirection = false,
    this.invertColors = false,
    this.filterQuality = FilterQuality.low,
    this.isAntiAlias = false,
    this.onFinish,
    this.onStart,
    this.onFrame,
    double scale = 1.0,
  })  : image = MemoryImage(bytes, scale: scale),
        super(key: key);

  const GifView({
    Key? key,
    this.frameRate = 15,
    required this.image,
    this.loop = true,
    this.height,
    this.width,
    this.progress,
    this.fit,
    this.color,
    this.colorBlendMode,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.centerSlice,
    this.matchTextDirection = false,
    this.invertColors = false,
    this.filterQuality = FilterQuality.low,
    this.isAntiAlias = false,
    this.onFinish,
    this.onStart,
    this.onFrame,
  }) : super(key: key);

  @override
  GifViewState createState() => GifViewState();
}

class GifViewState extends State<GifView> with TickerProviderStateMixin {
  List<GifFrame> frames = [];
  bool _running = false;
  int currentIndex = 0;

  @override
  void initState() {
    Future.delayed(Duration.zero, _loadImage);
    super.initState();
  }

  GifFrame get currentFrame => frames[currentIndex];

  @override
  Widget build(BuildContext context) {
    if (frames.isEmpty) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: widget.progress,
      );
    }
    return RawImage(
      image: currentFrame.imageInfo.image,
      width: widget.width,
      height: widget.height,
      scale: currentFrame.imageInfo.scale,
      fit: widget.fit,
      color: widget.color,
      colorBlendMode: widget.colorBlendMode,
      alignment: widget.alignment,
      repeat: widget.repeat,
      centerSlice: widget.centerSlice,
      matchTextDirection: widget.matchTextDirection,
      invertColors: widget.invertColors,
      filterQuality: widget.filterQuality,
      isAntiAlias: widget.isAntiAlias,
    );
  }

  final HttpClient _sharedHttpClient = HttpClient()..autoUncompress = false;

  HttpClient get _httpClient {
    HttpClient client = _sharedHttpClient;
    assert(() {
      if (debugNetworkImageHttpClientProvider != null) {
        client = debugNetworkImageHttpClientProvider!();
      }
      return true;
    }());
    return client;
  }

  String _getKeyImage(ImageProvider provider) {
    return provider is NetworkImage
        ? provider.url
        : provider is AssetImage
            ? provider.assetName
            : provider is MemoryImage
                ? provider.bytes.toString()
                : "";
  }

  Future<List<GifFrame>> _fetchGif(ImageProvider provider) async {
    List<GifFrame> frameList = [];
    dynamic data;
    String key = _getKeyImage(provider);
    if (_cache.containsKey(key)) {
      frameList = _cache[key]!;
      return frameList;
    }
    if (provider is NetworkImage) {
      final Uri resolved = Uri.base.resolve(provider.url);
      final HttpClientRequest request = await _httpClient.getUrl(resolved);
      provider.headers?.forEach((String name, String value) {
        request.headers.add(name, value);
      });
      final HttpClientResponse response = await request.close();
      data = await consolidateHttpClientResponseBytes(
        response,
      );
    } else if (provider is AssetImage) {
      AssetBundleImageKey key =
          await provider.obtainKey(const ImageConfiguration());
      data = await key.bundle.load(key.name);
    } else if (provider is FileImage) {
      data = await provider.file.readAsBytes();
    } else if (provider is MemoryImage) {
      data = provider.bytes;
    }

    Codec codec = await instantiateImageCodec(
      data.buffer.asUint8List(),
      allowUpscaling: false,
    );

    for (int i = 0; i < codec.frameCount; i++) {
      FrameInfo frameInfo = await codec.getNextFrame();
      Duration duration = frameInfo.duration;
      if (widget.frameRate != null) {
        duration = Duration(milliseconds: (1000 / widget.frameRate!).ceil());
      }
      frameList.add(
        GifFrame(
          ImageInfo(image: frameInfo.image),
          duration,
        ),
      );
    }
    _cache.putIfAbsent(key, () => frameList);
    return frameList;
  }

  FutureOr _loadImage() async {
    frames = await _fetchGif(widget.image);

    if (mounted) {
      setState(() {
        widget.onStart?.call();
        play();
      });
    }
  }

  void _startAnimation() async {
    if (_running) {
      await Future.delayed(currentFrame.duration);
      if (currentIndex < frames.length - 1) {
        if (mounted) {
          setState(() {
            currentIndex++;
          });
          widget.onFrame?.call(currentIndex);
        }
      } else if (widget.loop) {
        currentIndex = 0;
      } else {
        widget.onFinish?.call();
        _running = false;
      }
      _startAnimation();
    }
  }

  void play() {
    _running = true;
    _startAnimation();
  }

  void pause() {
    _running = false;
  }

  void stop() {
    _running = false;
    currentIndex = 0;
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
