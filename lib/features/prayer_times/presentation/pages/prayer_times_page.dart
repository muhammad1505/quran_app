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
  Coordinates? _coordinates;
  final PrayerSettingsController _prayerSettings =
      PrayerSettingsController.instance;
  Timer? _ticker;

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
      });
      final manual = await _loadManualLocation();
      if (manual != null) {
        _coordinates = manual.coordinates;
        _locationName = manual.name;
        await _calculatePrayerTimes(_coordinates!);
        return;
      }
      // 1. Permission Check
      final status = await Permission.locationWhenInUse.request();
      if (!status.isGranted) {
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
          setState(() {
            _locationName =
                "${place.subAdministrativeArea ?? place.locality}, ${place.country}";
          });
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
    final next = _resolveNextPrayer(prayerTimes, coordinates, params);
    setState(() {
      _prayerTimes = prayerTimes;
      _nextPrayer = next.prayer;
      _nextPrayerTime = next.time;
      _isLoading = false;
      _isRefreshing = false;
    });
    _updateCountdown();
    await _scheduleNotificationsIfEnabled(prayerTimes, coordinates, params);
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

  Future<void> _scheduleNotificationsIfEnabled(
    PrayerTimes today,
    Coordinates coordinates,
    CalculationParameters params,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('notifications') ?? true;
    if (!enabled) {
      await PrayerNotificationService.instance.cancelAll();
      return;
    }
    final tomorrow = PrayerTimes(
      coordinates,
      DateComponents.from(DateTime.now().add(const Duration(days: 1))),
      params,
    );
    await PrayerNotificationService.instance.schedulePrayerTimes(
      today,
      tomorrow,
    );
  }

  _NextPrayerInfo _resolveNextPrayer(
    PrayerTimes prayerTimes,
    Coordinates coordinates,
    CalculationParameters params,
  ) {
    final next = prayerTimes.nextPrayer();
    final nextTime = prayerTimes.timeForPrayer(next);
    if (next != Prayer.none && nextTime != null) {
      return _NextPrayerInfo(next, nextTime);
    }
    final tomorrow = PrayerTimes(
      coordinates,
      DateComponents.from(DateTime.now().add(const Duration(days: 1))),
      params,
    );
    return _NextPrayerInfo(Prayer.fajr, tomorrow.fajr);
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

  Future<void> _storeLastLocation(Position position) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('last_lat', position.latitude);
    await prefs.setDouble('last_lng', position.longitude);
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
                      const SizedBox(height: 20),
                      _buildInfoRow(),
                      const SizedBox(height: 16),
                      _buildTimeRow(
                        "Subuh",
                        prayerTimes.fajr,
                        _nextPrayer == Prayer.fajr,
                      ),
                      _buildTimeRow(
                        "Syuruq",
                        prayerTimes.sunrise,
                        _nextPrayer == Prayer.sunrise,
                      ),
                      _buildTimeRow(
                        "Dzuhur",
                        prayerTimes.dhuhr,
                        _nextPrayer == Prayer.dhuhr,
                      ),
                      _buildTimeRow(
                        "Ashar",
                        prayerTimes.asr,
                        _nextPrayer == Prayer.asr,
                      ),
                      _buildTimeRow(
                        "Maghrib",
                        prayerTimes.maghrib,
                        _nextPrayer == Prayer.maghrib,
                      ),
                      _buildTimeRow(
                        "Isya",
                        prayerTimes.isha,
                        _nextPrayer == Prayer.isha,
                      ),
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
            DateFormat.Hm().format(time),
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
        ? DateFormat.Hm().format(_nextPrayerTime!)
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
                      DateFormat('EEEE, d MMMM y').format(DateTime.now()),
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

class _ManualLocation {
  final String name;
  final Coordinates coordinates;

  const _ManualLocation({
    required this.name,
    required this.coordinates,
  });
}
