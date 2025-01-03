library gif_view;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gif_view/src/gif_controller.dart';
import 'package:gif_view/src/gif_frame_builder.dart';

import 'src/gif_cache_provider.dart';
import 'src/gif_loader.dart';

export 'package:gif_view/src/gif_cache_provider.dart';
export 'package:gif_view/src/gif_controller.dart';

class GifView extends StatefulWidget {
  /// Optional controller to manage GIF playback externally.
  final GifController? controller;

  /// Duration between frames in the GIF animation.
  /// Defaults is the fps original file
  final int? frameRate;
  final ImageProvider image;

  /// The height of the GIF view widget.
  /// If null, the widget will use its parent's height constraints.
  final double? height;

  /// The width of the GIF view widget.
  /// If null, the widget will use its parent's width constraints.
  final double? width;
  final Widget Function(
          BuildContext context, Exception error, VoidCallback tryAgain)?
      errorBuilder;
  final WidgetBuilder? progressBuilder;

  /// How to fit the image within its bounds.
  /// Uses Flutter's BoxFit enum.
  /// Defaults to BoxFit.contain.
  final BoxFit? fit;
  final Color? color;
  final BlendMode? colorBlendMode;
  final AlignmentGeometry alignment;
  final ImageRepeat imageRepeat;
  final Rect? centerSlice;
  final bool matchTextDirection;
  final bool invertColors;
  final FilterQuality filterQuality;
  final bool isAntiAlias;

  final bool withOpacityAnimation;
  final Duration? fadeDuration;

  /// Controls whether the GIF animation should auto-start.
  /// Defaults to true.
  final bool autoPlay;

  /// Determines if the GIF should loop continuously.
  /// When false, the animation will play once and stop.
  /// Defaults to true.
  final bool loop;
  final bool playInverted;
  final void Function()? onStart;

  /// Callback function that triggers when animation completes.
  /// Only called when [loop] is false.
  final void Function()? onFinish;
  final void Function(int frame)? onFrame;
  final void Function(int totalFrames)? onLoaded;

  GifView.network(
    String url, {
    Key? key,
    this.controller,
    this.frameRate,
    this.height,
    this.width,
    this.progressBuilder,
    this.fit,
    this.color,
    this.colorBlendMode,
    this.alignment = Alignment.center,
    this.imageRepeat = ImageRepeat.noRepeat,
    this.centerSlice,
    this.matchTextDirection = false,
    this.invertColors = false,
    this.filterQuality = FilterQuality.low,
    this.isAntiAlias = false,
    this.withOpacityAnimation = true,
    this.errorBuilder,
    this.fadeDuration,
    double scale = 1.0,
    Map<String, String>? headers,
    this.onStart,
    this.onFinish,
    this.onFrame,
    this.onLoaded,
    this.autoPlay = true,
    this.loop = true,
    this.playInverted = false,
  })  : image = NetworkImage(url, scale: scale, headers: headers),
        super(key: key);

  GifView.asset(
    String asset, {
    Key? key,
    this.controller,
    this.frameRate,
    this.height,
    this.width,
    this.progressBuilder,
    this.fit,
    this.color,
    this.colorBlendMode,
    this.alignment = Alignment.center,
    this.imageRepeat = ImageRepeat.noRepeat,
    this.centerSlice,
    this.matchTextDirection = false,
    this.invertColors = false,
    this.filterQuality = FilterQuality.low,
    this.isAntiAlias = false,
    this.withOpacityAnimation = true,
    this.errorBuilder,
    this.fadeDuration,
    String? package,
    AssetBundle? bundle,
    this.onStart,
    this.onFinish,
    this.onFrame,
    this.onLoaded,
    this.autoPlay = true,
    this.loop = true,
    this.playInverted = false,
  })  : image = AssetImage(asset, package: package, bundle: bundle),
        super(key: key);

