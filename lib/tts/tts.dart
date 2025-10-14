import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:file_picker/file_picker.dart';

void main() => runApp(const MaterialApp(home: TTSApp()));

class TTSApp extends StatefulWidget {
  const TTSApp({super.key});

  @override
  State<TTSApp> createState() => _TTSAppState();
}

class _TTSAppState extends State<TTSApp> {
  final FlutterTts flutterTts = FlutterTts();
  final TextEditingController inputTTScontroller = TextEditingController();
  final TextEditingController renameController = TextEditingController();

  String? savedFilePath;
  String? selectedDir;
  double pitch = 1.0;
  double speechRate = 0.5;

  Future<void> getAvailableLanguages() async {
    try {
      List<dynamic> languages = await flutterTts.getLanguages;
      log("Supported Languages: $languages");
    } catch (e) {
      log("Error fetching languages: $e");
    }
  }

  Map<String, List<Map<String, String>>> languageVoiceOptions = {};
  Future<void> loadAvailableVoices() async {
    try {
      // all voices
      List<dynamic> voices = await flutterTts.getVoices;
      // voices by language
      Map<String, List<Map<String, String>>> voiceMap = {};

      //--
      for (var voice in voices) {
        String language = voice['language'] ?? 'Unknown';
        String name = voice['name'] ?? 'Unnamed';

        if (!voiceMap.containsKey(language)) {
          voiceMap[language] = [];
        }
        voiceMap[language]?.add({'name': name});
      }

      setState(() {
        log("Voice Map: $voiceMap");
        languageVoiceOptions = voiceMap;
      });
    } catch (e) {
      log("Error fetching voices: $e");
    }
  }

  // Language and voice options with unique voices and model
  final Map<String, List<Map<String, String>>> customLanguageVoiceOptions = {
    "en-US": [
      {"name": "en-us-x-sfg-local", "model": "model1"},
      {"name": "en-us-x-sfh-local", "model": "model2"},
    ],
    "bn-BD": [
      {"name": "bn-bd-x-ban-local", "model": "model1"},
      {"name": "bn-bd-x-bap-local", "model": "model2"},
    ],
    "hi-IN": [
      {"name": "hi-in-x-hia-local", "model": "model1"},
      {"name": "hi-in-x-hie-local", "model": "model2"},
    ],
    "ur-PK": [
      {"name": "ur-pk-x-urd-local", "model": "model1"},
      {"name": "ur-pk-x-ure-local", "model": "model2"},
    ],
    "ar-SA": [
      {"name": "ar-sa-x-ard-local", "model": "model1"},
      {"name": "ar-sa-x-are-local", "model": "model2"},
    ],
  };

  String selectedLanguage = "en-US";
  Map<String, String>? selectedVoice;

  @override
  void initState() {
    super.initState();
    getAvailableLanguages();
    loadAvailableVoices();
    selectedVoice = customLanguageVoiceOptions[selectedLanguage]!.first;
  }

  // Speak text
  Future<void> speak(String text) async {
    final voice = selectedVoice;
    await flutterTts.setLanguage(selectedLanguage);
    if (voice != null) {
      await flutterTts.setVoice({
        "name": voice["name"]!,
        "locale": selectedLanguage,
        "model": voice["model"]!, // included model
      });
    }
    await flutterTts.setPitch(pitch);
    await flutterTts.setSpeechRate(speechRate);
    await flutterTts.speak(text);
  }

  // Generate audio file
  Future<void> generateAudioFile(String text, String fileName) async {
    if (selectedDir == null) return;

    if (!fileName.endsWith('.mp3')) fileName += '.mp3';
    String filePath = "$selectedDir/$fileName";

    final voice = selectedVoice;
    await flutterTts.setLanguage(selectedLanguage);
    if (voice != null) {
      await flutterTts.setVoice({
        "name": voice["name"]!,
        "locale": selectedLanguage,
        "model": voice["model"]!, // included model
      });
    }
    await flutterTts.setPitch(pitch);
    await flutterTts.setSpeechRate(speechRate);
    await flutterTts.synthesizeToFile(text, filePath);

    setState(() => savedFilePath = filePath);

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Saved: $fileName in $selectedDir")));
  }

