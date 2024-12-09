import 'package:flutter/material.dart';
import 'package:gif_view/src/git_frame.dart';

enum GifStatus { loading, playing, stoped, paused, reversing, error }

class GifController extends ChangeNotifier {
  List<GifFrame> _frames = [];
  int _currentIndex = 0;
  GifStatus status = GifStatus.loading;
  Exception? exception;

  final bool autoPlay;
  final VoidCallback? onFinish;
  final VoidCallback? onStart;
  final ValueChanged<int>? onFrame;

  bool loop;
  bool _inverted;
  bool _disposed = false;

  int get index => _currentIndex;

  GifController({
    this.autoPlay = true,
    this.loop = true,
    bool inverted = false,
    this.onStart,
    this.onFinish,
    this.onFrame,
  }) : _inverted = inverted;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _run() {
    if (_disposed) return;
    switch (status) {
      case GifStatus.playing:
      case GifStatus.reversing:
        _runNextFrame();
        break;
      case GifStatus.stoped:
        onFinish?.call();
        _currentIndex = 0;
        break;
      case GifStatus.loading:
      case GifStatus.paused:
      case GifStatus.error:
        break;
    }
  }

  void _runNextFrame() async {
    if (_disposed || _frames.isEmpty) return;
    await Future.delayed(_frames[_currentIndex].duration);
    if (_disposed) return;

    if (status == GifStatus.reversing) {
      if (_currentIndex > 0) {
        _currentIndex = (_currentIndex - 1) % _frames.length;
      } else if (loop) {
        _currentIndex = _frames.length - 1;
      } else {
        status = GifStatus.stoped;
      }
    } else {
      if (_currentIndex < _frames.length - 1) {
        _currentIndex = (_currentIndex + 1) % _frames.length;
      } else if (loop) {
        _currentIndex = 0;
      } else {
        status = GifStatus.stoped;
      }
    }

    onFrame?.call(_currentIndex);
    if (hasListeners) {
      notifyListeners();
    }
    _run();
  }

  GifFrame get currentFrame => _frames[_currentIndex];

  int get countFrames => _frames.length;

  bool get isReversing => status == GifStatus.reversing;

  bool get isPaused => status == GifStatus.stoped || status == GifStatus.paused;

  bool get isPlaying => status == GifStatus.playing;

  void play({bool? inverted, int? initialFrame}) {
    if (_disposed || status == GifStatus.loading || _frames.isEmpty) return;
    _inverted = inverted ?? _inverted;

    if (status == GifStatus.stoped || status == GifStatus.paused) {
      status = _inverted ? GifStatus.reversing : GifStatus.playing;
      bool isValidInitialFrame = initialFrame != null &&
          initialFrame > 0 &&
          initialFrame < _frames.length - 1;

      if (isValidInitialFrame) {
        _currentIndex = initialFrame;
      } else {
        _currentIndex = isReversing ? _frames.length - 1 : _currentIndex;
      }

      onStart?.call();
      _run();
    } else {
      status = _inverted ? GifStatus.reversing : GifStatus.playing;
    }
  }

  void stop() {
    if (_disposed) return;
    status = GifStatus.stoped;
  }

  void pause() {
    if (_disposed) return;
    status = GifStatus.paused;
  }

  void seek(int index) {
    if (_disposed || _frames.isEmpty) return;
    _currentIndex = index % _frames.length;
    if (hasListeners) {
      notifyListeners();
    }
  }

  void configure(List<GifFrame> frames, {bool updateFrames = false}) {
    if (_disposed) return;
    exception = null;
    _frames = frames;
    if (!updateFrames || status == GifStatus.loading) {
      status = GifStatus.stoped;
      if (autoPlay) {
        play();
      }
      if (hasListeners) {
        notifyListeners();
      }
    }
  }

  void error(Exception e) {
    if (_disposed) return;
    exception = e;
    status = GifStatus.error;
    if (hasListeners) {
      notifyListeners();
    }
  }

  void loading() {
    if (_disposed) return;
    status = GifStatus.loading;
    if (hasListeners) {
      notifyListeners();
    }
  }
}
