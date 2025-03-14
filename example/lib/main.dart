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
      home: const MyHomePage(title: 'GifView Demo'),
    );
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
            'assets/gif1.gif',
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
                'https://media.giphy.com/media/11sBLVxNs7v6WA/giphy.gif?cid=790b7611inzoz5yw2ba2rp3pjak43bxvun5rjnrzj6ybli8g&ep=v1_gifs_search&rid=giphy.gif&ct=g',
                height: 200,
              ),
              GifView.network(
                'https://user-images.githubusercontent.com/53127751/201799963-23725770-a848-42a4-9593-20b835c7e238.png',
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
                'https://media.giphy.com/media/rdma0nDFZMR32/giphy.gif?cid=790b7611vcvs5r1arjpbqdgmame2a11h3w6pkn5wbi2aeugl&ep=v1_gifs_search&rid=giphy.gif&ct=g',
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
