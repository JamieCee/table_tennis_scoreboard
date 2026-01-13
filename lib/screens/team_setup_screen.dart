// lib/screens/team_setup_screen.dart
import 'package:bottom_navy_bar/bottom_navy_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_tennis_scoreboard/bloc/match/match_bloc.dart';
import 'package:table_tennis_scoreboard/bloc/team_setup/team_setup_bloc.dart';
import 'package:table_tennis_scoreboard/services/match_state_manager.dart';
import 'package:table_tennis_scoreboard/theme.dart';
import 'package:table_tennis_scoreboard/widgets/app_drawer.dart';

// Top-level widget to provide the Bloc
class TeamSetupScreen extends StatelessWidget {
  const TeamSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          TeamSetupBloc(matchStateManager: context.read<MatchStateManager>()),
      child: const _TeamSetupView(),
    );
  }
}

// The main view widget that consumes the Bloc
class _TeamSetupView extends StatefulWidget {
  const _TeamSetupView();

  @override
  State<_TeamSetupView> createState() => _TeamSetupViewState();
}

class _TeamSetupViewState extends State<_TeamSetupView> {
  final _homeNameController = TextEditingController();
  final _awayNameController = TextEditingController();
  final _homePlayers = List.generate(3, (i) => TextEditingController());
  final _awayPlayers = List.generate(3, (i) => TextEditingController());

  @override
  void initState() {
    super.initState();
    // Add listeners to dispatch name changes to the BLoC
    _homeNameController.addListener(_updateBlocWithNames);
    _awayNameController.addListener(_updateBlocWithNames);
    for (var controller in _homePlayers) {
      controller.addListener(_updateBlocWithNames);
    }
    for (var controller in _awayPlayers) {
      controller.addListener(_updateBlocWithNames);
    }
  }

  @override
  void dispose() {
    _homeNameController.removeListener(_updateBlocWithNames);
    _awayNameController.removeListener(_updateBlocWithNames);
    for (var c in _homePlayers) {
      c.removeListener(_updateBlocWithNames);
      c.dispose();
    }
    for (var c in _awayPlayers) {
      c.removeListener(_updateBlocWithNames);
      c.dispose();
    }
    _homeNameController.dispose();
    _awayNameController.dispose();
    super.dispose();
  }

