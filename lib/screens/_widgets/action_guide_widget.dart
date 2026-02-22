import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/models.dart';

class ActionGuideWidget extends StatelessWidget {
  final List<ActionHint> hints;

  const ActionGuideWidget({super.key, required this.hints});

  @override
  Widget build(BuildContext context) {
    if (hints.isEmpty) return const SizedBox.shrink();

    return Container(
      color: AppColors.darkSurface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: List.generate(
          hints.length,
          (i) => Padding(
            padding: EdgeInsets.only(right: i < hints.length - 1 ? 24 : 0),
            child: _ActionHintItem(hint: hints[i]),
          ),
        ),
      ),
    );
  }
}

class _ActionHintItem extends StatelessWidget {
  final ActionHint hint;

  const _ActionHintItem({required this.hint});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primaryBlue),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(
              hint.button,
              style: TextStyle(
                color: AppColors.primaryBlue,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          hint.label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
