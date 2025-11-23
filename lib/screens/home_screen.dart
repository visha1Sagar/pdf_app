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

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final libraryProvider = Provider.of<LibraryProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark || 
                   (themeProvider.themeMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);

    return Scaffold(
      body: Column(
        children: [
          // Modern Header with gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF1A237E), const Color(0xFF0D47A1)]
                    : [const Color(0xFF667EEA), const Color(0xFF764BA2)],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with title and actions
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 16, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _currentIndex == 0 ? 'My Library' : (_currentIndex == 1 ? 'Notes' : 'Vocabulary'),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        if (_currentIndex == 2)
                          IconButton(
                            icon: const Icon(Icons.style_outlined, color: Colors.white),
                            tooltip: 'Flashcards Mode',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const FlashcardScreen()),
                              );
                            },
                          ),
                        IconButton(
                          icon: Icon(
                            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            themeProvider.toggleTheme(!isDark);
                          },
                        ),
                      ],
                    ),
                  ),
                  // Search bar (only for library)
                  if (_currentIndex == 0 && libraryProvider.books.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Search your library...',
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                            prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.8)),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.clear, color: Colors.white.withOpacity(0.8)),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          ),
                          onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          // Content area
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                _buildLibraryView(libraryProvider),
                const NotesScreen(),
                const VocabularyList(),
              ],
            ),
          ),
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

    final filteredBooks = _searchQuery.isEmpty
        ? libraryProvider.books
        : libraryProvider.books.where((book) => 
            book.title.toLowerCase().contains(_searchQuery)).toList();

    if (filteredBooks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'No books found',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Try a different search term',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 16,
        mainAxisSpacing: 20,
      ),
      itemCount: filteredBooks.length,
      itemBuilder: (context, index) {
        final book = filteredBooks[index];
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 300 + (index * 50)),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: BookCard(
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
          ),
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
    Widget? fab;
    if (_currentIndex == 0 && libraryProvider.books.isNotEmpty) {
      fab = FloatingActionButton.extended(
        onPressed: () => libraryProvider.pickAndSaveFile(),
        icon: const Icon(Icons.add_rounded, size: 24),
        label: const Text('Add PDF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        elevation: 8,
      );
    } else if (_currentIndex == 2) {
      fab = FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FlashcardScreen()),
          );
        },
        icon: const Icon(Icons.style_outlined, size: 24),
        label: const Text('Practice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        elevation: 8,
      );
    }
    
    if (fab == null) return null;
    
    return ScaleTransition(
      scale: _fabAnimation,
      child: fab,
    );
  }
}
