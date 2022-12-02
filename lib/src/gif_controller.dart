import 'package:flutter/material.dart';
import 'package:gif_view/src/git_frame.dart';

enum GifStatus { loading, playing, stoped, paused, reversing }

class GifController extends ChangeNotifier {
  List<GifFrame> frames = [];
  int currentIndex = 0;
  GifStatus status = GifStatus.loading;

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

      case GifStatus.stoped:
        onFinish?.call();
        currentIndex = 0;
        break;
      case GifStatus.loading:
      case GifStatus.paused:
    }
  }

  void _runNextFrame() async {
    await Future.delayed(frames[currentIndex].duration);

    if (status == GifStatus.reversing) {
      if (currentIndex > 0) {
        currentIndex--;
      } else if (loop) {
        currentIndex = frames.length - 1;
      } else {
        status = GifStatus.stoped;
      }
    } else {
      if (currentIndex < frames.length - 1) {
        currentIndex++;
      } else if (loop) {
        currentIndex = 0;
      } else {
        status = GifStatus.stoped;
      }
    }

    onFrame?.call(currentIndex);
    notifyListeners();
    _run();
  }

  GifFrame get currentFrame => frames[currentIndex];

  void play({bool? inverted, int? initialFrame}) {
    if (status == GifStatus.loading) return;
    _inverted = inverted ?? _inverted;

    if (status == GifStatus.stoped || status == GifStatus.paused) {
      status = _inverted ? GifStatus.reversing : GifStatus.playing;

      bool isValidInitialFrame = initialFrame != null &&
          initialFrame > 0 &&
          initialFrame < frames.length - 1;

      if (isValidInitialFrame) {
        currentIndex = initialFrame;
      } else {
        currentIndex = status == GifStatus.reversing ? frames.length - 1 : 0;
      }
      onStart?.call();
      _run();
    } else {
      status = _inverted ? GifStatus.reversing : GifStatus.playing;
    }
  }

  void stop() {
    status = GifStatus.stoped;
  }

  void pause() {
    status = GifStatus.paused;
  }

  void configure(List<GifFrame> frames, {bool updateFrames = false}) {
    this.frames = frames;
    if (!updateFrames) {
      status = GifStatus.stoped;
      if (autoPlay) {
        play();
      }
      notifyListeners();
    }
  }
}
