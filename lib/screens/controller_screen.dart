import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_tennis_scoreboard/bloc/match_controller/match_controller_bloc.dart';

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

class ControllerScreen extends StatefulWidget {
  final bool showDialogOnLoad;
  const ControllerScreen({super.key, this.showDialogOnLoad = false});

  @override
  State<ControllerScreen> createState() => _ControllerScreenState();
}

class _ControllerScreenState extends State<ControllerScreen> {
  Timer? _breakTimer;

  @override
  void initState() {
    super.initState();

    // Trigger any setup dialogs after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bloc = context.read<MatchControllerBloc>();
      final state = bloc.state;
      final game = state.currentGame;

      if (game == null || state.isTransitioning) return;

      if ((game.isDoubles ?? false) && (game.homePlayers?.isEmpty ?? true)) {
        _showDoublesPlayerPicker(context, bloc);
      } else if (game.startingServer == null) {
        _showServerReceiverPicker(context, bloc);
      }
    });
  }

  @override
  void dispose() {
    _breakTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MatchControllerBloc, MatchControllerState>(
      builder: (context, state) {
        final bloc = context.read<MatchControllerBloc>();

        return Stack(
          children: [
            Scaffold(
              backgroundColor: AppColors.charcoal,
              appBar: _buildAppBar(context, bloc, state),
              body: _buildMainBody(context, bloc, state),
              bottomNavigationBar: _buildBottomBar(context, bloc, state),
            ),
            if (!state.isObserver &&
                state.isTransitioning &&
                state.isNextGameReady &&
                state.nextGamePreview != null)
              TransitionOverlay(
                gameNumber: state.nextGamePreview!.order,
                totalGames: state.games.length,
                homeNames: _teamNames(
                  state.nextGamePreview?.homePlayers,
                  state.home,
                ),
                awayNames: _teamNames(
                  state.nextGamePreview?.awayPlayers,
                  state.away,
                ),
                onStartGame: () => bloc.add(StartNextGame()),
              ),
          ],
        );
      },
    );
  }

  AppBar _buildAppBar(
    BuildContext context,
    MatchControllerBloc bloc,
    MatchControllerState state,
  ) {
    return AppBar(
      title: Text(
        'Match Controller',
        style: GoogleFonts.oswald(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.white,
        ),
      ),
      backgroundColor: AppColors.purple.withOpacity(0.4),
      centerTitle: true,
      elevation: 6,
      actions: [
        IconButton(
          tooltip: "Open Display View",
          icon: const Icon(Icons.tv, color: Colors.white),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: bloc,
                child: const ScoreboardDisplayScreen(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainBody(
    BuildContext context,
    MatchControllerBloc bloc,
    MatchControllerState state,
  ) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.steelGray,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10)],
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.isBreakActive) const BreakTimerWidget(),
              if (state.isTimeoutActive) const TimeoutTimerWidget(),
              GameAndScoreWidget(),
              const SizedBox(height: 16),
              PointsCounter(),
              const SizedBox(height: 30),
              if (!state.isObserver && !state.isMatchOver) PointsButtons(),
              const SizedBox(height: 24),
              if (!state.isObserver && state.isMatchOver)
                _buildCompleteMatchButton(context, bloc, state),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    MatchControllerBloc bloc,
    MatchControllerState state,
  ) {
    return BottomAppBar(
      color: AppColors.midnightBlue,
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (!state.isObserver)
              StyledIconButton(
                color: AppColors.turkeyRed,
                onPressed: () {
                  bloc.add(DeleteMatch());
                  context.pushReplacement('/team-setup');
                },
                icon: const Icon(Icons.refresh, color: Colors.white),
                child: const Text(
                  "Reset App",
                  style: TextStyle(color: Colors.white),
                ),
              )
            else
              const SizedBox(width: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.vpn_key, color: Colors.white70),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      "${state.matchId}",
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
                      Clipboard.setData(ClipboardData(text: state.matchId));
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

  Widget _buildCompleteMatchButton(
    BuildContext context,
    MatchControllerBloc bloc,
    MatchControllerState state,
  ) {
    return StyledIconButton(
      color: AppColors.purpleAccent,
      icon: const Icon(Icons.emoji_events_outlined, color: Colors.white),
      onPressed: () => context.push('/controller/match-card', extra: bloc),
      child: const Text(
        'Complete Match',
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }

  String _teamNames(List<Player>? specific, dynamic team) =>
      specific != null && specific.isNotEmpty
      ? specific.map((p) => p.name).join(' & ')
      : team.players.map((p) => p.name).join(' & ');

  void _showDoublesPlayerPicker(
    BuildContext context,
    MatchControllerBloc bloc,
  ) {
    final state = bloc.state;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => DoublesPickerDialog(
        homePlayers: state.home.players,
        awayPlayers: state.away.players,
        onConfirm: (home, away) {
          bloc.add(SetDoublesPlayers(home, away));
          Navigator.pop(context);
          _showServerReceiverPicker(context, bloc);
        },
      ),
    );
  }

  void _showServerReceiverPicker(
    BuildContext context,
    MatchControllerBloc bloc,
  ) {
    final game = bloc.state.currentGame;
    if (game == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ServerPickerDialog(
        homePlayers: game.homePlayers,
        awayPlayers: game.awayPlayers,
        onConfirm: (server) {
          final receiver = game.homePlayers.contains(server)
              ? game.awayPlayers.first
              : game.homePlayers.first;
          bloc.add(SetServer(server, receiver));
          Navigator.pop(context);
        },
      ),
    );
  }
}
