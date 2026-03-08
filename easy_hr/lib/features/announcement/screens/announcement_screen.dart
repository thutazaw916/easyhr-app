import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';

class AnnouncementScreen extends ConsumerWidget {
  const AnnouncementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(authProvider).user;

    final announcements = [
      {
        'title': 'Office Closure - Thingyan Holiday',
        'content': 'Our office will be closed from April 13-17 for Thingyan Water Festival. Please plan your work accordingly. Happy Thingyan! 🎉💧',
        'creator': 'Admin',
        'time': '2 hours ago',
        'priority': 'high',
        'is_pinned': true,
        'is_read': false,
      },
      {
        'title': 'New Leave Policy Update',
        'content': 'Starting next month, WFH days will be increased to 4 days per month. Please check the updated policy document.',
        'creator': 'HR Manager',
        'time': 'Yesterday',
        'priority': 'normal',
        'is_pinned': false,
        'is_read': true,
      },
      {
        'title': 'Monthly Town Hall Meeting',
        'content': 'Monthly town hall meeting will be held on March 5th at 3:00 PM. All employees are required to attend.',
        'creator': 'Admin',
        'time': '3 days ago',
        'priority': 'normal',
        'is_pinned': false,
        'is_read': true,
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Announcements')),
      floatingActionButton: (user?.isAdmin ?? false)
          ? FloatingActionButton(
              onPressed: () => _showCreateSheet(context),
              backgroundColor: AppColors.primary,
              child: const Icon(Iconsax.add, color: Colors.white),
            )
          : null,
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: announcements.length,
        itemBuilder: (context, i) {
          final a = announcements[i];
          final isHigh = a['priority'] == 'high';
          final isPinned = a['is_pinned'] as bool;
          final isRead = a['is_read'] as bool;

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
                  // Header row
                  Row(
                    children: [
                      if (isPinned)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Iconsax.attach_square, size: 12, color: AppColors.warning),
                              SizedBox(width: 2),
                              Text('Pinned', style: TextStyle(fontSize: 10, color: AppColors.warning, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      if (isHigh)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Important', style: TextStyle(fontSize: 10, color: AppColors.error, fontWeight: FontWeight.w600)),
                        ),
                      const Spacer(),
                      if (!isRead)
                        Container(
                          width: 8, height: 8,
                          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Title
                  Text(
                    a['title'] as String,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Content preview
                  Text(
                    a['content'] as String,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Footer
                  Row(
                    children: [
                      Icon(Iconsax.user, size: 14, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                      const SizedBox(width: 4),
                      Text(a['creator'] as String, style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(width: 16),
                      Icon(Iconsax.clock, size: 14, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                      const SizedBox(width: 4),
                      Text(a['time'] as String, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDetail(BuildContext context, Map<String, Object> a) {
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
              Text(a['title'] as String, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Iconsax.user, size: 14),
                  const SizedBox(width: 4),
                  Text(a['creator'] as String, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(width: 16),
                  const Icon(Iconsax.clock, size: 14),
                  const SizedBox(width: 4),
                  Text(a['time'] as String, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              const Divider(height: 32),
              Text(a['content'] as String, style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6)),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('New Announcement', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 20),
            const TextField(decoration: InputDecoration(hintText: 'Title', prefixIcon: Icon(Iconsax.text, size: 20))),
            const SizedBox(height: 12),
            const TextField(maxLines: 4, decoration: InputDecoration(hintText: 'Content')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: 'normal',
              decoration: const InputDecoration(prefixIcon: Icon(Iconsax.flag, size: 20)),
              items: const [
                DropdownMenuItem(value: 'normal', child: Text('Normal')),
                DropdownMenuItem(value: 'high', child: Text('Important / Urgent')),
              ],
              onChanged: (v) {},
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Iconsax.send_1),
                label: const Text('Post Announcement'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}