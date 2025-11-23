import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_provider.dart';
import '../services/library_provider.dart';
import '../models/book.dart';
import '../widgets/book_card.dart';
import '../widgets/empty_library_view.dart';
import 'reader_screen.dart';
import 'vocabulary_screen.dart';
import 'flashcard_screen.dart';
import 'notes_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final libraryProvider = Provider.of<LibraryProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark || 
                   (themeProvider.themeMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentIndex == 0 ? 'My Library' : (_currentIndex == 1 ? 'Notes' : 'Vocabulary'),
        ),
        actions: [
          if (_currentIndex == 2)
            IconButton(
              icon: const Icon(Icons.style_outlined),
              tooltip: 'Flashcards Mode',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FlashcardScreen()),
                );
              },
            ),
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
            onPressed: () {
              themeProvider.toggleTheme(!isDark);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildLibraryView(libraryProvider),
          const NotesScreen(),
          const VocabularyList(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.library_books_outlined),
            selectedIcon: Icon(Icons.library_books),
            label: 'Library',
          ),
          NavigationDestination(
            icon: Icon(Icons.note_outlined),
            selectedIcon: Icon(Icons.note),
            label: 'Notes',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: 'Vocabulary',
          ),
        ],
      ),
      floatingActionButton: _getFloatingActionButton(libraryProvider),
    );
  }

  Widget _buildLibraryView(LibraryProvider libraryProvider) {
    if (libraryProvider.books.isEmpty) {
      return EmptyLibraryView(
        onAddBook: () => libraryProvider.pickAndSaveFile(),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7, // Taller for book shape
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),
      itemCount: libraryProvider.books.length,
      itemBuilder: (context, index) {
        final book = libraryProvider.books[index];
        return BookCard(
          book: book,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReaderScreen(filePath: book.filePath),
              ),
            );
          },
          onLongPress: () => _showDeleteDialog(context, book, libraryProvider),
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context, Book book, LibraryProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Book'),
        content: Text('Are you sure you want to delete "${book.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteBook(book);
              Navigator.pop(context);
            },
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget? _getFloatingActionButton(LibraryProvider libraryProvider) {
    if (_currentIndex == 0 && libraryProvider.books.isNotEmpty) {
      return FloatingActionButton.extended(
        onPressed: () => libraryProvider.pickAndSaveFile(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add PDF'),
      );
    } else if (_currentIndex == 1) {
      return FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FlashcardScreen()),
          );
        },
        icon: const Icon(Icons.style_outlined),
        label: const Text('Practice'),
      );
    }
    return null;
  }
}
