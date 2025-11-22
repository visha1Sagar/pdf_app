import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/vocabulary_item.dart';
import '../services/database_service.dart';
import 'flashcard_screen.dart';

class VocabularyScreen extends StatelessWidget {
  const VocabularyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Vocabulary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.style),
            tooltip: 'Flashcards Mode',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FlashcardScreen()),
              );
            },
          ),
        ],
      ),
      body: const VocabularyList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FlashcardScreen()),
          );
        },
        icon: const Icon(Icons.style),
        label: const Text('Practice Flashcards'),
      ),
    );
  }
}

class VocabularyList extends StatefulWidget {
  const VocabularyList({super.key});

  @override
  State<VocabularyList> createState() => _VocabularyListState();
}

class _VocabularyListState extends State<VocabularyList> {
  late Stream<List<VocabularyItem>> _wordsStream;

  @override
  void initState() {
    super.initState();
    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    _wordsStream = databaseService.watchSavedWords();
  }
  
  Future<void> _deleteWord(int id) async {
    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    await databaseService.deleteWord(id);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<VocabularyItem>>(
      stream: _wordsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final words = snapshot.data;

        if (words == null || words.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.school_outlined, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No words saved yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: words.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final word = words[index];
            return Dismissible(
              key: Key(word.id.toString()),
              background: Container(
                decoration: BoxDecoration(
                  color: Colors.red.shade400,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              direction: DismissDirection.endToStart,
              onDismissed: (direction) {
                _deleteWord(word.id);
              },
              child: Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Text(
                    word.word,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        word.definition,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  trailing: Text(
                    '${word.timestamp.day}/${word.timestamp.month}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
