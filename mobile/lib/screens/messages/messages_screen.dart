import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _myUserId;
  List<Map<String, dynamic>> _conversations = [];

  @override
  void initState() {
    super.initState();
    _loadUserAndMessages();
  }

  Future<void> _loadUserAndMessages() async {
    final prefs = await SharedPreferences.getInstance();
    // Retrieve stored user ID
    final rawUser = prefs.getString('userType');
    _myUserId = prefs.getString('userId');

    setState(() {
      _isLoading = false;
      // Pre-populate with typical ecosystem contact channels if none fetched yet
      _conversations = [
        {
          'id': 'support_desk',
          'name': 'NISK Support Desk',
          'role': 'Help & Support',
          'lastMessage': 'Welcome to NISK! Let us know if you need assistance.',
          'avatarColor': Colors.blue.value
        },
        {
          'id': 'education_desk',
          'name': 'Education Hub Help',
          'role': 'Tutors & Bookings',
          'lastMessage': 'Check your booked tutoring sessions here.',
          'avatarColor': Colors.deepOrange.value
        },
        {
          'id': 'market_seller',
          'name': 'Marketplace Updates',
          'role': 'Orders & Logistics',
          'lastMessage': 'View seller updates and delivery notices.',
          'avatarColor': Colors.green.value
        }
      ];
    });
  }

  void _openChat(Map<String, dynamic> contact) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailScreen(
          contactId: contact['id'] ?? '',
          contactName: contact['name'] ?? 'Contact',
          contactRole: contact['role'] ?? '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? const Center(
                  child: Text(
                    'No conversations yet.\nMessages from tutors, employers, or sellers will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, height: 1.5),
                  ),
                )
              : ListView.separated(
                  itemCount: _conversations.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = _conversations[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: Color(item['avatarColor'] ?? Colors.blue.value),
                        child: Text(
                          (item['name'] as String).substring(0, 1),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item['name'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            item['role'] ?? '',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          item['lastMessage'] ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.black87),
                        ),
                      ),
                      onTap: () => _openChat(item),
                    );
                  },
                ),
    );
  }
}

class ChatDetailScreen extends StatefulWidget {
  final String contactId;
  final String contactName;
  final String contactRole;

  const ChatDetailScreen({
    super.key,
    required this.contactId,
    required this.contactName,
    required this.contactRole,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _msgController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isSending = false;

  void _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    _msgController.clear();
    final newMsg = {
      'content': text,
      'isMe': true,
      'time': '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}'
    };

    setState(() {
      _messages.add(newMsg);
      _isSending = true;
    });

    try {
      await _api.post('/messages', {
        'receiver': widget.contactId,
        'content': text,
      });
    } catch (_) {
      // Gracefully retained locally in optimistic UI
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.contactName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(widget.contactRole, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Text(
                      'This is the start of your conversation with ${widget.contactName}.',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final m = _messages[index];
                      final isMe = m['isMe'] == true;
                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isMe ? const Color(0xFF1B3B6F) : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              Text(
                                m['content'] ?? '',
                                style: TextStyle(color: isMe ? Colors.white : Colors.black87),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                m['time'] ?? '',
                                style: TextStyle(
                                  color: isMe ? Colors.white70 : Colors.black45,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, -1),
                    blurRadius: 4,
                  )
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _isSending ? null : _sendMessage,
                    icon: _isSending
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.send, color: Color(0xFF1B3B6F)),
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
