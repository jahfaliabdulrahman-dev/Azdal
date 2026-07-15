import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:azdal/app/brand.dart';

/// حسابي tab — hosts bank linking (per the designer's settings-style
/// reference page), the journey/vision screen, and the OPTIONAL account
/// upgrade (DEC-017: anonymous experience is never gated behind login).
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    // Re-render when the anonymous session upgrades to a real account.
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final isAnon = user?.isAnonymous ?? true;
    final fullName = (user?.userMetadata?['full_name'] as String?)?.trim();

    return Scaffold(
      backgroundColor: Brand.surface,
      appBar: AppBar(title: const Text('حسابي')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _IdentityCard(isAnon: isAnon, name: fullName, email: user?.email),
          const SizedBox(height: 24),
          const _SectionLabel('رؤية أزدل'),
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Brand.border),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Brand.green.withValues(alpha: 0.12),
                child: const Icon(Icons.trending_up_rounded, color: Brand.green),
              ),
              title: const Text('خطتك نحو الاستثمار',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('من مديون... إلى مستثمر — شاهد مراحل رحلتك'),
              trailing: const Icon(Icons.chevron_left, color: Brand.muted),
              onTap: () => context.push('/journey'),
            ),
          ),
          const SizedBox(height: 24),
          const _SectionLabel('الربط البنكي'),
          _SettingsRow(
            icon: Icons.account_balance_outlined,
            title: 'ربط الحساب البنكي',
            subtitle: 'لكي يستطيع أزدل متابعة مصروفاتك تلقائياً',
            onTap: () => context.push('/bank-linking'),
          ),
          const SizedBox(height: 24),
          const _SectionLabel('الحساب'),
          if (isAnon) ...[
            _SettingsRow(
              icon: Icons.person_add_alt_outlined,
              title: 'أنشئ حسابك في أزدل',
              subtitle: 'حساب دائم — كل بياناتك الحالية تنتقل معك',
              onTap: () => context.push('/signup'),
            ),
            const SizedBox(height: 12),
            _SettingsRow(
              icon: Icons.login_outlined,
              title: 'تسجيل الدخول',
              subtitle: 'لديك حساب بالفعل؟ سجّل دخولك',
              onTap: () => context.push('/login'),
            ),
          ] else
            _SettingsRow(
              icon: Icons.verified_outlined,
              title: 'حسابك دائم وموثق',
              subtitle: user?.email ?? '',
              onTap: null,
            ),
          const SizedBox(height: 32),
          const Center(
            child: Text(
              'أزدل 0.1.0 — نسخة تجريبية',
              style: TextStyle(color: Brand.muted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.isAnon, this.name, this.email});

  final bool isAnon;
  final String? name;
  final String? email;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Brand.border),
      ),
      child: Row(
        children: [
          const BrandMark(size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAnon
                      ? 'ضيف أزدل'
                      : (name?.isNotEmpty == true ? name! : 'حسابي'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: Brand.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isAnon
                      ? 'حسابك مؤقت على هذا الجهاز — أنشئ حساباً دائماً لحفظه'
                      : (email ?? ''),
                  style: const TextStyle(fontSize: 12, color: Brand.muted),
                ),
              ],
            ),
          ),
          if (!isAnon)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Brand.greenTint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'موثق',
                style: TextStyle(
                  fontSize: 11,
                  color: Brand.green,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 4, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: Brand.navy,
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: Brand.border),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Brand.cyanTint,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Brand.navy, size: 22),
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
                        fontSize: 14.5,
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
                  ],
                ),
              ),
              if (onTap != null)
                // chevron_left points "forward" in RTL reading direction.
                const Icon(Icons.chevron_left, color: Brand.muted)
              else
                const Icon(Icons.check_circle, color: Brand.green, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
