import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../l10n/app_localizations.dart';

class PlazaNetScreen extends StatelessWidget {
  final String label;
  final IconData icon;

  const PlazaNetScreen({
    super.key,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return _ComingSoonPlaceholder(label: label, icon: icon);
  }
}

class _ComingSoonPlaceholder extends StatelessWidget {
  final String label;
  final IconData icon;

  const _ComingSoonPlaceholder({
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.elevatedSurface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, size: 64, color: AppColors.primaryBlue),
          ),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context).plazaNetComingSoonTitle(label),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).plazaNetComingSoonSubtitle,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
