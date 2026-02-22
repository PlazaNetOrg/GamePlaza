import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
class TopBarWidget extends StatelessWidget {
  final String label;

  const TopBarWidget({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.darkSurface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
