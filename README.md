[![pub package](https://img.shields.io/pub/v/gif_view.svg)](https://pub.dev/packages/gif_view)

# GifView

Load [GIF](https://pt.wikipedia.org/wiki/GIF)|[APNG](https://pt.wikipedia.org/wiki/Animated_Portable_Network_Graphics) images and can set framerate

## Features

With `GifView` you can load GIF images of easy way and can configure frameRate.

- Load from `Assets`;
- Load from `Network`;
- Load from `Memory`;
- Set frame rate;
- Set `progress` while loading GIF

## Getting started

Add `gif_view` as a [dependency in your pubspec.yaml file](https://flutter.dev/using-packages/).

## Usage

### GIF from Asset

```dart
  GifView.asset(
    'assets/gif1.gif',
    height: 200,
    width: 200,
    frameRate: 30, 
  )
```


### GIF from Network

```dart
  GifView.network(
    'https://www.showmetech.com.br/wp-content/uploads/2015/09/happy-minion-gif.gif',
    height: 200,
    width: 200,
  )
```


### GIF from Memory

```dart
  GifView.memory(
    _bytes,
    height: 200,
    width: 200,
  )
```

## Atributes

| Name | Description  | Default  |
| ------- | --- | --- |
| controller | - | - |
| frameRate | - | - | 
| height | - | - | 
| width | - | - | 
| fit | - | - | 
| color | - | - | 
| colorBlendMode | - | - | 
| alignment | - | `Alignment.center` |
| imageRepeat | - |  `ImageRepeat.noRepeat` |
| centerSlice | - | - | 
| matchTextDirection | - | `false` |
| invertColors | - | `false` |
| filterQuality | - | `FilterQuality.low` |
| isAntiAlias | - | `false` |
| onFinish | - | - | 
| onStart | - | - | 
| onFrame | - | - | 
| onLoaded | - | - | 
| loop | - | - | 
| playInverted | - | - | 
| errorBuilder | You can return a widget to show when happen error | - | 
| progressBuilder | You can return a widget to show while loading | - |
| scale | - | `1.0` |
| headers | - | - | 


## Controller

```dart

  GifController controller = GifController();

  controller.play({bool? inverted, int? initialFrame});

  controller.pause();

  controller.stop();

  controller.seek(34);

  GifStatus status = controller.status;
  // GifStatus { loading, playing, stoped, paused, reversing }

```

## Controller use simple example

```dart

class MyPage extends StatelessWidget {
  final controller = GifController();
  MyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GifView.network(
        'https://www.showmetech.com.br/wp-content/uploads/2015/09/happy-minion-gif.gif',
        controller: controller,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (controller.status == GifStatus.playing) {
            controller.pause();
          } else {
            controller.play();
          }
        },
      ),
    );
  }
}


```

## Cache Management

### Pre-fetching Images

GifView provides a static `preFetch` method to load and cache GIF images ahead of time for better performance:

```dart
// Pre-fetch single or multiple GIFs
// Asset
await GifView.preFetch(AssetImage('my/path/item.gif'));
// Network
await GifView.preFetch(NetworkImage('http://my/path/item.gif'));
// Memory
await GifView.preFetch(MemoryImage(Uint8List()));
// File
await GifView.preFetch(FileImage(File()));
```

### Custom Cache Provider

You can implement your own caching strategy by setting a custom cache provider:

```dart
// Create custom provider
class MyCustomCacheProvider implements GifCacheProvider {
  @override
  Future<void> add(String key, Uint8List bytes) async {
    // Custom cache implementation
  }

  @override
  Future<Uint8List?> get(String key) async {
    // Custom retrieval implementation
  }

  @override
  Future<void> clear() async {
    // Custom clear implementation
  }
}

// Set custom provider
GifView.setCacheProvider(MyCustomCacheProvider());

// Revert to default provider
GifView.setCacheProvider(null);
```
