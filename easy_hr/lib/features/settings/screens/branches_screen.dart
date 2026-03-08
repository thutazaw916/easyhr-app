import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/localization/app_strings.dart';

class BranchesScreen extends ConsumerStatefulWidget {
  const BranchesScreen({super.key});

  @override
  ConsumerState<BranchesScreen> createState() => _BranchesScreenState();
}

class _BranchesScreenState extends ConsumerState<BranchesScreen> {
  List<Map<String, dynamic>> _branches = [
    {
      'id': '1',
      'name': 'Head Office',
      'name_mm': 'ရုံးချုပ်',
      'address': 'No.123, Pyay Road, Kamayut Township',
      'city': 'Yangon',
      'phone': '09123456789',
      'lat': 16.8409,
      'lng': 96.1735,
      'radius': 200,
      'employee_count': 25,
      'is_active': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = ref.watch(languageProvider);
    final mm = lang == 'mm';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Iconsax.arrow_left), onPressed: () => Navigator.pop(context)),
        title: Text(mm ? 'ရုံးခွဲများ' : 'Branches'),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.add_circle, size: 24),
            onPressed: () => _showAddBranchDialog(isDark, mm),
          ),
        ],
      ),
      body: _branches.isEmpty
          ? _buildEmptyState(mm)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _branches.length,
              itemBuilder: (context, index) => _buildBranchCard(isDark, mm, index),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddBranchDialog(isDark, mm),
        icon: const Icon(Iconsax.building_4, size: 20),
        label: Text(mm ? 'ရုံးခွဲထည့်ရန်' : 'Add Branch'),
      ),
    );
  }

  Widget _buildEmptyState(bool mm) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.building_4, size: 64, color: AppColors.primary.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(mm ? 'ရုံးခွဲ မရှိသေးပါ' : 'No branches yet', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text(mm ? 'ရုံးခွဲထည့်ပြီး GPS တည်နေရာ သတ်မှတ်ပါ' : 'Add branches with GPS location for attendance',
            style: TextStyle(fontSize: 13, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildBranchCard(bool isDark, bool mm, int index) {
    final b = _branches[index];
    final name = mm ? (b['name_mm'] ?? b['name']) : b['name'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Iconsax.building, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: b['is_active'] ? AppColors.present.withOpacity(0.1) : AppColors.absent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            b['is_active'] ? (mm ? 'ဖွင့်ထား' : 'Active') : (mm ? 'ပိတ်ထား' : 'Inactive'),
                            style: TextStyle(fontSize: 10, color: b['is_active'] ? AppColors.present : AppColors.absent, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(b['city'] ?? '', style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Info rows
          _infoRow(isDark, Iconsax.location, b['address'] ?? ''),
          const SizedBox(height: 6),
          _infoRow(isDark, Iconsax.call, b['phone'] ?? ''),
          const SizedBox(height: 6),
          _infoRow(isDark, Iconsax.people, '${b['employee_count']} ${mm ? 'ဝန်ထမ်း' : 'employees'}'),
          const SizedBox(height: 6),
          _infoRow(isDark, Iconsax.gps, '${mm ? 'GPS အကွာအဝေး' : 'GPS Radius'}: ${b['radius']}m'),

          const SizedBox(height: 14),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Iconsax.edit_2, size: 16),
                  label: Text(mm ? 'ပြင်ဆင်' : 'Edit', style: const TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  onPressed: () => _showAddBranchDialog(isDark, mm, editIndex: index),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  icon: Icon(Iconsax.gps, size: 16, color: AppColors.info),
                  label: Text(mm ? 'GPS ကြည့်ရန်' : 'View GPS', style: const TextStyle(fontSize: 13, color: AppColors.info)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.info),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('📍 Lat: ${b['lat']}, Lng: ${b['lng']}'), behavior: SnackBarBehavior.floating),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(bool isDark, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary))),
      ],
    );
  }

  void _showAddBranchDialog(bool isDark, bool mm, {int? editIndex}) {
    final isEdit = editIndex != null;
    final nameC = TextEditingController(text: isEdit ? _branches[editIndex]['name'] : '');
    final nameMmC = TextEditingController(text: isEdit ? _branches[editIndex]['name_mm'] : '');
    final addressC = TextEditingController(text: isEdit ? _branches[editIndex]['address'] : '');
    final cityC = TextEditingController(text: isEdit ? _branches[editIndex]['city'] : '');
    final phoneC = TextEditingController(text: isEdit ? _branches[editIndex]['phone'] : '');
    final latC = TextEditingController(text: isEdit ? '${_branches[editIndex]['lat']}' : '');
    final lngC = TextEditingController(text: isEdit ? '${_branches[editIndex]['lng']}' : '');
    final radiusC = TextEditingController(text: isEdit ? '${_branches[editIndex]['radius']}' : '200');

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text(isEdit ? (mm ? 'ရုံးခွဲပြင်ဆင်ရန်' : 'Edit Branch') : (mm ? 'ရုံးခွဲအသစ်ထည့်ရန်' : 'Add New Branch'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              _sheetField(mm ? 'ရုံးခွဲအမည် (English) *' : 'Branch Name (English) *', nameC, Iconsax.building),
              const SizedBox(height: 10),
              _sheetField(mm ? 'ရုံးခွဲအမည် (မြန်မာ)' : 'Branch Name (Myanmar)', nameMmC, Iconsax.building_4),
              const SizedBox(height: 10),
              _sheetField(mm ? 'လိပ်စာ' : 'Address', addressC, Iconsax.location),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _sheetField(mm ? 'မြို့' : 'City', cityC, Iconsax.map)),
                  const SizedBox(width: 10),
                  Expanded(child: _sheetField(mm ? 'ဖုန်း' : 'Phone', phoneC, Iconsax.call)),
                ],
              ),
              const SizedBox(height: 16),

              Text(mm ? 'GPS တည်နေရာ (Attendance အတွက်)' : 'GPS Location (For Attendance)',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _sheetField('Latitude', latC, Iconsax.gps, keyboardType: TextInputType.number)),
                  const SizedBox(width: 10),
                  Expanded(child: _sheetField('Longitude', lngC, Iconsax.gps, keyboardType: TextInputType.number)),
                  const SizedBox(width: 10),
                  Expanded(child: _sheetField(mm ? 'အကွာအဝေး(m)' : 'Radius(m)', radiusC, Iconsax.ruler, keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 6),
              Text(mm ? '* Google Maps မှ lat/lng ကူးယူနိုင်ပါသည်' : '* Copy lat/lng from Google Maps',
                style: TextStyle(fontSize: 11, color: Colors.grey[500], fontStyle: FontStyle.italic)),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton.icon(
                  icon: Icon(isEdit ? Iconsax.tick_circle : Iconsax.add_circle, size: 20),
                  label: Text(isEdit ? (mm ? 'သိမ်းရန်' : 'Save') : (mm ? 'ထည့်ရန်' : 'Add Branch')),
                  onPressed: () {
                    if (nameC.text.isEmpty) return;
                    final branch = {
                      'id': isEdit ? _branches[editIndex]['id'] : DateTime.now().millisecondsSinceEpoch.toString(),
                      'name': nameC.text, 'name_mm': nameMmC.text.isNotEmpty ? nameMmC.text : nameC.text,
                      'address': addressC.text, 'city': cityC.text, 'phone': phoneC.text,
                      'lat': double.tryParse(latC.text) ?? 0, 'lng': double.tryParse(lngC.text) ?? 0,
                      'radius': int.tryParse(radiusC.text) ?? 200,
                      'employee_count': isEdit ? _branches[editIndex]['employee_count'] : 0,
                      'is_active': true,
                    };
                    setState(() {
                      if (isEdit) { _branches[editIndex] = branch; } else { _branches.add(branch); }
                    });
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isEdit ? '✅ ${mm ? 'ပြင်ဆင်ပြီး!' : 'Updated!'}' : '✅ ${mm ? 'ရုံးခွဲထည့်ပြီး!' : 'Branch added!'}'),
                        backgroundColor: AppColors.present, behavior: SnackBarBehavior.floating),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetField(String label, TextEditingController c, IconData icon, {TextInputType? keyboardType}) {
    return TextField(
      controller: c, keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label, prefixIcon: Icon(icon, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      style: const TextStyle(fontSize: 14),
    );
  }
}