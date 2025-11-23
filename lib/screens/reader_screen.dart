import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/pdf_service.dart';
import '../services/library_provider.dart';
import '../services/database_service.dart';
import '../models/book.dart';
import '../models/note.dart';
import '../widgets/definition_bottom_sheet.dart';
import '../widgets/note_dialog.dart';
import '../widgets/notes_list_widget.dart';

import 'package:syncfusion_flutter_pdf/pdf.dart';

class ReaderScreen extends StatefulWidget {
  final String filePath;

  const ReaderScreen({super.key, required this.filePath});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  // Lazy Loading State
  PdfDocument? _document;
  int _totalPages = 0;
  final Map<int, String> _pageContent = {};
  final Map<int, Widget> _pageWidgetCache = {}; // Cache built widgets for better performance
  bool _isLoading = true;
  bool _isPreloading = false;
  
  late PageController _pageController;
  Book? _book;
  int _currentPage = 0;

  // Selection State
  bool _isSelectionMode = false;
  // Store selection as (paragraphIndex, wordIndex)
  // We use a simple class or just a list of ints for simplicity: [paragraphIndex, wordIndex]
  List<int>? _selectionStart;
  List<int>? _selectionEnd;
  // Store the actual words selected to build the phrase
  String _selectedPhrase = "";
  String _selectedContext = "";

  // Appearance Settings
  double _fontSize = 18.0;
  double _lineHeight = 1.6; // Optimized for readability
  String _fontFamily = 'Merriweather';
  final List<String> _fontOptions = ['Lato', 'Libre Baskerville', 'Merriweather', 'Roboto', 'Open Sans'];
  
  // Full Screen State
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    final pdfService = Provider.of<PdfService>(context, listen: false);
    final libraryProvider = Provider.of<LibraryProvider>(context, listen: false);
    
    // Find the book to get last read page
    try {
      _book = libraryProvider.books.firstWhere((b) => b.filePath == widget.filePath);
    } catch (e) {
      // Book might not be in library
    }

    if (mounted) setState(() => _isLoading = true);