  void _updateBlocWithNames() {
    context.read<TeamSetupBloc>().add(
      NameChanged(
        homeTeamName: _homeNameController.text,
        awayTeamName: _awayNameController.text,
        homePlayerNames: _homePlayers.map((c) => c.text).toList(),
        awayPlayerNames: _awayPlayers.map((c) => c.text).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TeamSetupBloc, TeamSetupState>(
      listenWhen: (prev, current) =>
          prev.status != current.status ||
          // Listen for name changes to sync controllers
          prev.homeTeamName != current.homeTeamName,
      listener: (context, state) {
        if (state.status == TeamSetupStatus.success &&
            state.matchBloc != null) {
          context.go('/controller', extra: state.matchBloc);
        }
        if (state.status == TeamSetupStatus.failure) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(
                  state.errorMessage ?? 'An unknown error occurred.',
                ),
                backgroundColor: Colors.red,
              ),
            );
        }

        // Sync local text controllers with the BLoC state.
        // This ensures that when the BLoC loads its initial state,
        // the text fields are populated correctly.
        if (_homeNameController.text != state.homeTeamName) {
          _homeNameController.text = state.homeTeamName;
        }
        if (_awayNameController.text != state.awayTeamName) {
          _awayNameController.text = state.awayTeamName;
        }
        for (int i = 0; i < 3; i++) {
          if (_homePlayers[i].text != state.homePlayerNames[i]) {
            _homePlayers[i].text = state.homePlayerNames[i];
          }
          if (_awayPlayers[i].text != state.awayPlayerNames[i]) {
            _awayPlayers[i].text = state.awayPlayerNames[i];
          }
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xff3E4249),
          appBar: AppBar(
            title: const Text('Team Setup'),
            centerTitle: true,
            backgroundColor: AppColors.primaryBackground,
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
          ),
          drawer: const AppDrawer(),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  // Conditionally show widgets based on BLoC state
                  if (state.matchType == MatchType.singles ||
                      state.matchType == MatchType.handicap)
                    _buildSetsToWinSelector(state),
                  if (state.matchType == MatchType.handicap) ...[
                    const SizedBox(height: 16),
                    _buildHandicapSelector(state),
                  ],
                  const SizedBox(height: 24),
                  _teamCard(state, isHome: true),
                  const SizedBox(height: 24),
                  _teamCard(state, isHome: false),
                  const SizedBox(height: 36),
                  _buildStartButton(state),
                ],
              ),
            ),
          ),
          bottomNavigationBar: BottomNavyBar(
            // The selectedIndex now needs to map to our new order.
            // We can create a small map or use a switch for clarity.
            selectedIndex: () {
              switch (state.matchType) {
                case MatchType.singles:
                  return 0; // Singles is now at index 0
                case MatchType.team:
                  return 1; // Team is now at index 1
                case MatchType.handicap:
                  return 2; // Handicap is now at index 2
              }
            }(),
            onItemSelected: (index) {
              // Map the tapped index back to the correct MatchType
              MatchType newType;
              switch (index) {
                case 0:
                  newType = MatchType.singles;
                  break;
                case 1:
                  newType = MatchType.team;
                  break;
                case 2:
                  newType = MatchType.handicap;
                  break;
                default:
                  newType = MatchType.team;
              }
              context.read<TeamSetupBloc>().add(MatchTypeChanged(newType));
            },
            backgroundColor: AppColors.primaryBackground,
            items: <BottomNavyBarItem>[
              // Item 1: Singles
              BottomNavyBarItem(
                title: Text(
                  'Singles',
                  style: TextStyle(color: AppColors.white),
                ),
                icon: const Icon(Icons.person),
                activeColor: AppColors.purpleAccent, // Use primary purple
                inactiveColor: Colors.white,
                textAlign: TextAlign.center,
              ),
              // Item 2: Team (default)
              BottomNavyBarItem(
                title: Text('Team', style: TextStyle(color: AppColors.white)),
                icon: const Icon(Icons.groups),
                activeColor: AppColors.purpleAccent, // Use primary purple
                inactiveColor: Colors.white,
                textAlign: TextAlign.center,
              ),
              // Item 3: Handicap
              BottomNavyBarItem(
                title: Text(
                  'Handicap',
                  style: TextStyle(color: AppColors.white),
                ),
                icon: const Icon(Icons.star),
                activeColor: AppColors.purpleAccent, // Use primary purple
                inactiveColor: Colors.white,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.sports_tennis,
            size: 80,
            color: Colors.purpleAccent.withValues(alpha: 0.9),
          ),
          const SizedBox(height: 8),
          Text(
            "Match Setup",
            style: GoogleFonts.bebasNeue(
              color: Colors.white,
              fontSize: 48,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetsToWinSelector(TeamSetupState state) {
    return SegmentedButton<int>(
      segments: const [
        ButtonSegment(value: 2, label: Text('Best of 3')),
        ButtonSegment(value: 3, label: Text('Best of 5')),
        ButtonSegment(value: 4, label: Text('Best of 7')),
      ],
      selected: {state.setsToWin},
      onSelectionChanged: (newSelection) => context.read<TeamSetupBloc>().add(
        SetsToWinChanged(newSelection.first),
      ),
      style: SegmentedButton.styleFrom(
        backgroundColor: AppColors.primaryBackground.withValues(alpha: 0.5),
        foregroundColor: Colors.white,
        selectedBackgroundColor: AppColors.purpleAccent.withValues(alpha: 0.4),
        selectedForegroundColor: AppColors.white,
      ),
    );
  }

  Widget _buildHandicapSelector(TeamSetupState state) {
    // Read names from the BLoC state for the labels
    String homePlayerName = state.homePlayerNames.first.isNotEmpty
        ? state.homePlayerNames.first
        : 'Player 1';
    String awayPlayerName = state.awayPlayerNames.first.isNotEmpty
        ? state.awayPlayerNames.first
        : 'Player 2';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryBackground.withOpacity(0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.purpleAccent, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Handicap Setup",
            style: GoogleFonts.oswald(
              color: Colors.purpleAccent,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SegmentedButton<int>(
            segments: [
              ButtonSegment(value: 0, label: Text(homePlayerName)),
              ButtonSegment(value: 1, label: Text(awayPlayerName)),
            ],
            selected: {state.handicapPlayerIndex},
            onSelectionChanged: (newSelection) => context
                .read<TeamSetupBloc>()
                .add(HandicapPlayerChanged(newSelection.first)),
            style: SegmentedButton.styleFrom(
              backgroundColor: AppColors.primaryBackground.withOpacity(0.5),
              foregroundColor: Colors.white,
              selectedBackgroundColor: AppColors.purpleAccent.withOpacity(0.4),
              selectedForegroundColor: AppColors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Starting Points: ${state.handicapPoints.toInt()}",
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          Slider(
            value: state.handicapPoints,
            min: 0,
            max: 20,
            divisions: 20,
            label: state.handicapPoints.toInt().toString(),
            activeColor: Colors.white,
            inactiveColor: Colors.purpleAccent.withOpacity(0.3),
            onChanged: (newValue) => context.read<TeamSetupBloc>().add(
              HandicapPointsChanged(newValue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _teamCard(TeamSetupState state, {required bool isHome}) {
    // Read all configuration from the BLoC state
    final matchType = state.matchType;
    final label = matchType == MatchType.team
        ? (isHome ? "Home Team" : "Away Team")
        : (isHome ? "Player 1" : "Player 2");
    final color = isHome ? Colors.blueAccent : Colors.redAccent;
    final nameController = isHome ? _homeNameController : _awayNameController;
    final playerControllers = isHome ? _homePlayers : _awayPlayers;
    final playerCount = matchType == MatchType.team ? 3 : 1;

    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label.toUpperCase(),
                style: GoogleFonts.oswald(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          if (matchType == MatchType.team) ...[
            const SizedBox(height: 8),
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Team Name', AppColors.white),
            ),
          ],
          const SizedBox(height: 12),
          for (int i = 0; i < playerCount; i++) ...[
            TextField(
              controller: playerControllers[i],
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration(
                matchType == MatchType.team ? 'Player ${i + 1}' : 'Player Name',
                AppColors.white.withOpacity(0.9),
              ),
            ),
            if (i < playerCount - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, Color color) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: color.withOpacity(0.9)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color.withValues(alpha: 0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: 2),
      ),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
    );
  }

  Widget _buildStartButton(TeamSetupState state) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.purpleAccent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
        shadowColor: Colors.purple.withValues(alpha: 0.6),
      ),
      onPressed: state.status == TeamSetupStatus.loading
          ? null
          : () => context.read<TeamSetupBloc>().add(StartMatchSubmitted()),
      child: state.status == TeamSetupStatus.loading
          ? const CircularProgressIndicator(color: Colors.white)
          : Text(
              "Start Match",
              style: GoogleFonts.oswald(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
    );
  }
}
