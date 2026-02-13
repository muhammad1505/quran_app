import 'dart:async';

import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quran_app/core/services/prayer_notification_service.dart';
import 'package:quran_app/core/settings/prayer_settings.dart';
import 'package:quran_app/features/settings/presentation/pages/settings_page.dart';
import 'package:quran_app/core/di/injection.dart';

enum ScheduleView { today, week, month }

class PrayerTimesPage extends StatefulWidget {
  const PrayerTimesPage({super.key});

  @override
  State<PrayerTimesPage> createState() => _PrayerTimesPageState();
}

class _PrayerTimesPageState extends State<PrayerTimesPage> {
  String _locationName = "Mencari Lokasi...";
  bool _manualLocationEnabled = false;
  String? _manualLocationName;
  PrayerTimes? _prayerTimes;
  Prayer? _nextPrayer;
  DateTime? _nextPrayerTime;
  Duration _timeRemaining = Duration.zero;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;
  String? _warningMessage;
  Coordinates? _coordinates;
  final PrayerSettingsController _prayerSettings =
      getIt<PrayerSettingsController>();
  Timer? _ticker;
  ScheduleView _view = ScheduleView.today;

  @override
  void initState() {
    super.initState();
    _prayerSettings.addListener(_onSettingsChanged);
    _prayerSettings.load();
    _initLocationAndPrayers();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateCountdown();
    });
  }

  @override
  void dispose() {
    _prayerSettings.removeListener(_onSettingsChanged);
    _ticker?.cancel();
    super.dispose();
  }

  void _onSettingsChanged() {
    if (_coordinates != null) {
      unawaited(_calculatePrayerTimes(_coordinates!));
    }
  }

  Future<void> _initLocationAndPrayers() async {
    try {
      setState(() {
        _isRefreshing = true;
        _errorMessage = null;
        _warningMessage = null;
      });
      final manual = await _loadManualLocation();
      if (manual != null) {
        _coordinates = manual.coordinates;
        _locationName = manual.name;
        await _calculatePrayerTimes(_coordinates!);
        return;
      }
      final cached = await _loadCachedLocation();
      // 1. Permission Check
      final status = await Permission.locationWhenInUse.request();
      if (!status.isGranted) {
        if (cached != null) {
          await _useCachedLocation(
            cached,
            message: "Izin lokasi ditolak. Menampilkan lokasi terakhir.",
          );
          return;
        }
        setState(() {
          _locationName = "Izin Lokasi Ditolak";
          _isLoading = false;
          _isRefreshing = false;
          _errorMessage = "Izin lokasi dibutuhkan untuk jadwal sholat.";
        });
        return;
      }

      // 2. Get GPS Position (with distance filter for battery saving in future updates)
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      // 3. Reverse Geocoding (Get City Name)
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final name =
              "${place.subAdministrativeArea ?? place.locality}, ${place.country}";
          setState(() => _locationName = name);
          await _storeLastLocationName(name);
        }
      } catch (e) {
        setState(() {
          _locationName =
              "Koordinat: ${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)}";
        });
      }

      _coordinates = Coordinates(position.latitude, position.longitude);
      await _storeLastLocation(position);
      await _calculatePrayerTimes(_coordinates!);

    } catch (e) {
      final cached = await _loadCachedLocation();
      if (cached != null) {
        await _useCachedLocation(
          cached,
          message: "Gagal memuat lokasi terbaru. Menampilkan lokasi terakhir.",
        );
        return;
      }
      setState(() {
        _locationName = "Gagal memuat lokasi";
        _isLoading = false;
        _isRefreshing = false;
        _errorMessage = "Gagal memuat lokasi. Coba lagi.";
      });
    }
  }

  Future<void> _calculatePrayerTimes(Coordinates coordinates) async {
    final params = _prayerSettings.buildParameters();
    final prayerTimes = PrayerTimes.today(coordinates, params);
    final tomorrow = PrayerTimes(
      coordinates,
      DateComponents.from(DateTime.now().add(const Duration(days: 1))),
      params,
    );
    final next = _resolveNextPrayer(prayerTimes, coordinates, params);

    // Re-schedule notifications
    await getIt<PrayerNotificationService>().schedulePrayerTimes(
      prayerTimes,
      tomorrow,
      _prayerSettings.value,
    );

    setState(() {
      _prayerTimes = prayerTimes;
      _nextPrayer = next.prayer;
      _nextPrayerTime = next.time;
      _isLoading = false;
      _isRefreshing = false;
    });
    _updateCountdown();
  }

  Future<_ManualLocation?> _loadManualLocation() async {
    final prefs = await SharedPreferences.getInstance();
    _manualLocationEnabled = prefs.getBool('manual_location_enabled') ?? false;
    _manualLocationName = prefs.getString('manual_location_name');
    if (!_manualLocationEnabled) return null;
    final lat = prefs.getDouble('last_lat');
    final lng = prefs.getDouble('last_lng');
    if (lat == null || lng == null || _manualLocationName == null) return null;
    return _ManualLocation(
      name: _manualLocationName!,
      coordinates: Coordinates(lat, lng),
    );
  }

  Future<_CachedLocation?> _loadCachedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble('last_lat');
    final lng = prefs.getDouble('last_lng');
    if (lat == null || lng == null) return null;
    final name = prefs.getString('last_location_name');
    return _CachedLocation(
      name: name,
      coordinates: Coordinates(lat, lng),
    );
  }

  Future<void> _useCachedLocation(
    _CachedLocation cached, {
    required String message,
  }) async {
    if (mounted) {
      setState(() {
        _coordinates = cached.coordinates;
        _locationName = cached.name ?? "Lokasi terakhir";
        _warningMessage = message;
        _isLoading = false;
        _isRefreshing = false;
        _errorMessage = null;
      });
    }
    await _calculatePrayerTimes(cached.coordinates);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }



  _NextPrayerInfo _resolveNextPrayer(
    PrayerTimes prayerTimes,
    Coordinates coordinates,
    CalculationParameters params,
  ) {
    final now = DateTime.now();
    final offset = Duration(minutes: _prayerSettings.value.correctionMinutes);
    final times = <Prayer, DateTime>{
      Prayer.fajr: prayerTimes.fajr.add(offset),
      Prayer.dhuhr: prayerTimes.dhuhr.add(offset),
      Prayer.asr: prayerTimes.asr.add(offset),
      Prayer.maghrib: prayerTimes.maghrib.add(offset),
      Prayer.isha: prayerTimes.isha.add(offset),
    };
    for (final prayer in [
      Prayer.fajr,
      Prayer.dhuhr,
      Prayer.asr,
      Prayer.maghrib,
      Prayer.isha,
    ]) {
      final time = times[prayer]!;
      if (time.isAfter(now)) {
        return _NextPrayerInfo(prayer, time);
      }
    }
    final tomorrow = PrayerTimes(
      coordinates,
      DateComponents.from(DateTime.now().add(const Duration(days: 1))),
      params,
    );
    return _NextPrayerInfo(Prayer.fajr, tomorrow.fajr.add(offset));
  }

  void _updateCountdown() {
    if (_nextPrayerTime == null) return;
    final diff = _nextPrayerTime!.difference(DateTime.now());
    if (diff.isNegative) {
      if (_coordinates != null && _prayerTimes != null) {
        unawaited(_calculatePrayerTimes(_coordinates!));
      }
      return;
    }
    setState(() => _timeRemaining = diff);
  }

  DateTime _applyOffset(DateTime time) {
    final minutes = _prayerSettings.value.correctionMinutes;
    return time.add(Duration(minutes: minutes));
  }



  Future<void> _storeLastLocation(Position position) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('last_lat', position.latitude);
    await prefs.setDouble('last_lng', position.longitude);
  }

  Future<void> _storeLastLocationName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_location_name', name);
  }

  Future<void> _handleRefresh() async {
    await _initLocationAndPrayers();
  }

  @override
  Widget build(BuildContext context) {
    final prayerTimes = _prayerTimes;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Jadwal Sholat"),
        actions: [
          IconButton(
            onPressed: _isRefreshing ? null : _handleRefresh,
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: _isLoading
            ? _buildLoadingState()
            : _errorMessage != null || prayerTimes == null
                ? _buildErrorState()
                : ListView(
                    padding: const EdgeInsets.all(20.0),
                    children: [
                      _buildHeaderCard(),
                      if (_warningMessage != null) ...[
                        const SizedBox(height: 12),
                        _buildWarningBanner(_warningMessage!),
                      ],
                      const SizedBox(height: 20),
                      _buildInfoRow(),
                      const SizedBox(height: 16),
                      _buildViewSwitcher(),
                      const SizedBox(height: 12),
                      ..._buildScheduleWidgets(prayerTimes),
                      const SizedBox(height: 16),
                      _buildSettingsSection(),
                      const SizedBox(height: 24),
                    ],
                  ),
      ),
    );
  }

  String _getPrayerName(Prayer p) {
    switch (p) {
      case Prayer.fajr: return "Subuh";
      case Prayer.sunrise: return "Syuruq";
      case Prayer.dhuhr: return "Dzuhur";
      case Prayer.asr: return "Ashar";
      case Prayer.maghrib: return "Maghrib";
      case Prayer.isha: return "Isya";
      default: return "-";
    }
  }

  Widget _buildViewSwitcher() {
    return SegmentedButton<ScheduleView>(
      segments: const [
        ButtonSegment(value: ScheduleView.today, label: Text('Hari Ini')),
        ButtonSegment(value: ScheduleView.week, label: Text('Mingguan')),
        ButtonSegment(value: ScheduleView.month, label: Text('Bulanan')),
      ],
      selected: {_view},
      onSelectionChanged: (value) {
        if (value.isEmpty) return;
        setState(() => _view = value.first);
      },
    );
  }

  List<Widget> _buildScheduleWidgets(PrayerTimes prayerTimes) {
    switch (_view) {
      case ScheduleView.today:
        return [
          _buildTimeRow(
            "Subuh",
            _applyOffset(prayerTimes.fajr),
            _nextPrayer == Prayer.fajr,
          ),
          _buildTimeRow(
            "Syuruq",
            _applyOffset(prayerTimes.sunrise),
            _nextPrayer == Prayer.sunrise,
          ),
          _buildTimeRow(
            "Dzuhur",
            _applyOffset(prayerTimes.dhuhr),
            _nextPrayer == Prayer.dhuhr,
          ),
          _buildTimeRow(
            "Ashar",
            _applyOffset(prayerTimes.asr),
            _nextPrayer == Prayer.asr,
          ),
          _buildTimeRow(
            "Maghrib",
            _applyOffset(prayerTimes.maghrib),
            _nextPrayer == Prayer.maghrib,
          ),
          _buildTimeRow(
            "Isya",
            _applyOffset(prayerTimes.isha),
            _nextPrayer == Prayer.isha,
          ),
        ];
      case ScheduleView.week:
        return _buildScheduleCards(7);
      case ScheduleView.month:
        return _buildScheduleCards(_daysInMonth(DateTime.now()));
    }
  }

  List<Widget> _buildScheduleCards(int days) {
    if (_coordinates == null) {
      return [
        Text(
          'Lokasi belum tersedia.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ];
    }
    final params = _prayerSettings.buildParameters();
    final offset = Duration(minutes: _prayerSettings.value.correctionMinutes);
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final cards = <Widget>[];
    for (var i = 0; i < days; i++) {
      final date = start.add(Duration(days: i));
      final times = PrayerTimes(
        _coordinates!,
        DateComponents.from(date),
        params,
      );
      final schedule = _DaySchedule(
        date: date,
        times: {
          Prayer.fajr: times.fajr.add(offset),
          Prayer.dhuhr: times.dhuhr.add(offset),
          Prayer.asr: times.asr.add(offset),
          Prayer.maghrib: times.maghrib.add(offset),
          Prayer.isha: times.isha.add(offset),
        },
      );
      cards.add(_buildDayCard(schedule));
    }
    return cards;
  }

  int _daysInMonth(DateTime date) {
    final nextMonth = DateTime(date.year, date.month + 1, 1);
    return nextMonth.subtract(const Duration(days: 1)).day;
  }

  Widget _buildDayCard(_DaySchedule schedule) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('EEE, d MMM y', 'id_ID').format(schedule.date),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _timeChip('Subuh', schedule.times[Prayer.fajr]!),
                _timeChip('Dzuhur', schedule.times[Prayer.dhuhr]!),
                _timeChip('Ashar', schedule.times[Prayer.asr]!),
                _timeChip('Maghrib', schedule.times[Prayer.maghrib]!),
                _timeChip('Isya', schedule.times[Prayer.isha]!),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeChip(String label, DateTime time) {
    return Chip(
      label: Text('$label ${DateFormat.Hm('id_ID').format(time)}'),
      backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
    );
  }

  Widget _buildTimeRow(String name, DateTime time, bool isNext) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isNext ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isNext ? Border.all(color: Theme.of(context).primaryColor, width: 1.5) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.access_time_filled, 
                size: 20, 
                color: isNext ? Theme.of(context).primaryColor : Colors.grey[400]
              ),
              const SizedBox(width: 16),
              Text(
                name, 
                style: GoogleFonts.poppins(
                  fontWeight: isNext ? FontWeight.bold : FontWeight.w500,
                  fontSize: 16,
                  color: isNext ? Theme.of(context).primaryColor : Theme.of(context).textTheme.bodyLarge?.color
                )
              ),
            ],
          ),
          Text(
            DateFormat.Hm('id_ID').format(time),
            style: GoogleFonts.poppins(
              fontSize: 18, 
              fontWeight: FontWeight.bold,
              color: isNext ? Theme.of(context).primaryColor : Theme.of(context).textTheme.bodyLarge?.color
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    final nextLabel = _nextPrayer != null && _nextPrayer != Prayer.none
        ? _getPrayerName(_nextPrayer!)
        : "Selesai";
    final nextTimeLabel = _nextPrayerTime != null
        ? DateFormat.Hm('id_ID').format(_nextPrayerTime!)
        : "--:--";
    final remaining = _formatDuration(_timeRemaining);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).primaryColor, const Color(0xFF0C4035)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE, d MMMM y', 'id_ID').format(DateTime.now()),
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _locationName,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.location_on, color: Colors.white, size: 24),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Sholat Berikutnya",
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      nextLabel,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    nextTimeLabel,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Sisa $remaining",
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.calculate, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              prayerMethodLabel(_prayerSettings.value.method),
              style: GoogleFonts.poppins(fontSize: 12),
            ),
          ),
          const SizedBox(width: 12),
          Icon(Icons.menu_book, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          Text(
            prayerMadhabLabel(_prayerSettings.value.madhab),
            style: GoogleFonts.poppins(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pengaturan',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.calculate),
                title: const Text('Metode Perhitungan'),
                subtitle: Text(prayerMethodLabel(_prayerSettings.value.method)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsPage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.tune),
                title: const Text('Koreksi Menit'),
                subtitle: Text(
                  _prayerSettings.value.correctionMinutes == 0
                      ? 'Tidak ada koreksi'
                      : '${_prayerSettings.value.correctionMinutes > 0 ? '+' : ''}${_prayerSettings.value.correctionMinutes} menit',
                ),
                onTap: _showCorrectionSheet,
              ),
              ListTile(
                leading: const Icon(Icons.notifications_active_outlined),
                title: const Text('Notifikasi per Waktu'),
                subtitle: const Text('Atur pengingat setiap sholat'),
                onTap: _showPrayerNotificationSheet,
              ),
              ListTile(
                leading: const Icon(Icons.volume_up_outlined),
                title: const Text('Suara Adzan'),
                subtitle: Text(_prayerSettings.value.adzanSound.label),
                onTap: _showAdzanSheet,
              ),
              SwitchListTile(
                title: const Text('Mode Silent Saat Sholat'),
                subtitle: const Text('Matikan suara notifikasi'),
                value: _prayerSettings.value.silentMode,
                onChanged: (value) async {
                  await _prayerSettings.setSilentMode(value);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showCorrectionSheet() {
    var temp = _prayerSettings.value.correctionMinutes.toDouble();
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Koreksi Menit',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      temp == 0
                          ? '0 menit'
                          : '${temp > 0 ? '+' : ''}${temp.toInt()} menit',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Slider(
                      value: temp,
                      min: -30,
                      max: 30,
                      divisions: 60,
                      label: temp.toInt().toString(),
                      onChanged: (value) {
                        setSheetState(() => temp = value);
                      },
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final navigator = Navigator.of(context);
                          await _prayerSettings
                              .updateCorrectionMinutes(temp.toInt());
                          if (!mounted) return;
                          navigator.pop();
                        },
                        child: const Text('Simpan'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showPrayerNotificationSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text('Notifikasi per Waktu'),
              ),
              SwitchListTile(
                title: const Text('Subuh'),
                value: _prayerSettings.value.notifyFajr,
                onChanged: (value) async {
                  await _prayerSettings.setNotificationEnabled(
                    Prayer.fajr,
                    value,
                  );
                },
              ),
              SwitchListTile(
                title: const Text('Dzuhur'),
                value: _prayerSettings.value.notifyDhuhr,
                onChanged: (value) async {
                  await _prayerSettings.setNotificationEnabled(
                    Prayer.dhuhr,
                    value,
                  );
                },
              ),
              SwitchListTile(
                title: const Text('Ashar'),
                value: _prayerSettings.value.notifyAsr,
                onChanged: (value) async {
                  await _prayerSettings.setNotificationEnabled(
                    Prayer.asr,
                    value,
                  );
                },
              ),
              SwitchListTile(
                title: const Text('Maghrib'),
                value: _prayerSettings.value.notifyMaghrib,
                onChanged: (value) async {
                  await _prayerSettings.setNotificationEnabled(
                    Prayer.maghrib,
                    value,
                  );
                },
              ),
              SwitchListTile(
                title: const Text('Isya'),
                value: _prayerSettings.value.notifyIsha,
                onChanged: (value) async {
                  await _prayerSettings.setNotificationEnabled(
                    Prayer.isha,
                    value,
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showAdzanSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(title: Text('Pilih Suara Adzan')),
              RadioGroup<AdzanSound>(
                groupValue: _prayerSettings.value.adzanSound,
                onChanged: (value) async {
                  if (value == null) return;
                  final navigator = Navigator.of(context);
                  await _prayerSettings.setAdzanSound(value);
                  if (!mounted) return;
                  navigator.pop();
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: AdzanSound.values
                      .map(
                        (sound) => RadioListTile<AdzanSound>(
                          value: sound,
                          title: Text(sound.label),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        const SizedBox(height: 20),
        ...List.generate(
          6,
          (index) => Container(
            height: 64,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 80),
        Icon(Icons.error_outline, size: 56, color: Colors.red[300]),
        const SizedBox(height: 16),
        Text(
          _errorMessage ?? "Gagal menghitung jadwal sholat",
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        const SizedBox(height: 16),
        Center(
          child: ElevatedButton.icon(
            onPressed: _initLocationAndPrayers,
            icon: const Icon(Icons.refresh),
            label: const Text("Coba Lagi"),
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class _NextPrayerInfo {
  final Prayer prayer;
  final DateTime time;

  const _NextPrayerInfo(this.prayer, this.time);
}

class _DaySchedule {
  final DateTime date;
  final Map<Prayer, DateTime> times;

  const _DaySchedule({
    required this.date,
    required this.times,
  });
}

class _ManualLocation {
  final String name;
  final Coordinates coordinates;

  const _ManualLocation({
    required this.name,
    required this.coordinates,
  });
}

class _CachedLocation {
  final String? name;
  final Coordinates coordinates;

  const _CachedLocation({
    required this.name,
    required this.coordinates,
  });
}
