import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gif_view/src/gif_controller.dart';
import 'package:gif_view/src/git_frame.dart';
import 'package:http/http.dart' as http;

class GifFrame {
  final ImageInfo imageInfo;
  final Duration duration;

  GifFrame(this.imageInfo, this.duration);
}

enum GifStatus { loading, playing, stopped, paused, reversing, error }

class GifController extends ChangeNotifier {
  List<GifFrame> _frames = [];
  int currentIndex = 0;
  GifStatus status = GifStatus.loading;
  Exception? exception;

  final bool autoPlay;
  final VoidCallback? onFinish;
  final VoidCallback? onStart;
  final ValueChanged<int>? onFrame;

  bool loop;
  bool _inverted;

  GifController({
    this.autoPlay = true,
    this.loop = true,
    bool inverted = false,
    this.onStart,
    this.onFinish,
    this.onFrame,
  }) : _inverted = inverted;

  void _run() {
    switch (status) {
      case GifStatus.playing:
      case GifStatus.reversing:
        _runNextFrame();
        break;
      case GifStatus.stopped:
        onFinish?.call();
        currentIndex = 0;
        break;
      case GifStatus.loading:
      case GifStatus.paused:
      case GifStatus.error:
        break;
    }
  }

  void _runNextFrame() async {
    if (_frames.isEmpty) return;

    await Future.delayed(_frames[currentIndex].duration);

    if (status == GifStatus.reversing) {
      if (currentIndex > 0) {
        currentIndex--;
      } else if (loop) {
        currentIndex = _frames.length - 1;
      } else {
        status = GifStatus.stopped;
      }
    } else {
      if (currentIndex < _frames.length - 1) {
        currentIndex++;
      } else if (loop) {
        currentIndex = 0;
      } else {
        status = GifStatus.stopped;
      }
    }

    onFrame?.call(currentIndex);
    notifyListeners();
    _run();
  }

  GifFrame? get currentFrame =>
      _frames.isNotEmpty ? _frames[currentIndex] : null;

  int get countFrames => _frames.length;
  bool get isReversing => status == GifStatus.reversing;
  bool get isPaused => status == GifStatus.stopped || status == GifStatus.paused;
  bool get isPlaying => status == GifStatus.playing;

  void play({bool? inverted, int? initialFrame}) {
    if (status == GifStatus.loading || _frames.isEmpty) return;
    _inverted = inverted ?? _inverted;

    if (status == GifStatus.stopped || status == GifStatus.paused) {
      status = _inverted ? GifStatus.reversing : GifStatus.playing;

      bool isValidInitialFrame = initialFrame != null &&
          initialFrame >= 0 &&
          initialFrame < _frames.length;

      if (isValidInitialFrame) {
        currentIndex = initialFrame!;
      } else {
        currentIndex = isReversing ? _frames.length - 1 : 0;
      }
      onStart?.call();
      _run();
    } else {
      status = _inverted ? GifStatus.reversing : GifStatus.playing;
    }
  }

  void stop() {
    status = GifStatus.stopped;
  }

  void pause() {
    status = GifStatus.paused;
  }

  void seek(int index) {
    if (index >= 0 && index < _frames.length) {
      currentIndex = index;
      notifyListeners();
    }
  }

  void configure(List<GifFrame> frames, {bool updateFrames = false}) {
    exception = null;
    _frames = frames;
    if (!updateFrames || status == GifStatus.loading) {
      status = GifStatus.stopped;
      if (autoPlay) {
        play();
      }
      notifyListeners();
    }
  }

  void error(Exception e) {
    exception = e;
    status = GifStatus.error;
    notifyListeners();
  }

  void loading() {
    status = GifStatus.loading;
    notifyListeners();
  }
}

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
    Future.delayed(Duration.zero, _loadImage);
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
      image: controller.currentFrame?.imageInfo.image,
      width: widget.width,
      height: widget.height,
      scale: controller.currentFrame?.imageInfo.scale ?? 1.0,
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
        : "";
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
