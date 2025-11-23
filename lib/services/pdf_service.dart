import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class Chapter {
  final String title;
  final String content;

  Chapter({required this.title, required this.content});
}

// Configuration for text extraction
class TextExtractionConfig {
  final bool fixHyphenation;
  final bool fixMergedWords;
  final bool fixPunctuation;
  final bool normalizeWhitespace;
  final bool smartParagraphDetection;
  final bool removePageNumbers;
  final int minWordLength;

  const TextExtractionConfig({
    this.fixHyphenation = true,
    this.fixMergedWords = true,
    this.fixPunctuation = true,
    this.normalizeWhitespace = true,
    this.smartParagraphDetection = true,
    this.removePageNumbers = true,
    this.minWordLength = 1,
  });
}

class PdfService {
  // Cache for extracted page text to avoid re-extraction
  final Map<String, Map<int, String>> _pageCache = {};
  
  // Clear cache for a specific document
  void clearCache(String documentPath) {
    _pageCache.remove(documentPath);
  }
  
  // Clear all cached data
  void clearAllCache() {
    _pageCache.clear();
  }
  
  Future<List<Chapter>> extractChapters(String path) async {
    final File file = File(path);
    final List<int> bytes = await file.readAsBytes();
    final PdfDocument document = PdfDocument(inputBytes: bytes);
    
    List<Chapter> chapters = [];

    // Extract all text
    String text = PdfTextExtractor(document).extractText();
    
    if (text.trim().isNotEmpty) {
      chapters.add(Chapter(title: "Full Text", content: _cleanText(text)));
    }

    document.dispose();
    return chapters;
  }
  
  // Extract text per page
  Future<List<Chapter>> extractPages(String path) async {
    final File file = File(path);
    final List<int> bytes = await file.readAsBytes();
    final PdfDocument document = PdfDocument(inputBytes: bytes);
    
    List<Chapter> pages = [];
    final PdfTextExtractor extractor = PdfTextExtractor(document);
    int pageCount = document.pages.count;
    
    for (int i = 0; i < pageCount; i++) {
      // Yield to event loop every 10 pages
      if (i % 10 == 0) await Future.delayed(Duration.zero);

      String text = "";
      try {
        text = extractor.extractText(startPageIndex: i, endPageIndex: i);
      } catch (e) {
        text = "Error extracting text: $e";
      }
      
      if (text.trim().isEmpty) {
        text = "";
      } else {
        text = _cleanText(text);
      }
      
      pages.add(Chapter(title: "Page ${i + 1}", content: text));
    }

    document.dispose();
    return pages;
  }

  // --- Lazy Loading Methods ---

  Future<PdfDocument> openDocument(String path) async {
    final File file = File(path);
    final List<int> bytes = await file.readAsBytes();
    return PdfDocument(inputBytes: bytes);
  }

  String extractPageText(PdfDocument document, int pageIndex, {TextExtractionConfig? config, String? cachePath}) {
    config ??= const TextExtractionConfig();
    
    // Check cache first
    if (cachePath != null && _pageCache.containsKey(cachePath)) {
      final pageText = _pageCache[cachePath]?[pageIndex];
      if (pageText != null) {
        return pageText;
      }
    }
    
    try {
      final PdfTextExtractor extractor = PdfTextExtractor(document);
      
      // Try layout-based extraction first for better results
      String text = '';
      try {
        text = _extractTextWithLayout(document, pageIndex, extractor);
      } catch (e) {
        // Fallback to simple extraction
        text = extractor.extractText(startPageIndex: pageIndex, endPageIndex: pageIndex);
      }
      
      if (text.trim().isEmpty) {
        text = "[This page appears to be empty or contains only images. Text extraction is not possible.]";
      } else {
        text = _cleanText(text, config: config);
      }
      
      // Cache the result
      if (cachePath != null) {
        _pageCache.putIfAbsent(cachePath, () => {});
        _pageCache[cachePath]![pageIndex] = text;
      }
      
      return text;
    } catch (e) {
      return "Error extracting text: $e";
    }
  }

