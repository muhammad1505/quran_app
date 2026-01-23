import 'package:flutter/material.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';

class QiblaPage extends StatelessWidget {
  const QiblaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Arah Kiblat")),
      body: FutureBuilder(
        future: FlutterQiblah.androidDeviceSensorSupport(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (snapshot.data == true) {
            return const QiblaCompass();
          } else {
            return const Center(child: Text("Perangkat ini tidak mendukung sensor arah kiblat."));
          }
        },
      ),
    );
  }
}

class QiblaCompass extends StatelessWidget {
  const QiblaCompass({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FlutterQiblah.qiblaStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor));
        }

        final qiblaDirection = snapshot.data!;
        final direction = qiblaDirection.qibla;

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               Text(
                "Arah Ka'bah",
                style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 10),
              Text(
                "${direction.toStringAsFixed(1)}°", 
                style: GoogleFonts.poppins(
                  fontSize: 56, 
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor
                )
              ),
              const SizedBox(height: 40),
              Stack(
                alignment: Alignment.center,
                children: [
                  // Compass background
                  Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).cardTheme.color ?? Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 30,
                          spreadRadius: 5,
                        )
                      ],
                    ),
                  ),
                   // Compass Ticks
                  Container(
                    width: 300,
                    height: 300,
                     decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.withOpacity(0.2), width: 2),
                    ),
                  ),
                  // Needle
                  Transform.rotate(
                    angle: (direction * (math.pi / 180) * -1),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                         // Custom Compass Art
                         Icon(Icons.compass_calibration_outlined, size: 280, color: Colors.grey.withOpacity(0.2)),
                         
                         // The Needle
                         Column(
                           mainAxisSize: MainAxisSize.min,
                           children: [
                             Icon(Icons.navigation, size: 60, color: Theme.of(context).primaryColor),
                             const SizedBox(height: 60), // Offset to center the rotation point roughly
                           ],
                         )
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Container(
                 padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                 decoration: BoxDecoration(
                   color: Theme.of(context).primaryColor.withOpacity(0.1),
                   borderRadius: BorderRadius.circular(30),
                 ),
                 child: Row(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     const Icon(Icons.info_outline, size: 20),
                     const SizedBox(width: 10),
                     Text("Pastikan GPS aktif & kalibrasi kompas", style: GoogleFonts.poppins(fontSize: 12)),
                   ],
                 ),
              )
            ],
          ),
        );
      },
    );
  }
}
