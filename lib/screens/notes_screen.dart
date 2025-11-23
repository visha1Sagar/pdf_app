import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../models/note.dart';
import '../models/book.dart';
import 'package:collection/collection.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final databaseService = Provider.of<DatabaseService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        actions: [
          StreamBuilder<List<Note>>(
            stream: databaseService.watchNotes(),
            builder: (context, snapshot) {
              final count = snapshot.data?.length ?? 0;
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$count notes',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Note>>(
        stream: databaseService.watchNotes(),
        builder: (context, notesSnapshot) {
          if (notesSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final notes = notesSnapshot.data ?? [];

          if (notes.isEmpty) {
            return _buildEmptyState(context);
          }

          return StreamBuilder<List<Book>>(
            stream: databaseService.watchBooks(),
            builder: (context, booksSnapshot) {
              final books = booksSnapshot.data ?? [];

              // Group notes by book path
              final notesGroupedByBook = groupBy<Note, String>(
                notes,
                (note) => note.bookPath,
              );

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: notesGroupedByBook.length,
                itemBuilder: (context, index) {
                  final bookPath = notesGroupedByBook.keys.elementAt(index);
                  final bookNotes = notesGroupedByBook[bookPath]!;

                  // Find the book details
                  final book = books.firstWhereOrNull((b) => b.filePath == bookPath);

                  return _BookNotesCard(
                    bookPath: bookPath,
                    bookTitle: book?.title ?? _extractFileName(bookPath),
                    noteCount: bookNotes.length,
                    notes: bookNotes,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withAlpha(60),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.note_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withAlpha(180),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Notes Yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Start adding notes while reading to keep track of your thoughts and highlights',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(180),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  String _extractFileName(String path) {
    return path.split('/').last.split('\\').last.replaceAll('.pdf', '');
  }
}

class _BookNotesCard extends StatelessWidget {
  final String bookPath;
  final String bookTitle;
  final int noteCount;
  final List<Note> notes;

  const _BookNotesCard({
    required this.bookPath,
    required this.bookTitle,
    required this.noteCount,
    required this.notes,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showBookNotes(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primaryContainer,
                          Theme.of(context).colorScheme.secondaryContainer,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.menu_book_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bookTitle,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.notes_rounded,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$noteCount ${noteCount == 1 ? 'note' : 'notes'}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(120),
                  ),
                ],
              ),
              if (notes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(100),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.preview_rounded,
                        size: 14,
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          notes.first.noteText,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showBookNotes(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookNotesDetailScreen(
          bookPath: bookPath,
          bookTitle: bookTitle,
        ),
      ),
    );
  }
}

class BookNotesDetailScreen extends StatelessWidget {
  final String bookPath;
  final String bookTitle;

  const BookNotesDetailScreen({
    super.key,
    required this.bookPath,
    required this.bookTitle,
  });

  @override
  Widget build(BuildContext context) {
    final databaseService = Provider.of<DatabaseService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              bookTitle,
              style: const TextStyle(fontSize: 16),
            ),
            StreamBuilder<List<Note>>(
              stream: databaseService.watchNotesForBook(bookPath),
              builder: (context, snapshot) {
                final count = snapshot.data?.length ?? 0;
                return Text(
                  '$count ${count == 1 ? 'note' : 'notes'}',
                  style: Theme.of(context).textTheme.labelSmall,
                );
              },
            ),
          ],
        ),
      ),
      body: StreamBuilder<List<Note>>(
        stream: databaseService.watchNotesForBook(bookPath),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final notes = snapshot.data ?? [];

          if (notes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.note_outlined,
                    size: 80,
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(100),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notes for this book',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return _NoteDetailCard(note: note, bookPath: bookPath);
            },
          );
        },
      ),
    );
  }
}

class _NoteDetailCard extends StatelessWidget {
  final Note note;
  final String bookPath;

  const _NoteDetailCard({
    required this.note,
    required this.bookPath,
  });

  @override
  Widget build(BuildContext context) {
    final databaseService = Provider.of<DatabaseService>(context, listen: false);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant.withAlpha(100),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bookmark_rounded,
                        size: 14,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Page ${note.pageNumber + 1}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(note.updatedAt ?? note.createdAt),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                      ),
                ),
              ],
            ),
            if (note.selectedText != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withAlpha(60),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withAlpha(100),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.format_quote_rounded,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        note.selectedText!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                              height: 1.4,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              note.noteText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _deleteNote(context, databaseService),
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  label: Text(
                    'Delete',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        if (diff.inMinutes == 0) {
          return 'Just now';
        }
        return '${diff.inMinutes}m ago';
      }
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _deleteNote(BuildContext context, DatabaseService databaseService) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await databaseService.deleteNote(note.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note deleted')),
        );
      }
    }
  }
}