  // Extract text with layout awareness for better reading order
  String _extractTextWithLayout(PdfDocument document, int pageIndex, PdfTextExtractor extractor) {
    try {
      // Extract text with layout information
      final List<TextLine> textLines = extractor.extractTextLines(startPageIndex: pageIndex, endPageIndex: pageIndex);
      
      if (textLines.isEmpty) {
        return extractor.extractText(startPageIndex: pageIndex, endPageIndex: pageIndex);
      }
      
      // Sort text lines by position (top to bottom, left to right)
      textLines.sort((a, b) {
        final yDiff = a.bounds.top.compareTo(b.bounds.top);
        if (yDiff.abs() > 5) return yDiff; // 5 pixel tolerance
        return a.bounds.left.compareTo(b.bounds.left);
      });
      
      // Build text respecting layout
      final StringBuffer buffer = StringBuffer();
      String? lastText;
      double lastBottom = 0;
      
      for (final line in textLines) {
        final text = line.text.trim();
        if (text.isEmpty) continue;
        
        // Detect paragraph breaks based on vertical spacing
        final verticalGap = line.bounds.top - lastBottom;
        if (lastText != null && verticalGap > 15) {
          buffer.writeln(); // Add paragraph break
        }
        
        // Add space or newline based on layout
        if (lastText != null && verticalGap <= 15) {
          if (!lastText.endsWith('-') && !lastText.endsWith(' ')) {
            buffer.write(' ');
          }
        }
        
        buffer.write(text);
        lastText = text;
        lastBottom = line.bounds.bottom;
      }
      
      return buffer.toString();
    } catch (e) {
      return '';
    }
  }

  // Main text cleaning method with modular processing stages
  String _cleanText(String text, {TextExtractionConfig? config}) {
    config ??= const TextExtractionConfig();
    
    // Stage 1: Normalize Unicode Characters
    String cleaned = _normalizeUnicode(text);
    
    // Stage 2: Fix Common OCR Errors
    cleaned = _fixOCRErrors(cleaned);
    
    // Stage 3: Handle Hyphenation
    if (config.fixHyphenation) {
      cleaned = _fixHyphenation(cleaned);
    }
    
    // Stage 4: Smart Paragraph Detection
    if (config.smartParagraphDetection) {
      cleaned = _detectParagraphs(cleaned);
    }
    
    // Stage 5: Fix Punctuation Spacing
    if (config.fixPunctuation) {
      cleaned = _fixPunctuationSpacing(cleaned);
    }
    
    // Stage 6: Fix Merged Words
    if (config.fixMergedWords) {
      cleaned = _fixMergedWords(cleaned);
    }
    
    // Stage 7: Normalize Whitespace
    if (config.normalizeWhitespace) {
      cleaned = _normalizeWhitespace(cleaned);
    }
    
    // Stage 8: Remove Page Numbers (optional)
    if (config.removePageNumbers) {
      cleaned = _removePageNumbers(cleaned);
    }
    
    return cleaned.trim();
  }
  
  // Stage 1: Normalize Unicode characters
  String _normalizeUnicode(String text) {
    return text
        // Ligatures
        .replaceAll('\ufb00', 'ff')
        .replaceAll('\ufb01', 'fi')
        .replaceAll('\ufb02', 'fl')
        .replaceAll('\ufb03', 'ffi')
        .replaceAll('\ufb04', 'ffl')
        .replaceAll('\ufb05', 'ft')
        .replaceAll('\ufb06', 'st')
        // Quotation marks
        .replaceAll('\u201C', '"').replaceAll('\u201D', '"')
        .replaceAll('\u2018', "'").replaceAll('\u2019', "'")
        .replaceAll('\u201A', "'").replaceAll('\u201E', '"')
        .replaceAll('"', '"').replaceAll('"', '"')
        .replaceAll(''', "'").replaceAll(''', "'")
        // Dashes
        .replaceAll('\u2013', '-').replaceAll('\u2014', ' - ')
        .replaceAll('–', '-').replaceAll('—', ' - ')
        // Ellipsis and spaces
        .replaceAll('\u2026', '...')
        .replaceAll('\u00A0', ' ')  // Non-breaking space
        .replaceAll('\u2009', ' ')  // Thin space
        .replaceAll('\u200B', '')   // Zero-width space
        // Bullets
        .replaceAll('\u2022', '•').replaceAll('\u2023', '•')
        .replaceAll('\u25E6', '•').replaceAll('\u2043', '•');
  }
  
