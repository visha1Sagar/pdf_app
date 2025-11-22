import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/book.dart';
import 'database_service.dart';

class LibraryProvider extends ChangeNotifier {
  final DatabaseService _databaseService;
  List<Book> _books = [];

  LibraryProvider(this._databaseService) {
    _loadBooks();
  }

  List<Book> get books => _books;

  void _loadBooks() {
    _databaseService.watchBooks().listen((books) {
      _books = books;
      notifyListeners();
    });
  }

  Future<void> pickAndSaveFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      final File originalFile = File(result.files.single.path!);
      final String fileName = result.files.single.name;
      
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String newPath = '${appDir.path}/$fileName';
      
      // Copy file to app directory
      await originalFile.copy(newPath);

      // Create Book entry
      final newBook = Book()
        ..title = fileName.replaceAll('.pdf', '')
        ..filePath = newPath
        ..addedDate = DateTime.now()
        ..lastReadDate = DateTime.now();

      await _databaseService.addBook(newBook);
    }
  }

  Future<void> deleteBook(Book book) async {
    // Delete file
    final file = File(book.filePath);
    if (await file.exists()) {
      await file.delete();
    }
    
    // Delete from DB
    await _databaseService.deleteBook(book.id);
  }
  
  Future<void> updateProgress(int bookId, int page) async {
    await _databaseService.updateBookProgress(bookId, page);
  }
}
