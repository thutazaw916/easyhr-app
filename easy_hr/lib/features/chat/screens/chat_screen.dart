import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme/app_theme.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  String? _selectedChannelId;
  String? _selectedChannelName;

  final _channels = [
    {'id': '1', 'name': 'General', 'type': 'company', 'unread': 3, 'last': 'Welcome to Easy HR!'},
    {'id': '2', 'name': 'HR Team', 'type': 'department', 'unread': 0, 'last': 'Meeting at 2pm'},
    {'id': '3', 'name': 'Engineering', 'type': 'department', 'unread': 5, 'last': 'Deploy done'},
  ];

  @override
  Widget build(BuildContext context) {
    if (_selectedChannelId != null) {
      return _buildChatView(context);
    }
    return _buildChannelList(context);
  }

  Widget _buildChannelList(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _channels.length,
        itemBuilder: (context, i) {
          final ch = _channels[i];
          final unread = ch['unread'] as int;

          return GestureDetector(
            onTap: () => setState(() {
              _selectedChannelId = ch['id'] as String;
              _selectedChannelName = ch['name'] as String;
            }),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 0.5),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: ch['type'] == 'company'
                          ? AppColors.primary.withOpacity(0.1)
                          : AppColors.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      ch['type'] == 'company' ? Iconsax.people5 : Iconsax.building,
                      color: ch['type'] == 'company' ? AppColors.primary : AppColors.accent,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ch['name'] as String, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(ch['last'] as String, style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  if (unread > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
                      child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChatView(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final msgController = TextEditingController();

    final messages = [
      {'sender': 'Admin', 'msg': 'Welcome to Easy HR! 🎉', 'time': '9:00 AM', 'isMe': false},
      {'sender': 'You', 'msg': 'Thank you!', 'time': '9:05 AM', 'isMe': true},
      {'sender': 'HR Manager', 'msg': 'Please submit your documents by Friday', 'time': '10:30 AM', 'isMe': false},
      {'sender': 'You', 'msg': 'Understood, will do!', 'time': '10:32 AM', 'isMe': true},
      {'sender': 'Admin', 'msg': 'Meeting at 2pm in conference room', 'time': '11:00 AM', 'isMe': false},
    ];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () => setState(() { _selectedChannelId = null; _selectedChannelName = null; }),
        ),
        title: Text(_selectedChannelName ?? 'Chat'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, i) {
                final m = messages[i];
                final isMe = m['isMe'] as bool;

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMe ? AppColors.primary : (isDark ? AppColors.darkCardElevated : AppColors.lightDivider),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isMe ? 16 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        if (!isMe)
                          Text(m['sender'] as String, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                        if (!isMe) const SizedBox(height: 2),
                        Text(
                          m['msg'] as String,
                          style: TextStyle(color: isMe ? Colors.white : (isDark ? AppColors.darkText : AppColors.lightText), fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        Text(m['time'] as String, style: TextStyle(color: isMe ? Colors.white60 : AppColors.lightTextSecondary, fontSize: 11)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Message Input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              border: Border(top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 0.5)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(icon: const Icon(Iconsax.attach_circle, color: AppColors.lightTextSecondary), onPressed: () {}),
                  Expanded(
                    child: TextField(
                      controller: msgController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        filled: true,
                        fillColor: isDark ? AppColors.darkCardElevated : AppColors.lightDivider,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(22)),
                    child: IconButton(
                      icon: const Icon(Iconsax.send_1, color: Colors.white, size: 20),
                      onPressed: () {},
                    ),
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