  // Stage 2: Fix common OCR errors
  String _fixOCRErrors(String text) {
    return text
        // Common letter confusion
        .replaceAll(RegExp(r'\b([a-z]+)cdy\b'), r'$1ctly')  // direcdy -> directly
        .replaceAll(RegExp(r'\b([a-z]+)tdy\b'), r'$1tly')   // exactdy -> exactly
        .replaceAll(RegExp(r'\bwidi\b'), 'with')
        .replaceAll(RegExp(r'\bwidiin\b'), 'within')
        .replaceAll(RegExp(r'\bwidout\b'), 'without')
        .replaceAll(RegExp(r'\bdiat\b'), 'that')
        .replaceAll(RegExp(r'\bdiis\b'), 'this')
        .replaceAll(RegExp(r'\bdien\b'), 'then')
        .replaceAll(RegExp(r'\bdie\b'), 'the')
        // Number confusion
        .replaceAll(RegExp(r'\b0ne\b'), 'one')
        .replaceAll(RegExp(r'\b0nly\b'), 'only')
        // Common word corrections
        .replaceAll(RegExp(r'\bcan\s*not\b'), 'cannot')
        // Fix "m" mistaken as "rn"
        .replaceAll(RegExp(r'\bfrorn\b'), 'from')
        .replaceAll(RegExp(r'\bforrn\b'), 'form')
        .replaceAll(RegExp(r'\binforrnation\b'), 'information')
        // Fix common spacing issues in compound words
        .replaceAll(RegExp(r'\bevery\s+day\b'), 'everyday')
        .replaceAll(RegExp(r'\bsome\s+thing\b'), 'something')
        .replaceAll(RegExp(r'\bany\s+thing\b'), 'anything')
        .replaceAll(RegExp(r'\bany\s+one\b'), 'anyone')
        .replaceAll(RegExp(r'\bsome\s+one\b'), 'someone')
        .replaceAll(RegExp(r'\bno\s+thing\b'), 'nothing');
  }
  
  // Stage 3: Fix hyphenation issues
  String _fixHyphenation(String text) {
    // Improved: Only merge hyphens at line ends when followed by lowercase (likely continuation)
    // But preserve intentional hyphens (compound words)
    return text.replaceAllMapped(
      RegExp(r'-\s*\r?\n\s*([a-z])'),
      (match) {
        // Check if this might be a compound word vs line break
        // Simple heuristic: if followed by lowercase, likely line break
        return match.group(1)!;  // Merge without hyphen
      }
    );
  }
  
  // Stage 4: Smart paragraph detection
  String _detectParagraphs(String text) {
    // Join lines that don't end in terminal punctuation
    text = text.replaceAllMapped(
      RegExp(r'([^\n\r.!?:;""''])\r?\n([^\n\r])'),
      (match) {
        final char = match.group(1)!;
        final next = match.group(2)!;
        
        // If line ends with hyphen, keep it
        if (char == '-') {
          return '$char $next';
        }
        
        // If next line starts with lowercase, likely same paragraph
        if (RegExp(r'[a-z]').hasMatch(next)) {
          return '$char $next';
        }
        
        // Otherwise keep the line break
        return '${match.group(0)}';
      }
    );
    
    // Ensure paragraph breaks (lines ending with terminal punctuation)
    text = text.replaceAllMapped(
      RegExp(r'([.!?:;""''])\r?\n'),
      (match) => '${match.group(1)}\n\n'
    );
    
    // Normalize excessive newlines
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    
    return text;
  }
  
  // Stage 5: Fix punctuation spacing
  String _fixPunctuationSpacing(String text) {
    return text
        // Add space after punctuation if missing
        .replaceAll(RegExp(r'\.(?=[a-zA-Z])'), '. ')
        .replaceAll(RegExp(r',(?=[a-zA-Z])'), ', ')
        .replaceAll(RegExp(r':(?=[a-zA-Z])'), ': ')
        .replaceAll(RegExp(r';(?=[a-zA-Z])'), '; ')
        .replaceAll(RegExp(r'\?(?=[a-zA-Z])'), '? ')
        .replaceAll(RegExp(r'!(?=[a-zA-Z])'), '! ')
        // Fix parentheses spacing
        .replaceAll(RegExp(r'(?<=[a-z])\((?=[a-zA-Z])'), ' (')
        .replaceAll(RegExp(r'(?<=[a-zA-Z])\)(?=[a-zA-Z])'), ') ')
        // Remove space before punctuation
        .replaceAll(RegExp(r'\s+([.,!?;:])'), r'$1');
  }
  
  // Stage 6: Fix merged words
  String _fixMergedWords(String text) {
    // Split CamelCase (likely merged words)
    text = text.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (match) => '${match.group(1)} ${match.group(2)}'
    );
    
    // Split word-number combinations
    text = text.replaceAllMapped(
      RegExp(r'([a-zA-Z])(\d)'),
      (match) => '${match.group(1)} ${match.group(2)}'
    );
    text = text.replaceAllMapped(
      RegExp(r'(\d)([a-zA-Z])'),
      (match) => '${match.group(1)} ${match.group(2)}'
    );
    
