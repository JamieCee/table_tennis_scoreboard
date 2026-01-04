import 'package:flutter/material.dart';

import '../models/player.dart';

/// --------------------------------------------------------------
/// DoublesPickerDialog
/// --------------------------------------------------------------
/// Lets the user pick 2 home players and 2 away players for a
/// doubles match. Returns the selected players via `onConfirm`.
/// --------------------------------------------------------------
class DoublesPickerDialog extends StatefulWidget {
  final List<Player> homePlayers;
  final List<Player> awayPlayers;
  final void Function(List<Player> home, List<Player> away) onConfirm;

  const DoublesPickerDialog({
    super.key,
    required this.homePlayers,
    required this.awayPlayers,
    required this.onConfirm,
  });

  @override
  State<DoublesPickerDialog> createState() => _DoublesPickerDialogState();
}

class _DoublesPickerDialogState extends State<DoublesPickerDialog> {
  final List<Player> _selectedHome = [];
  final List<Player> _selectedAway = [];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Select Doubles Players"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _teamChipSection(
              "Home Team (Select 2)",
              widget.homePlayers,
              _selectedHome,
              Colors.blueAccent,
            ),
            const SizedBox(height: 16),
            _teamChipSection(
              "Away Team (Select 2)",
              widget.awayPlayers,
              _selectedAway,
              Colors.redAccent,
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton.icon(
          icon: const Icon(Icons.check),
          label: const Text("Confirm"),
          onPressed: (_selectedHome.length == 2 && _selectedAway.length == 2)
              ? () => widget.onConfirm(_selectedHome, _selectedAway)
              : null,
        ),
      ],
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
        Text(
          title,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
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
}
