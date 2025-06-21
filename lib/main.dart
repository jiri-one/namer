import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

// this is needed to save the state of the scroll
final pageBucket = PageStorageBucket();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Namer App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();
  var favorites = <WordPair>{};
  var pairs = <WordPair>{};

  void getNext() {
    current = WordPair.random();
    if (!favorites.contains(current)) {
      pairs.add(current);
    }
    notifyListeners();
  }

  void toggleFavorite() {
    if (favorites.contains(current)) {
      favorites.remove(current);
    } else {
      favorites.add(current);
      pairs.remove(current);
    }
    notifyListeners();
  }

  void setCurrent(WordPair pair) {
    current = pair;
    notifyListeners();
  }

  void removeFavorite(WordPair pair) {
    favorites.remove(pair);
    notifyListeners();
  }
}

// ...

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = GeneratorPage();
      case 1:
        page = FavoritesPage();
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }
    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              child: NavigationRail(
                extended: constraints.maxWidth >= 600,
                destinations: [
                  NavigationRailDestination(
                    icon: Icon(Icons.home),
                    label: Text('Home'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.favorite),
                    label: Text('Favorites'),
                  ),
                ],
                selectedIndex: selectedIndex,
                onDestinationSelected: (value) {
                  setState(() {
                    selectedIndex = value;
                  });
                },
              ),
            ),
            Expanded(
              child: Container(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: page,
              ),
            ),
          ],
        ),
      );
    });
  }
}

class GeneratorPage extends StatefulWidget {
  @override
  State<GeneratorPage> createState() => _GeneratorPageState();
}

class _GeneratorPageState extends State<GeneratorPage> {
  final ScrollController _controllerTop = ScrollController();
  final ScrollController _controllerBottom = ScrollController();

  void updateControllers() {
    _controllerTop.animateTo(_controllerTop.position.maxScrollExtent,
        duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
    _controllerBottom.animateTo(_controllerBottom.position.maxScrollExtent,
        duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var pair = appState.current;
    var pairs = appState.pairs;
    var favorites = appState.favorites;

    IconData icon;
    if (appState.favorites.contains(pair)) {
      icon = Icons.favorite;
    } else {
      icon = Icons.favorite_border;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: PageStorage(
              bucket: pageBucket,
              child: ListView.builder(
                key: PageStorageKey<String>('favorites_list'),
                controller: _controllerTop,
                scrollDirection: Axis.vertical,
                shrinkWrap: true,
                itemCount: favorites.length,
                itemBuilder: (context, index) {
                  var currentPair = favorites.elementAt(index);
                  IconData icon = appState.favorites.contains(currentPair)
                      ? Icons.favorite
                      : Icons.favorite_border;
                  return ListTile(
                    title: Text(currentPair.asLowerCase),
                    leading: Icon(icon),
                    onTap: () {
                      appState.setCurrent(currentPair);
                    },
                  );
                },
              ),
            ),
          ),
          Text(
            'A new word pair:',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          BigCard(pair: pair),
          SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  appState.toggleFavorite();
                },
                icon: Icon(icon),
                label: Text('Like'),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  appState.getNext();
                  updateControllers();
                },
                child: Text('Next'),
              ),
            ],
          ),
          Expanded(
            child: PageStorage(
              bucket: pageBucket,
              child: ListView.builder(
                key: PageStorageKey<String>('pairs_list'),
                controller: _controllerBottom,
                scrollDirection: Axis.vertical,
                itemCount: pairs.length,
                reverse: true,
                itemBuilder: (context, index) {
                  var currentPair = pairs.elementAt(index);
                  IconData icon = appState.favorites.contains(currentPair)
                      ? Icons.favorite
                      : Icons.favorite_border;
                  return ListTile(
                    title: Text(currentPair.asLowerCase),
                    leading: Icon(icon),
                    onTap: () {
                      appState.setCurrent(currentPair);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BigCard extends StatelessWidget {
  const BigCard({
    super.key,
    required this.pair,
  });

  final WordPair pair;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.displayMedium!.copyWith(
        color: theme.colorScheme.onPrimary, fontStyle: FontStyle.italic);

    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text(pair.asLowerCase,
            style: style, semanticsLabel: "${pair.first} ${pair.second}"),
      ),
    );
  }
}

class FavoritesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var favorites = appState.favorites;

    if (favorites.isEmpty) {
      return Center(child: Text('No favorites yet!'));
    }

    return ListView(children: [
      Text(
          'You have '
          '${favorites.length} favorites:',
          style: Theme.of(context).textTheme.headlineSmall),
      ListView.builder(
        scrollDirection: Axis.vertical,
        shrinkWrap: true,
        itemCount: favorites.length,
        itemBuilder: (context, index) {
          var pair = favorites.elementAt(index);
          return ListTile(
            title: Text(pair.asLowerCase),
            leading: IconButton(
                icon: Icon(Icons.delete),
                onPressed: () {
                  appState.removeFavorite(pair);
                }),
            onTap: () {
              appState.current = pair;
            },
          );
        },
      ),
    ]);
  }
}
