import 'package:flutter/material.dart';
import 'package:quran_app/core/di/injection.dart';
import 'package:quran_app/core/settings/quran_settings.dart';
import 'package:quran_app/core/settings/theme_settings.dart';

class QuranDisplaySettingsSheet extends StatelessWidget {
  const QuranDisplaySettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final quranSettings = getIt<QuranSettingsController>();
    final themeSettings = getIt<ThemeSettingsController>();

    return AnimatedBuilder(
      animation: Listenable.merge([quranSettings, themeSettings]),
      builder: (context, _) {
        final settings = quranSettings.value;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'Tampilan',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    Text(
                      'Aa',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSlider(
                  label: 'Ukuran Arab',
                  value: settings.arabicFontSize,
                  min: 26,
                  max: 38,
                  onChanged: (value) =>
                      quranSettings.setArabicFontSize(value),
                ),
                _buildSlider(
                  label: 'Ukuran Terjemahan',
                  value: settings.translationFontSize,
                  min: 12,
                  max: 20,
                  onChanged: (value) =>
                      quranSettings.setTranslationFontSize(value),
                ),
                _buildSlider(
                  label: 'Spasi Baris Arab',
                  value: settings.arabicLineHeight,
                  min: 1.6,
                  max: 2.6,
                  onChanged: (value) =>
                      quranSettings.setArabicLineHeight(value),
                ),
                _buildSlider(
                  label: 'Spasi Baris Terjemahan',
                  value: settings.translationLineHeight,
                  min: 1.2,
                  max: 2.2,
                  onChanged: (value) =>
                      quranSettings.setTranslationLineHeight(value),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<ArabicFontFamily>(
                  initialValue: settings.arabicFontFamily,
                  decoration: const InputDecoration(
                    labelText: 'Font Arab',
                    border: OutlineInputBorder(),
                  ),
                  items: ArabicFontFamily.values
                      .map(
                        (font) => DropdownMenuItem(
                          value: font,
                          child: Text(font.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      quranSettings.setArabicFontFamily(value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Transliterasi (Latin)'),
                  value: settings.showLatin,
                  onChanged: (value) => quranSettings.setShowLatin(value),
                ),
                SwitchListTile(
                  title: const Text('Tajwid'),
                  value: settings.showTajwid,
                  onChanged: (value) => quranSettings.setShowTajwid(value),
                ),
                SwitchListTile(
                  title: const Text('Terjemahan per kata'),
                  value: settings.showWordByWord,
                  onChanged: (value) =>
                      quranSettings.setShowWordByWord(value),
                ),
                const Divider(height: 24),
                _buildThemeSelector(context, themeSettings),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeSelector(BuildContext context, ThemeSettingsController themeSettings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mode Tema',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        SegmentedButton<AppThemeMode>(
          segments: const [
            ButtonSegment(value: AppThemeMode.light, label: Text('Terang')),
            ButtonSegment(value: AppThemeMode.dark, label: Text('Gelap')),
            ButtonSegment(value: AppThemeMode.sepia, label: Text('Sepia')),
          ],
          selected: {themeSettings.value.mode},
          onSelectionChanged: (value) {
            if (value.isEmpty) return;
            themeSettings.setThemeMode(value.first);
          },
        ),
      ],
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label),
              const Spacer(),
              Text(value.toStringAsFixed(0)),
            ],
          ),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
