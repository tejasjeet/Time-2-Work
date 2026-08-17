import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const faqs = [
      ('How do I find work?', 'Open Jobs / Kaam, browse listings, and tap to apply. Use filters only when you want to narrow results.'),
      ('Kaam kaise dhundein?', 'Jobs tab kholen, listing dekhen, aur apply karein. Filter tab use karein jab zarurat ho.'),
      ('How do I post a job?', 'Tap + on the bottom bar, fill job details, preview, then pay the posting fee to go live.'),
      ('Are phone numbers shared?', 'No. Chat stays in-app. Time2Work never shows other users’ phone numbers.'),
      ('What is SOS?', 'Double-confirm in SOS / Aapatkaal to alert emergency contacts with your location.'),
      ('Local Bazar & Services', 'Buy/sell used items in Local Bazar. Book electricians, cleaners and more under Local Services.'),
      (AppStrings.tagline, 'Kaam Bhi, Rojgar Bhi, Bazar Bhi — your hyperlocal work marketplace.'),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Help')),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: faqs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final item = faqs[i];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.$1, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 6),
                Text(item.$2, style: const TextStyle(height: 1.35)),
              ],
            ),
          );
        },
      ),
    );
  }
}