  GifView.memory(
    Uint8List bytes, {
    Key? key,
    this.controller,
    this.frameRate,
    this.height,
    this.width,
    this.progressBuilder,
    this.fit,
    this.color,
    this.colorBlendMode,
    this.alignment = Alignment.center,
    this.imageRepeat = ImageRepeat.noRepeat,
    this.centerSlice,
    this.matchTextDirection = false,
    this.invertColors = false,
    this.filterQuality = FilterQuality.low,
    this.isAntiAlias = false,
    this.withOpacityAnimation = true,
    this.errorBuilder,
    this.fadeDuration,
    double scale = 1.0,
    this.onStart,
    this.onFinish,
    this.onFrame,
    this.onLoaded,
    this.autoPlay = true,
    this.loop = true,
    this.playInverted = false,
  })  : image = MemoryImage(bytes, scale: scale),
        super(key: key);

  const GifView({
    Key? key,
    required this.image,
    this.controller,
    this.frameRate,
    this.height,
    this.width,
    this.progressBuilder,
    this.fit,
    this.color,
    this.colorBlendMode,
    this.alignment = Alignment.center,
    this.imageRepeat = ImageRepeat.noRepeat,
    this.centerSlice,
    this.matchTextDirection = false,
    this.invertColors = false,
    this.filterQuality = FilterQuality.low,
    this.isAntiAlias = false,
    this.withOpacityAnimation = true,
    this.errorBuilder,
    this.fadeDuration,
    this.onStart,
    this.onFinish,
    this.onFrame,
    this.onLoaded,
    this.autoPlay = true,
    this.loop = true,
    this.playInverted = false,
  }) : super(key: key);

  /// Pre-fetches GIF images and stores them in cache for faster loading.
  ///
  /// [image] A ImageProvider to be pre-fetched.
  ///
  /// Example:
  /// ```dart
  /// await GifView.preFetch(AssetImage());
  /// ```
  static Future<void> preFetchImage(ImageProvider image) async {
    await GifLoader.instance.fetch(image);
  }

  static Future<void> clearCache() async {
    await GifLoader.instance.clearCache();
  }

  /// Sets a custom cache provider for GIF image storage.
  ///
  /// [provider] An implementation of [GifCacheProvider] to handle caching.
  /// If null, reverts to the default cache provider.
  ///
  /// Example:
  /// ```dart
  /// GifView.setCacheProvider(MyCustomCacheProvider());
  /// ```
  static void setCacheProvider(GifCacheProvider? provider) {
    GifLoader.instance.setCacheProvider(provider);
  }

  @override
  GifViewState createState() => GifViewState();
}

class GifViewState extends State<GifView> with SingleTickerProviderStateMixin {
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
    controller.init(
      autoPlay: widget.autoPlay,
      inverted: widget.playInverted,
      loop: widget.loop,
      onStart: widget.onStart,
      onFinish: widget.onFinish,
      onFrame: widget.onFrame,
    );
    controller.addListener(_listener);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _loadImage(),
    );
    super.initState();
  }

  @override
  void dispose() {
    controller.removeListener(_listener);
    if (widget.controller == null) {
      controller.dispose();
    } else {
      controller.stop();
    }

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
        child: widget.progressBuilder?.call(context),
      );
    }

    if (controller.status == GifStatus.error) {
      final errorWidget = widget.errorBuilder?.call(
        context,
        controller.exception!,
        () => _loadImage(),
      );
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
      repeat: widget.imageRepeat,
      centerSlice: widget.centerSlice,
      matchTextDirection: widget.matchTextDirection,
      invertColors: widget.invertColors,
      filterQuality: widget.filterQuality,
      isAntiAlias: widget.isAntiAlias,
      opacity: _animationController,
    );
  }

  FutureOr _loadImage({bool updateFrames = false}) async {
    controller.loading();
    try {
      final data = await GifLoader.instance.fetch(widget.image);
      if (data != null) {
        final frames = await GifFrameBuilder(
          data: data,
          frameRate: widget.frameRate,
        ).build();
        if (frames.isNotEmpty) {
          widget.onLoaded?.call(frames.length);
          controller.configure(frames, updateFrames: updateFrames);
          _animationController?.forward(from: 0);
        } else {
          controller.error(Exception('Can not load image'));
        }
      } else {
        controller.error(Exception('Can not load image'));
      }
    } catch (e) {
      controller.error(e as Exception);
    }
  }

  void _listener() {
    if (mounted) {
      setState(() {});
    }
  }
}
