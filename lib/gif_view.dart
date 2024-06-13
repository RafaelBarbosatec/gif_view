import 'dart:async';
import 'dart:math';
// ignore: unnecessary_import
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gif_view/src/gif_controller.dart';
import 'package:gif_view/src/git_frame.dart';
import 'package:http/http.dart' as http;

export 'package:gif_view/src/gif_controller.dart';

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

final Map<String, List<GifFrame>> _cache = {};

class GifView extends StatefulWidget {
  final GifController? controller;
  final int? frameRate;
  final ImageProvider image;
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
  final bool withOpacityAnimation;
  final FilterQuality filterQuality;
  final bool isAntiAlias;
  final Widget Function(Exception error)? onError;
  final Duration? fadeDuration;

  GifView.network(
    String url, {
    Key? key,
    this.controller,
    this.frameRate,
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
    this.withOpacityAnimation = true,
    this.onError,
    this.fadeDuration,
    double scale = 1.0,
    Map<String, String>? headers,
  })  : image = NetworkImage(url, scale: scale, headers: headers),
        super(key: key);

  GifView.asset(
    String asset, {
    Key? key,
    this.controller,
    this.frameRate,
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
    this.withOpacityAnimation = true,
    this.onError,
    this.fadeDuration,
    String? package,
    AssetBundle? bundle,
  })  : image = AssetImage(asset, package: package, bundle: bundle),
        super(key: key);

  GifView.memory(
    Uint8List bytes, {
    Key? key,
    this.controller,
    this.frameRate = 15,
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
    this.withOpacityAnimation = true,
    this.onError,
    this.fadeDuration,
    double scale = 1.0,
  })  : image = MemoryImage(bytes, scale: scale),
        super(key: key);

  const GifView({
    Key? key,
    required this.image,
    this.controller,
    this.frameRate = 15,
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
    this.withOpacityAnimation = true,
    this.onError,
    this.fadeDuration,
  }) : super(key: key);

  @override
  GifViewState createState() => GifViewState();
}

class GifViewState extends State<GifView> with TickerProviderStateMixin {
  late GifController controller;

  AnimationController? _animationController;

  @override
  void initState() {
    if (widget.withOpacityAnimation) {
      _animationController = AnimationController(
        vsync: this,
        duration: widget.fadeDuration ?? const Duration(milliseconds: 300),
      );
    }
    controller = widget.controller ?? GifController();
    controller.addListener(_listener);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _loadImage(),
    );
    super.initState();
  }

  @override
  void dispose() {
    controller.stop();
    controller.removeListener(_listener);
    _animationController?.dispose();
    _animationController = null;
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant GifView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.image != widget.image ||
        controller.status == GifStatus.error) {
      _loadImage(updateFrames: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (controller.status == GifStatus.loading) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: widget.progress,
      );
    }

    if (controller.status == GifStatus.error) {
      final errorWidget = widget.onError?.call(controller.exception!);
      if (errorWidget == null) {
        throw controller.exception!;
      }
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: errorWidget,
      );
    }

    return RawImage(
      image: controller.currentFrame.imageInfo.image,
      width: widget.width,
      height: widget.height,
      scale: controller.currentFrame.imageInfo.scale,
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
      opacity: _animationController,
    );
  }

  String _getKeyImage(ImageProvider provider) {
    return provider is NetworkImage
        ? provider.url
        : provider is AssetImage
            ? provider.assetName
            : provider is MemoryImage
                ? provider.bytes.toString().substring(0, 100)
                : provider is FileImage
                    ? provider.file.path
                    : Random().nextDouble().toString();
  }

  Future<List<GifFrame>> _fetchGif(ImageProvider provider) async {
    List<GifFrame> frameList = [];
    try {
      String key = _getKeyImage(provider);

      if (_cache.containsKey(key)) {
        frameList = _cache[key]!;
        return frameList;
      }

      Uint8List? data = await _loadImageBytes(provider);

      if (data == null) {
        return [];
      }

      frameList.addAll(await _buildFrames(data));

      _cache.putIfAbsent(key, () => frameList);
    } catch (e) {
      controller.error(e as Exception);
    }
    return frameList;
  }

  FutureOr _loadImage({bool updateFrames = false}) async {
    controller.loading();
    final frames = await _fetchGif(widget.image);
    if (frames.isNotEmpty) {
      controller.configure(frames, updateFrames: updateFrames);
      _animationController?.forward(from: 0);
    }
  }

  void _listener() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<Uint8List?> _loadImageBytes(ImageProvider<Object> provider) {
    if (provider is NetworkImage) {
      final Uri resolved = Uri.base.resolve(provider.url);
      return http
          .get(resolved, headers: provider.headers)
          .then((value) => value.bodyBytes);
    } else if (provider is AssetImage) {
      return provider.obtainKey(const ImageConfiguration()).then(
        (value) async {
          final d = await value.bundle.load(value.name);
          return d.buffer.asUint8List();
        },
      );
    } else if (provider is FileImage) {
      return provider.file.readAsBytes();
    } else if (provider is MemoryImage) {
      return Future.value(provider.bytes);
    }
    return Future.value(null);
  }

  Future<Iterable<GifFrame>> _buildFrames(Uint8List data) async {
    Codec codec = await instantiateImageCodec(
      data,
      allowUpscaling: false,
    );

    List<GifFrame> list = [];

    for (int i = 0; i < codec.frameCount; i++) {
      FrameInfo frameInfo = await codec.getNextFrame();
      Duration duration = frameInfo.duration;
      if (widget.frameRate != null) {
        duration = Duration(milliseconds: (1000 / widget.frameRate!).ceil());
      }
      list.add(
        GifFrame(
          ImageInfo(image: frameInfo.image),
          duration,
        ),
      );
    }
    return list;
  }
}
