import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

String capitalize(word) {
  return "${word[0].toUpperCase()}${word.substring(1).toLowerCase()}";
}

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
          colorScheme: ColorScheme.fromSeed(
            seedColor: Color.fromRGBO(172, 230, 243, 0.871),
          ),
          textTheme: GoogleFonts.jetBrainsMonoTextTheme(),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class PairRecord {
  @override
  String toString() {
    return wordPair.asCamelCase;
  }

  final WordPair wordPair;
  bool isFavorite;

  PairRecord(this.wordPair, {this.isFavorite = false});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PairRecord && other.wordPair == wordPair;
  }

  @override
  int get hashCode => wordPair.hashCode;
}

class MyAppState extends ChangeNotifier {
  PairRecord current = PairRecord(WordPair.random());
  List<PairRecord> wordPairs = [];
  final GlobalKey<AnimatedListState> key = GlobalKey();

  void removeItem(int index) {
    print("remove: index = $index");
    key.currentState!.removeItem(
      index,
      (_, animation) => SizeTransition(
        sizeFactor: animation,
        child: const Card(
          margin: EdgeInsets.all(10),
          color: Colors.red,
          child: ListTile(
            title: Text(
              'Deleted',
              style: TextStyle(fontSize: 24),
            ),
          ),
        ),
      ),
      duration: const Duration(milliseconds: 300),
    );
    wordPairs.remove(wordPairs.elementAt(index));
    notifyListeners();
  }

  void getNext() {
    if (wordPairs.contains(current)) return;
    print(wordPairs.length);
    int index = 0;
    key.currentState!.insertItem(
      index,
      duration: Duration(milliseconds: 500),
    );
    wordPairs.insert(index, current);
    print("list: $wordPairs");
    current = PairRecord(WordPair.random());
    notifyListeners();
  }

  void toggleCurrent() {
    current.isFavorite = !current.isFavorite;
    notifyListeners();
  }

  void toggleFavorite(PairRecord pair) {
    for (var item in wordPairs) {
      if (item == pair) {
        item.isFavorite = !item.isFavorite;
        notifyListeners();
        break;
      }
    }
  }

  void deleteFavorite(PairRecord pair) {
    if (pair == current) {
      current.isFavorite = false;
      notifyListeners();
    }

    for (var item in wordPairs) {
      if (item == pair) {
        item.isFavorite = false;
        notifyListeners();
        break;
      }
    }
  }

  List<PairRecord> getFavorites() {
    List<PairRecord> res =
        wordPairs.where((element) => element.isFavorite).toList();
    if (current.isFavorite) res.add(current);
    return res;
  }
}

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
        break;
      case 1:
        page = FavoritesPage();
        break;
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              child: constraints.maxWidth > 400
                  ? NavigationRail(
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
                    )
                  : SizedBox(),
            ),
            Expanded(
              child: Container(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: page,
              ),
            ),
          ],
        ),
        bottomNavigationBar: constraints.maxWidth <= 400
            ? BottomNavigationBar(
                items: const <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.favorite),
                    label: 'Favorites',
                  ),
                ],
                currentIndex: selectedIndex,
                onTap: (value) {
                  setState(() {
                    selectedIndex = value;
                  });
                },
              )
            : null,
      );
    });
  }
}

class GeneratorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var pair = appState.current;

    IconData icon = pair.isFavorite ? Icons.favorite : Icons.favorite_border;

    return Padding(
      padding: const EdgeInsets.only(
        left: 20,
        top: 50,
        right: 20,
        bottom: 50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Historical(),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Text('A random AWSOME idea:'),
                BigCard(pair: pair),
                SizedBox(height: 10),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        appState.toggleCurrent();
                      },
                      icon: Icon(icon),
                      label: Text('Like'),
                    ),
                    SizedBox(width: 20),
                    ElevatedButton(
                        onPressed: () {
                          appState.getNext();
                        },
                        child: Text('Next')),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FavoritesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var favorites = appState.getFavorites();
    final theme = Theme.of(context);
    if (favorites.isEmpty) {
      return Center(
        child: Text('No favorites yet.'),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'You have ${favorites.length} favorites:',
          ),
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: favorites.map((pair) {
            return Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(
                  color: theme.colorScheme.primary,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete_forever),
                    tooltip: 'Delete',
                    onPressed: () {
                      appState.deleteFavorite(pair);
                    },
                  ),
                  SizedBox(width: 5),
                  RichText(
                    text: TextSpan(
                      text: capitalize(pair.wordPair.first),
                      style: TextStyle(
                        fontWeight: FontWeight.w100,
                        color: theme.colorScheme.primary,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text: pair.wordPair.second.toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class BigCard extends StatelessWidget {
  const BigCard({
    super.key,
    required this.pair,
  });

  final PairRecord pair;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
    );

    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: AnimatedSize(
          curve: Curves.easeIn,
          duration: const Duration(milliseconds: 400),
          child: RichText(
            text: TextSpan(
              text: capitalize(pair.wordPair.first),
              style: style.copyWith(
                fontWeight: FontWeight.w100,
              ),
              children: <TextSpan>[
                TextSpan(
                  text: pair.wordPair.second.toUpperCase(),
                  style: style.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Historical extends StatelessWidget {
  const Historical({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    var appState = context.watch<MyAppState>();
    var wordPairs = appState.wordPairs.toList();
    var key = appState.key;

    // if (wordPairs.isEmpty) {
    //   return Center(
    //     child: SizedBox(height: 10),
    //   );
    // }

    return Expanded(
      child: AnimatedList(
        reverse: true,
        key: key,
        initialItemCount: wordPairs.length,
        padding: const EdgeInsets.all(10),
        itemBuilder:
            (BuildContext context, int index, Animation<double> animation) {
          return SizeTransition(
            key: UniqueKey(),
            sizeFactor: animation,
            child: Card(
              margin: const EdgeInsets.all(10),
              child: ListTile(
                leading: Ink(
                  width: 60,
                  height: 40,
                  decoration: ShapeDecoration(
                    color: theme.colorScheme.onPrimary,
                    shape: StadiumBorder(),
                  ),
                  child: IconButton(
                    highlightColor: theme.colorScheme.inversePrimary,
                    color: theme.colorScheme.primary,
                    icon: wordPairs[index].isFavorite
                        ? Icon(
                            Icons.favorite,
                          )
                        : Icon(Icons.check_box_outline_blank),
                    onPressed: () {
                      appState.toggleFavorite(wordPairs[index]);
                    },
                  ),
                ),
                title: RichText(
                  text: TextSpan(
                    text: capitalize(wordPairs[index].wordPair.first),
                    style: TextStyle(
                      fontWeight: FontWeight.w100,
                      color: theme.colorScheme.primary,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: wordPairs[index].wordPair.second.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                trailing: Ink(
                  width: 60,
                  height: 40,
                  decoration: ShapeDecoration(
                    color: theme.colorScheme.primary,
                    shape: StadiumBorder(),
                  ),
                  child: IconButton(
                    highlightColor: theme.colorScheme.error,
                    color: theme.colorScheme.onPrimary,
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      appState.removeItem(index);
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
