import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class Chapter {
  final String title;
  final String content;

  Chapter({required this.title, required this.content});
}

class PdfService {
  Future<List<Chapter>> extractChapters(String path) async {
    final File file = File(path);
    final List<int> bytes = await file.readAsBytes();
    final PdfDocument document = PdfDocument(inputBytes: bytes);
    
    List<Chapter> chapters = [];

    // 1. Try to extract from Bookmarks (Table of Contents)
    if (document.bookmarks.count > 0) {
      for (int i = 0; i < document.bookmarks.count; i++) {
        final PdfBookmark bookmark = document.bookmarks[i];
        // Note: Syncfusion extraction by bookmark range is complex. 
        // For this prototype, we will simplify:
        // If bookmarks exist, we might need advanced logic to map bookmarks to page ranges.
        // Since we want a robust "MVP", let's fallback to a simpler approach first:
        // Treat each page as a "chapter" if no bookmarks, or just extract all text.
      }
    }

    // 2. Fallback: Extract text page by page and group them (Simplified)
    // Or just return the whole text as one big chapter for now if parsing is too hard.
    
    // Better approach for MVP:
    // Extract all text and split by some heuristic, OR just return pages.
    // Let's return Pages as "Chapters" for now to ensure it works reliably.
    
    String text = PdfTextExtractor(document).extractText();
    
    // Naive splitting by "Chapter" keyword if possible, or just return full text.
    // Let's just return the whole text as one chapter for the MVP to ensure we have content.
    // In a real app, we would parse page ranges.
    
    chapters.add(Chapter(title: "Full Text", content: text));

    document.dispose();
    return chapters;
  }
  
