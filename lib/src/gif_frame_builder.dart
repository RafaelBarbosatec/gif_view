import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:gif_view/src/git_frame.dart';

class GifFrameBuilder {
  final Uint8List data;
  final int? frameRate;

  GifFrameBuilder({
    required this.data,
    required this.frameRate,
  });

  Future<List<GifFrame>> build() async {
    Codec codec = await instantiateImageCodec(
      data,
      allowUpscaling: false,
    );

    List<GifFrame> list = [];

    for (int i = 0; i < codec.frameCount; i++) {
      FrameInfo frameInfo = await codec.getNextFrame();
      Duration duration = frameInfo.duration;
      if (frameRate != null) {
        duration = Duration(milliseconds: (1000 / frameRate!).ceil());
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