    try {
      // Open document lazily
      _document = await pdfService.openDocument(widget.filePath);
      _totalPages = _document!.pages.count;
      
      int initialPage = _book?.lastReadPage ?? 0;
      if (initialPage >= _totalPages) initialPage = 0;
      
      _pageController = PageController(initialPage: initialPage);
      _currentPage = initialPage;
      
      // Load initial window with more aggressive preloading
      await _loadPageWindow(initialPage, aggressive: true);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      
      // Start background preloading after initial load
      _startBackgroundPreloading();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading PDF: $e')),
        );
      }
    }
  }

  Future<void> _loadPageWindow(int centerIndex, {bool aggressive = false}) async {
    if (_document == null) return;
    final pdfService = Provider.of<PdfService>(context, listen: false);

    // Aggressive preloading: load 10 pages before and after for smooth scrolling
    // Normal: load 5 pages before and after
    final window = aggressive ? 10 : 7;
    int start = (centerIndex - window).clamp(0, _totalPages - 1);
    int end = (centerIndex + window).clamp(0, _totalPages - 1);

    // Prioritize pages closest to current page
    final pagesToLoad = <int>[];
    for (int offset = 0; offset <= window; offset++) {
      final prevPage = centerIndex - offset;
      final nextPage = centerIndex + offset;
      
      if (prevPage >= start && !_pageContent.containsKey(prevPage)) {
        pagesToLoad.add(prevPage);
      }
      if (nextPage <= end && nextPage != prevPage && !_pageContent.containsKey(nextPage)) {
        pagesToLoad.add(nextPage);
      }
    }

    bool needsUpdate = false;
    for (int i = 0; i < pagesToLoad.length; i++) {
      final pageIndex = pagesToLoad[i];
      
      // Yield to event loop every 2 pages to keep UI responsive
      if (i % 2 == 0) await Future.delayed(Duration.zero);
      
      String text = pdfService.extractPageText(_document!, pageIndex, cachePath: widget.filePath);
      _pageContent[pageIndex] = text;
      needsUpdate = true;
    }

    // Keep a buffer of 25 pages to avoid reloading on back-and-forth navigation
    final removedPages = <int>[];
    _pageContent.removeWhere((key, value) {
      final shouldRemove = (key < centerIndex - 15 || key > centerIndex + 15);
      if (shouldRemove) removedPages.add(key);
      return shouldRemove;
    });
    
    // Also clear widget cache for removed pages
    for (final page in removedPages) {
      _pageWidgetCache.remove(page);
    }

    if (needsUpdate && mounted) {
      setState(() {});
    }
  }
  
  // Background preloader for upcoming pages
  void _startBackgroundPreloading() async {
    if (_isPreloading) return;
    _isPreloading = true;
    
    while (mounted && _document != null) {
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!mounted || _document == null) break;
      
      // Preload pages ahead of current position
      final currentIndex = _currentPage;
      final pdfService = Provider.of<PdfService>(context, listen: false);
      
      // Preload next 15 pages if not already loaded
      for (int i = currentIndex + 8; i <= currentIndex + 15 && i < _totalPages; i++) {
        if (!_pageContent.containsKey(i)) {
          await Future.delayed(Duration.zero);
          String text = pdfService.extractPageText(_document!, i, cachePath: widget.filePath);
          _pageContent[i] = text;
        }
      }
    }
    
    _isPreloading = false;
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
      // Clear widget cache since layout changes in fullscreen
      _pageWidgetCache.clear();
    });
    
    if (_isFullScreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  @override
  void dispose() {
    // Restore system UI when leaving
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _pageController.dispose();
    _document?.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    _currentPage = index;
    
    // Update app bar counter without setState for better performance
    // The PageView.builder will handle page rendering
    
    // Update progress asynchronously to avoid blocking
    if (_book != null) {
      Future.microtask(() {
        if (mounted) {
          Provider.of<LibraryProvider>(context, listen: false).updateProgress(_book!.id, index);
        }
      });
    }
    
    // Trigger lazy load for new window asynchronously
    Future.microtask(() {
      if (mounted) {
        _loadPageWindow(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Use tracked current page instead of reading from controller for better performance
    final currentPage = _currentPage + 1;

    return WillPopScope(
      onWillPop: () async {
        if (_isFullScreen) {
          _toggleFullScreen();
          return false;
        }
        return true;
      },
      child: Scaffold(
        extendBodyBehindAppBar: false,
        appBar: _isFullScreen 
            ? null 
            : AppBar(
          elevation: 0,
          backgroundColor: Theme.of(context).colorScheme.surface,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _book?.title ?? 'Reader',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (_totalPages > 0)
                Text(
                  'Page $currentPage of $_totalPages',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                  ),
                ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.fullscreen),
              tooltip: 'Full Screen',
              onPressed: _toggleFullScreen,
            ),
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Search Word',
              onPressed: _showManualSearch,
            ),
            IconButton(
              icon: const Icon(Icons.text_format),
              tooltip: 'Appearance Settings',
              onPressed: _showAppearanceSettings,
            ),
            IconButton(
              icon: const Icon(Icons.note_add),
              tooltip: 'Add Note',
              onPressed: _addNote,
            ),
            IconButton(
              icon: Icon(_isSelectionMode ? Icons.check_circle : Icons.select_all),
              tooltip: _isSelectionMode ? 'Finish Selection' : 'Select Phrase',
              color: _isSelectionMode ? Colors.green : null,
              onPressed: () {
                setState(() {
                  _isSelectionMode = !_isSelectionMode;
                  if (!_isSelectionMode) {
                    // Clear selection when turning off
                    _selectionStart = null;
                    _selectionEnd = null;
                    _selectedPhrase = "";
                  }
                  // Clear widget cache when toggling selection mode
                  // so widgets rebuild with/without selection handlers
                  _pageWidgetCache.clear();
                });
              },
            ),
          ],
        ),
        floatingActionButton: _isSelectionMode && _selectionStart != null && _selectionEnd != null
            ? FloatingActionButton.extended(
                onPressed: () => _onWordTap(_selectedPhrase, _selectedContext),
                label: const Text('Define Phrase'),
                icon: const Icon(Icons.search),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              )
            : (!_isFullScreen
                ? FloatingActionButton(
                    onPressed: _addNote,
                    tooltip: 'Add Note',
                    child: const Icon(Icons.note_add_rounded),
                  )
                : null),
        bottomNavigationBar: (_totalPages > 0 && !_isFullScreen)
            ? Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      offset: const Offset(0, -2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            onPressed: currentPage > 1
                                ? () => _pageController.previousPage(
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    )
                                : null,
                            icon: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 20,
                              color: currentPage > 1
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).disabledColor,
                            ),
                            tooltip: 'Previous Page',
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary.withOpacity(0.15),
                                Theme.of(context).colorScheme.secondary.withOpacity(0.15),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$currentPage / $_totalPages',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            onPressed: currentPage < _totalPages
                                ? () => _pageController.nextPage(
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    )
                                : null,
                            icon: Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 20,
                              color: currentPage < _totalPages
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).disabledColor,
                            ),
                            tooltip: 'Next Page',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : null,
        body: Stack(
          children: [
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _totalPages == 0
                    ? const Center(child: Text('No content found.'))
                    : PageView.builder(
                        controller: _pageController,
                        onPageChanged: _onPageChanged,
                        itemCount: _totalPages,
                        physics: const BouncingScrollPhysics(), // Smoother scrolling physics
                        pageSnapping: true, // Ensure proper page snapping
                        itemBuilder: (context, index) {
                          // Check if page content is loaded
                          if (!_pageContent.containsKey(index)) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          
                          // Use cached widget if available and not in selection mode
                          // (selection mode needs fresh widgets for interaction)
                          if (!_isSelectionMode && _pageWidgetCache.containsKey(index)) {
                            return _pageWidgetCache[index]!;
                          }
                          
                          final content = _pageContent[index]!;
                          final pageWidget = SingleChildScrollView(
                            key: ValueKey('page_$index'), // Add key for better widget reuse
                            physics: const ClampingScrollPhysics(), // Better scrolling within page
                            padding: EdgeInsets.fromLTRB(
                              16.0, 
                              _isFullScreen ? 32.0 : 16.0, // Add top padding in full screen
                              16.0, 
                              16.0
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!_isFullScreen)
                                  Center(
                                    child: Text(
                                      "Page ${index + 1}",
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey),
                                    ),
                                  ),
                                const SizedBox(height: 16),
                                NotesListWidget(
                                  bookPath: widget.filePath,
                                  pageNumber: index,
                                ),
                                _buildClickableText(content),
                                const SizedBox(height: 40),
                              ],
                            ),
                          );
                          
                          // Cache the widget if not in selection mode
                          if (!_isSelectionMode) {
                            _pageWidgetCache[index] = pageWidget;
                          }
                          
                          return pageWidget;
                        },
                      ),
            if (_isFullScreen && !_isSelectionMode)
              Positioned(
                bottom: 32,
                right: 32,
                child: SafeArea(
                  child: FloatingActionButton.small(
                    heroTag: 'exit_fullscreen',
                    onPressed: _toggleFullScreen,
                    backgroundColor: Colors.black.withOpacity(0.5),
                    child: const Icon(Icons.fullscreen_exit, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildClickableText(String text) {
    // 1. Normalize line endings (handle both \r\n and \r)
    String cleanText = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    
    // 2. Split into paragraphs based on double newlines
    // If the PDF doesn't have double newlines for paragraphs, this might treat the whole page as one paragraph.
    // But we will also handle single newlines inside _buildParagraph to ensure flow.
    final paragraphs = cleanText.split(RegExp(r'\n\s*\n'));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: paragraphs.asMap().entries.map((entry) {
        int index = entry.key;
        String paragraph = entry.value;
        
        if (paragraph.trim().isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0), // Increased paragraph spacing
          child: _buildParagraph(paragraph, index),
        );
      }).toList(),
    );
  }

  Widget _buildParagraph(String paragraph, int paragraphIndex) {
    // Replace single newlines with spaces to allow text to reflow naturally
    String reflowedText = paragraph.replaceAll('\n', ' ');
    
    // Remove multiple spaces
    reflowedText = reflowedText.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Indent the first line of the paragraph for a more natural book look
    // We can achieve this by adding a Widget before the text or using TextSpan with leading spaces?
    // Leading spaces in TextSpan might be trimmed or not render as expected with justify.
    // A better way is to use `textIndent` if available, but Flutter RichText doesn't support it directly.
    // We can simulate it with a transparent Widget or just spaces if we trust they won't be trimmed.
    // Let's try adding 4 non-breaking spaces.
    // reflowedText = "    " + reflowedText; 
    // Actually, let's not force indentation if the user didn't ask for it, but "natural" implies it.
    // Let's stick to block paragraphs with spacing for now as it's safer for mobile.

    final words = reflowedText.split(' ');
    List<TextSpan> spans = [];
    
    // Get current text color based on theme
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final highlightColor = Colors.blue.withOpacity(0.3);

    for (int i = 0; i < words.length; i++) {
      String word = words[i];
      
      // Check if this word is selected
      bool isSelected = false;
      if (_isSelectionMode && _selectionStart != null) {
        // If only start is set, highlight just start
        if (_selectionEnd == null) {
          if (_selectionStart![0] == paragraphIndex && _selectionStart![1] == i) {
            isSelected = true;
          }
        } else {
          // Range check
          // We need to compare (p1, w1) <= (p, w) <= (p2, w2)
          // Simplified: Assume selection is within one paragraph for now for easier logic, 
          // or handle multi-paragraph.
          // Let's handle multi-paragraph logic:
          
          // Normalize start/end to ensure start <= end
          List<int> start = _selectionStart!;
          List<int> end = _selectionEnd!;
          
          if (start[0] > end[0] || (start[0] == end[0] && start[1] > end[1])) {
            start = _selectionEnd!;
            end = _selectionStart!;
          }

          // Check if current word (paragraphIndex, i) is in range
          bool afterStart = (paragraphIndex > start[0]) || (paragraphIndex == start[0] && i >= start[1]);
          bool beforeEnd = (paragraphIndex < end[0]) || (paragraphIndex == end[0] && i <= end[1]);
          
          isSelected = afterStart && beforeEnd;
        }
      }

      TextStyle baseStyle = GoogleFonts.getFont(_fontFamily).copyWith(
        color: textColor,
        fontSize: _fontSize,
        height: _lineHeight,
        backgroundColor: isSelected ? highlightColor : null,
      );

      spans.add(
        TextSpan(
          text: '$word ',
          style: baseStyle,
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              if (_isSelectionMode) {
                _handleSelectionTap(paragraphIndex, i, word, reflowedText);
              } else {
                _onWordTap(word, reflowedText);
              }
            },
        ),
      );
    }

    return RichText(
      textAlign: TextAlign.justify, // Justify text for better block appearance
      text: TextSpan(children: spans),
    );
  }

  void _handleSelectionTap(int pIndex, int wIndex, String word, String context) {
    setState(() {
      if (_selectionStart == null) {
        // Start selection
        _selectionStart = [pIndex, wIndex];
        _selectionEnd = null;
        _selectedPhrase = word;
        _selectedContext = context;
      } else if (_selectionEnd == null) {
        // End selection
        _selectionEnd = [pIndex, wIndex];
        _updateSelectedPhrase(context); // Helper to extract text
      } else {
        // Reset and start new
        _selectionStart = [pIndex, wIndex];
        _selectionEnd = null;
        _selectedPhrase = word;
        _selectedContext = context;
      }
    });
  }

  void _updateSelectedPhrase(String context) {
    // This is tricky because context is per-paragraph.
    // If selection spans paragraphs, we need access to all paragraphs.
    // For MVP, let's assume selection is within the SAME paragraph for the phrase extraction to be simple.
    // If it spans paragraphs, we might just take the start/end words or need to reconstruct.
    
    if (_selectionStart![0] != _selectionEnd![0]) {
      // Multi-paragraph selection
      _selectedPhrase = "Multi-paragraph selection not fully supported for definition yet.";
      return;
    }

    // Same paragraph
    // Reconstruct the phrase from the context string? 
    // We have 'context' which is the reflowed text of the CURRENT paragraph (where the tap happened).
    // But we need to know which words correspond to indices.
    // We split by space in _buildParagraph. We should do same here.
    
    final words = context.split(' ');
    int start = _selectionStart![1];
    int end = _selectionEnd![1];
    
    if (start > end) {
      final temp = start;
      start = end;
      end = temp;
    }
    
    // Safety check
    if (start < 0) start = 0;
    if (end >= words.length) end = words.length - 1;
    
    _selectedPhrase = words.sublist(start, end + 1).join(' ');
    _selectedContext = context;
  }

  void _addNote() async {
    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    
    final result = await showDialog<Note>(
      context: context,
      builder: (context) => NoteDialog(
        pageNumber: _currentPage,
        bookPath: widget.filePath,
        selectedText: _selectedPhrase.isNotEmpty ? _selectedPhrase : null,
      ),
    );

    if (result != null && mounted) {
      await databaseService.saveNote(result);
      
      // Clear selection if any
      if (_isSelectionMode) {
        setState(() {
          _isSelectionMode = false;
          _selectionStart = null;
          _selectionEnd = null;
          _selectedPhrase = "";
          _pageWidgetCache.clear();
        });
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note added successfully')),
        );
      }
    }
  }

  void _showManualSearch() {
    final TextEditingController searchController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Word'),
        content: TextField(
          controller: searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter a word...',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            Navigator.pop(context);
            if (value.trim().isNotEmpty) {
              _onWordTap(value.trim(), "");
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (searchController.text.trim().isNotEmpty) {
                _onWordTap(searchController.text.trim(), "");
              }
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _showAppearanceSettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Appearance',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Icon(Icons.text_fields),
                    const SizedBox(width: 16),
                    const Text('Font Size'),
                    const Spacer(),
                    IconButton(
                      onPressed: _fontSize > 12 
                          ? () {
                              setState(() => _fontSize -= 2);
                              setModalState(() {});
                            } 
                          : null,
                      icon: const Icon(Icons.remove),
                    ),
                    Text('${_fontSize.toInt()}'),
                    IconButton(
                      onPressed: _fontSize < 32 
                          ? () {
                              setState(() => _fontSize += 2);
                              setModalState(() {});
                            } 
                          : null,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.format_line_spacing),
                    const SizedBox(width: 16),
                    const Text('Line Height'),
                    const Spacer(),
                    IconButton(
                      onPressed: _lineHeight > 1.0 
                          ? () {
                              setState(() => _lineHeight -= 0.1);
                              setModalState(() {});
                            } 
                          : null,
                      icon: const Icon(Icons.remove),
                    ),
                    Text(_lineHeight.toStringAsFixed(1)),
                    IconButton(
                      onPressed: _lineHeight < 3.0 
                          ? () {
                              setState(() => _lineHeight += 0.1);
                              setModalState(() {});
                            } 
                          : null,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Font Family', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: _fontOptions.map((font) {
                    return ChoiceChip(
                      label: Text(font, style: TextStyle(fontFamily: font)),
                      selected: _fontFamily == font,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _fontFamily = font);
                          setModalState(() {});
                        }
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _onWordTap(String word, String sentence) {
    // Clean the word (remove punctuation, but keep hyphens and apostrophes)
    final cleanedWord = word.replaceAll(RegExp(r"[^\w\s\-']"), '').trim();
    if (cleanedWord.isEmpty) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => DefinitionBottomSheet(
        word: cleanedWord,
        contextSentence: sentence,
      ),
    );
  }
}
