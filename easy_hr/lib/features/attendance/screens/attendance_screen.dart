import 'dart:async';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_theme.dart';
import 'qr_scan_screen.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  bool _isCheckedIn = false;
  bool _isCheckedOut = false;
  String? _checkInTime;
  String? _checkOutTime;
  DateTime? _checkInDateTime;
  bool _isLoading = false;
  double _totalHours = 0;
  Timer? _workTimer;
  List<Map<String, dynamic>> _historyRecords = [];

  // GPS State
  Position? _currentPosition;
  bool _isWithinRadius = false;
  double _distanceToOffice = 0;
  bool _gpsLoading = true;
  String? _gpsError;
  Timer? _locationTimer;

  // Office GPS — default values, Admin sets via setup
  double _officeLat = 16.8409;
  double _officeLng = 96.1735;
  double _officeRadius = 200;
  String _officeName = 'Head Office';
  bool _officeGpsSet = false; // false until admin sets it

  @override
  void initState() {
    super.initState();
    _initOfficeGps();
    _loadTodayStatus();
    _loadHistory();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _workTimer?.cancel();
    super.dispose();
  }

  void _startWorkTimer() {
    _workTimer?.cancel();
    _workTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_checkInDateTime != null && !_isCheckedOut && mounted) {
        setState(() {
          _totalHours = DateTime.now().difference(_checkInDateTime!).inMinutes / 60.0;
        });
      }
    });
  }

  Future<void> _loadTodayStatus() async {
    try {
      final api = ref.read(apiServiceProvider);
      final status = await api.getMyAttendanceStatus(
        lat: _currentPosition?.latitude,
        lng: _currentPosition?.longitude,
      );
      if (mounted) {
        setState(() {
          _isCheckedIn = status['checked_in'] == true;
          _isCheckedOut = status['checked_out'] == true;
          if (status['check_in_time'] != null) {
            _checkInDateTime = DateTime.tryParse(status['check_in_time']);
            _checkInTime = _checkInDateTime != null ? DateFormat('h:mm a').format(_checkInDateTime!.toLocal()) : null;
          }
          if (status['check_out_time'] != null) {
            final co = DateTime.tryParse(status['check_out_time']);
            _checkOutTime = co != null ? DateFormat('h:mm a').format(co.toLocal()) : null;
          }
          _totalHours = (status['total_hours'] ?? 0).toDouble();
          if (_isCheckedIn && !_isCheckedOut && _checkInDateTime != null) {
            _totalHours = DateTime.now().difference(_checkInDateTime!).inMinutes / 60.0;
            _startWorkTimer();
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _loadHistory() async {
    try {
      final api = ref.read(apiServiceProvider);
      final result = await api.getMyAttendanceHistory();
      if (mounted && result['records'] != null) {
        setState(() {
          _historyRecords = List<Map<String, dynamic>>.from(result['records']);
        });
      }
    } catch (_) {}
  }

  void _startLocationTracking() {
    _updateLocation();
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (_) => _updateLocation());
  }

  Future<void> _initOfficeGps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble('office_lat');
      final lng = prefs.getDouble('office_lng');
      final radius = prefs.getDouble('office_radius');
      final name = prefs.getString('office_name');

      if (lat != null && lng != null && radius != null) {
        setState(() {
          _officeLat = lat;
          _officeLng = lng;
          _officeRadius = radius;
          _officeName = name ?? 'Head Office';
          _officeGpsSet = true;
        });
      }
    } catch (_) {
      // ignore; fall back to defaults
    } finally {
      _startLocationTracking();
    }
  }

  Future<void> _saveOfficeGpsToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('office_lat', _officeLat);
    await prefs.setDouble('office_lng', _officeLng);
    await prefs.setDouble('office_radius', _officeRadius);
    await prefs.setString('office_name', _officeName);
  }

  Future<void> _updateLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() { _gpsLoading = false; _gpsError = 'GPS ဖွင့်ပေးပါ / Enable GPS'; });
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() { _gpsLoading = false; _gpsError = 'Location permission denied'; });
          }
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() { _gpsLoading = false; _gpsError = 'Location permanently denied. Enable in Settings.'; });
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      final distance = _calculateDistance(
        position.latitude, position.longitude, _officeLat, _officeLng,
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _distanceToOffice = distance;
          _isWithinRadius = _officeGpsSet && distance <= _officeRadius;
          _gpsLoading = false;
          _gpsError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _gpsLoading = false; _gpsError = 'GPS error - tap to retry'; });
      }
    }
  }

  // Haversine formula
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 - cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)) * 1000;
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.toInt()}m';
    return '${(meters / 1000).toStringAsFixed(1)}km';
  }

  void _handleCheckIn() async {
    if (_currentPosition == null || _isCheckedIn || _isLoading) return;
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiServiceProvider);
      final result = await api.checkIn(_currentPosition!.latitude, _currentPosition!.longitude);
      if (mounted) {
        final msg = result['message'] ?? 'Checked in!';
        _checkInDateTime = DateTime.tryParse(result['attendance']?['check_in_time'] ?? '');
        setState(() {
          _isCheckedIn = true;
          _isCheckedOut = false;
          _checkInTime = _checkInDateTime != null ? DateFormat('h:mm a').format(_checkInDateTime!.toLocal()) : TimeOfDay.now().format(context);
          _totalHours = 0;
          _isLoading = false;
        });
        _startWorkTimer();
        _loadHistory();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✅ $msg'), backgroundColor: AppColors.present, behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        String errMsg = e.toString();
        if (e is DioException && e.response?.data is Map) {
          errMsg = e.response?.data['message'] ?? errMsg;
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('❌ $errMsg'), backgroundColor: AppColors.absent, behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  void _handleCheckOut() async {
    if (!_isCheckedIn || _isCheckedOut || _currentPosition == null || _isLoading) return;
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiServiceProvider);
      final result = await api.checkOut(_currentPosition!.latitude, _currentPosition!.longitude);
      if (mounted) {
        final msg = result['message'] ?? 'Checked out!';
        _workTimer?.cancel();
        setState(() {
          _isCheckedOut = true;
          _checkOutTime = DateFormat('h:mm a').format(DateTime.now());
          _totalHours = (result['total_hours'] ?? _totalHours).toDouble();
          _isLoading = false;
        });
        _loadHistory();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✅ $msg'), backgroundColor: AppColors.present, behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        String errMsg = e.toString();
        if (e is DioException && e.response?.data is Map) {
          errMsg = e.response?.data['message'] ?? errMsg;
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('❌ $errMsg'), backgroundColor: AppColors.absent, behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = ref.watch(languageProvider);
    final mm = lang == 'mm';

    return Scaffold(
      appBar: AppBar(
        title: Text(mm ? 'တက်ရောက်မှု' : 'Attendance'),
        actions: [
          IconButton(
            icon: _gpsLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Iconsax.gps, size: 22),
            onPressed: () { setState(() => _gpsLoading = true); _updateLocation(); },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildGpsStatusCard(isDark, mm),
            const SizedBox(height: 16),
            _buildCheckButtons(isDark, mm),
            const SizedBox(height: 16),
            _buildTimeCards(isDark, mm),
            const SizedBox(height: 20),
            _buildAdminGpsSetup(isDark, mm),
            _buildQrSection(isDark, mm),
            const SizedBox(height: 20),
            _buildRecentHistory(isDark, mm),
          ],
        ),
      ),
    );
  }

  // ==================== GPS STATUS CARD ====================
  Widget _buildGpsStatusCard(bool isDark, bool mm) {
    Color c; IconData ic; String title, detail;

    if (_gpsLoading) {
      c = AppColors.warning; ic = Iconsax.gps;
      title = mm ? 'GPS ရှာဖွေနေသည်...' : 'Finding GPS...';
      detail = mm ? 'ခဏစောင့်ပါ' : 'Please wait';
    } else if (_gpsError != null) {
      c = AppColors.absent; ic = Iconsax.close_circle;
      title = mm ? 'GPS အမှား' : 'GPS Error';
      detail = _gpsError!;
    } else if (!_officeGpsSet) {
      c = Colors.orange; ic = Iconsax.warning_2;
      title = mm ? '⚠️ ရုံး GPS မသတ်မှတ်ရသေး' : '⚠️ Office GPS not set';
      detail = mm ? 'Admin/HR က ရုံးတည်နေရာ သတ်မှတ်ပေးရန် လိုပါသည်' : 'Admin/HR must set office location first';
    } else if (_isWithinRadius) {
      c = AppColors.present; ic = Iconsax.location_tick;
      title = mm ? 'ရုံးအတွင်း ရောက်နေပါသည် ✓' : 'You\'re at the office ✓';
      detail = '📍 $_officeName • ${_formatDistance(_distanceToOffice)} ${mm ? "အကွာ" : "away"}';
    } else {
      c = AppColors.absent; ic = Iconsax.location_slash;
      title = mm ? 'ရုံးအပြင်ဘက် ရောက်နေပါသည်' : 'Outside office area';
      detail = '📍 ${_formatDistance(_distanceToOffice)} ${mm ? "အကွာ" : "away"} (${mm ? "လိုအပ်" : "need"} ≤ ${_officeRadius.round()}m)';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(color: c.withOpacity(0.15), shape: BoxShape.circle),
            child: _gpsLoading
                ? Padding(padding: const EdgeInsets.all(14), child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(c)))
                : Icon(ic, color: c, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: c)),
              const SizedBox(height: 2),
              Text(detail, style: TextStyle(fontSize: 12, color: c.withOpacity(0.8))),
              if (_currentPosition != null && !_gpsLoading && _gpsError == null && _officeGpsSet)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(children: [
                    _chip('${_distanceToOffice.toInt()}m', c),
                    const SizedBox(width: 5),
                    _chip('R:${_officeRadius.round()}m', AppColors.info),
                    const SizedBox(width: 5),
                    _chip(_officeName, AppColors.primary),
                  ]),
                ),
            ],
          )),
          if (!_gpsLoading && _gpsError == null && _officeGpsSet)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: c.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
              child: Text(_formatDistance(_distanceToOffice),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: c)),
            ),
        ],
      ),
    );
  }

  Widget _chip(String t, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
    child: Text(t, style: TextStyle(fontSize: 9, color: c, fontWeight: FontWeight.w600)),
  );

  // ==================== CHECK IN / OUT BUTTONS ====================
  Widget _buildCheckButtons(bool isDark, bool mm) {
    final bool canIn = _currentPosition != null && !_isCheckedIn && !_gpsLoading && _gpsError == null;
    final bool canOut = _isCheckedIn && !_isCheckedOut && !_gpsLoading;

    return Row(
      children: [
        Expanded(child: _checkBtn(
          isDark, mm,
          enabled: canIn,
          icon: _isCheckedIn ? Iconsax.tick_circle : Iconsax.login,
          label: _isCheckedIn ? (mm ? 'ဝင်ပြီး ✓' : 'Checked In ✓') : (mm ? 'အလုပ်ဝင်ရန်' : 'Check In'),
          subLabel: _isCheckedIn
              ? _checkInTime
              : _gpsLoading
                  ? (mm ? 'GPS ရှာနေသည်...' : 'Finding GPS...')
                  : _currentPosition == null
                      ? (mm ? 'GPS ဖွင့်ပေးပါ' : 'Enable GPS')
                      : null,
          gradient: const [Color(0xFF22C55E), Color(0xFF16A34A)],
          loading: _isLoading && !_isCheckedIn,
          onTap: _handleCheckIn,
        )),
        const SizedBox(width: 12),
        Expanded(child: _checkBtn(
          isDark, mm,
          enabled: canOut,
          icon: _isCheckedOut ? Iconsax.tick_circle : Iconsax.logout,
          label: _isCheckedOut ? (mm ? 'ထွက်ပြီး ✓' : 'Checked Out ✓') : (mm ? 'အလုပ်ထွက်ရန်' : 'Check Out'),
          subLabel: _isCheckedOut
              ? _checkOutTime
              : !_isCheckedIn ? (mm ? 'အရင် Check In လုပ်ပါ' : 'Check in first') : null,
          gradient: const [Color(0xFFF59E0B), Color(0xFFD97706)],
          loading: _isLoading && _isCheckedIn,
          onTap: _handleCheckOut,
        )),
      ],
    );
  }

  Widget _checkBtn(bool isDark, bool mm, {
    required bool enabled, required IconData icon, required String label,
    String? subLabel, required List<Color> gradient, required bool loading, required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 110,
        decoration: BoxDecoration(
          gradient: enabled ? LinearGradient(colors: gradient) : null,
          color: enabled ? null : (isDark ? AppColors.darkCard : AppColors.lightCard),
          borderRadius: BorderRadius.circular(20),
          border: enabled ? null : Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 0.5),
          boxShadow: enabled ? [BoxShadow(color: gradient[0].withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))] : null,
        ),
        child: loading
            ? const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 32, color: enabled ? Colors.white : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary).withOpacity(0.35)),
                  const SizedBox(height: 8),
                  Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15,
                    color: enabled ? Colors.white : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary).withOpacity(0.35))),
                  if (subLabel != null)
                    Text(subLabel, style: TextStyle(fontSize: 10, color: enabled ? Colors.white70 : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary).withOpacity(0.3))),
                ],
              ),
      ),
    );
  }

  // ==================== TIME CARDS ====================
  Widget _buildTimeCards(bool isDark, bool mm) {
    String hoursDisplay = '--';
    if (_isCheckedIn) {
      final h = _totalHours.floor();
      final m = ((_totalHours - h) * 60).round();
      hoursDisplay = '${h}h ${m}m';
    }
    return Row(
      children: [
        _timeCard(isDark, mm ? 'အဝင်' : 'In', _checkInTime ?? '--:--', AppColors.present),
        const SizedBox(width: 10),
        _timeCard(isDark, mm ? 'အထွက်' : 'Out', _checkOutTime ?? '--:--', AppColors.warning),
        const SizedBox(width: 10),
        _timeCard(isDark, mm ? 'နာရီ' : 'Hours', hoursDisplay, AppColors.info),
      ],
    );
  }

  Widget _timeCard(bool isDark, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 0.5),
        ),
        child: Column(children: [
          Text(label, style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ]),
      ),
    );
  }

  // ==================== ADMIN GPS SETUP BUTTON ====================
  Widget _buildAdminGpsSetup(bool isDark, bool mm) {
    final isAdmin = ref.watch(authProvider).user?.isAdmin ?? false;
    if (!isAdmin) return const SizedBox.shrink();

    final btnColor = _officeGpsSet ? AppColors.primary : Colors.orange;

    return GestureDetector(
      onTap: () => _showGpsSetupSheet(mm),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: btnColor.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: btnColor.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: btnColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Iconsax.setting_2, color: btnColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _officeGpsSet
                        ? (mm ? '⚙️ ရုံး GPS ပြင်ဆင်ရန်' : '⚙️ Edit Office GPS')
                        : (mm ? '⚠️ ရုံး GPS သတ်မှတ်ရန် (လိုအပ်)' : '⚠️ Set Office GPS (Required)'),
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: btnColor),
                  ),
                  Text(
                    _officeGpsSet
                        ? 'Lat: ${_officeLat.toStringAsFixed(4)}, Lng: ${_officeLng.toStringAsFixed(4)}, R: ${_officeRadius.round()}m'
                        : (mm ? 'ဝန်ထမ်းများ Check In နိုင်ရန် ရုံး GPS လိုအပ်ပါသည်' : 'Required for employee check-in'),
                    style: TextStyle(fontSize: 10, color: btnColor.withOpacity(0.6)),
                  ),
                ],
              ),
            ),
            Icon(Iconsax.arrow_right_3, size: 18, color: btnColor),
          ],
        ),
      ),
    );
  }

  // ==================== GPS SETUP BOTTOM SHEET ====================
  void _showGpsSetupSheet(bool mm) {
    final latC = TextEditingController(text: _officeLat.toStringAsFixed(6));
    final lngC = TextEditingController(text: _officeLng.toStringAsFixed(6));
    final nameC = TextEditingController(text: _officeName);
    int radius = _officeRadius.round();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setBS) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),

                Text(mm ? '⚙️ ရုံး GPS တည်နေရာ' : '⚙️ Office GPS Location',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(mm ? 'ဝန်ထမ်းများ ဤ radius အတွင်းမှသာ Check In နိုင်မည်' : 'Employees can only check in within this radius',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                const SizedBox(height: 18),

                // USE CURRENT LOCATION
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Iconsax.gps, size: 18),
                    label: Text(mm ? '📍 ယခုတည်နေရာ အသုံးပြုရန်' : '📍 Use My Current Location'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () async {
                      try {
                        final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
                        setBS(() {
                          latC.text = pos.latitude.toStringAsFixed(6);
                          lngC.text = pos.longitude.toStringAsFixed(6);
                        });
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(mm ? '📍 တည်နေရာ ရယူပြီး!' : '📍 Location captured!'),
                            backgroundColor: AppColors.present, behavior: SnackBarBehavior.floating,
                          ));
                        }
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('GPS error'), behavior: SnackBarBehavior.floating),
                          );
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(height: 14),

                // Office Name
                TextField(
                  controller: nameC,
                  decoration: InputDecoration(
                    labelText: mm ? 'ရုံးအမည်' : 'Office Name',
                    prefixIcon: const Icon(Iconsax.building, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 10),

                // Lat / Lng
                Row(children: [
                  Expanded(child: TextField(controller: latC, keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'Latitude', prefixIcon: const Icon(Iconsax.gps, size: 16),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(controller: lngC, keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'Longitude', prefixIcon: const Icon(Iconsax.gps, size: 16),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                ]),
                const SizedBox(height: 4),
                Text(mm ? '* Google Maps မှ lat/lng ကူးယူ သို့ ယခုတည်နေရာသုံးပါ' : '* Copy from Google Maps or use current location',
                    style: TextStyle(fontSize: 10, color: Colors.grey[500], fontStyle: FontStyle.italic)),
                const SizedBox(height: 18),

                // RADIUS
                Text('Radius: ${radius}m', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(mm ? 'ရုံးအကျယ်အဝန်းပေါ်မူတည်ပြီး ရွေးချယ်ပါ' : 'Choose based on your office size',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                const SizedBox(height: 6),

                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.primary,
                    thumbColor: AppColors.primary,
                    overlayColor: AppColors.primary.withOpacity(0.1),
                    valueIndicatorColor: AppColors.primary,
                    showValueIndicator: ShowValueIndicator.always,
                  ),
                  child: Slider(
                    value: radius.toDouble(), min: 50, max: 1000, divisions: 19,
                    label: '${radius}m',
                    onChanged: (v) => setBS(() => radius = v.toInt()),
                  ),
                ),

                // Presets
                Row(children: [
                  _presetBtn(setBS, mm ? 'ရုံးသေး' : 'Small', 100, radius, (v) { radius = v; }),
                  const SizedBox(width: 6),
                  _presetBtn(setBS, mm ? 'ရုံးလတ်' : 'Medium', 200, radius, (v) { radius = v; }),
                  const SizedBox(width: 6),
                  _presetBtn(setBS, mm ? 'ရုံးကြီး' : 'Large', 500, radius, (v) { radius = v; }),
                  const SizedBox(width: 6),
                  _presetBtn(setBS, mm ? 'စက်ရုံ' : 'Factory', 1000, radius, (v) { radius = v; }),
                ]),
                const SizedBox(height: 22),

                // SAVE
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton.icon(
                    icon: const Icon(Iconsax.tick_circle, size: 20),
                    label: Text(mm ? 'သိမ်းဆည်းရန်' : 'Save Office GPS',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      setState(() {
                        _officeLat = double.tryParse(latC.text) ?? _officeLat;
                        _officeLng = double.tryParse(lngC.text) ?? _officeLng;
                        _officeRadius = radius.toDouble();
                        _officeName = nameC.text.isNotEmpty ? nameC.text : 'Office';
                        _officeGpsSet = true;
                      });
                      await _saveOfficeGpsToPrefs();
                      _updateLocation();
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(mm ? '✅ ရုံး GPS သိမ်းပြီး! Radius: ${radius}m' : '✅ Office GPS saved! Radius: ${radius}m'),
                        backgroundColor: AppColors.present,
                        behavior: SnackBarBehavior.floating,
                      ));
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _presetBtn(StateSetter setBS, String label, int value, int current, Function(int) onSet) {
    final active = current == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setBS(() => onSet(value)),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: active ? AppColors.primary : Colors.grey.shade600),
          ),
          child: Column(children: [
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: active ? Colors.white : Colors.grey)),
            Text('${value}m', style: TextStyle(fontSize: 9, color: active ? Colors.white70 : Colors.grey)),
          ]),
        ),
      ),
    );
  }

  // ==================== QR SECTION ====================
  Widget _buildQrSection(bool isDark, bool mm) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 0.5),
      ),
      child: Column(children: [
        Icon(Iconsax.scan_barcode, size: 36, color: AppColors.primary.withOpacity(0.6)),
        const SizedBox(height: 10),
        Text(mm ? 'QR ကုဒ်ဖြင့် တက်ရောက်မှု' : 'QR Code Attendance', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 4),
        Text(mm ? 'QR ကုဒ်ဖြင့် အလုပ်ဝင်/ထွက် မှတ်တမ်းတင်ပါ' : 'Scan QR code for check-in/out',
          style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton.icon(
            icon: const Icon(Iconsax.scan, size: 18),
            label: Text(mm ? 'QR စကန်ဖတ်ရန်' : 'Scan QR Code'),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const QRAttendanceScanScreen()),
              );
              if (mounted && result == true) {
                _loadTodayStatus();
                _loadHistory();
              }
            },
          ),
        ),
      ]),
    );
  }

  // ==================== RECENT HISTORY ====================
  Widget _buildRecentHistory(bool isDark, bool mm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(mm ? 'မှတ်တမ်း' : 'Recent History', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        if (_historyRecords.isEmpty)
          Container(
            width: double.infinity, padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 0.5),
            ),
            child: Text(mm ? 'မှတ်တမ်း မရှိသေးပါ' : 'No attendance records yet',
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, fontSize: 13)),
          ),
        ..._historyRecords.take(10).map((h) {
          final status = h['status']?.toString() ?? 'absent';
          final color = status == 'present' ? AppColors.present : status == 'late' ? AppColors.warning : AppColors.absent;
          final label = status == 'present' ? (mm ? 'ရှိ' : 'Present') : status == 'late' ? (mm ? 'နောက်ကျ' : 'Late') : (mm ? 'ပျက်ကွက်' : 'Absent');
          final dateStr = h['date']?.toString() ?? '';
          final d = DateTime.tryParse(dateStr);
          final dateLabel = d != null ? DateFormat('dd MMM').format(d) : dateStr;
          final ciTime = h['check_in_time'] != null ? DateFormat('h:mm a').format(DateTime.parse(h['check_in_time']).toLocal()) : '--:--';
          final coTime = h['check_out_time'] != null ? DateFormat('h:mm a').format(DateTime.parse(h['check_out_time']).toLocal()) : '--:--';
          return Container(
            margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 0.5),
            ),
            child: Row(children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(dateLabel, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text('$ciTime → $coTime', style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
              ),
            ]),
          );
        }),
      ],
    );
  }
}