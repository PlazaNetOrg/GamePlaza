import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ProfileAvatar extends StatelessWidget {
  final String? userName;
  final double size;

  const ProfileAvatar({
    super.key,
    required this.userName,
    this.size = 40,
  });

  String _getInitial() {
    if (userName == null || userName!.isEmpty) {
      return '?';
    }
    return userName![0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryBlue,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          _getInitial(),
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
