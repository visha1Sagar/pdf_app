import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/vocabulary_item.dart';
import '../services/database_service.dart';

class FlashcardScreen extends StatefulWidget {
  const FlashcardScreen({super.key});

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  List<VocabularyItem> _words = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  bool _showDefinition = false;

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  Future<void> _loadWords() async {
    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    final words = await databaseService.getSavedWords();
    
    if (mounted) {
      setState(() {
        _words = words;
        _isLoading = false;
      });
    }
  }

  void _nextCard() {
    if (_currentIndex < _words.length - 1) {
      setState(() {
        _currentIndex++;
        _showDefinition = false;
      });
    }
  }

  void _previousCard() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _showDefinition = false;
      });
    }
  }

  void _flipCard() {
    setState(() {
      _showDefinition = !_showDefinition;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashcards'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _words.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.style_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No words to review',
                        style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: GestureDetector(
                            onTap: _flipCard,
                            child: TweenAnimationBuilder(
                              tween: Tween<double>(begin: 0, end: _showDefinition ? 180 : 0),
                              duration: const Duration(milliseconds: 300),
                              builder: (context, double val, child) {
                                bool isFront = val < 90;
                                return Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.identity()
                                    ..setEntry(3, 2, 0.001)
                                    ..rotateY(val * pi / 180),
                                  child: Card(
                                    elevation: 4,
                                    color: Theme.of(context).colorScheme.surface,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                      side: BorderSide(
                                        color: Theme.of(context).dividerColor.withOpacity(0.1),
                                        width: 1,
                                      ),
                                    ),
                                    child: Container(
                                      width: double.infinity,
                                      height: 400,
                                      alignment: Alignment.center,
                                      padding: const EdgeInsets.all(32),
                                      child: isFront
                                          ? _buildFront(_words[_currentIndex])
                                          : Transform(
                                              alignment: Alignment.center,
                                              transform: Matrix4.identity()..rotateY(pi),
                                              child: _buildBack(_words[_currentIndex]),
                                            ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _currentIndex > 0 ? _previousCard : null,
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('Previous'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
                          Text(
                            '${_currentIndex + 1} / ${_words.length}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          ElevatedButton.icon(
                            onPressed: _currentIndex < _words.length - 1 ? _nextCard : null,
                            icon: const Icon(Icons.arrow_forward),
                            label: const Text('Next'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildFront(VocabularyItem item) {
    final theme = Theme.of(context);
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'WORD',
          style: theme.textTheme.labelMedium?.copyWith(
            letterSpacing: 2.0,
            color: theme.colorScheme.secondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          item.word,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Tap to flip',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildBack(VocabularyItem item) {
    final theme = Theme.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'DEFINITION',
          style: theme.textTheme.labelMedium?.copyWith(
            letterSpacing: 2.0,
            color: theme.colorScheme.secondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 32),
        SingleChildScrollView(
          child: Text(
            item.definition,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.5,
              fontSize: 18,
            ),
          ),
        ),
      ],
    );
  }
}
