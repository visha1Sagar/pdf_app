import 'dart:convert';
import 'package:http/http.dart' as http;
import 'pos_tagger.dart';

class DefinitionResult {
  final String definition;
  final String partOfSpeech;
  final bool isBestMatch;
  final String? phonetic;
  final String? audioUrl;
  final String? example;
  final List<String> synonyms;

  DefinitionResult({
    required this.definition,
    required this.partOfSpeech,
    this.isBestMatch = false,
    this.phonetic,
    this.audioUrl,
    this.example,
    this.synonyms = const [],
  });
}

class DictionaryService {
  static const String _baseUrl = 'https://api.dictionaryapi.dev/api/v2/entries/en/';

  Future<List<DefinitionResult>> getDefinitions(String word, {String? contextSentence}) async {
    try {
      final encodedWord = Uri.encodeComponent(word);
      final response = await http.get(Uri.parse('$_baseUrl$encodedWord'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          final entry = data[0];
          final meanings = entry['meanings'] as List<dynamic>;
          
          // Extract phonetic and audio
          String? phonetic = entry['phonetic'];
          String? audioUrl;
          final phonetics = entry['phonetics'] as List<dynamic>?;
          if (phonetics != null) {
            for (var p in phonetics) {
              if (p['text'] != null && phonetic == null) {
                phonetic = p['text'];
              }
              if (p['audio'] != null && p['audio'].toString().isNotEmpty) {
                audioUrl = p['audio'];
              }
            }
          }

          if (meanings.isEmpty) return [];

          String guessedPos = 'unknown';
          if (contextSentence != null) {
            guessedPos = PosTagger.guessPos(word, contextSentence);
          }

          List<DefinitionResult> results = [];

          for (var meaning in meanings) {
            final partOfSpeech = meaning['partOfSpeech'] as String;
            final definitions = meaning['definitions'] as List<dynamic>;
            final synonyms = (meaning['synonyms'] as List<dynamic>?)?.cast<String>() ?? [];
            
            if (definitions.isNotEmpty) {
              final defEntry = definitions[0];
              final def = defEntry['definition'] as String;
              final example = defEntry['example'] as String?;
              final isMatch = partOfSpeech.toLowerCase() == guessedPos;
              
              results.add(DefinitionResult(
                definition: def,
                partOfSpeech: partOfSpeech,
                isBestMatch: isMatch,
                phonetic: phonetic,
                audioUrl: audioUrl,
                example: example,
                synonyms: synonyms,
              ));
            }
          }

          // Sort: Best match first
          results.sort((a, b) {
            if (a.isBestMatch && !b.isBestMatch) return -1;
            if (!a.isBestMatch && b.isBestMatch) return 1;
            return 0;
          });

          return results;
        }
      }
      return [];
    } catch (e) {
      print('Error fetching definition: $e');
      return [];
    }
  }

  // Keep old method for backward compatibility if needed, or just remove it.
  // But for now, let's just replace the logic in the UI to use the new method.
  Future<String?> getDefinition(String word, {String? contextSentence}) async {
    final results = await getDefinitions(word, contextSentence: contextSentence);
    if (results.isNotEmpty) {
      return results.first.definition;
    }
    return null;
  }
}
