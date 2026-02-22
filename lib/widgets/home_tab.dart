import 'dart:async';

import 'package:flutter/material.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:intl/intl.dart';

import '../theme/app_colors.dart';
import '../widgets/focusable_card.dart';
import '../services/game_library_service.dart';
import '../l10n/app_localizations.dart';

class HomeTab extends StatefulWidget {
  final List<Game> games;
  final int allAppsCount;
  final bool isLoading;
  final VoidCallback onGoToLibrary;
  final void Function(Game) onOpenGameDetail;
  final void Function(Game) onLaunchGame;
  final ImageProvider? Function(Game) coverImageProvider;
  final String Function(DateTime) formatLastPlayed;

  const HomeTab({
    super.key,
    required this.games,
    required this.allAppsCount,
    required this.isLoading,
    required this.onGoToLibrary,
    required this.onOpenGameDetail,
    required this.onLaunchGame,
    required this.coverImageProvider,
    required this.formatLastPlayed,
  });

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  String _currentTime = '';
  String _currentDate = '';
  int _batteryLevel = 100;
  BatteryState _batteryState = BatteryState.unknown;
  Timer? _timer;
  final Battery _battery = Battery();
  StreamSubscription<BatteryState>? _batterySubscription;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _updateBattery();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
    _batterySubscription = _battery.onBatteryStateChanged.listen((state) {
      if (!mounted) return;
      setState(() => _batteryState = state);
      _updateBattery();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _batterySubscription?.cancel();
    super.dispose();
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _currentTime = DateFormat('HH:mm').format(now);
      _currentDate = DateFormat('EEEE, d MMMM').format(now);
    });
  }

  Future<void> _updateBattery() async {
    final level = await _battery.batteryLevel;
    final state = await _battery.batteryState;
    if (!mounted) return;
    setState(() {
      _batteryLevel = level;
      _batteryState = state;
    });
  }

  Game? get _lastPlayedGame {
    final played = widget.games.where((g) => g.lastPlayed != null).toList()
      ..sort((a, b) => b.lastPlayed!.compareTo(a.lastPlayed!));
    if (played.isNotEmpty) return played.first;
    if (widget.games.isNotEmpty) return widget.games.first;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.primaryBlue),
      );
    }

    final game = _lastPlayedGame;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: _buildLastPlayedCard(game),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: _buildStatusCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildLastPlayedCard(Game? game) {
    return FocusableCard(
      autofocus: true,
      onActivate: () {
        if (game != null) {
          widget.onOpenGameDetail(game);
        } else {
          widget.onGoToLibrary();
        }
      },
      child: game == null ? _buildNoGamesContent() : _buildGameContent(game),
    );
  }

  Widget _buildNoGamesContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.videogame_asset_outlined,
          size: 64,
          color: AppColors.textSecondary,
        ),
        const SizedBox(height: 16),
        Text(
          AppLocalizations.of(context).homeNoGamesTitle,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context).homeNoGamesSubtitle,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: widget.onGoToLibrary,
          icon: const Icon(Icons.add),
          label: Text(AppLocalizations.of(context).homeGoToLibrary),
        ),
      ],
    );
  }

  Widget _buildGameContent(Game game) {
    final coverImage = widget.coverImageProvider(game);
    return Row(
      children: [
        Container(
          width: 160,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: coverImage != null
                ? DecorationImage(
                    image: coverImage,
                    fit: BoxFit.cover,
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppLocalizations.of(context).homeLastPlayedLabel,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                game.title,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                game.lastPlayed != null
                    ? widget.formatLastPlayed(game.lastPlayed!)
                    : AppLocalizations.of(context).homeNeverPlayed,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => widget.onLaunchGame(game),
                    icon: const Icon(Icons.play_arrow),
                    label: Text(AppLocalizations.of(context).homePlay),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () => widget.onOpenGameDetail(game),
                    child: Text(AppLocalizations.of(context).homeDetails),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard() {
    return FocusableCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _currentTime,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w300,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _currentDate,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
          const Spacer(),
          _buildBatteryRow(),
          const SizedBox(height: 16),
          Divider(color: AppColors.divider),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatChip(
                Icons.videogame_asset,
                AppLocalizations.of(context).homeGamesCount(widget.games.length),
              ),
              const SizedBox(width: 12),
              _buildStatChip(
                Icons.apps,
                AppLocalizations.of(context).homeAppsCount(widget.allAppsCount),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBatteryRow() {
    final isCharging = _batteryState == BatteryState.charging;
    final isLow = _batteryLevel <= 20 && !isCharging;
    
    return Row(
      children: [
        Icon(
          isCharging
              ? Icons.battery_charging_full
              : _batteryLevel > 80
                  ? Icons.battery_full
                  : _batteryLevel > 50
                      ? Icons.battery_5_bar
                      : _batteryLevel > 20
                          ? Icons.battery_3_bar
                          : Icons.battery_1_bar,
          color: isLow ? Colors.red : AppColors.textSecondary,
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          '$_batteryLevel%',
          style: TextStyle(
            color: isLow ? Colors.red : AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (isCharging) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              AppLocalizations.of(context).homeCharging,
              style: const TextStyle(
                color: Colors.green,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
