import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/pdf_service.dart';
import '../services/library_provider.dart';
import '../models/book.dart';
import '../widgets/definition_bottom_sheet.dart';

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
  bool _isLoading = true;
  
  late PageController _pageController;
  Book? _book;

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
      
      // Load initial window
      await _loadPageWindow(initialPage);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading PDF: $e')),
        );
      }
    }
  }

  Future<void> _loadPageWindow(int centerIndex) async {
    if (_document == null) return;
    final pdfService = Provider.of<PdfService>(context, listen: false);

    // Load 5 pages before and 5 pages after
    int start = (centerIndex - 5).clamp(0, _totalPages - 1);
    int end = (centerIndex + 5).clamp(0, _totalPages - 1);

    bool needsUpdate = false;

    for (int i = start; i <= end; i++) {
      if (!_pageContent.containsKey(i)) {
        // Extract text if not already loaded
        // We use a microtask to avoid blocking UI too much in loop
        await Future.delayed(Duration.zero); 
        String text = pdfService.extractPageText(_document!, i);
        _pageContent[i] = text;
        needsUpdate = true;
      }
    }

    // Clean up pages far away to save memory (optional, but good for huge books)
    // Keep a buffer of 20 pages?
    _pageContent.removeWhere((key, value) => (key < centerIndex - 10 || key > centerIndex + 10));

    if (needsUpdate && mounted) {
      setState(() {});
    }
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
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
    if (mounted) setState(() {}); // Refresh to update app bar counter
    if (_book != null) {
      Provider.of<LibraryProvider>(context, listen: false).updateProgress(_book!.id, index);
    }
    // Trigger lazy load for new window
    _loadPageWindow(index);
  }

  @override
  Widget build(BuildContext context) {
    final currentPage = _pageController.hasClients 
        ? (_pageController.page?.round() ?? 0) + 1 
        : (_book?.lastReadPage ?? 0) + 1;

    return WillPopScope(
      onWillPop: () async {
        if (_isFullScreen) {
          _toggleFullScreen();
          return false;
        }
        return true;
      },
      child: Scaffold(
        extendBodyBehindAppBar: true, // Allow content to flow behind app bar when shown/hidden
        appBar: _isFullScreen 
            ? null 
            : AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_book?.title ?? 'Reader', style: const TextStyle(fontSize: 16)),
              if (_totalPages > 0)
                Text(
                  'Page $currentPage of $_totalPages',
                  style: Theme.of(context).textTheme.labelSmall,
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
              )
            : null,
        bottomNavigationBar: (_totalPages > 0 && !_isFullScreen)
            ? Container(
                height: 56,
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  border: Border(top: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      onPressed: currentPage > 1
                          ? () => _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              )
                          : null,
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                      tooltip: 'Previous Page',
                    ),
                    Text(
                      '$currentPage / $_totalPages',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      onPressed: currentPage < _totalPages
                          ? () => _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              )
                          : null,
                      icon: const Icon(Icons.arrow_forward_ios_rounded, size: 20),
                      tooltip: 'Next Page',
                    ),
                  ],
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
                        itemBuilder: (context, index) {
                          // Check if page content is loaded
                          if (!_pageContent.containsKey(index)) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          
                          final content = _pageContent[index]!;
                          return SingleChildScrollView(
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
                                _buildClickableText(content),
                                const SizedBox(height: 40),
                              ],
                            ),
                          );
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
