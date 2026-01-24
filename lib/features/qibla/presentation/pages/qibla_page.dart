import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class QiblaPage extends StatefulWidget {
  const QiblaPage({super.key});

  @override
  State<QiblaPage> createState() => _QiblaPageState();
}

class _QiblaPageState extends State<QiblaPage> {
  double? _qiblaDirection;
  bool _hasPermission = false;
  double? _lastHeading;
  final List<double> _headingBuffer = [];
  DateTime? _lastHapticAt;
  String? _accuracyMessage;

  @override
  void initState() {
    super.initState();
    _checkPermissionAndCalculateQibla();
  }

  Future<void> _checkPermissionAndCalculateQibla() async {
    final status = await Permission.locationWhenInUse.request();
    if (status.isGranted) {
      setState(() => _hasPermission = true);
      // High accuracy for better initial lock
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );
      
      final coordinates = Coordinates(position.latitude, position.longitude);
      final qibla = Qibla(coordinates);
      setState(() {
        _qiblaDirection = qibla.direction;
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Izin lokasi diperlukan untuk akurasi tinggi')),
        );
      }
    }
  }

  // Low-Pass Filter to smooth out sensor jitter
  double _smoothHeading(double newHeading) {
    // Keep last few readings and compute circular mean to reduce jitter.
    _headingBuffer.add(newHeading);
    if (_headingBuffer.length > 6) {
      _headingBuffer.removeAt(0);
    }
    final average = _circularMean(_headingBuffer);
    final previous = _lastHeading ?? average;
    final diff = _angleDelta(average, previous);
    final alpha = diff.abs() > 10 ? 0.2 : 0.08;
    var filtered = previous + diff * alpha;
    filtered = _normalizeAngle(filtered);
    _lastHeading = filtered;
    return filtered;
  }

  double _circularMean(List<double> angles) {
    double sinSum = 0;
    double cosSum = 0;
    for (final angle in angles) {
      final radians = angle * math.pi / 180;
      sinSum += math.sin(radians);
      cosSum += math.cos(radians);
    }
    final mean = math.atan2(sinSum, cosSum) * 180 / math.pi;
    return _normalizeAngle(mean);
  }

  double _angleDelta(double target, double source) {
    var diff = target - source;
    if (diff > 180) diff -= 360;
    if (diff < -180) diff += 360;
    return diff;
  }

  double _normalizeAngle(double angle) {
    var normalized = angle % 360;
    if (normalized < 0) normalized += 360;
    return normalized;
  }

  double? _resolveHeading(CompassEvent? event) {
    if (event == null) return null;
    final dynamic raw = event;
    try {
      final headingForCompass = raw.headingForCompass;
      if (headingForCompass is double) return headingForCompass;
    } catch (_) {
      // Ignore if property is not available on this platform.
    }
    return event.heading;
  }

  String? _resolveAccuracyMessage(CompassEvent? event) {
    if (event == null) return null;
    final dynamic raw = event;
    try {
      final accuracy = raw.accuracy;
      if (accuracy is double && accuracy >= 0 && accuracy > 15) {
        return 'Akurasi rendah. Gerakkan ponsel membentuk angka 8.';
      }
    } catch (_) {
      // Ignore if property is not available on this platform.
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;
    final subtleText =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        title: Text("Arah Kiblat", style: GoogleFonts.poppins(color: textColor)),
        centerTitle: true,
      ),
      body: !_hasPermission
          ? _buildPermissionButton()
          : _qiblaDirection == null
              ? Center(
                  child: CircularProgressIndicator(color: colorScheme.secondary),
                )
              : StreamBuilder<CompassEvent>(
                  stream: FlutterCompass.events,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) return Text('Error: ${snapshot.error}');
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: colorScheme.secondary,
                        ),
                      );
                    }

                    final rawHeading = _resolveHeading(snapshot.data);
                    if (rawHeading == null) {
                      return const Center(child: Text("Sensor tidak tersedia"));
                    }
                    _accuracyMessage = _resolveAccuracyMessage(snapshot.data);

                    // Apply Smoothing
                    final normalizedHeading = _normalizeAngle(rawHeading);
                    double smoothedHeading = _smoothHeading(normalizedHeading);
                    
                    // Calculate Qibla relative to North
                    // We rotate the COMPASS DISK so North matches reality.
                    // Qibla needle is static relative to the disk, pointing at _qiblaDirection.
                    
                    // For UI:
                    // 1. Rotate the whole dial opposite to heading (-smoothedHeading)
                    // 2. This makes 'N' on the dial point North.
                    // 3. The Qibla needle should point to _qiblaDirection on the dial.

                    // Check alignment for Haptic Feedback
                    final diff =
                        _angleDelta(smoothedHeading, _qiblaDirection!).abs();
                    if (diff < 2) {
                      final now = DateTime.now();
                      if (_lastHapticAt == null ||
                          now.difference(_lastHapticAt!) >
                              const Duration(seconds: 2)) {
                        HapticFeedback.selectionClick();
                        _lastHapticAt = now;
                      }
                    }

                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Digital Indicator
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: colorScheme.secondary.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  "Sudut Qibla",
                                  style: GoogleFonts.poppins(
                                    color: subtleText,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  "${_qiblaDirection!.toStringAsFixed(1)}°",
                                  style: GoogleFonts.poppins(
                                    color: colorScheme.secondary,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (_accuracyMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                _accuracyMessage!,
                                style: GoogleFonts.poppins(
                                  color: Colors.orangeAccent,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          const SizedBox(height: 18),
                          
                          // THE COMPASS UI
                          SizedBox(
                            height: 320,
                            width: 320,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // 1. Outer Ring (Static decoration)
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.grey.withValues(alpha: 0.2),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: colorScheme.secondary.withValues(alpha: 0.1),
                                        blurRadius: 50,
                                        spreadRadius: 1,
                                      )
                                    ]
                                  ),
                                ),

                                // 2. Rotating Dial (The Card)
                                AnimatedRotation(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeOut,
                                  turns: -smoothedHeading / 360,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Dial Image/Icon
                                      Icon(Icons.explore, size: 300, color: Colors.grey.withValues(alpha: 0.3)),
                                      
                                      // North Indicator (Simulated)
                                      Positioned(
                                        top: 20,
                                        child: Text("N", style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 24)),
                                      ),
                                      Positioned(
                                        bottom: 20,
                                        child: Text("S", style: GoogleFonts.poppins(color: Colors.white, fontSize: 24)),
                                      ),
                                      Positioned(
                                        right: 20,
                                        child: Text("E", style: GoogleFonts.poppins(color: Colors.white, fontSize: 24)),
                                      ),
                                      Positioned(
                                        left: 20,
                                        child: Text("W", style: GoogleFonts.poppins(color: Colors.white, fontSize: 24)),
                                      ),

                                      // Qibla Target Marker on the Dial
                                      Transform.rotate(
                                        angle: (_qiblaDirection! * (math.pi / 180)),
                                        child: Column(
                                          children: [
                                            Icon(
                                              Icons.location_on,
                                              color: colorScheme.secondary,
                                              size: 40,
                                            ),
                                            const Spacer(),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // 3. Center Pivot & Fixed Needle (Device Heading)
                                // Actually, simpler logic:
                                // Let's keep the Dial Static North-Up, and rotate the NEEDLE?
                                // No, standard compass apps rotate the Dial so 'N' matches real North.
                                
                                // Fixed Center Indicator (Your Phone's orientation)
                                Icon(Icons.arrow_drop_up, color: Colors.white.withValues(alpha: 0.5), size: 50),
                              ],
                            ),
                          ),
                          const SizedBox(height: 50),
                          
                          // Status Text
                          Text(
                            "Sejajarkan ikon Ka'bah dengan panah",
                            style: GoogleFonts.poppins(color: subtleText, fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildPermissionButton() {
    return Center(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.secondary,
          foregroundColor: Colors.black,
        ),
        onPressed: _checkPermissionAndCalculateQibla,
        child: const Text('Aktifkan GPS Presisi Tinggi'),
      ),
    );
  }
}
