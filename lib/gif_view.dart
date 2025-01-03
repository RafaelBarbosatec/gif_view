import 'dart:async';
// ignore: unnecessary_import
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gif_view/src/gif_controller.dart';
import 'package:gif_view/src/gif_frame_builder.dart';

import 'src/gif_cache_provider.dart';
import 'src/gif_loader.dart';

export 'package:gif_view/src/gif_cache_provider.dart';
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

class GifView extends StatefulWidget {
  final GifController? controller;
  final int? frameRate;
  final ImageProvider image;
  final double? height;
  final double? width;
  final WidgetBuilder? progressBuilder;
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
  final Widget Function(BuildContext context, Exception error)? errorBuilder;
  final Duration? fadeDuration;
  final void Function()? onStart;
  final void Function()? onFinish;
  final void Function(int frame)? onFrame;

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
    this.repeat = ImageRepeat.noRepeat,
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
    this.repeat = ImageRepeat.noRepeat,
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
  })  : image = AssetImage(asset, package: package, bundle: bundle),
        super(key: key);

  GifView.memory(
    Uint8List bytes, {
    Key? key,
    this.controller,
    this.frameRate = 15,
    this.height,
    this.width,
    this.progressBuilder,
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
    this.errorBuilder,
    this.fadeDuration,
    double scale = 1.0,
    this.onStart,
    this.onFinish,
    this.onFrame,
  })  : image = MemoryImage(bytes, scale: scale),
        super(key: key);

  const GifView({
    Key? key,
    required this.image,
    this.controller,
    this.frameRate = 15,
    this.height,
    this.width,
    this.progressBuilder,
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
    this.errorBuilder,
    this.fadeDuration,
    this.onStart,
    this.onFinish,
    this.onFrame,
  }) : super(key: key);

  static Future<void> preFetch(ImageProvider image) async {
    await GifLoader.instance.fetch(image);
  }

  static void setCacheProvider(GifCacheProvider provider) {
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
      repeat: widget.repeat,
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
          controller.configure(frames, updateFrames: updateFrames);
          _animationController?.forward(from: 0);
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