  // Show rename dialog
  Future<void> showRenameDialog() async {
    selectedDir = await FilePicker.platform.getDirectoryPath();
    if (selectedDir == null) return;
    if (!mounted) return;

    renameController.text = "tts_output.mp3";

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Rename File"),
            content: TextField(
              controller: renameController,
              decoration: const InputDecoration(
                labelText: "File Name",
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  generateAudioFile(
                    inputTTScontroller.text,
                    renameController.text.trim(),
                  );
                },
                child: const Text("Save"),
              ),
            ],
          ),
    );
  }

  String _languageName(String code) {
    switch (code) {
      case "en-US":
        return "English (US)";
      case "bn-BD":
        return "Bangla (Bangladesh)";
      case "hi-IN":
        return "Hindi (India)";
      case "ur-PK":
        return "Urdu (Pakistan)";
      case "ar-SA":
        return "Arabic (Saudi Arabia)";
      default:
        return code;
    }
  }

  Widget _buildControlRow({
    required String label,
    required double value,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "$label: ${value.toStringAsFixed(2)}",
          style: const TextStyle(fontSize: 16),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: onDecrement,
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: onIncrement,
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final voices = customLanguageVoiceOptions[selectedLanguage]!;

    return Scaffold(
      appBar: AppBar(title: const Text('Text → Voice')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Language dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: "Select Language",
                  border: OutlineInputBorder(),
                ),
                initialValue: selectedLanguage,
                items:
                    customLanguageVoiceOptions.keys
                        .map(
                          (lang) => DropdownMenuItem(
                            value: lang,
                            child: Text(_languageName(lang)),
                          ),
                        )
                        .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedLanguage = value;
                      selectedVoice = customLanguageVoiceOptions[value]?.first;
                    });
                  }
                },
              ),
              const SizedBox(height: 10),

              // Voice dropdown
              DropdownButtonFormField<Map<String, String>>(
                decoration: const InputDecoration(
                  labelText: "Select Voice",
                  border: OutlineInputBorder(),
                ),
                initialValue: selectedVoice,
                items:
                    voices
                        .map(
                          (voice) => DropdownMenuItem(
                            value: voice,
                            child: Text("${voice["name"]} (${voice["model"]})"),
                          ),
                        )
                        .toList(),
                onChanged: (voice) {
                  if (voice != null) {
                    setState(() {
                      selectedVoice = voice;
                    });
                  }
                },
              ),
              const SizedBox(height: 15),

              // Pitch & Speech Rate
              _buildControlRow(
                label: "Pitch",
                value: pitch,
                onIncrement: () {
                  setState(() {
                    if (pitch < 2.0) pitch += 0.1;
                  });
                },
                onDecrement: () {
                  setState(() {
                    if (pitch > 0.5) pitch -= 0.1;
                  });
                },
              ),
              const SizedBox(height: 5),
              _buildControlRow(
                label: "Speech Rate",
                value: speechRate,
                onIncrement: () {
                  setState(() {
                    if (speechRate < 1.0) speechRate += 0.1;
                  });
                },
                onDecrement: () {
                  setState(() {
                    if (speechRate > 0.1) speechRate -= 0.1;
                  });
                },
              ),
              const SizedBox(height: 15),

              // Text input
              TextField(
                controller: inputTTScontroller,
                decoration: const InputDecoration(
                  labelText: 'Enter text',
                  border: OutlineInputBorder(),
                ),
                maxLines: null,
              ),
              const SizedBox(height: 20),

              // Buttons
              Wrap(
                spacing: 15,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => speak(inputTTScontroller.text),
                    icon: const Icon(Icons.volume_up),
                    label: const Text('Speak'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => showRenameDialog(),
                    icon: const Icon(Icons.download),
                    label: const Text('Download'),
                  ),
                ],
              ),

              if (savedFilePath != null) ...[
                const SizedBox(height: 20),
                Text(
                  "Audio saved at:\n$savedFilePath",
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
