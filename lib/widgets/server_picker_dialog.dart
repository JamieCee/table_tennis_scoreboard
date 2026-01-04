import 'package:flutter/material.dart';

import '../models/player.dart';

/// --------------------------------------------------------------
/// ServerPickerDialog
/// --------------------------------------------------------------
/// Lets the user choose which player will serve first. Returns
/// that player via `onConfirm`.
/// --------------------------------------------------------------
class ServerPickerDialog extends StatefulWidget {
  final List<Player> homePlayers;
  final List<Player> awayPlayers;
  final void Function(Player server) onConfirm;

  const ServerPickerDialog({
    super.key,
    required this.homePlayers,
    required this.awayPlayers,
    required this.onConfirm,
  });

  @override
  State<ServerPickerDialog> createState() => _ServerPickerDialogState();
}

class _ServerPickerDialogState extends State<ServerPickerDialog> {
  Player? _selectedServer;

  @override
  Widget build(BuildContext context) {
    final allPlayers = [...widget.homePlayers, ...widget.awayPlayers];

    return AlertDialog(
      title: const Text("Select Starting Server"),
      content: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: allPlayers.map((p) {
          final isSelected = _selectedServer == p;
          return ChoiceChip(
            label: Text(p.name),
            selected: isSelected,
            selectedColor: widget.homePlayers.contains(p)
                ? Colors.blueAccent
                : Colors.redAccent,
            labelStyle: TextStyle(
              color: isSelected ? Colors.black : Colors.white,
            ),
            onSelected: (_) => setState(() => _selectedServer = p),
          );
        }).toList(),
      ),
      actions: [
        ElevatedButton(
          onPressed: _selectedServer == null
              ? null
              : () => widget.onConfirm(_selectedServer!),
          child: Text(
            _selectedServer == null
                ? "Confirm"
                : "Start: ${_selectedServer!.name} serves",
          ),
        ),
      ],
    );
  }
}
