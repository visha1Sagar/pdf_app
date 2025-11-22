import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/vocabulary_item.dart';
import '../models/book.dart';

class DatabaseService {
  late Isar _isar;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [VocabularyItemSchema, BookSchema],
      directory: dir.path,
    );
  }

  // --- Word Methods ---

  Future<void> saveWord(String word, String definition) async {
    final newWord = VocabularyItem()
      ..word = word
      ..definition = definition
      ..timestamp = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.vocabularyItems.put(newWord);
    });
  }

  Future<List<VocabularyItem>> getSavedWords() async {
    return await _isar.vocabularyItems.where().sortByTimestampDesc().findAll();
  }

  Stream<List<VocabularyItem>> watchSavedWords() {
    return _isar.vocabularyItems.where().sortByTimestampDesc().watch(fireImmediately: true);
  }

  Future<void> deleteWord(int id) async {
    await _isar.writeTxn(() async {
      await _isar.vocabularyItems.delete(id);
    });
  }

  // --- Book Methods ---

  Future<void> addBook(Book book) async {
    await _isar.writeTxn(() async {
      await _isar.books.put(book);
    });
  }

  Future<List<Book>> getBooks() async {
    return await _isar.books.where().sortByAddedDateDesc().findAll();
  }

  Stream<List<Book>> watchBooks() {
    return _isar.books.where().sortByAddedDateDesc().watch(fireImmediately: true);
  }

  Future<void> deleteBook(int id) async {
    await _isar.writeTxn(() async {
      await _isar.books.delete(id);
    });
  }

  Future<void> updateBookProgress(int id, int page) async {
    final book = await _isar.books.get(id);
    if (book != null) {
      book.lastReadPage = page;
      book.lastReadDate = DateTime.now();
      await _isar.writeTxn(() async {
        await _isar.books.put(book);
      });
    }
  }
}
