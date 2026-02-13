import 'dart:async';

import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quran_app/core/di/injection.dart';
import 'package:quran_app/core/settings/prayer_settings.dart';
import 'package:quran_app/features/prayer_times/presentation/pages/prayer_times_page.dart';

class PrayerTimesSummaryCard extends StatefulWidget {
  const PrayerTimesSummaryCard({super.key});

  @override
  State<PrayerTimesSummaryCard> createState() => _PrayerTimesSummaryCardState();
}

class _PrayerTimesSummaryCardState extends State<PrayerTimesSummaryCard> {
  String _locationName = "Menentukan lokasi...";
  PrayerTimes? _prayerTimes;
  Prayer? _nextPrayer;
  DateTime? _nextPrayerTime;
  Duration _timeRemaining = Duration.zero;
  bool _isLoading = true;
  String? _errorMessage;
  Coordinates? _coordinates;
  bool _manualLocationEnabled = false;
  String? _manualLocationName;
  Timer? _ticker;
  final PrayerSettingsController _prayerSettings =
      getIt<PrayerSettingsController>();

  @override
  void initState() {
    super.initState();
    _prayerSettings.addListener(_onSettingsChanged);
    _prayerSettings.load();
    unawaited(_initCard());
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
      _calculatePrayerTimes(_coordinates!);
    }
  }

  Future<void> _initCard() async {
    await _loadFromLastLocation();
    await _initLocation();
  }

  Future<void> _loadFromLastLocation() async {
    final prefs = await SharedPreferences.getInstance();
    _manualLocationEnabled = prefs.getBool('manual_location_enabled') ?? false;
    _manualLocationName = prefs.getString('manual_location_name');
    final lastName = prefs.getString('last_location_name');
    final lat = prefs.getDouble('last_lat');
    final lng = prefs.getDouble('last_lng');
    if (lat != null && lng != null) {
      _coordinates = Coordinates(lat, lng);
      _calculatePrayerTimes(_coordinates!);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = null;
        if (_manualLocationEnabled && _manualLocationName != null) {
          _locationName = _manualLocationName!;
        } else if (lastName != null) {
          _locationName = lastName;
        }
      });
    }
  }

  Future<void> _initLocation() async {
    if (_manualLocationEnabled && _coordinates != null) {
      return;
    }
    final status = await Permission.locationWhenInUse.request();
    if (!status.isGranted) {
      if (!mounted) return;
      if (_prayerTimes == null) {
        setState(() {
          _errorMessage = "Izin lokasi dibutuhkan";
          _isLoading = false;
        });
      }
      return;
    }
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );
      _coordinates = Coordinates(position.latitude, position.longitude);
      await _storeLastLocation(position);
      await _resolveLocationName(position);
      _calculatePrayerTimes(_coordinates!);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = "Gagal memuat lokasi";
        _isLoading = false;
      });
    }
  }

  Future<void> _resolveLocationName(Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final name =
            "${place.subAdministrativeArea ?? place.locality}, ${place.country}";
        if (!mounted) return;
        setState(() {
          _locationName = name;
        });
        await _storeLastLocationName(name);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _locationName =
            "${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)}";
      });
    }
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

  void _calculatePrayerTimes(Coordinates coordinates) {
    final params = _prayerSettings.buildParameters();
    final prayerTimes = PrayerTimes.today(coordinates, params);
    final next = _resolveNextPrayer(prayerTimes, coordinates, params);
    if (!mounted) return;
    setState(() {
      _prayerTimes = prayerTimes;
      _nextPrayer = next.prayer;
      _nextPrayerTime = next.time;
      _isLoading = false;
      _errorMessage = null;
    });
    _updateCountdown();
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
        _calculatePrayerTimes(_coordinates!);
      }
      return;
    }
    setState(() => _timeRemaining = diff);
  }

  String _getPrayerName(Prayer p) {
    switch (p) {
      case Prayer.fajr:
        return "Subuh";
      case Prayer.dhuhr:
        return "Dzuhur";
      case Prayer.asr:
        return "Ashar";
      case Prayer.maghrib:
        return "Maghrib";
      case Prayer.isha:
        return "Isya";
      default:
        return "-";
    }
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [Theme.of(context).primaryColor, const Color(0xFF0C4035)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: _isLoading
          ? const SizedBox(
              height: 110,
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            )
          : _errorMessage != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _errorMessage!,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _initLocation,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Coba Lagi"),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE, d MMMM y').format(DateTime.now()),
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _locationName,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Sholat Berikutnya",
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _nextPrayer != null
                                ? _getPrayerName(_nextPrayer!)
                                : '- ',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          _nextPrayerTime != null
                              ? DateFormat.Hm().format(_nextPrayerTime!)
                              : '--:--',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Sisa ${_formatDuration(_timeRemaining)}",
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PrayerTimesPage(),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.open_in_new, size: 18),
                        label: const Text("Lihat Detail"),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _NextPrayerInfo {
  final Prayer prayer;
  final DateTime time;

  const _NextPrayerInfo(this.prayer, this.time);
}
