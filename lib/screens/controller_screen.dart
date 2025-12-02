import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../controllers/match_controller.dart';
import '../models/player.dart';
import '../screens/controller/game_score.dart';
import '../screens/controller/points_buttons.dart';
import '../screens/controller/points_counter.dart';
import '../screens/scoreboard_display.dart';
import '../shared/styled_button.dart';
import '../theme.dart';
import '../widgets/break_timer_widget.dart';
import '../widgets/doubles_picker_dialog.dart';
import '../widgets/server_picker_dialog.dart';
import '../widgets/timeout_widget.dart';
import '../widgets/transition_overlay.dart';

/// --------------------------------------------------------------
/// Main match controller screen — handles gameplay flow, breaks,
/// timeouts, next-game transitions, and quick navigation.
/// Observer mode disables buttons and only shows the scoreboard.
/// --------------------------------------------------------------
class ControllerScreen extends StatefulWidget {
  final bool showDialogOnLoad;
  final MatchController? controller;
  const ControllerScreen({
    super.key,
    this.controller,
    this.showDialogOnLoad = false,
  });

  @override
  State<ControllerScreen> createState() => _ControllerScreenState();
}

class _ControllerScreenState extends State<ControllerScreen> {
  late final MatchController _ctrl;
  Timer? _breakTimer;

  @override
  void initState() {
    super.initState();
    _ctrl = widget.controller ?? context.read<MatchController>();

    // Register callbacks for when the controller needs user input
    if (!_ctrl.isObserver) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        _ctrl.onDoublesPlayersNeeded = () =>
            _showDoublesPlayerPicker(context, _ctrl);

        _ctrl.onServerSelectionNeeded = () =>
            _showServerReceiverPicker(context, _ctrl);

        // FIRST GAME: Trigger dialog if needed
        final game = _ctrl.currentGame;
        if (!_ctrl.isTransitioning) {
          if (game.isDoubles && game.homePlayers.isEmpty) {
            _showDoublesPlayerPicker(context, _ctrl);
          } else if (game.startingServer == null) {
            _showServerReceiverPicker(context, _ctrl);
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _breakTimer?.cancel();
    _ctrl.onDoublesPlayersNeeded = null;
    _ctrl.onServerSelectionNeeded = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<MatchController>();

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.charcoal,
          appBar: _buildAppBar(context, ctrl),
          body: _buildMainBody(ctrl),
          bottomNavigationBar: _buildBottomBar(context),
        ),
        if (!_ctrl.isObserver && ctrl.isTransitioning && ctrl.isNextGameReady)
          TransitionOverlay(
            gameNumber: ctrl.nextGamePreview!.order,
            totalGames: ctrl.games.length,
            homeNames: _teamNames(ctrl.nextGamePreview?.homePlayers, ctrl.home),
            awayNames: _teamNames(ctrl.nextGamePreview?.awayPlayers, ctrl.away),
            onStartGame: ctrl.startNextGame,
          ),
      ],
    );
  }

  AppBar _buildAppBar(BuildContext context, MatchController ctrl) {
    return AppBar(
      title: Text(
        'Match Controller',
        style: GoogleFonts.oswald(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.white,
        ),
      ),
      backgroundColor: AppColors.purple.withValues(alpha: 0.4),
      centerTitle: true,
      elevation: 6,
      titleTextStyle: GoogleFonts.oswald(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.timberWhite,
      ),
      actions: [
        IconButton(
          tooltip: "Open Display View",
          icon: const Icon(Icons.tv, color: Colors.white),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider.value(
                value: ctrl,
                child: const ScoreboardDisplayScreen(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainBody(MatchController ctrl) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.steelGray,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10)],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (ctrl.isBreakActive) BreakTimerWidget(ctrl: _ctrl),
                    if (ctrl.isTimeoutActive) TimeoutTimerWidget(ctrl: _ctrl),
                    GameAndScoreWidget(ctrl: _ctrl),
                    const SizedBox(height: 16),
                    PointsCounter(ctrl: _ctrl),
                    const SizedBox(height: 30),
                    if (!_ctrl.isObserver && !_isMatchOver(ctrl))
                      PointsButtons(ctrl: _ctrl),
                    const SizedBox(height: 24),
                    if (!_ctrl.isObserver && _isMatchOver(ctrl))
                      _buildCompleteMatchButton(ctrl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final matchController = Provider.of<MatchController>(
      context,
      listen: false,
    );

    return BottomAppBar(
      color: AppColors.midnightBlue,
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (!_ctrl.isObserver)
              StyledIconButton(
                color: AppColors.turkeyRed,
                onPressed: () {
                  context.pushReplacement('/team-setup');
                  matchController.deleteMatch();
                },
                icon: const Icon(Icons.refresh, color: Colors.white),
                child: const Text(
                  "Reset App",
                  style: TextStyle(color: Colors.white),
                ),
              )
            else
              const SizedBox(
                width: 48,
              ), // placeholder to keep layout consistent

            const SizedBox(width: 12),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.vpn_key, color: Colors.white70),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      "${matchController.matchId}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Colors.white70),
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: matchController.matchId),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Game code copied to clipboard"),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompleteMatchButton(MatchController ctrl) {
    return StyledIconButton(
      color: AppColors.purpleAccent,
      icon: const Icon(Icons.emoji_events_outlined, color: Colors.white),
      onPressed: () => context.go('/match-card', extra: ctrl),
      child: const Text(
        'Complete Match',
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }

  bool _isMatchOver(MatchController ctrl) => ctrl.isMatchOver;

  String _teamNames(List<Player>? specific, dynamic team) =>
      specific != null && specific.isNotEmpty
      ? specific.map((p) => p.name).join(' & ')
      : team.players.map((p) => p.name).join(' & ');

  void _showDoublesPlayerPicker(BuildContext context, MatchController ctrl) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => DoublesPickerDialog(
        homePlayers: ctrl.home.players,
        awayPlayers: ctrl.away.players,
        onConfirm: (home, away) {
          ctrl.setDoublesPlayers(home, away);
          Navigator.pop(context);
          _showServerReceiverPicker(context, ctrl);
        },
      ),
    );
  }

  void _showServerReceiverPicker(BuildContext context, MatchController ctrl) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ServerPickerDialog(
        homePlayers: ctrl.currentGame.homePlayers,
        awayPlayers: ctrl.currentGame.awayPlayers,
        onConfirm: (server) {
          final receiver = ctrl.currentGame.homePlayers.contains(server)
              ? ctrl.currentGame.awayPlayers.first
              : ctrl.currentGame.homePlayers.first;
          ctrl.setServer(server, receiver);
          Navigator.pop(context);
        },
      ),
    );
  }
}
