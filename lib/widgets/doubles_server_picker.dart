import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/match_controller.dart';
import '../models/player.dart';
import '../models/team.dart';

class DoublesServerPicker extends StatefulWidget {
  const DoublesServerPicker({super.key});

  @override
  State<DoublesServerPicker> createState() => _DoublesServerPickerState();
}

class _DoublesServerPickerState extends State<DoublesServerPicker> {
  Player? selectedServer;
  Player? selectedReceiver;

  List<Player> selectedHomePlayers = [];
  List<Player> selectedAwayPlayers = [];

  @override
  Widget build(BuildContext context) {
    final ctrl = context.read<MatchController>();
    final homeTeam = ctrl.home;
    final awayTeam = ctrl.away;

    return AlertDialog(
      title: const Text("Select Doubles Players & Server"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTeamSelection(homeTeam, selectedHomePlayers, (p, s) {
              setState(() {
                if (s) {
                  if (selectedHomePlayers.length < 2) {
                    selectedHomePlayers.add(p);
                  }
                } else {
                  selectedHomePlayers.remove(p);
                }
              });
            }),
            const SizedBox(height: 16),
            _buildTeamSelection(awayTeam, selectedAwayPlayers, (p, s) {
              setState(() {
                if (s) {
                  if (selectedAwayPlayers.length < 2) {
                    selectedAwayPlayers.add(p);
                  }
                } else {
                  selectedAwayPlayers.remove(p);
                }
              });
            }),
            const SizedBox(height: 24),
            DropdownButtonFormField<Player>(
              decoration: const InputDecoration(labelText: "Server"),
              initialValue: selectedServer,
              items: [...selectedHomePlayers, ...selectedAwayPlayers].map((p) {
                return DropdownMenuItem(value: p, child: Text(p.name));
              }).toList(),
              onChanged: (p) => setState(() => selectedServer = p),
            ),
            DropdownButtonFormField<Player>(
              decoration: const InputDecoration(labelText: "Receiver"),
              initialValue: selectedReceiver,
              items: [...selectedHomePlayers, ...selectedAwayPlayers].map((p) {
                return DropdownMenuItem(value: p, child: Text(p.name));
              }).toList(),
              onChanged: (p) => setState(() => selectedReceiver = p),
            ),
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
              selectedServer != null &&
                  selectedReceiver != null &&
                  selectedHomePlayers.length == 2 &&
                  selectedAwayPlayers.length == 2
              ? () {
                  ctrl.setDoublesPlayers(
                    selectedHomePlayers,
                    selectedAwayPlayers,
                  );
                  ctrl.setDoublesStartingServer(
                    selectedServer!,
                    selectedReceiver!,
                  );
                  Navigator.pop(context);
                }
              : null,
          child: const Text("Set"),
        ),
      ],
    );
  }

  Widget _buildTeamSelection(
    Team team,
    List<Player> selectedPlayers,
    Function(Player, bool) onSelected,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "${team.name} (Select 2)",
          style: Theme.of(context).textTheme.titleMedium,
        ),
        ...team.players.map((p) {
          return CheckboxListTile(
            title: Text(p.name),
            value: selectedPlayers.contains(p),
            onChanged: (selected) => onSelected(p, selected ?? false),
          );
        }),
      ],
    );
  }
}
