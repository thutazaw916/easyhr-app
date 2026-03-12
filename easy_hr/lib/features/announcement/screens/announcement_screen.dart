import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';

class AnnouncementScreen extends ConsumerStatefulWidget {
  const AnnouncementScreen({super.key});

  @override
  ConsumerState<AnnouncementScreen> createState() => _AnnouncementScreenState();
}

class _AnnouncementScreenState extends ConsumerState<AnnouncementScreen> {
  List<Map<String, dynamic>> _announcements = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = ref.read(apiServiceProvider);
      final data = await api.getAnnouncements();
      if (mounted) {
        setState(() {
          _announcements = List<Map<String, dynamic>>.from(data);
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('[Announcements] load error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  String _timeAgo(String? dateStr) {
    if (dateStr == null) return '';
    final d = DateTime.tryParse(dateStr);
    if (d == null) return dateStr;
    final diff = DateTime.now().difference(d.toLocal());
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(d.toLocal());
  }

  String _creatorName(dynamic creator) {
    if (creator is Map<String, dynamic>) {
      final fn = creator['first_name'] ?? '';
      final ln = creator['last_name'] ?? '';
      final name = '$fn $ln'.trim();
      return name.isNotEmpty ? name : 'Admin';
    }
    return 'Admin';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(title: const Text('Announcements')),
      floatingActionButton: (user?.isAdmin ?? false)
          ? FloatingActionButton(
              onPressed: () => _showCreateSheet(context),
              backgroundColor: AppColors.primary,
              child: const Icon(Iconsax.add, color: Colors.white),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _announcements.isEmpty
                  ? ListView(children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                      Center(child: Column(children: [
                        Icon(Iconsax.message_text, size: 48, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                        const SizedBox(height: 12),
                        Text('No announcements yet', style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                      ])),
                    ])
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _announcements.length,
                      itemBuilder: (context, i) {
                        final a = _announcements[i];
                        final isHigh = a['priority'] == 'high';
                        final isPinned = a['is_pinned'] == true;
                        final isRead = a['is_read'] == true;
                        final title = a['title']?.toString() ?? '';
                        final content = a['content']?.toString() ?? '';
                        final creator = _creatorName(a['creator']);
                        final timeAgo = _timeAgo(a['created_at']?.toString());

                        return GestureDetector(
                          onTap: () => _showDetail(context, a),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCard : AppColors.lightCard,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isHigh
                                    ? AppColors.error.withOpacity(0.4)
                                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                width: isHigh ? 1.5 : 0.5,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  if (isPinned) _badge('Pinned', AppColors.warning, Iconsax.attach_square),
                                  if (isHigh) _badge('Important', AppColors.error, null),
                                  const Spacer(),
                                  if (!isRead) Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                                ]),
                                const SizedBox(height: 10),
                                Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: isRead ? FontWeight.w500 : FontWeight.w700)),
                                const SizedBox(height: 6),
                                Text(content, maxLines: 2, overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                                const SizedBox(height: 12),
                                Row(children: [
                                  Icon(Iconsax.user, size: 14, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                  const SizedBox(width: 4),
                                  Text(creator, style: Theme.of(context).textTheme.bodySmall),
                                  const SizedBox(width: 16),
                                  Icon(Iconsax.clock, size: 14, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                  const SizedBox(width: 4),
                                  Text(timeAgo, style: Theme.of(context).textTheme.bodySmall),
                                ]),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  Widget _badge(String label, Color color, IconData? icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 12, color: color), const SizedBox(width: 2)],
        Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  void _showDetail(BuildContext context, Map<String, dynamic> a) {
    // Mark as read
    final id = a['id']?.toString();
    if (id != null && a['is_read'] != true) {
      ref.read(apiServiceProvider).markAnnouncementRead(id);
      setState(() => a['is_read'] = true);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        expand: false,
        builder: (context, sc) => Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: sc,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text(a['title']?.toString() ?? '', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Iconsax.user, size: 14), const SizedBox(width: 4),
                Text(_creatorName(a['creator']), style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(width: 16),
                const Icon(Iconsax.clock, size: 14), const SizedBox(width: 4),
                Text(_timeAgo(a['created_at']?.toString()), style: Theme.of(context).textTheme.bodySmall),
              ]),
              const Divider(height: 32),
              Text(a['content']?.toString() ?? '', style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6)),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateSheet(BuildContext context) {
    final titleC = TextEditingController();
    final contentC = TextEditingController();
    String priority = 'normal';
    bool posting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setBS) => Padding(
          padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text('New Announcement', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 20),
              TextField(controller: titleC, decoration: const InputDecoration(hintText: 'Title', prefixIcon: Icon(Iconsax.text, size: 20))),
              const SizedBox(height: 12),
              TextField(controller: contentC, maxLines: 4, decoration: const InputDecoration(hintText: 'Content')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: priority,
                decoration: const InputDecoration(prefixIcon: Icon(Iconsax.flag, size: 20)),
                items: const [
                  DropdownMenuItem(value: 'normal', child: Text('Normal')),
                  DropdownMenuItem(value: 'high', child: Text('Important / Urgent')),
                ],
                onChanged: (v) => setBS(() => priority = v ?? 'normal'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton.icon(
                  onPressed: posting ? null : () async {
                    if (titleC.text.trim().isEmpty || contentC.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill in title and content'), behavior: SnackBarBehavior.floating));
                      return;
                    }
                    setBS(() => posting = true);
                    try {
                      final api = ref.read(apiServiceProvider);
                      await api.createAnnouncement({
                        'title': titleC.text.trim(),
                        'content': contentC.text.trim(),
                        'priority': priority,
                      });
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('✅ Announcement posted!'), backgroundColor: AppColors.present, behavior: SnackBarBehavior.floating));
                        _load();
                      }
                    } catch (e) {
                      setBS(() => posting = false);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('❌ Failed: $e'), backgroundColor: AppColors.absent, behavior: SnackBarBehavior.floating));
                      }
                    }
                  },
                  icon: posting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Iconsax.send_1),
                  label: Text(posting ? 'Posting...' : 'Post Announcement'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}