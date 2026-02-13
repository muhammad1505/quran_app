import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:quran_app/core/utils/battery_optimization_helper.dart';

class PermissionStatusCard extends StatefulWidget {
  const PermissionStatusCard({super.key});

  @override
  State<PermissionStatusCard> createState() => _PermissionStatusCardState();
}

class _PermissionStatusCardState extends State<PermissionStatusCard> {
  bool _notificationGranted = false;
  bool _exactAlarmGranted = false;
  bool _batteryOptimized = true;
  DeviceManufacturer _manufacturer = DeviceManufacturer.other;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() => _loading = true);
    
    final notification = await Permission.notification.status;
    final exactAlarm = await Permission.scheduleExactAlarm.status;
    final batteryOptimized = await BatteryOptimizationHelper.isBatteryOptimized();
    final manufacturer = await BatteryOptimizationHelper.getManufacturer();

    setState(() {
      _notificationGranted = notification.isGranted;
      _exactAlarmGranted = exactAlarm.isGranted;
      _batteryOptimized = batteryOptimized;
      _manufacturer = manufacturer;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final allGood = _notificationGranted && _exactAlarmGranted && !_batteryOptimized;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  allGood ? Icons.check_circle : Icons.warning_amber_rounded,
                  color: allGood ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  'Status Izin Notifikasi',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _PermissionItem(
              title: 'Izin Notifikasi',
              granted: _notificationGranted,
              onTap: () async {
                await Permission.notification.request();
                _checkPermissions();
              },
            ),
            const Divider(),
            _PermissionItem(
              title: 'Izin Alarm Tepat',
              subtitle: 'Diperlukan untuk notifikasi tepat waktu',
              granted: _exactAlarmGranted,
              onTap: () async {
                await Permission.scheduleExactAlarm.request();
                _checkPermissions();
              },
            ),
            const Divider(),
            _PermissionItem(
              title: 'Optimasi Baterai',
              subtitle: _batteryOptimized
                  ? 'App mungkin masih di-optimize. Periksa manual jika sudah di-nonaktifkan.'
                  : 'App tidak di-optimize ✅ (atau sudah di-nonaktifkan secara manual)',
              granted: !_batteryOptimized,
              onTap: () async {
                final messenger = ScaffoldMessenger.of(context);
                final result = await BatteryOptimizationHelper.requestDisableBatteryOptimization();
                _checkPermissions();
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      result
                          ? 'Battery optimization disabled ✅'
                          : 'Tidak bisa disable battery optimization otomatis. Ikuti panduan manual di bawah.',
                    ),
                    duration: const Duration(seconds: 3),
                  ),
                );
              },
            ),
            if (_batteryOptimized) ...[ 
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Deteksi optimasi baterai tidak 100% akurat. Jika sudah nonaktifkan secara manual, abaikan peringatan ini.',
                        style: TextStyle(fontSize: 11, color: Colors.orange.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_batteryOptimized && _manufacturer != DeviceManufacturer.other) ...[
              const SizedBox(height: 16),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text(
                  'Panduan Nonaktifkan Optimasi',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      BatteryOptimizationHelper.getBatteryOptimizationGuide(_manufacturer),
                      style: const TextStyle(fontSize: 12, height: 1.5),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PermissionItem extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool granted;
  final VoidCallback onTap;

  const _PermissionItem({
    required this.title,
    this.subtitle,
    required this.granted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        granted ? Icons.check_circle : Icons.cancel,
        color: granted ? Colors.green : Colors.red,
      ),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!, style: const TextStyle(fontSize: 12)) : null,
      trailing: granted
          ? null
          : TextButton(
              onPressed: onTap,
              child: const Text('Izinkan'),
            ),
    );
  }
}
