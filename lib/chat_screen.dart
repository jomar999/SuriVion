import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChatScreen extends StatefulWidget {
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const String _defaultChatEndpoint = 'http://127.0.0.1:5000/chat';
  static const String _chatEndpointFromEnv = String.fromEnvironment(
    'CHAT_ENDPOINT',
    defaultValue: _defaultChatEndpoint,
  );
  static final String _chatEndpoint = _chatEndpointFromEnv.trim().isEmpty
      ? _defaultChatEndpoint
      : _chatEndpointFromEnv;
  static const Duration _requestTimeout = Duration(seconds: 75);

  final TextEditingController _controller = TextEditingController();
  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(_ChatMessage(role: _Role.user, text: text));
      _isLoading = true;
      _controller.clear();
    });

    try {
      final response = await http
          .post(
            Uri.parse(_chatEndpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'message': text}),
          )
          .timeout(_requestTimeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final reply = (decoded['reply'] ?? '').toString();

        setState(() {
          _messages.add(
            _ChatMessage(
              role: _Role.bot,
              text: reply.isEmpty ? 'No reply from server.' : reply,
            ),
          );
        });
      } else {
        String serverMessage = '';
        try {
          final decoded = jsonDecode(response.body) as Map<String, dynamic>;
          serverMessage = (decoded['error'] ?? '').toString();
        } catch (_) {}

        setState(() {
          _messages.add(
            _ChatMessage(
              role: _Role.system,
              text: serverMessage.isEmpty
                  ? 'Server error (${response.statusCode}).'
                  : 'Server error (${response.statusCode}): $serverMessage',
            ),
          );
        });
      }
    } on TimeoutException {
      setState(() {
        _messages.add(
          _ChatMessage(
            role: _Role.system,
            text:
                'Request timed out after ${_requestTimeout.inSeconds}s. If using free Render, first request can take up to ~60s while the service wakes up. Try once more.',
          ),
        );
      });
    } on SocketException {
      setState(() {
        _messages.add(
          _ChatMessage(
            role: _Role.system,
            text: 'Network error. Could not reach $_chatEndpoint',
          ),
        );
      });
    } catch (_) {
      setState(() {
        _messages.add(
          _ChatMessage(
            role: _Role.system,
            text: 'Could not reach backend. Check IP, port, and Wi-Fi.',
          ),
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('SuriVion AI Assistant')),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Text(
                      'Ask about recycling, sorting, and disposal tips.',
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isUser = message.role == _Role.user;

                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: EdgeInsets.symmetric(vertical: 6),
                          padding: EdgeInsets.all(12),
                          constraints: BoxConstraints(maxWidth: 320),
                          decoration: BoxDecoration(
                            color: isUser
                                ? Colors.green.shade100
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(message.text),
                        ),
                      );
                    },
                  ),
          ),
          if (_isLoading)
            Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: CircularProgressIndicator(),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Ask Gemini...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _sendMessage,
                    child: Text('Send'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _Role { user, bot, system }

class _ChatMessage {
  final _Role role;
  final String text;

  _ChatMessage({required this.role, required this.text});
}
