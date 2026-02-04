import 'package:flutter/material.dart';
import 'package:word_app/screens/add_word_screen.dart';
import 'package:word_app/screens/word_list_screen.dart';
import 'package:word_app/services/isar_service.dart';

import 'models/word.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final isarService = IsarService();
  try {
    await isarService.init();
    await isarService.addWord(
      Word(
        englishWord: "Hello",
        turkishWord: "Merhaba",
        wordType: "Noun",
        story: "bu hikaye",
      ),
    );
  } catch (e) {
    debugPrint("Mainde hata oluştu isar başlatılırken: $e");
  }
  runApp(MyApp(isarService: isarService));
}

class MyApp extends StatelessWidget {
  final IsarService isarService;

  const MyApp({super.key, required this.isarService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Material App',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.deepPurple),
      home: MainPage(isarService: isarService),
    );
  }
}

class MainPage extends StatefulWidget {
  final IsarService isarService;

  const MainPage({super.key, required this.isarService});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  Word? _wordToEdit;

  void _editWord(Word word) {
    setState(() {
      _selectedIndex = 1;
      _wordToEdit = word;
    });
  }

  List<Widget> getScreen() {
    return [
      WordList(isarService: widget.isarService, onEditWord: _editWord),
      AddWordScreen(
        isarService: widget.isarService,
        wordToEdit: _wordToEdit,
        onSave: () {
          setState(() {
            _selectedIndex = 0;
            _wordToEdit = null;
          });
        },
      ),
    ];
  }

  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kelimelerim")),
      body: getScreen()[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            label: "Kelimeler",
          ),
          NavigationDestination(
            icon: Icon(Icons.add),
            label: _wordToEdit == null ? 'Ekle' : 'Güncelle',
          ),
        ],
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
            if (_selectedIndex == 0) {
              _wordToEdit = null;
            }
          });
        },
      ),
    );
  }
}
