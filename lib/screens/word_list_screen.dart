import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:word_app/services/isar_service.dart';

import '../models/word.dart';

class WordList extends StatefulWidget {
  final IsarService isarService;
  final Function(Word) onEditWord;

  const WordList({
    super.key,
    required this.isarService,
    required this.onEditWord,
  });

  @override
  State<WordList> createState() => _WordListState();
}

class _WordListState extends State<WordList> {
  late Future<List<Word>> words;
  late List<Word> _wordList;
  late List<Word> _filterWordList;
  final List<String> _wordTypes = [
    "All",
    "Noun",
    "Verb",
    "Adjective",
    "Adverb",
    "Preposition",
    "Conjunction",
    "Interjection",
  ];
  String _selectType = "All";
  bool _hideLearned = false;

  @override
  void initState() {
    super.initState();
    words = _getWordsFromDb();
  }

  Card _filterCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.filter_alt_outlined,
                  color: Theme.of(context).primaryColor,
                ),
                SizedBox(width: 12),
                Text("Filter"),
                SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    items: _wordTypes
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectType = value.toString();
                      });
                      _applyFilter();
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      contentPadding: EdgeInsets.all(10),
                      label: Text("Word Type"),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text("Hide Learned"),
                SizedBox(width: 12),
                Switch(
                  value: _hideLearned,
                  onChanged: (value) {
                    setState(() {
                      _hideLearned = value;
                    });
                    _applyFilter();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _applyFilter() {
    _filterWordList = _wordList;
    if (_selectType != "All") {
      _filterWordList = _filterWordList
          .where(
            (element) =>
                element.wordType.toLowerCase() == _selectType.toLowerCase(),
          )
          .toList();
    }
    if (_hideLearned) {
      _filterWordList = _filterWordList
          .where((element) => element.isLearned == false)
          .toList();
    }
  }

  Future<List<Word>> _getWordsFromDb() async {
    final dbWords = await widget.isarService.getAllWords();
    _wordList = dbWords;
    return _wordList;
  }

  Future<void> _toggleUpdateWord(Word word) async {
    await widget.isarService.toggleWordLearned(word.id);
    final indexWord = _wordList.indexWhere((element) => element.id == word.id);
    var updateWord = _wordList[indexWord];
    updateWord.isLearned = !updateWord.isLearned;
    setState(() {
      _wordList[indexWord] = updateWord;
    });
  }

  Future<void> _deleteWord(Word word) async {
    await widget.isarService.deleteWord(word.id);
    setState(() {
      _wordList.removeWhere((element) => word.id == element.id);
      _filterWordList.removeWhere((element) => word.id == element.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _filterCard(),
        SizedBox(height: 12),
        Expanded(
          child: FutureBuilder<List<Word>>(
            future: words,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Text("Bir hata oluştu: ${snapshot.error}");
              } else {
                final wordList = snapshot.data!;
                if (wordList.isEmpty) {
                  return Text("Word list is empty");
                } else {
                  return _buildListView(wordList);
                }
              }
            },
          ),
        ),
      ],
    );
  }

  ListView _buildListView(List<Word> wordList) {
    _applyFilter();
    return ListView.builder(
      itemBuilder: (context, index) {
        final word = _filterWordList[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Dismissible(
              key: UniqueKey(),
              direction: DismissDirection.endToStart,
              background: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.centerRight,
                padding: EdgeInsets.only(right: 10),
                child: Icon(
                  Icons.delete,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              onDismissed: (direction) => _deleteWord(word),
              confirmDismiss: (direction) async {
                return await showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text("Delete Word"),
                      content: Text(
                        "Are you sure you want to delete ${word.englishWord}?",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text("Delete"),
                        ),
                      ],
                    );
                  },
                );
              },
              child: GestureDetector(
                onTap: () => widget.onEditWord(word),
                child: Column(
                  children: [
                    ListTile(
                      title: Text(word.englishWord),
                      subtitle: Text(word.turkishWord),
                      leading: Chip(label: Text(word.wordType)),
                      trailing: Switch(
                        value: word.isLearned,
                        onChanged: (value) => _toggleUpdateWord(word),
                      ),
                    ),
                    if (word.story != null)
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          color: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.3),
                        ),
                        padding: EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Icon(Icons.one_k_rounded),
                                SizedBox(width: 5),
                                Text("Remember notes"),
                              ],
                            ),
                            SizedBox(height: 12),
                            Text(
                              word.story ?? "",
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(height: 12),
                            if (word.imageBytes != null)
                              Image.memory(
                                Uint8List.fromList(word.imageBytes!),
                                height: 120,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      itemCount: _filterWordList.length,
    );
  }
}
