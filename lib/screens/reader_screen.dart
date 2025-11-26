import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../services/library_provider.dart';
import '../services/database_service.dart';
import '../models/book.dart';
import '../models/note.dart';
import '../widgets/definition_bottom_sheet.dart';
import '../widgets/note_dialog.dart';
import '../widgets/notes_list_widget.dart';

class ReaderScreen extends StatefulWidget {
  final String filePath;

  const ReaderScreen({super.key, required this.filePath});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late PdfViewerController _pdfViewerController;
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  Book? _book;
  bool _isLoading = true;
  PdfTextSelectionChangedDetails? _selectionDetails;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
    _loadBookInfo();
  }

  Future<void> _loadBookInfo() async {
    final libraryProvider = Provider.of<LibraryProvider>(context, listen: false);
    try {
      _book = libraryProvider.books.firstWhere((b) => b.filePath == widget.filePath);
    } catch (e) {
      // Book might not be in library
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        // Jump to last read page if available
        if (_book != null && _book!.lastReadPage > 0) {
          // We need to wait for the viewer to load to jump, 
          // but controller.jumpToPage works if called after build? 
          // Actually usually better to do it in onDocumentLoaded
        }
      });
    }
  }

  void _onDocumentLoaded(PdfDocumentLoadedDetails details) {
    if (_book != null && _book!.lastReadPage > 0) {
      _pdfViewerController.jumpToPage(_book!.lastReadPage + 1); // API is 1-based usually? Check docs. 
      // Syncfusion jumpToPage is 1-based.
    }
  }

  void _onPageChanged(PdfPageChangedDetails details) {
    // details.newPageNumber is 1-based
    final pageIndex = details.newPageNumber - 1;
    
    if (_book != null) {
      // Update progress
      Provider.of<LibraryProvider>(context, listen: false).updateProgress(_book!.id, pageIndex);
    }
  }

  void _onTextSelectionChanged(PdfTextSelectionChangedDetails details) {
    setState(() {
      _selectionDetails = details.selectedText != null ? details : null;
    });
    
    if (details.selectedText == null) {
      _removeOverlay();
    } else {
      _showSelectionMenu(context, details);
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showSelectionMenu(BuildContext context, PdfTextSelectionChangedDetails details) {
    _removeOverlay();
    
    final OverlayState overlayState = Overlay.of(context);
    
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: details.globalSelectedRegion!.top - 50,
        left: details.globalSelectedRegion!.left,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.search),
                  tooltip: 'Define',
                  onPressed: () {
                    _removeOverlay();
                    _showDefinition(details.selectedText!);
                    _pdfViewerController.clearSelection();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.note_add),
                  tooltip: 'Add Note',
                  onPressed: () {
                    _removeOverlay();
                    _addNote(details.selectedText!);
                    _pdfViewerController.clearSelection();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  tooltip: 'Copy',
                  onPressed: () {
                    // Copy to clipboard
                    // Clipboard.setData(ClipboardData(text: details.selectedText!));
                    _removeOverlay();
                    _pdfViewerController.clearSelection();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlayState.insert(_overlayEntry!);
  }

  void _showDefinition(String text) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DefinitionBottomSheet(word: text.trim()),
    );
  }

  void _addNote(String selectedText) async {
    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    // Get current page number (1-based from controller)
    final pageNumber = _pdfViewerController.pageNumber - 1;

    final result = await showDialog<Note>(
      context: context,
      builder: (context) => NoteDialog(
        pageNumber: pageNumber,
        bookPath: widget.filePath,
        selectedText: selectedText,
      ),
    );

    if (result != null && mounted) {
      await databaseService.saveNote(result);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note added successfully')),
      );
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    // _pdfViewerController.dispose(); // Controller doesn't need dispose? Check docs. It doesn't extend ChangeNotifier/Disposable usually in Syncfusion.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_book?.title ?? 'Reader'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () {
              _pdfViewerKey.currentState?.openBookmarkView();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (Theme.of(context).brightness == Brightness.dark
              ? ColorFiltered(
                  colorFilter: const ColorFilter.matrix([
                    -1,  0,  0, 0, 255,
                     0, -1,  0, 0, 255,
                     0,  0, -1, 0, 255,
                     0,  0,  0, 1,   0,
                  ]),
                  child: RepaintBoundary(
                    child: ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context).copyWith(
                        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                      ),
                      child: SfPdfViewer.file(
                        File(widget.filePath),
                        controller: _pdfViewerController,
                        key: _pdfViewerKey,
                        onDocumentLoaded: _onDocumentLoaded,
                        onPageChanged: _onPageChanged,
                        onTextSelectionChanged: _onTextSelectionChanged,
                        canShowScrollHead: true,
                        canShowScrollStatus: true,
                        pageLayoutMode: PdfPageLayoutMode.continuous,
                      ),
                    ),
                  ),
                )
              : RepaintBoundary(
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(
                      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                    ),
                    child: SfPdfViewer.file(
                      File(widget.filePath),
                      controller: _pdfViewerController,
                      key: _pdfViewerKey,
                      onDocumentLoaded: _onDocumentLoaded,
                      onPageChanged: _onPageChanged,
                      onTextSelectionChanged: _onTextSelectionChanged,
                      canShowScrollHead: true,
                      canShowScrollStatus: true,
                      pageLayoutMode: PdfPageLayoutMode.continuous,
                    ),
                  ),
                )),
    );
  }
}
