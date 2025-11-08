import 'package:flutter/material.dart';

import '../models/player.dart';
import '../widgets/themed_dialog.dart';

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
    return ThemedDialog(
      title: 'Select Server',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Choose the player who will serve first:',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _serverSelectSection(
                  'Home Team',
                  widget.homePlayers,
                  Colors.blueAccent,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _serverSelectSection(
                  'Away Team',
                  widget.awayPlayers,
                  Colors.redAccent,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        ElevatedButton.icon(
          icon: const Icon(Icons.check),
          label: Text(
            _selectedServer == null
                ? 'Confirm'
                : 'Start: ${_selectedServer!.name} serves',
          ),
          onPressed: _selectedServer == null
              ? null
              : () => widget.onConfirm(_selectedServer!),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.greenAccent.shade400,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  /// Build one team’s server picker section
  Widget _serverSelectSection(String label, List<Player> players, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 6.0,
          alignment: WrapAlignment.center,
          children: players.map((p) {
            final isSelected = _selectedServer == p;
            return ChoiceChip(
              label: Text(p.name),
              selected: isSelected,
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold,
              ),
              selectedColor: color,
              backgroundColor: Colors.white10,
              side: BorderSide(color: color.withValues(alpha: 0.4)),
              onSelected: (_) => setState(() => _selectedServer = p),
            );
          }).toList(),
        ),
      ],
    );
  }
}
