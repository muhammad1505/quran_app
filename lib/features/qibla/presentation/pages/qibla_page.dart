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
  double _lastHeading = 0.0;

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
        desiredAccuracy: LocationAccuracy.high,
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
    const double alpha = 0.1; // Smoothing factor (0.0 - 1.0). Lower is smoother but slower.
    
    // Handle wrap-around (360 -> 0)
    double diff = newHeading - _lastHeading;
    if (diff > 180) diff -= 360;
    if (diff < -180) diff += 360;

    _lastHeading += diff * alpha;
    
    // Normalize to 0-360
    if (_lastHeading < 0) _lastHeading += 360;
    if (_lastHeading >= 360) _lastHeading -= 360;

    return _lastHeading;
  }

  @override
  Widget build(BuildContext context) {
    final goldColor = const Color(0xFFD4AF37);

    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Force dark background for premium feel
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text("Arah Kiblat", style: GoogleFonts.poppins(color: Colors.white)),
        centerTitle: true,
      ),
      body: !_hasPermission
          ? _buildPermissionButton()
          : _qiblaDirection == null
              ? Center(child: CircularProgressIndicator(color: goldColor))
              : StreamBuilder<CompassEvent>(
                  stream: FlutterCompass.events,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) return Text('Error: ${snapshot.error}');
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator(color: goldColor));
                    }

                    double? rawHeading = snapshot.data?.heading;
                    if (rawHeading == null) return const Center(child: Text("Sensor tidak tersedia"));

                    // Apply Smoothing
                    double smoothedHeading = _smoothHeading(rawHeading);
                    
                    // Calculate Qibla relative to North
                    // We rotate the COMPASS DISK so North matches reality.
                    // Qibla needle is static relative to the disk, pointing at _qiblaDirection.
                    
                    // For UI:
                    // 1. Rotate the whole dial opposite to heading (-smoothedHeading)
                    // 2. This makes 'N' on the dial point North.
                    // 3. The Qibla needle should point to _qiblaDirection on the dial.

                    // Check alignment for Haptic Feedback
                    double diff = (smoothedHeading - _qiblaDirection!).abs();
                    if (diff < 2) {
                      HapticFeedback.selectionClick();
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
                              border: Border.all(color: goldColor.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  "Sudut Qibla",
                                  style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
                                ),
                                Text(
                                  "${_qiblaDirection!.toStringAsFixed(1)}°",
                                  style: GoogleFonts.poppins(
                                    color: goldColor,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 50),
                          
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
                                    border: Border.all(color: Colors.grey.withValues(alpha: 0.2), width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: goldColor.withValues(alpha: 0.1),
                                        blurRadius: 50,
                                        spreadRadius: 1,
                                      )
                                    ]
                                  ),
                                ),

                                // 2. Rotating Dial (The Card)
                                AnimatedRotation(
                                  duration: const Duration(milliseconds: 50), // Smooth via stream, but layout animation helps
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
                                            Icon(Icons.location_on, color: goldColor, size: 40),
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
                            style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
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
          backgroundColor: const Color(0xFFD4AF37),
          foregroundColor: Colors.black,
        ),
        onPressed: _checkPermissionAndCalculateQibla,
        child: const Text('Aktifkan GPS Presisi Tinggi'),
      ),
    );
  }
}