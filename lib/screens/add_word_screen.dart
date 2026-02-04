import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:word_app/models/word.dart';
import 'package:word_app/services/isar_service.dart';

class AddWordScreen extends StatefulWidget {
  final IsarService isarService;
  final VoidCallback onSave;
  final Word? wordToEdit;

  const AddWordScreen({
    super.key,
    required this.isarService,
    required this.onSave,
    this.wordToEdit,
  });

  @override
  State<AddWordScreen> createState() => _AddWordScreenState();
}

class _AddWordScreenState extends State<AddWordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _englishWordController = TextEditingController();
  final _turkishWordController = TextEditingController();
  final _storyController = TextEditingController();
  String _wordType = "Noun";
  File? _image;
  final ImagePicker _picker = ImagePicker();
  bool _isLearned = false;

  final List<String> _wordTypes = [
    "Noun",
    "Verb",
    "Adjective",
    "Adverb",
    "Preposition",
    "Conjunction",
    "Interjection",
  ];

  @override
  void initState() {
    super.initState();
    if (widget.wordToEdit != null) {
      var updateWord = widget.wordToEdit!;
      setState(() {
        _englishWordController.text = updateWord.englishWord;
        _turkishWordController.text = updateWord.turkishWord;
        _wordType = updateWord.wordType;
        _storyController.text = updateWord.story ?? "";
        _isLearned = updateWord.isLearned;
      });
    }
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _image = File(image.path);
      });
    }
  }

  @override
  void dispose() {
    _englishWordController.dispose();
    _turkishWordController.dispose();
    _storyController.dispose();
    super.dispose();
  }

  Future<void> _saveWord() async {
    if (_formKey.currentState!.validate()) {
      final word = Word(
        englishWord: _englishWordController.text,
        turkishWord: _turkishWordController.text,
        wordType: _wordType,
        story: _storyController.text,
      );
      word.isLearned = _isLearned;
      if (widget.wordToEdit == null) {
        if (_image != null) {
          word.imageBytes = await _image!.readAsBytes();
        }
        await widget.isarService.addWord(word);
      } else {
        if (_image != null) {
          word.imageBytes = await _image!.readAsBytes();
        } else {
          word.imageBytes = widget.wordToEdit!.imageBytes;
        }
        word.id = widget.wordToEdit!.id;
        await widget.isarService.updateWord(word);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: widget.wordToEdit == null
                ? Text("Word saved")
                : Text("Word updated"),
          ),
        );
        _englishWordController.clear();
        _turkishWordController.clear();
        _storyController.clear();
        setState(() {
          _image = null;
          _isLearned = false;
        });
      }
    }
    widget.onSave();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Please enter english word";
                }
                return null;
              },
              controller: _englishWordController,
              decoration: InputDecoration(
                labelText: "English Word",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            TextFormField(
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Please enter turkish word";
                }
                return null;
              },
              controller: _turkishWordController,
              decoration: InputDecoration(
                labelText: "Turkish Word",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: "Word Type",
                border: OutlineInputBorder(),
              ),
              initialValue: _wordType,
              items: _wordTypes.map((String e) {
                return DropdownMenuItem<String>(value: e, child: Text(e));
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _wordType = newValue.toString();
                });
              },
            ),
            SizedBox(height: 12),
            TextFormField(
              controller: _storyController,
              decoration: InputDecoration(
                labelText: "Word Story",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Row(
                spacing: 6,
                children: [
                  Text("Learned"),
                  Switch(
                    value: _isLearned,
                    onChanged: (value) {
                      setState(() {
                        _isLearned = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            ElevatedButton.icon(
              icon: Icon(Icons.image),
              onPressed: _pickImage,
              label: Text("Add Image"),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
            ),
            SizedBox(height: 12),
            if (_image != null || widget.wordToEdit != null) ...[
              if (_image != null)
                Image.file(
                  _image!,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                )
              else if (widget.wordToEdit?.imageBytes != null)
                Image.memory(
                  Uint8List.fromList(widget.wordToEdit!.imageBytes!),
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
            ],

            SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _saveWord(),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: widget.wordToEdit == null
                  ? const Text("Save Word")
                  : const Text("Update Word"),
            ),
          ],
        ),
      ),
    );
  }
}
