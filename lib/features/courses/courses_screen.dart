import 'package:flutter/material.dart';

import 'package:azdal/app/brand.dart';

/// Courses tab — MOCK content for the demo. Course order deliberately
/// mirrors the brand tagline arc: budgeting → debt payoff → emergency
/// fund → first investment ("من مديون... إلى مستثمر").
class CoursesScreen extends StatelessWidget {
  const CoursesScreen({super.key});

  static const _courses = [
    (
      icon: Icons.savings_outlined,
      title: 'أساسيات الميزانية',
      subtitle: 'أكملت 3 من 5 دروس',
      progress: 0.6,
      soon: false,
    ),
    (
      icon: Icons.credit_card_off_outlined,
      title: 'خطة سداد الديون',
      subtitle: '4 دروس · 25 دقيقة',
      progress: 0.0,
      soon: false,
    ),
    (
      icon: Icons.health_and_safety_outlined,
      title: 'صندوق الطوارئ',
      subtitle: '3 دروس · 15 دقيقة',
      progress: 0.0,
      soon: true,
    ),
    (
      icon: Icons.show_chart,
      title: 'أولى خطوات الاستثمار',
      subtitle: '6 دروس · 40 دقيقة',
      progress: 0.0,
      soon: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Brand.surface,
      appBar: AppBar(title: const Text('الدورات التعليمية')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Brand.navy, Color(0xFF0A4DA6)],
                begin: AlignmentDirectional.topStart,
                end: AlignmentDirectional.bottomEnd,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'رحلتك التعليمية',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'من مديون... إلى مستثمر — خطوة بخطوة',
                  style: TextStyle(color: Brand.cyan, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (final c in _courses) ...[
            _CourseCard(
              icon: c.icon,
              title: c.title,
              subtitle: c.subtitle,
              progress: c.progress,
              soon: c.soon,
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.soon,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final double progress;
  final bool soon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('محتوى تجريبي — الدورات التعليمية قادمة قريباً'),
            behavior: SnackBarBehavior.floating,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: Brand.border),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Brand.cyanTint,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Brand.navy, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: Brand.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Brand.muted,
                      ),
                    ),
                    if (progress > 0) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          color: Brand.green,
                          backgroundColor: Brand.greenTint,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (soon)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Brand.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Brand.border),
                  ),
                  child: const Text(
                    'قريباً',
                    style: TextStyle(fontSize: 11, color: Brand.muted),
                  ),
                )
              else
                const Icon(Icons.chevron_left, color: Brand.muted),
            ],
          ),
        ),
      ),
    );
  }
}
