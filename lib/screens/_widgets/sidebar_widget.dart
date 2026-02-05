import 'package:flutter/material.dart';
import 'package:battery_plus/battery_plus.dart';
import '../../theme/app_colors.dart';
import '../../models/models.dart';
import '../../widgets/profile_avatar.dart';

class SidebarWidget extends StatelessWidget {
  final int selectedIndex;
  final List<NavigationItem> navItems;
  final String? userName;
  final String currentTime;
  final int batteryLevel;
  final BatteryState batteryState;
  final ValueChanged<int> onNavItemPressed;

  const SidebarWidget({
    super.key,
    required this.selectedIndex,
    required this.navItems,
    required this.userName,
    required this.currentTime,
    required this.batteryLevel,
    required this.batteryState,
    required this.onNavItemPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkBattery = batteryState == BatteryState.discharging && batteryLevel < 15;
    return Container(
      width: 240,
      color: AppColors.darkSurface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ProfileAvatar(userName: userName, size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(userName ?? 'Player', style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(currentTime, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.divider, height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: navItems.length,
              itemBuilder: (context, index) {
                final item = navItems[index];
                final isSelected = selectedIndex == index;
                return _NavItemButton(
                  item: item,
                  isSelected: isSelected,
                  onPressed: () => onNavItemPressed(index),
                );
              },
            ),
          ),
          const Divider(color: AppColors.divider, height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  batteryState == BatteryState.charging ? Icons.battery_charging_full : Icons.battery_std,
                  color: isDarkBattery ? Colors.red : AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '$batteryLevel%',
                  style: TextStyle(
                    color: isDarkBattery ? Colors.red : AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItemButton extends StatelessWidget {
  final NavigationItem item;
  final bool isSelected;
  final VoidCallback onPressed;

  const _NavItemButton({
    required this.item,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryBlue : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  item.label,
                  style: TextStyle(
                    color: isSelected ? Colors.black : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
