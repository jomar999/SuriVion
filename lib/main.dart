import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'chat_screen.dart';
import 'scan_screen.dart';

void main() {
  runApp(SuriVionApp());
}

class SuriVionApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SuriVion',
      theme: ThemeData(primarySwatch: Colors.green),
      home: HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  bool _isVoiceAvailable = false;
  bool _isNavigating = false;
  bool _isVoiceAssistantEnabled = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeVoiceCommand();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _isVoiceAssistantEnabled &&
        _isVoiceAvailable &&
        !_isNavigating) {
      _rearmListening();
    }
  }

  Future<void> _initializeVoiceCommand() async {
    final isAvailable = await _configureSpeech();

    if (!isAvailable) {
      if (!mounted) return;
      return;
    }

    if (!mounted) return;
    setState(() {
      _isVoiceAvailable = true;
    });

    if (_isVoiceAssistantEnabled) {
      _startListening();
    }
  }

  Future<bool> _configureSpeech() async {
    try {
      final isAvailable = await _speech.initialize(
        onStatus: (status) {
          final normalized = status.toLowerCase();
          if (mounted) {
            setState(() {
              _isListening = _speech.isListening;
            });
          }
          if ((normalized == 'done' || normalized == 'notlistening') &&
              mounted &&
              _isVoiceAssistantEnabled &&
              _isVoiceAvailable &&
              !_isNavigating) {
            Future.delayed(const Duration(milliseconds: 150), _startListening);
          }
        },
        onError: (_) {
          if (mounted &&
              _isVoiceAssistantEnabled &&
              _isVoiceAvailable &&
              !_isNavigating) {
            Future.delayed(const Duration(milliseconds: 150), _startListening);
          }
        },
      );
      return isAvailable;
    } catch (_) {
      return false;
    }
  }

  Future<void> _startListening() async {
    if (!_isVoiceAssistantEnabled ||
        !_isVoiceAvailable ||
        _speech.isListening ||
        _isNavigating) {
      return;
    }

    if (mounted) {
      setState(() {
        _isListening = true;
      });
    }

    final started = await _speech.listen(
      listenFor: Duration(seconds: 30),
      onResult: (result) {
        final command = result.recognizedWords.toLowerCase().trim();

        if (command.contains('open ai') && !_isNavigating) {
          _openChatScreen();
        }
      },
      onSoundLevelChange: (_) {},
      cancelOnError: true,
      partialResults: true,
    );

    if (!started && mounted) {
      setState(() {
        _isListening = false;
      });
    }
  }

  Future<void> _rearmListening() async {
    if (!_isVoiceAssistantEnabled || !_isVoiceAvailable || _isNavigating) {
      return;
    }

    try {
      await _speech.cancel();
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isListening = false;
      });
    }

    await Future.delayed(const Duration(milliseconds: 250));
    final ready = await _configureSpeech();
    if (!ready) return;

    await _startListening();
  }

  Future<void> _toggleVoiceAssistant() async {
    final nextEnabled = !_isVoiceAssistantEnabled;

    if (!nextEnabled) {
      try {
        await _speech.stop();
        await _speech.cancel();
      } catch (_) {}

      if (mounted) {
        setState(() {
          _isVoiceAssistantEnabled = false;
          _isListening = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isVoiceAssistantEnabled = true;
      });
    }

    await _rearmListening();
  }

  Future<void> _openChatScreen() async {
    if (_isNavigating) return;

    _isNavigating = true;

    if (_speech.isListening) {
      try {
        await _speech.stop();
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _isListening = false;
      });
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChatScreen()),
    );

    _isNavigating = false;
    await _rearmListening();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("SuriVion Waste Scanner"), centerTitle: true),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.recycling, size: 120, color: Colors.green),

            SizedBox(height: 20),

            Text(
              "SuriVion",
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 10),

            Text(
              "Offline Waste Scanner",
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),

            SizedBox(height: 8),

            Text(
              !_isVoiceAssistantEnabled
                  ? 'Voice command is turned off'
                  : _isVoiceAvailable
                  ? (_isListening
                        ? 'Voice command active: say "open ai"'
                        : 'Voice command ready')
                  : 'Voice command unavailable on this device',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 20),

            ElevatedButton(
              onPressed: _isVoiceAvailable ? _toggleVoiceAssistant : null,
              child: Text(
                _isVoiceAssistantEnabled
                    ? 'Turn Off Voice Assistant'
                    : 'Turn On Voice Assistant',
                style: TextStyle(fontSize: 16),
              ),
            ),

            SizedBox(height: 40),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ScanScreen()),
                );
              },
              child: Text("Scan Waste", style: TextStyle(fontSize: 20)),
            ),

            SizedBox(height: 20),

            ElevatedButton(
              onPressed: _openChatScreen,
              child: Text("Ask AI Assistant", style: TextStyle(fontSize: 20)),
            ),
          ],
        ),
      ),
    );
  }
}
