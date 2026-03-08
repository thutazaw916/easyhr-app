import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';

class MyanmarHoliday {
  final DateTime date;
  final String name;
  final String nameMm;
  final String type; // public, religious, festival
  final String? description;
  final Color color;

  MyanmarHoliday({
    required this.date,
    required this.name,
    required this.nameMm,
    required this.type,
    this.description,
    required this.color,
  });
}

// Myanmar 2026 Public Holidays
final List<MyanmarHoliday> myanmarHolidays2026 = [
  // January
  MyanmarHoliday(date: DateTime(2026, 1, 1), name: 'New Year\'s Day', nameMm: 'နှစ်သစ်ကူးနေ့', type: 'public', color: AppColors.primary),
  MyanmarHoliday(date: DateTime(2026, 1, 4), name: 'Independence Day', nameMm: 'လွတ်လပ်ရေးနေ့', type: 'public', description: 'Myanmar Independence Day (1948)', color: AppColors.error),

  // February
  MyanmarHoliday(date: DateTime(2026, 2, 12), name: 'Union Day', nameMm: 'ပြည်ထောင်စုနေ့', type: 'public', description: 'Panglong Agreement (1947)', color: AppColors.error),
  MyanmarHoliday(date: DateTime(2026, 2, 14), name: 'Valentine\'s Day', nameMm: 'ချစ်သူများနေ့', type: 'festival', color: AppColors.error),

  // March
  MyanmarHoliday(date: DateTime(2026, 3, 2), name: 'Peasants\' Day', nameMm: 'တောင်သူလယ်သမားနေ့', type: 'public', color: AppColors.accent),
  MyanmarHoliday(date: DateTime(2026, 3, 10), name: 'Tabaung Full Moon', nameMm: 'တပေါင်းလပြည့်', type: 'religious', description: 'Shwedagon Pagoda Festival', color: AppColors.warning),
  MyanmarHoliday(date: DateTime(2026, 3, 27), name: 'Armed Forces Day', nameMm: 'တပ်မတော်နေ့', type: 'public', color: AppColors.error),

  // April - Thingyan
  MyanmarHoliday(date: DateTime(2026, 4, 9), name: 'Thingyan Eve (အကြိုနေ့)', nameMm: 'သင်္ကြန်အကြိုနေ့', type: 'festival', description: 'Water Festival begins', color: AppColors.primary),
  MyanmarHoliday(date: DateTime(2026, 4, 10), name: 'Thingyan Day 1', nameMm: 'သင်္ကြန်ကျနေ့ (၁)', type: 'public', color: AppColors.primary),
  MyanmarHoliday(date: DateTime(2026, 4, 11), name: 'Thingyan Day 2', nameMm: 'သင်္ကြန်ကျနေ့ (၂)', type: 'public', color: AppColors.primary),
  MyanmarHoliday(date: DateTime(2026, 4, 12), name: 'Thingyan Day 3', nameMm: 'သင်္ကြန်ကျနေ့ (၃)', type: 'public', color: AppColors.primary),
  MyanmarHoliday(date: DateTime(2026, 4, 13), name: 'Thingyan Day 4', nameMm: 'သင်္ကြန်ကျနေ့ (၄)', type: 'public', color: AppColors.primary),
  MyanmarHoliday(date: DateTime(2026, 4, 14), name: 'Thingyan Atat (အတက်နေ့)', nameMm: 'သင်္ကြန်အတက်နေ့', type: 'public', description: 'Last day of Water Festival', color: AppColors.primary),
  MyanmarHoliday(date: DateTime(2026, 4, 15), name: 'Myanmar New Year (နှစ်ဆန်းတစ်ရက်)', nameMm: 'မြန်မာနှစ်ဆန်းတစ်ရက်နေ့', type: 'public', description: 'Myanmar Year 1388', color: AppColors.warning),
  MyanmarHoliday(date: DateTime(2026, 4, 16), name: 'Myanmar New Year Holiday', nameMm: 'နှစ်ဆန်းအကြွင်းရက်', type: 'public', color: AppColors.warning),

  // May
  MyanmarHoliday(date: DateTime(2026, 5, 1), name: 'May Day', nameMm: 'အလုပ်သမားနေ့', type: 'public', color: AppColors.accent),
  MyanmarHoliday(date: DateTime(2026, 5, 8), name: 'Kasone Full Moon', nameMm: 'ကဆုန်လပြည့်', type: 'religious', description: 'Buddha Day - Vesak', color: AppColors.warning),

  // June
  MyanmarHoliday(date: DateTime(2026, 6, 7), name: 'Nayon Full Moon', nameMm: 'နယုန်လပြည့်', type: 'religious', description: 'Start of Buddhist Lent (ဓမ္မစကြာ)', color: AppColors.warning),

  // July
  MyanmarHoliday(date: DateTime(2026, 7, 6), name: 'Waso Full Moon', nameMm: 'ဝါဆိုလပြည့်', type: 'religious', description: 'Beginning of Buddhist Lent (ဝါဆို)', color: AppColors.warning),
  MyanmarHoliday(date: DateTime(2026, 7, 19), name: 'Martyrs\' Day', nameMm: 'အာဇာနည်နေ့', type: 'public', description: 'Aung San & martyrs (1947)', color: AppColors.error),

  // October
  MyanmarHoliday(date: DateTime(2026, 10, 2), name: 'Thadingyut Full Moon', nameMm: 'သီတင်းကျွတ်လပြည့်', type: 'religious', description: 'End of Buddhist Lent - Festival of Lights', color: AppColors.warning),
  MyanmarHoliday(date: DateTime(2026, 10, 3), name: 'Thadingyut Holiday', nameMm: 'သီတင်းကျွတ်အကြွင်း (၁)', type: 'public', color: AppColors.warning),
  MyanmarHoliday(date: DateTime(2026, 10, 4), name: 'Thadingyut Holiday', nameMm: 'သီတင်းကျွတ်အကြွင်း (၂)', type: 'public', color: AppColors.warning),

  // November
  MyanmarHoliday(date: DateTime(2026, 11, 1), name: 'Tazaungdaing Full Moon', nameMm: 'တန်ဆောင်မုန်းလပြည့်', type: 'religious', description: 'Tazaungdaing Festival of Lights', color: AppColors.warning),
  MyanmarHoliday(date: DateTime(2026, 11, 14), name: 'National Day', nameMm: 'အမျိုးသားနေ့', type: 'public', color: AppColors.error),

  // December
  MyanmarHoliday(date: DateTime(2026, 12, 25), name: 'Christmas Day', nameMm: 'ခရစ္စမတ်နေ့', type: 'public', color: AppColors.accent),
  MyanmarHoliday(date: DateTime(2026, 12, 31), name: 'New Year\'s Eve', nameMm: 'နှစ်ကုန်ပိတ်ရက်', type: 'festival', color: AppColors.primary),
];

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();

    // Get holidays for selected month
    final monthHolidays = myanmarHolidays2026.where((h) =>
      h.date.month == _selectedMonth.month && h.date.year == _selectedMonth.year
    ).toList();

    // Get upcoming holidays
    final upcoming = myanmarHolidays2026.where((h) => h.date.isAfter(now)).take(5).toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Iconsax.arrow_left), onPressed: () => Navigator.pop(context)),
        title: const Text('Myanmar Calendar'),
        actions: [
          TextButton(
            onPressed: () => setState(() {
              _selectedMonth = DateTime(now.year, now.month);
              _selectedDate = now;
            }),
            child: const Text('Today'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month Selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Iconsax.arrow_left_2),
                    onPressed: () => setState(() {
                      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
                    }),
                  ),
                  Text(
                    DateFormat('MMMM yyyy').format(_selectedMonth),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Iconsax.arrow_right_3),
                    onPressed: () => setState(() {
                      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
                    }),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Weekday Headers
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                    .map((d) => Expanded(
                          child: Center(
                            child: Text(d,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: d == 'Sun' || d == 'Sat'
                                    ? AppColors.error.withOpacity(0.6)
                                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),

            const SizedBox(height: 8),

            // Calendar Grid
            _buildCalendarGrid(context, isDark),

            const SizedBox(height: 16),

            // Selected Date Holidays
            if (_selectedDate != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  DateFormat('EEEE, dd MMMM yyyy').format(_selectedDate!),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 8),
              ..._getHolidaysForDate(_selectedDate!).map((h) => _buildHolidayCard(context, isDark, h)),
              if (_getHolidaysForDate(_selectedDate!).isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text('No holidays on this date', style: Theme.of(context).textTheme.bodySmall),
                ),
              const SizedBox(height: 16),
            ],

            // This Month's Holidays
            if (monthHolidays.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  '${DateFormat('MMMM').format(_selectedMonth)} Holidays (${monthHolidays.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 8),
              ...monthHolidays.map((h) => _buildHolidayCard(context, isDark, h)),
            ],

            if (monthHolidays.isEmpty)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Iconsax.calendar_1, size: 48, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                      const SizedBox(height: 8),
                      Text('No holidays this month', style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Upcoming Holidays
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('Upcoming Holidays', style: Theme.of(context).textTheme.titleMedium),
            ),
            const SizedBox(height: 8),
            ...upcoming.map((h) => _buildUpcomingCard(context, isDark, h)),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid(BuildContext context, bool isDark) {
    final year = _selectedMonth.year;
    final month = _selectedMonth.month;
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    final firstWeekday = firstDay.weekday; // 1=Mon, 7=Sun
    final now = DateTime.now();

    List<Widget> dayWidgets = [];

    // Empty cells before first day
    for (int i = 1; i < firstWeekday; i++) {
      dayWidgets.add(const SizedBox());
    }

    // Day cells
    for (int day = 1; day <= lastDay.day; day++) {
      final date = DateTime(year, month, day);
      final isToday = date.day == now.day && date.month == now.month && date.year == now.year;
      final isSelected = _selectedDate != null &&
          date.day == _selectedDate!.day && date.month == _selectedDate!.month;
      final isWeekend = date.weekday == 6 || date.weekday == 7;
      final holidays = _getHolidaysForDate(date);
      final hasHoliday = holidays.isNotEmpty;

      dayWidgets.add(
        GestureDetector(
          onTap: () => setState(() => _selectedDate = date),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : isToday
                      ? AppColors.primary.withOpacity(0.1)
                      : null,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? Colors.white
                        : isWeekend
                            ? AppColors.error
                            : hasHoliday
                                ? AppColors.warning
                                : (isDark ? AppColors.darkText : AppColors.lightText),
                  ),
                ),
                if (hasHoliday)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    width: 5, height: 5,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : holidays.first.color,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 7,
        childAspectRatio: 1,
        children: dayWidgets,
      ),
    );
  }

  List<MyanmarHoliday> _getHolidaysForDate(DateTime date) {
    return myanmarHolidays2026.where((h) =>
      h.date.day == date.day && h.date.month == date.month && h.date.year == date.year
    ).toList();
  }

  Widget _buildHolidayCard(BuildContext context, bool isDark, MyanmarHoliday h) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: h.color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 4, height: 44,
            decoration: BoxDecoration(color: h.color, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(h.nameMm, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 15)),
                const SizedBox(height: 2),
                Text(h.name, style: Theme.of(context).textTheme.bodySmall),
                if (h.description != null) ...[
                  const SizedBox(height: 2),
                  Text(h.description!, style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    fontStyle: FontStyle.italic,
                  )),
                ],
              ],
            ),
          ),
          Column(
            children: [
              Text(DateFormat('dd').format(h.date), style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: h.color)),
              Text(DateFormat('MMM').format(h.date), style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingCard(BuildContext context, bool isDark, MyanmarHoliday h) {
    final daysLeft = h.date.difference(DateTime.now()).inDays;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.all(14),
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
              color: h.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(DateFormat('dd').format(h.date), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: h.color)),
                Text(DateFormat('MMM').format(h.date), style: TextStyle(fontSize: 10, color: h.color)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(h.nameMm, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14)),
                Text(h.name, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$daysLeft days',
              style: const TextStyle(color: AppColors.info, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}