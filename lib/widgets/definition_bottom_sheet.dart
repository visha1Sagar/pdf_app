import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/database_service.dart';
import '../services/dictionary_service.dart';

class DefinitionBottomSheet extends StatefulWidget {
  final String word;
  final String? contextSentence;

  const DefinitionBottomSheet({super.key, required this.word, this.contextSentence});

  @override
  State<DefinitionBottomSheet> createState() => _DefinitionBottomSheetState();
}

class _DefinitionBottomSheetState extends State<DefinitionBottomSheet> {
  List<DefinitionResult>? _definitions;
  bool _isLoading = true;
  bool _isSaved = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _fetchDefinition();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _fetchDefinition() async {
    final dictionaryService = Provider.of<DictionaryService>(context, listen: false);
    final definitions = await dictionaryService.getDefinitions(
      widget.word, 
      contextSentence: widget.contextSentence
    );
    
    if (mounted) {
      setState(() {
        _definitions = definitions;
        _isLoading = false;
      });
    }
  }

  Future<void> _playAudio(String url) async {
    try {
      await _audioPlayer.play(UrlSource(url));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not play audio')),
        );
      }
    }
  }

  Future<void> _saveWord(String definition) async {
    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    await databaseService.saveWord(widget.word, definition);
    
    if (mounted) {
      setState(() {
        _isSaved = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Word saved to vocabulary')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _launchSearchURL() async {
    final Uri url = Uri.parse('https://www.google.com/search?q=${Uri.encodeComponent(widget.word)} definition');
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch search')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Find first result with audio/phonetic for the header
    String? phonetic;
    String? audioUrl;
    if (_definitions != null && _definitions!.isNotEmpty) {
      for (var d in _definitions!) {
        if (d.phonetic != null) phonetic ??= d.phonetic;
        if (d.audioUrl != null) audioUrl ??= d.audioUrl;
      }
    }

    // Determine API source
    final apiSource = _definitions != null && _definitions!.isNotEmpty 
        ? _definitions!.first.source 
        : null;
    final isMerriamWebster = apiSource == 'merriam-webster';

    return Container(
      padding: const EdgeInsets.all(16.0),
      width: double.infinity,
      // Limit height to 70% of screen
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // API Source Indicator
          if (apiSource != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isMerriamWebster 
                    ? const Color(0xFF4CAF50).withOpacity(0.1)
                    : const Color(0xFF2196F3).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isMerriamWebster 
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFF2196F3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isMerriamWebster 
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFF2196F3),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isMerriamWebster 
                        ? 'Merriam-Webster API'
                        : 'Free Dictionary API',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isMerriamWebster 
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFF2196F3),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.word,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    if (phonetic != null)
                      Text(
                        phonetic,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontFamily: 'Arial', // Ensure phonetic chars render
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: widget.word));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Word copied to clipboard')),
                  );
                },
                icon: const Icon(Icons.copy),
                tooltip: 'Copy Word',
              ),
              if (audioUrl != null)
                IconButton(
                  onPressed: () => _playAudio(audioUrl!),
                  icon: const Icon(Icons.volume_up),
                  tooltip: 'Pronounce',
                ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_definitions != null && _definitions!.isNotEmpty)
            Expanded(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _definitions!.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final def = _definitions![index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Row(
                      children: [
                        Text(
                          def.partOfSpeech,
                          style: const TextStyle(
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        if (def.isBestMatch)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_outline, 
                                  size: 12, 
                                  color: Theme.of(context).colorScheme.primary
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Context Match',
                                  style: TextStyle(
                                    fontSize: 11, 
                                    color: Theme.of(context).colorScheme.primary, 
                                    fontWeight: FontWeight.bold
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(def.definition),
                        if (def.example != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '"${def.example}"',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                        if (def.synonyms.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: def.synonyms.take(3).map((s) => Chip(
                              label: Text(s, style: const TextStyle(fontSize: 10)),
                              padding: EdgeInsets.zero,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            )).toList(),
                          ),
                        ],
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _isSaved ? null : () => _saveWord(def.definition),
                                  child: const Text('Save this meaning'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: def.definition));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Definition copied')),
                                  );
                                },
                                icon: const Icon(Icons.copy),
                                tooltip: 'Copy Definition',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Definition not found.'),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _launchSearchURL,
                    icon: const Icon(Icons.search),
                    label: const Text('Search on Google'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
