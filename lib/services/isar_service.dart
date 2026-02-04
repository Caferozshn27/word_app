import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:word_app/models/word.dart';

class IsarService {
  Isar? _isar;

  Isar get isar => _isar!;

  Future<void> init() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      _isar = await Isar.open([WordSchema], directory: directory.path);
    } catch (e) {
      debugPrint("Isar init olurken hata oluştu: $e");
    }
  }

  Future<void> addWord(Word word) async {
    try {
      await isar.writeTxn(() async {
        await isar.words.put(word);
        debugPrint("Word eklendi: $word");
      });
    } catch (e) {
      debugPrint("Word eklenirken hata oluştu: $e");
    }
  }

  Future<List<Word>> getAllWords() async {
    try {
      final words = await isar.words.where().findAll();
      return words;
    } catch (e) {
      debugPrint("Wordler çekilirken hata oluştu: $e");
      return [];
    }
  }

  Future<void> deleteWord(int id) async {
    try {
      await isar.writeTxn(() async {
        await isar.words.delete(id);
      });
    } catch (e) {
      debugPrint("Word silinirken hata oluştu: $e");
    }
  }

  Future<void> updateWord(Word word) async {
    try {
      await isar.writeTxn(() async {
        await isar.words.put(word);
      });
    } catch (e) {
      debugPrint("Word güncellenirken hata oluştu: $e");
    }
  }

  Future<void> toggleWordLearned(int id) async {
    try {
      await isar.writeTxn(() async {
        final word = await isar.words.get(id);
        if (word != null) {
          word.isLearned = !word.isLearned;
          await isar.words.put(word);
        } else {
          debugPrint("Word bulunamadı: $id");
        }
      });
    } catch (e) {
      debugPrint("Word durumu güncellenirken hata oluştu: $e");
    }
  }
}
