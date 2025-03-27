// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:gif_view/gif_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(
        title: 'Gif View Example',
      ),
    );
  }
}

List<String> gifs = [
  'assets/gif1.gif',
  'https://media.giphy.com/media/11sBLVxNs7v6WA/giphy.gif?cid=790b7611inzoz5yw2ba2rp3pjak43bxvun5rjnrzj6ybli8g&ep=v1_gifs_search&rid=giphy.gif&ct=g',
  'https://user-images.githubusercontent.com/53127751/201799963-23725770-a848-42a4-9593-20b835c7e238.png',
  'https://media.giphy.com/media/rdma0nDFZMR32/giphy.gif?cid=790b7611vcvs5r1arjpbqdgmame2a11h3w6pkn5wbi2aeugl&ep=v1_gifs_search&rid=giphy.gif&ct=g',
];

class PreCachePage extends StatefulWidget {
  const PreCachePage({Key? key}) : super(key: key);

  @override
  State<PreCachePage> createState() => _PreCachePageState();
}

class _PreCachePageState extends State<PreCachePage> {
  ValueNotifier<String> gifLoading = ValueNotifier<String>('');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FutureBuilder(
              future: _preCacheGif(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MyHomePage(
                            title: 'Gif View Example',
                          ),
                        ),
                      );
                    },
                    child: const Text('Gif View Example with controller'),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Pre-caching gifs...',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ValueListenableBuilder(
                        valueListenable: gifLoading,
                        builder: (context, value, child) {
                          return Text('$value');
                        },
                      ),
                      const SizedBox(height: 16),
                      const CircularProgressIndicator(),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _preCacheGif() async {
    for (final gif in gifs) {
      ImageProvider provider = (gif.startsWith('http')
          ? NetworkImage(gif)
          : AssetImage(gif)) as ImageProvider;
      gifLoading.value = gif;
      await GifView.preFetchImage(provider);
    }
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Gif load from asset',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          const Divider(),
          GifView.asset(
            gifs[0],
            height: 200,
            frameRate: 30,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Gif load from network',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          const Divider(),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              GifView.network(
                gifs[1],
                height: 200,
              ),
              GifView.network(
                gifs[2],
                height: 200,
                progressBuilder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
                errorBuilder: (context, error, tryAgain) {
                  return InkWell(
                    onTap: tryAgain,
                    child: const Icon(Icons.error),
                  );
                },
                onLoaded: (totalFrames) {
                  print(totalFrames);
                },
                onStart: () {
                  print('onStart');
                },
              ),
              GifView.network(
                gifs[3],
                height: 200,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
