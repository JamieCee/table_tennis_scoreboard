import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/match/match_bloc.dart';
import '../models/player.dart';

class DoublesServerPicker extends StatefulWidget {
  const DoublesServerPicker({super.key});

  @override
  State<DoublesServerPicker> createState() => _DoublesServerPickerState();
}

class _DoublesServerPickerState extends State<DoublesServerPicker> {
  final List<Player> selectedHome = [];
  final List<Player> selectedAway = [];
  Player? selectedServer;
  Player? selectedReceiver;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MatchBloc, MatchState>(
      builder: (context, state) {
        if (state.currentGame == null) return Container(); // or some fallback

        final homePlayers = state.currentGame!.homePlayers;
        final awayPlayers = state.currentGame!.awayPlayers;

        return AlertDialog(
          title: const Text("Select Doubles Players & Server"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _teamChipSection(
                  "Home Team (Select 2)",
                  homePlayers,
                  selectedHome,
                  Colors.blueAccent,
                ),
                const SizedBox(height: 16),
                _teamChipSection(
                  "Away Team (Select 2)",
                  awayPlayers,
                  selectedAway,
                  Colors.redAccent,
                ),
                const SizedBox(height: 24),
                _serverReceiverSection(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed:
                  selectedHome.length == 2 &&
                      selectedAway.length == 2 &&
                      selectedServer != null &&
                      selectedReceiver != null
                  ? () {
                      context.read<MatchBloc>().add(
                        SetDoublesPlayers(
                          home: selectedHome,
                          away: selectedAway,
                        ),
                      );
                      context.read<MatchBloc>().add(
                        SetDoublesServer(
                          server: selectedServer!,
                          receiver: selectedReceiver!,
                        ),
                      );
                      Navigator.pop(context);
                    }
                  : null,
              child: const Text("Set"),
            ),
          ],
        );
      },
    );
  }

  Widget _teamChipSection(
    String title,
    List<Player> players,
    List<Player> selected,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: players.map((p) {
            final isSelected = selected.contains(p);
            return ChoiceChip(
              label: Text(p.name),
              selected: isSelected,
              selectedColor: color,
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
              ),
              onSelected: (sel) {
                setState(() {
                  if (sel && selected.length < 2) {
                    selected.add(p);
                  } else {
                    selected.remove(p);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _serverReceiverSection() {
    final allSelected = [...selectedHome, ...selectedAway];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Server"),
        Wrap(
          spacing: 8,
          children: allSelected.map((p) {
            return ChoiceChip(
              label: Text(p.name),
              selected: selectedServer == p,
              onSelected: (_) => setState(() => selectedServer = p),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        const Text("Receiver"),
        Wrap(
          spacing: 8,
          children: allSelected.map((p) {
            return ChoiceChip(
              label: Text(p.name),
              selected: selectedReceiver == p,
              onSelected: (_) => setState(() => selectedReceiver = p),
            );
          }).toList(),
        ),
      ],
    );
  }
}
