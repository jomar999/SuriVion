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

class _HomeScreenState extends State<HomeScreen> {
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  bool _isVoiceAvailable = false;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _initializeVoiceCommand();
  }

  Future<void> _initializeVoiceCommand() async {
    final isAvailable = await _speech.initialize(
      onStatus: (status) {
        final normalized = status.toLowerCase();
        if ((normalized == 'done' || normalized == 'notlistening') &&
            mounted &&
            _isVoiceAvailable &&
            !_isNavigating) {
          _startListening();
        }
      },
      onError: (_) {
        if (mounted && _isVoiceAvailable && !_isNavigating) {
          _startListening();
        }
      },
    );

    if (!isAvailable) {
      if (!mounted) return;
      return;
    }

    if (!mounted) return;
    setState(() {
      _isVoiceAvailable = true;
    });

    _startListening();
  }

  Future<void> _startListening() async {
    if (!_isVoiceAvailable || _speech.isListening || _isNavigating) {
      return;
    }

    if (mounted) {
      setState(() {
        _isListening = true;
      });
    }

    await _speech.listen(
      listenFor: Duration(seconds: 30),
      onResult: (result) {
        final command = result.recognizedWords.toLowerCase().trim();

        if (command.contains('open ai assistant') && !_isNavigating) {
          _isNavigating = true;
          _speech.stop();
          setState(() {
            _isListening = false;
          });

          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ChatScreen()),
          ).then((_) {
            _isNavigating = false;
            _startListening();
          });
        }
      },
      onSoundLevelChange: (_) {},
      cancelOnError: true,
      partialResults: true,
    );
  }

  @override
  void dispose() {
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
              _isVoiceAvailable
                  ? (_isListening
                        ? 'Voice command active: say "open ai assistant"'
                        : 'Voice command ready')
                  : 'Voice command unavailable on this device',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              textAlign: TextAlign.center,
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
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChatScreen()),
                );
              },
              child: Text("Ask AI Assistant", style: TextStyle(fontSize: 20)),
            ),
          ],
        ),
      ),
    );
  }
}
