import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../infrastructure/services/coach_service.dart';

class IAChatPage extends StatefulWidget {
  final CoachService? coachService;
  final String? uid;

  const IAChatPage({super.key, this.coachService, this.uid});

  @override
  State<IAChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<IAChatPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  late final String? _uid;
  late final CoachService _coach;

  final ScrollController _scrollController = ScrollController();
  bool _loading = false;
  static const int _maxMessages = 100; // keep persistence bounded
  String get _prefsKey => 'chat_messages_${_uid ?? 'anonymous'}';

  @override
  void initState() {
    super.initState();
    _uid = widget.uid ?? FirebaseAuth.instance.currentUser?.uid;
    _coach = widget.coachService ?? CoachService();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null) return;
      final List<dynamic> decoded = jsonDecode(raw);
      if (!mounted) return;
      setState(() {
        _messages.clear();
        for (final e in decoded) {
          if (e is Map) {
            _messages.add(
              Map<String, String>.from(
                e.map((k, v) => MapEntry(k.toString(), v.toString())),
              ),
            );
          }
        }
      });
      _scrollToEnd();
    } catch (_) {
      // ignore loading errors for minimal persistence
    }
  }

  Future<void> _saveMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // keep only the last _maxMessages
      final toSave = _messages.length > _maxMessages
          ? _messages.sublist(_messages.length - _maxMessages)
          : _messages;
      await prefs.setString(_prefsKey, jsonEncode(toSave));
    } catch (_) {
      // ignore save errors
    }
  }

  void _addMessage(Map<String, String> msg) {
    setState(() {
      _messages.add(msg);
      if (_messages.length > _maxMessages) {
        _messages.removeAt(0);
      }
    });
    _saveMessages();
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      try {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      } catch (_) {}
    });
  }

  Future<void> _sendMessage() async {
    if (_loading) return;
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final history = _messages
        .map(
          (message) => {
            'role': message['role'] == 'ai' ? 'assistant' : 'user',
            'text': message['text'] ?? '',
          },
        )
        .toList();
    _controller.clear();
    _addMessage({"role": "user", "text": text});
    setState(() => _loading = true);

    try {
      if (_uid == null) {
        throw const CoachException('Inicia sesión para usar el coach.');
      }
      final reply = await _coach.generateReply(text, history: history);
      _addMessage({"role": "ai", "text": reply});
    } on CoachException catch (error) {
      _addMessage({"role": "ai", "text": error.message});
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final msg = _messages[i];
                final isUser = msg["role"] == "user";
                return Container(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? colorScheme.primary : colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      msg["text"] ?? '',
                      style: TextStyle(
                        color: isUser
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Escribe tu mensaje...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(25)),
                      ),
                    ),
                    onSubmitted: _loading ? null : (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: colorScheme.primary),
                  onPressed: _loading ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