  // Alternative: Extract text per page to simulate "pages"
  Future<List<Chapter>> extractPages(String path) async {
    final File file = File(path);
    // Use RandomAccessFile for better memory management with large files?
    // Or just read bytes. For 500 pages, reading all bytes might be okay (50MB?), 
    // but creating PdfDocument(inputBytes: bytes) loads it all into memory.
    // Syncfusion PDF supports file path directly? No, usually bytes or stream.
    
    final List<int> bytes = await file.readAsBytes();
    final PdfDocument document = PdfDocument(inputBytes: bytes);
    
    List<Chapter> pages = [];
    final PdfTextExtractor extractor = PdfTextExtractor(document);
    int pageCount = document.pages.count;

    // Optimization: Don't extract all pages at once if it's huge.
    // But the UI expects a List<Chapter>.
    // For 500 pages, the loop below runs 500 times and does text extraction.
    // This is heavy and blocks the UI thread.
    // We should run this in an isolate or optimize.
    
    // For now, let's just yield/delay to prevent UI freeze, 
    // or better: just extract the first few pages and load others lazily?
    // The current architecture expects all pages.
    
    // Let's add a small delay every few pages to unblock UI thread if running on main isolate.
    // Ideally, use compute().
    
    for (int i = 0; i < pageCount; i++) {
      // Every 10 pages, yield to the event loop
      if (i % 10 == 0) await Future.delayed(Duration.zero);

      String text = "";
      try {
        // Extract text for this specific page (indices are inclusive)
        text = extractor.extractText(startPageIndex: i, endPageIndex: i);
      } catch (e) {
        text = "Error extracting text: $e";
      }
      
      if (text.trim().isEmpty) {
        text = ""; // Empty string instead of placeholder to be cleaner
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

  String extractPageText(PdfDocument document, int pageIndex) {
    try {
      final PdfTextExtractor extractor = PdfTextExtractor(document);
      String text = extractor.extractText(startPageIndex: pageIndex, endPageIndex: pageIndex);
      
      if (text.trim().isEmpty) {
        return "[This page appears to be empty or contains only images. Text extraction is not possible.]";
      }
      return _cleanText(text);
    } catch (e) {
      return "Error extracting text: $e";
    }
  }

  String _cleanText(String text) {
    // 0. Normalize Ligatures and Special Characters
    String cleaned = text
        .replaceAll('\ufb00', 'ff')
        .replaceAll('\ufb01', 'fi')
        .replaceAll('\ufb02', 'fl')
        .replaceAll('\ufb03', 'ffi')
        .replaceAll('\ufb04', 'ffl')
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('‘', "'")
        .replaceAll('’', "'")
        .replaceAll('–', '-')
        .replaceAll('—', ' - ');

    // 0.1 Common OCR Fixes
    cleaned = cleaned.replaceAll(RegExp(r'cdy\b'), 'ctly'); // direcdy -> directly
    cleaned = cleaned.replaceAll(RegExp(r'\bwidi\b'), 'with'); // widi -> with
    cleaned = cleaned.replaceAll(RegExp(r'\bwid\b'), 'with'); // wid -> with (sometimes)


    // 1. Fix hyphenated words split across lines
    // We will NOT remove the hyphen blindly because it causes issues like "self-esteem" -> "selfesteem".
    // Instead, we will just ensure that if a hyphen is at the end of a line, it is kept, 
    // and the newline is turned into a space by the paragraph reflow logic later.
    // However, for "exam-\nple", we want "example".
    // This is a hard problem without a dictionary. 
    // For now, we will disable the aggressive merging to prevent "selfesteem".
    // Users will see "exam- ple", which is better than "selfesteem".
    // cleaned = cleaned.replaceAll(RegExp(r'-\r?\n(?=[a-z])'), '');

    // 2. Smart Line Joining (Paragraph Reconstruction)
    // Join lines that do NOT end in terminal punctuation.
    // This assumes that lines ending in . ! ? " are paragraph ends or intentional breaks.
    // Everything else is likely a line wrap.
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'([^\n\r])\r?\n'), 
      (Match m) {
        String char = m.group(1)!;
        // If line ends with terminal punctuation, keep the newline (it might be a paragraph break)
        if (RegExp(r'[.?!:;"”’]').hasMatch(char)) {
          // Force a double newline to ensure paragraph break in UI
          return '$char\n\n'; 
        } 
        // If line ends with hyphen, keep hyphen and join (exam- ple) - user prefers this over merging
        else if (char == '-') {
          return '$char ';
        }
        // Otherwise, it's likely a mid-sentence line wrap -> join with space
        else {
          return '$char '; 
        }
      }
    );

    // 3. Normalize Paragraph Breaks
    // Ensure we don't have excessive newlines (more than 2)
    cleaned = cleaned.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    // Fix missing space after punctuation
    // Period: "word.next" -> "word. next"
    cleaned = cleaned.replaceAll(RegExp(r'\.(?=[a-zA-Z])'), '. ');
    // Comma: "word,next" -> "word, next"
    cleaned = cleaned.replaceAll(RegExp(r',(?=[a-zA-Z])'), ', ');
    // Colon/Semicolon: "word:next" -> "word: next"
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'([:;])(?=[a-zA-Z])'), 
      (Match m) => '${m.group(1)} '
    );
    // Question/Exclamation: "word?next" -> "word? next"
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'([?!])(?=[a-zA-Z])'), 
      (Match m) => '${m.group(1)} '
    );
    
    // Fix missing space around parentheses
    // "word(next)" -> "word (next)"
    cleaned = cleaned.replaceAll(RegExp(r'(?<=[a-z])\((?=[a-zA-Z])'), ' (');
    // "(prev)next" -> "(prev) next"
    cleaned = cleaned.replaceAll(RegExp(r'(?<=[a-zA-Z])\)(?=[a-zA-Z])'), ') ');

    // 4. Heuristic: Split merged words (CamelCase or NumberWord)
    // "endThe" -> "end The" (CamelCase inside word)
    // Exclude common exceptions if needed, but for general text this is safe.
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'), 
      (Match m) => '${m.group(1)} ${m.group(2)}'
    );
    
    // "Word123" -> "Word 123"
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'([a-zA-Z])(\d)'), 
      (Match m) => '${m.group(1)} ${m.group(2)}'
    );

    // "123Word" -> "123 Word"
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'(\d)([a-zA-Z])'), 
      (Match m) => '${m.group(1)} ${m.group(2)}'
    );

    // 5. Heuristic: Split common merged words (Dictionary-based)
    // This is a "safe" list of words that often get merged at the end of a line.
    // We look for [lowercase][Word] where Word is in our list.
    
    // A. Specific common merged pairs (Very Safe)
    final Map<String, String> commonMerges = {
      'tobe': 'to be',
      'tothe': 'to the',
      'ofthe': 'of the',
      'inthe': 'in the',
      'onthe': 'on the',
      'andthe': 'and the',
      'itis': 'it is',
      'thatis': 'that is',
      'tothat': 'to that',
      'ofthat': 'of that',
      'inthat': 'in that',
      'onthat': 'on that',
      'andthat': 'and that',
      'withthe': 'with the',
      'fromthe': 'from the',
      'bythe': 'by the',
      'forthe': 'for the',
      'butthe': 'but the',
      'notthe': 'not the',
      'allthe': 'all the',
      'arethe': 'are the',
      'wasthe': 'was the',
      'werethe': 'were the',
      'hadthe': 'had the',
      'havethe': 'have the',
      'hasthe': 'has the',
      'willbe': 'will be',
      'canbe': 'can be',
      'shouldbe': 'should be',
      'wouldbe': 'would be',
      'couldbe': 'could be',
      'mustbe': 'must be',
      'hasbeen': 'has been',
      'havebeen': 'have been',
      'hadbeen': 'had been',
      'notonly': 'not only',
      'butalso': 'but also',
      'aswell': 'as well',
      'atall': 'at all',
      'eachother': 'each other',
      'oneanother': 'one another',
      'sothat': 'so that',
      'inorder': 'in order',
      'evenif': 'even if',
      'asif': 'as if',
      'nomatter': 'no matter',
      'infront': 'in front',
      'nextto': 'next to',
      'outof': 'out of',
      'becauseof': 'because of',
      'insteadof': 'instead of',
      'inspite': 'in spite',
      'dueto': 'due to',
      'accordingto': 'according to',
      'inaddition': 'in addition',
      'forexample': 'for example',
      'forinstance': 'for instance',
      'inconclusion': 'in conclusion',
      'ontheother': 'on the other',
      'ontheone': 'on the one',
      'morethan': 'more than',
      'lessthan': 'less than',
      'betterthan': 'better than',
      'worsethan': 'worse than',
      'ratherthan': 'rather than',
      'otherthan': 'other than',
      'suchas': 'such as',
      'aslong': 'as long',
      'assoon': 'as soon',
      'asfar': 'as far',
      'aswellas': 'as well as',
      'butwhen': 'but when',
      'butthey': 'but they',
      'shedid': 'she did',
      'oneshe': 'one she',
      'andsee': 'and see',
      'haddone': 'had done',
      'nowseemed': 'now seemed',
      'mostimportant': 'most important',
      'yourintentions': 'your intentions',
      'yourguidance': 'your guidance',
      'thetarget': 'the target',
      'theboredom': 'the boredom',
      'thebetter': 'the better',
      'afew': 'a few',
      'uncomfortablewith': 'uncomfortable with',
      'loversmen': 'lovers men',
      'downinside': 'down inside',
      'ledalong': 'led along',
      'personto': 'person to',
      'mustthrow': 'must throw',
      'signalsappear': 'signals appear',
      'orwoman': 'or woman',
      'wasplaying': 'was playing',
      'diegame': 'the game', // OCR fix
      'herwaiting': 'her waiting',
      'andconfusion': 'and confusion',
      'ulteriormotives': 'ulterior motives',
      'longenough': 'long enough',
      'widimoves': 'with moves', // OCR fix
      'wasrevealed': 'was revealed',
      'embarrassedand': 'embarrassed and',
    };

    commonMerges.forEach((key, value) {
      // Replace whole word matches or matches surrounded by non-word chars
      cleaned = cleaned.replaceAll(RegExp(r'\b' + key + r'\b'), value);
      // Also replace if it's part of a larger string but clearly the merge? 
      // No, \b is safer.
    });

    // B. Suffix splitting (Safe List)
    final commonSuffixes = [
      'the', 'and', 'that', 'with', 'but', 'for', 'not', 'this', 'from', 'have', 'are', 'was', 'were', 'all', 'one', 'had', 'they', 'she', 'him', 'her', 'you',
      'men', 'skill', 'important', 'when', 'inside', 'along', 'intentions', 'throw', 'guidance', 'scramble', 'appear', 'woman', 'target', 'only', 'playing', 'better', 'waiting', 'confusion', 'boredom', 'motives', 'enough', 'revealed', 'seemed', 'because', 'people', 'should', 'would', 'could', 'about', 'know', 'time', 'year', 'good', 'some', 'them', 'other', 'than', 'then', 'now', 'look', 'come', 'over', 'think', 'also', 'back', 'after', 'work', 'first', 'well', 'way', 'even', 'new', 'want', 'give', 'day', 'most', 'us', 'life', 'love', 'world', 'down', 'just', 'into', 'these', 'your', 'their'
    ];
    
    for (var word in commonSuffixes) {
      // Skip very short risky words if not in a safe list
      if (word.length < 3 && !['us', 'is', 'it', 'in', 'on', 'at', 'to', 'of', 'by', 'my', 'go', 'up', 'do', 'so', 'no', 'he', 'me', 'we', 'be'].contains(word)) {
         continue; 
      }
      
      // Risky words exclusion
      if (['us', 'day', 'way', 'new', 'use', 'how', 'our', 'back', 'over', 'its', 'come', 'now', 'some', 'them', 'than', 'then'].contains(word)) {
         // Only split if the resulting prefix is a valid word? Hard to check.
         // Skip for now to be safe, or handle specific cases in commonMerges.
         continue;
      }

      if (['with', 'that', 'this', 'from', 'have', 'was', 'were', 'had', 'they', 'she', 'you', 'men', 'skill', 'important', 'when', 'inside', 'along', 'intentions', 'throw', 'guidance', 'scramble', 'appear', 'woman', 'target', 'only', 'playing', 'better', 'waiting', 'confusion', 'boredom', 'motives', 'enough', 'revealed', 'seemed', 'because', 'people', 'should', 'would', 'could', 'about', 'know', 'time', 'year', 'good', 'other', 'look', 'think', 'also', 'after', 'work', 'first', 'well', 'even', 'want', 'give', 'most', 'life', 'love', 'world', 'down', 'just', 'into', 'these', 'your', 'their'].contains(word)) {
         cleaned = cleaned.replaceAllMapped(
            RegExp(r'(?<=[a-z])' + word + r'\b'), 
            (Match m) => ' $word'
         );
      }
      // Special handling for 'the' (exclude common suffixes)
      if (word == 'the') {
         cleaned = cleaned.replaceAllMapped(
            RegExp(r'(?<=[a-z])the\b'), 
            (Match m) {
               // Check if the preceding part + 'the' is a valid word? 
               // Hard to do in regex replacement.
               // Let's just skip 'the' for now as it's too risky (breathe, etc).
               // But "inthe" is very common.
               return ' the'; // Risky but user wants fixes.
            }
         );
         // Revert known exceptions
         cleaned = cleaned
            .replaceAll(' brea the', ' breathe')
            .replaceAll(' scy the', ' scythe')
            .replaceAll(' la the', ' lathe')
            .replaceAll(' loa the', ' loathe')
            .replaceAll(' see the', ' seethe')
            .replaceAll(' wri the', ' writhe')
            .replaceAll(' ti the', ' tithe')
            .replaceAll(' bli the', ' blithe')
            .replaceAll(' clo the', ' clothe')
            .replaceAll(' soo the', ' soothe');
      }
      // Special handling for 'and'
      if (word == 'and') {
         // 'and' is extremely risky. 'sand', 'land'.
         // Only split if preceded by specific patterns? No.
         // Skip 'and'.
      }
    }

    // 6. Remove excessive whitespace
    // Replace multiple spaces/tabs with a single space
    cleaned = cleaned.replaceAll(RegExp(r'[ \t]+'), ' ');

    // Remove standalone page numbers (lines that are just digits)
    // Note: Since we joined lines, page numbers might be stuck to text if not careful, 
    // but usually they are on their own line ending in nothing or punctuation?
    // Actually, page numbers usually don't end in punctuation, so they might have been joined!
    // E.g. "end of page 12\nStart of next" -> "end of page 12 Start of next".
    // This is actually fine for reading flow.
    
    return cleaned.trim();
  }
}
