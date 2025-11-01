import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/match_controller.dart';
import '../models/player.dart';

class DoublesServerPicker extends StatefulWidget {
  const DoublesServerPicker({super.key});

  @override
  State<DoublesServerPicker> createState() => _DoublesServerPickerState();
}

class _DoublesServerPickerState extends State<DoublesServerPicker> {
  Player? selectedServer;
  Player? selectedReceiver;

  @override
  Widget build(BuildContext context) {
    final ctrl = context.read<MatchController>();
    final home = ctrl.currentGame.homePlayers;
    final away = ctrl.currentGame.awayPlayers;

    return AlertDialog(
      title: const Text("Select Doubles Starting Server"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<Player>(
            decoration: const InputDecoration(labelText: "Server"),
            value: selectedServer,
            items: [...home, ...away].map((p) {
              return DropdownMenuItem(value: p, child: Text(p.name));
            }).toList(),
            onChanged: (p) => setState(() => selectedServer = p),
          ),
          DropdownButtonFormField<Player>(
            decoration: const InputDecoration(labelText: "Receiver"),
            value: selectedReceiver,
            items: [...home, ...away].map((p) {
              return DropdownMenuItem(value: p, child: Text(p.name));
            }).toList(),
            onChanged: (p) => setState(() => selectedReceiver = p),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: selectedServer != null && selectedReceiver != null
              ? () {
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
}
