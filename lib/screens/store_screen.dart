import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_colors.dart';
import '../l10n/app_localizations.dart';

class StoreScreen extends StatefulWidget {
  final String label;
  final IconData icon;

  const StoreScreen({
    super.key,
    required this.label,
    required this.icon,
  });

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  bool _opened = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openPlayStore());
  }

  Future<void> _openPlayStore() async {
    if (_opened) return;
    _opened = true;

    // Google Play Store APp
    final playStoreAppUri = Uri.parse('com.android.vending://');
    if (await canLaunchUrl(playStoreAppUri)) {
      try {
        await launchUrl(playStoreAppUri, mode: LaunchMode.externalApplication);
        return;
      } catch (e) {}
    }

    // Web Fallback
    final webUri = Uri.parse('https://play.google.com/store');
    if (await canLaunchUrl(webUri)) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).storeUnableToOpen),
          backgroundColor: AppColors.elevatedSurface,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Text(
        l10n.loading,
        style: TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}