    // Fix common merged word pairs
    final commonMerges = {
      'tobe': 'to be', 'tothe': 'to the', 'ofthe': 'of the',
      'inthe': 'in the', 'onthe': 'on the', 'andthe': 'and the',
      'withthe': 'with the', 'fromthe': 'from the', 'forthe': 'for the',
      'butthe': 'but the', 'atthe': 'at the', 'bythe': 'by the',
      'itis': 'it is', 'thatis': 'that is', 'thisis': 'this is',
      'willbe': 'will be', 'canbe': 'can be', 'shouldbe': 'should be',
      'wouldbe': 'would be', 'couldbe': 'could be', 'mustbe': 'must be',
      'hasbeen': 'has been', 'havebeen': 'have been', 'hadbeen': 'had been',
      'notonly': 'not only', 'butalso': 'but also', 'aswell': 'as well',
      'eachother': 'each other', 'oneanother': 'one another',
      'sothat': 'so that', 'inorder': 'in order', 'evenif': 'even if',
      'suchas': 'such as', 'morethan': 'more than', 'lessthan': 'less than',
      'outof': 'out of', 'dueto': 'due to', 'inspite': 'in spite',
      'becauseof': 'because of', 'insteadof': 'instead of',
      'accordingto': 'according to', 'forexample': 'for example',
      'forinstance': 'for instance',
    };
    
    commonMerges.forEach((key, value) {
      text = text.replaceAll(RegExp(r'\b' + key + r'\b'), value);
    });
    
    return text;
  }
  
  // Stage 7: Normalize whitespace
  String _normalizeWhitespace(String text) {
    return text
        // Replace multiple spaces with single space
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        // Remove spaces at start/end of lines
        .replaceAll(RegExp(r'[ \t]+\n'), '\n')
        .replaceAll(RegExp(r'\n[ \t]+'), '\n')
        // Normalize line endings
        .replaceAll(RegExp(r'\r\n'), '\n');
  }
  
  // Stage 8: Remove page numbers
  String _removePageNumbers(String text) {
    // Remove standalone numbers (likely page numbers)
    text = text.replaceAll(RegExp(r'^\s*\d+\s*$', multiLine: true), '');
    
    // Remove lines with just "Page X" or similar
    text = text.replaceAll(RegExp(r'^\s*(Page|PAGE|page)\s+\d+\s*$', multiLine: true), '');
    
    return text;
  }
  
  // Analyze text quality to detect potential issues
  Map<String, dynamic> analyzeTextQuality(String text) {
    final words = text.split(RegExp(r'\s+'));
    final totalWords = words.length;
    
    if (totalWords == 0) {
      return {
        'quality': 'empty',
        'score': 0.0,
        'issues': ['No text extracted'],
      };
    }
    
    final issues = <String>[];
    double score = 100.0;
    
    // Check for excessive non-alphabetic characters (poor OCR)
    final nonAlphaCount = text.replaceAll(RegExp(r'[a-zA-Z\s]'), '').length;
    final nonAlphaRatio = nonAlphaCount / text.length;
    if (nonAlphaRatio > 0.3) {
      issues.add('High number of non-alphabetic characters (${(nonAlphaRatio * 100).toStringAsFixed(1)}%)');
      score -= 30;
    }
    
    // Check for very short words (potential OCR errors)
    final veryShortWords = words.where((w) => w.length == 1 && !['a', 'i', 'A', 'I'].contains(w)).length;
    if (veryShortWords > totalWords * 0.2) {
      issues.add('Many single-character words (${(veryShortWords / totalWords * 100).toStringAsFixed(1)}%)');
      score -= 20;
    }
    
    // Check for excessive numbers (might be a table or data page)
    final numberWords = words.where((w) => RegExp(r'^\d+$').hasMatch(w)).length;
    if (numberWords > totalWords * 0.5) {
      issues.add('Page appears to contain mostly numbers');
      score -= 10;
    }
    
    // Determine quality level
    String quality;
    if (score >= 80) {
      quality = 'excellent';
    } else if (score >= 60) {
      quality = 'good';
    } else if (score >= 40) {
      quality = 'fair';
    } else {
      quality = 'poor';
    }
    
    return {
      'quality': quality,
      'score': score,
      'wordCount': totalWords,
      'issues': issues,
    };
  }
  
  // Batch extract multiple pages efficiently
  Future<Map<int, String>> extractMultiplePages(
    PdfDocument document,
    List<int> pageIndices, {
    TextExtractionConfig? config,
    String? cachePath,
    void Function(int completed, int total)? onProgress,
  }) async {
    final results = <int, String>{};
    
    for (var i = 0; i < pageIndices.length; i++) {
      final pageIndex = pageIndices[i];
      results[pageIndex] = extractPageText(
        document,
        pageIndex,
        config: config,
        cachePath: cachePath,
      );
      
      // Report progress
      onProgress?.call(i + 1, pageIndices.length);
      
      // Yield to event loop every 5 pages
      if (i % 5 == 0) {
        await Future.delayed(Duration.zero);
      }
    }
    
    return results;
  }
}
