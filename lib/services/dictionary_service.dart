import 'dart:convert';
import 'package:http/http.dart' as http;
import 'pos_tagger.dart';
import '../config/api_config.dart';

class DefinitionResult {
  final String definition;
  final String partOfSpeech;
  final bool isBestMatch;
  final String? phonetic;
  final String? audioUrl;
  final String? example;
  final List<String> synonyms;
  final String source; // 'merriam-webster' or 'free-dictionary'

  DefinitionResult({
    required this.definition,
    required this.partOfSpeech,
    this.isBestMatch = false,
    this.phonetic,
    this.audioUrl,
    this.example,
    this.synonyms = const [],
    this.source = 'free-dictionary',
  });
}

class DictionaryService {
  
  static const String _merriamWebsterBaseUrl = 'https://www.dictionaryapi.com/api/v3/references/collegiate/json/';
  static const String _fallbackBaseUrl = 'https://api.dictionaryapi.dev/api/v2/entries/en/';

  Future<List<DefinitionResult>> getDefinitions(String word, {String? contextSentence}) async {
    // Try Merriam-Webster API first if configured
    if (ApiConfig.isMerriamWebsterConfigured) {
      try {
        final results = await _getMerriamWebsterDefinitions(word, contextSentence);
        if (results.isNotEmpty) {
          return results;
        }
      } catch (e) {
        print('Merriam-Webster API error, falling back: $e');
      }
    }
    
    // Fallback to Free Dictionary API
    return await _getFreeDictionaryDefinitions(word, contextSentence);
  }

  Future<List<DefinitionResult>> _getMerriamWebsterDefinitions(String word, String? contextSentence) async {
    try {
      final encodedWord = Uri.encodeComponent(word.toLowerCase());
      final url = '$_merriamWebsterBaseUrl$encodedWord?key=${ApiConfig.merriamWebsterApiKey}';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        
        // Check if response is a list of strings (suggestions) - means word not found
        if (data is List && data.isNotEmpty && data[0] is String) {
          return [];
        }

        if (data is List && data.isNotEmpty) {
          String? guessedPos;
          if (contextSentence != null) {
            guessedPos = PosTagger.guessPos(word, contextSentence);
          }

          List<DefinitionResult> results = [];

          for (var entry in data) {
            if (entry is! Map) continue;
            
            // Get word metadata
            final meta = entry['meta'] as Map<String, dynamic>?;
            if (meta == null) continue;

            // Get part of speech
            final partOfSpeech = entry['fl'] as String? ?? 'unknown';
            
            // Get pronunciation
            String? phonetic;
            String? audioUrl;
            final hwi = entry['hwi'] as Map<String, dynamic>?;
            if (hwi != null) {
              final prs = hwi['prs'] as List<dynamic>?;
              if (prs != null && prs.isNotEmpty) {
                final pr = prs[0] as Map<String, dynamic>?;
                if (pr != null) {
                  phonetic = pr['mw'] as String?;
                  final sound = pr['sound'] as Map<String, dynamic>?;
                  if (sound != null) {
                    final audio = sound['audio'] as String?;
                    if (audio != null && audio.isNotEmpty) {
                      // Construct audio URL
                      final subdirectory = audio.startsWith('bix') ? 'bix' :
                                         audio.startsWith('gg') ? 'gg' :
                                         audio.startsWith('_') ? 'number' :
                                         audio[0];
                      audioUrl = 'https://media.merriam-webster.com/audio/prons/en/us/mp3/$subdirectory/$audio.mp3';
                    }
                  }
                }
              }
            }

            // Get definitions
            final def = entry['def'] as List<dynamic>?;
            if (def == null || def.isEmpty) continue;

            for (var defSection in def) {
              final sseq = defSection['sseq'] as List<dynamic>?;
              if (sseq == null) continue;

              for (var sense in sseq) {
                if (sense is! List || sense.isEmpty) continue;
                
                for (var item in sense) {
                  if (item is! List || item.length < 2) continue;
                  if (item[0] != 'sense') continue;
                  
                  final senseData = item[1] as Map<String, dynamic>?;
                  if (senseData == null) continue;

                  final dt = senseData['dt'] as List<dynamic>?;
                  if (dt == null) continue;

                  String? definition;
                  String? example;
                  
                  for (var dtItem in dt) {
                    if (dtItem is! List || dtItem.length < 2) continue;
                    
                    if (dtItem[0] == 'text') {
                      // Clean up the text (remove markup like {bc}, {sx||})
                      final text = dtItem[1] as String;
                      definition = text
                          .replaceAll(RegExp(r'\{bc\}'), '')
                          .replaceAll(RegExp(r'\{sx\|([^|]+)\|\|?\}'), r'$1')
                          .replaceAll(RegExp(r'\{a_link\|([^}]+)\}'), r'$1')
                          .replaceAll(RegExp(r'\{wi\}([^{]+)\{/wi\}'), r'$1')
                          .trim();
                    } else if (dtItem[0] == 'vis') {
                      final vis = dtItem[1] as List<dynamic>?;
                      if (vis != null && vis.isNotEmpty) {
                        final visItem = vis[0] as Map<String, dynamic>?;
                        if (visItem != null) {
                          final t = visItem['t'] as String?;
                          if (t != null) {
                            example = t
                                .replaceAll(RegExp(r'\{wi\}([^{]+)\{/wi\}'), r'$1')
                                .trim();
                          }
                        }
                      }
                    }
                  }

                  if (definition != null && definition.isNotEmpty) {
                    final isMatch = guessedPos != null && 
                                   partOfSpeech.toLowerCase() == guessedPos.toLowerCase();
                    
                    results.add(DefinitionResult(
                      definition: definition,
                      partOfSpeech: partOfSpeech,
                      isBestMatch: isMatch,
                      phonetic: phonetic,
                      audioUrl: audioUrl,
                      example: example,
                      synonyms: const [],
                      source: 'merriam-webster',
                    ));
                  }
                }
              }
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
      print('Error fetching Merriam-Webster definition: $e');
      return [];
    }
  }

  Future<List<DefinitionResult>> _getFreeDictionaryDefinitions(String word, String? contextSentence) async {
    try {
      final encodedWord = Uri.encodeComponent(word);
      final response = await http.get(Uri.parse('$_fallbackBaseUrl$encodedWord'));

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
