import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/vocabulary_item.dart';
import '../models/book.dart';
import '../models/note.dart';

class DatabaseService {
  late Isar _isar;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [VocabularyItemSchema, BookSchema, NoteSchema],
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

  // --- Note Methods ---

  Future<void> saveNote(Note note) async {
    await _isar.writeTxn(() async {
      await _isar.notes.put(note);
    });
  }

  Future<List<Note>> getNotes() async {
    return await _isar.notes.where().sortByCreatedAtDesc().findAll();
  }

  Stream<List<Note>> watchNotes() {
    return _isar.notes.where().sortByCreatedAtDesc().watch(fireImmediately: true);
  }

  Future<List<Note>> getNotesForBook(String bookPath) async {
    return await _isar.notes
        .filter()
        .bookPathEqualTo(bookPath)
        .sortByPageNumber()
        .findAll();
  }

  Future<List<Note>> getNotesForPage(String bookPath, int pageNumber) async {
    return await _isar.notes
        .filter()
        .bookPathEqualTo(bookPath)
        .and()
        .pageNumberEqualTo(pageNumber)
        .sortByCreatedAtDesc()
        .findAll();
  }

  Stream<List<Note>> watchNotesForBook(String bookPath) {
    return _isar.notes
        .filter()
        .bookPathEqualTo(bookPath)
        .watch(fireImmediately: true);
  }

  Stream<List<Note>> watchNotesForPage(String bookPath, int pageNumber) {
    return _isar.notes
        .filter()
        .bookPathEqualTo(bookPath)
        .and()
        .pageNumberEqualTo(pageNumber)
        .watch(fireImmediately: true);
  }

  Future<void> updateNote(Note note) async {
    note.updatedAt = DateTime.now();
    await _isar.writeTxn(() async {
      await _isar.notes.put(note);
    });
  }

  Future<void> deleteNote(int id) async {
    await _isar.writeTxn(() async {
      await _isar.notes.delete(id);
    });
  }

  Future<void> deleteNotesForBook(String bookPath) async {
    final notes = await getNotesForBook(bookPath);
    await _isar.writeTxn(() async {
      for (final note in notes) {
        await _isar.notes.delete(note.id);
      }
    });
  }
}
