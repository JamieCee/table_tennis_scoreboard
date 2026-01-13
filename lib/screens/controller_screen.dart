import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:table_tennis_scoreboard/screens/controller/game_score.dart';
import 'package:table_tennis_scoreboard/screens/controller/points_buttons.dart';
import 'package:table_tennis_scoreboard/screens/controller/points_counter.dart';
import 'package:table_tennis_scoreboard/shared/styled_button.dart';
import 'package:table_tennis_scoreboard/theme.dart';
import 'package:table_tennis_scoreboard/widgets/app_drawer.dart';
import 'package:table_tennis_scoreboard/widgets/break_timer_widget.dart';
import 'package:table_tennis_scoreboard/widgets/timeout_widget.dart';

import '../bloc/match/match_bloc.dart';
import '../widgets/transition_overlay.dart';

class ControllerScreen extends StatelessWidget {
  const ControllerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MatchBloc, MatchState>(
      builder: (context, state) {
        final bloc = context.read<MatchBloc>();

        return Stack(
          children: [
            Scaffold(
              backgroundColor: const Color(0xFF1B1B1B),
              appBar: AppBar(
                title: const Text('Match Controller'),
                centerTitle: true,
                leading: Builder(
                  builder: (context) {
                    return IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    );
                  },
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.tv),
                    onPressed: () => GoRouter.of(
                      context,
                    ).push('/controller/scoreboard', extra: bloc),
                  ),
                ],
              ),
              body: Padding(
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
                            if (state.isBreakActive) BreakTimerWidget(),
                            if (state.isTimeoutActive) TimeoutTimerWidget(),
                            GameAndScoreWidget(),
                            const SizedBox(height: 16),
                            PointsCounter(),
                            const SizedBox(height: 30),
                            if (!state.isMatchOver && !bloc.isObserver)
                              PointsButtons(),
                            const SizedBox(height: 24),
                            if (!bloc.isObserver && state.isMatchOver)
                              _buildCompleteMatchButton(context, bloc),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              drawer: AppDrawer(),
              bottomNavigationBar: BottomAppBar(
                color: AppColors.midnightBlue,
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 2,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (!bloc.isObserver)
                        StyledIconButton(
                          color: AppColors.turkeyRed,
                          onPressed: () {
                            context.pushReplacement('/team-setup');
                            bloc.add(MatchDeleted());
                          },
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          child: const Text(
                            'Reset App',
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
                                bloc.matchId,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.copy,
                                color: Colors.white70,
                              ),
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: bloc.matchId),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Game code copied to clipboard",
                                    ),
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
              ),
            ),

            // Next game overlay
            if (state.isTransitioning && state.nextGame != null)
              TransitionOverlay(
                gameNumber: state.nextGame!.order,
                totalGames: state.games.length,
                homeNames: state.nextGame!.homePlayers
                    .map((p) => p.name)
                    .join(' & '),
                awayNames: state.nextGame!.awayPlayers
                    .map((p) => p.name)
                    .join(' & '),
                onStartGame: () => bloc.add(StartNextGame()),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCompleteMatchButton(BuildContext context, MatchBloc bloc) {
    return StyledIconButton(
      color: AppColors.purpleAccent,
      icon: const Icon(Icons.emoji_events_outlined, color: Colors.white),
      onPressed: () => context.go('/controller/match-card', extra: bloc),
      child: const Text(
        'View Scorecard',
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }
}
