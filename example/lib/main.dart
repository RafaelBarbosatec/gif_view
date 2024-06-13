import 'package:flutter/material.dart';
import 'package:gif_view/gif_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
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
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
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
          GifView.network(
            'https://www.showmetech.com.br/wp-content/uploads/2015/09/happy-minion-gif.gif',
            height: 200,
          ),
          GifView.network(
            'https://gifs.eco.br/wp-content/uploads/2022/05/gifs-de-homem-aranha-no-aranhaverso-20.gif',
            height: 200,
            progress: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
          GifView.network(
            'https://gifs.eco.br/wp-content/uploads/2021/08/engracados-memes-gif-19.gif',
            height: 200,
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
