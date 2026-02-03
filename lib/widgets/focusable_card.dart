import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class FocusableCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onActivate;
  final bool autofocus;
  final EdgeInsets padding;
  final double borderRadius;

  const FocusableCard({
    super.key,
    required this.child,
    this.onActivate,
    this.autofocus = false,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
          onActivate?.call();
          return null;
        }),
      },
      child: Focus(
        autofocus: autofocus,
        child: Builder(
          builder: (context) {
            final focused = Focus.of(context).hasFocus;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              padding: padding,
              decoration: BoxDecoration(
                color: AppColors.elevatedSurface,
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color: focused ? AppColors.primaryBlue : Colors.transparent,
                  width: 4,
                ),
              ),
              child: child,
            );
          },
        ),
      ),
    );
  }
}

