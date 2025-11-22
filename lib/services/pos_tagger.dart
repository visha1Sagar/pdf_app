class PosTagger {
  // Common word lists for tagging
  static const Set<String> _determiners = {
    'the', 'a', 'an', 'this', 'that', 'these', 'those', 'my', 'your', 'his', 'her', 'its', 'our', 'their'
  };
  
  static const Set<String> _prepositions = {
    'in', 'on', 'at', 'to', 'for', 'with', 'by', 'from', 'of', 'about', 'as', 'into', 'like', 'through', 'after', 'over', 'between', 'out', 'against', 'during', 'without', 'before', 'under', 'around', 'among'
  };

  static const Set<String> _pronouns = {
    'i', 'you', 'he', 'she', 'it', 'we', 'they', 'me', 'him', 'her', 'us', 'them', 'myself', 'yourself', 'himself', 'herself', 'itself', 'ourselves', 'themselves', 'who', 'whom', 'whose', 'which', 'what'
  };

  static const Set<String> _modals = {
    'can', 'could', 'shall', 'should', 'will', 'would', 'may', 'might', 'must'
  };

  static String guessPos(String word, String sentence) {
    final lowerWord = word.toLowerCase();
    final lowerSentence = sentence.toLowerCase();
    
    // Tokenize: Split by space and remove punctuation attached to words
    // We want to preserve the sequence
    final rawWords = lowerSentence.split(' ');
    final List<String> words = [];
    
    for (var w in rawWords) {
      // Remove leading/trailing punctuation
      final clean = w.replaceAll(RegExp(r'^[^a-z0-9]+|[^a-z0-9]+$'), '');
      if (clean.isNotEmpty) {
        words.add(clean);
      }
    }

    // Find index of target word
    // Note: This finds the *first* occurrence. 
    // Ideally we should pass the index from the caller, but for now this is an improvement.
    int index = words.indexOf(lowerWord);
    if (index == -1) return 'unknown';

    // Scores for each POS
    int nounScore = 0;
    int verbScore = 0;
    int adjScore = 0;
    int advScore = 0;

    // --- 1. Suffix Analysis (Morphology) ---
    if (lowerWord.endsWith('ly')) { advScore += 3; }
    if (lowerWord.endsWith('tion') || lowerWord.endsWith('sion') || lowerWord.endsWith('ness') || lowerWord.endsWith('ment') || lowerWord.endsWith('ity') || lowerWord.endsWith('ance') || lowerWord.endsWith('ence')) { nounScore += 3; }
    if (lowerWord.endsWith('ize') || lowerWord.endsWith('ise') || lowerWord.endsWith('ate') || lowerWord.endsWith('ify')) { verbScore += 3; }
    if (lowerWord.endsWith('ous') || lowerWord.endsWith('ful') || lowerWord.endsWith('able') || lowerWord.endsWith('ible') || lowerWord.endsWith('ive') || lowerWord.endsWith('al') || lowerWord.endsWith('ic')) { adjScore += 3; }
    if (lowerWord.endsWith('ing')) { verbScore += 1; nounScore += 1; adjScore += 1; } // Gerund, Participle, or Adjective
    if (lowerWord.endsWith('ed')) { verbScore += 2; adjScore += 1; }

    // --- 2. Context Analysis (Previous Word) ---
    if (index > 0) {
      final prev = words[index - 1];
      
      if (_determiners.contains(prev)) {
        nounScore += 3; // "The cat"
        adjScore += 1;  // "The big cat"
      }
      
      if (_modals.contains(prev)) {
        verbScore += 4; // "Can run"
      }
      
      if (_prepositions.contains(prev)) {
        nounScore += 2; // "In the house"
        verbScore += 1; // "In running" (Gerund)
      }
      
      if (prev == 'to') {
        verbScore += 3; // "To run"
      }
      
      if (_pronouns.contains(prev)) {
        verbScore += 2; // "He runs"
      }
    }

    // --- 3. Context Analysis (Next Word) ---
    if (index < words.length - 1) {
      final next = words[index + 1];
      
      if (_determiners.contains(next)) {
        verbScore += 2; // "ate the"
        // nounScore could be valid if it's "book the flight" -> book is verb
      }
      
      if (_prepositions.contains(next)) {
        nounScore += 1; // "house of"
        verbScore += 1; // "run to"
        adjScore += 1; // "full of"
      }
    }

    // --- 4. Default Probabilities ---
    // Nouns are most common, then verbs
    nounScore += 1;

    // --- Decision ---
    // Return the POS with the highest score
    // Map scores to map
    Map<String, int> scores = {
      'noun': nounScore,
      'verb': verbScore,
      'adjective': adjScore,
      'adverb': advScore,
    };

    var sortedKeys = scores.keys.toList(growable: false)
      ..sort((k1, k2) => scores[k2]!.compareTo(scores[k1]!));
      
    return sortedKeys.first;
  }
}
