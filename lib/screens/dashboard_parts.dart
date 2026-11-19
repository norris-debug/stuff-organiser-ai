import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';

/// Shared "add space" dialog (dashboard + settings).
Future<void> showAddSpaceDialog(BuildContext context) async {
  final TextEditingController nameController = TextEditingController();
  final AppState state = context.read<AppState>();
  String emoji = '📦';
  const List<String> emojis = <String>['📦', '🍳', '🗂️', '👕', '🛏️', '🛁', '🎸', '📚'];

  final bool? added = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) => StatefulBuilder(
      builder: (BuildContext context, StateSetter setDialogState) {
        return AlertDialog(
          title: const Text('New space'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextField(
                controller: nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Space name',
                  hintText: 'Kitchen, desk, wardrobe...',
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: emojis.map((String value) {
                  final bool selected = value == emoji;
                  return InkWell(
                    onTap: () => setDialogState(() => emoji = value),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected
                            ? Theme.of(context).colorScheme.primaryContainer
                            : null,
                      ),
                      child: Text(value, style: const TextStyle(fontSize: 20)),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Add'),
            ),
          ],
        );
      },
    ),
  );

  if (added == true && nameController.text.trim().isNotEmpty) {
    await state.addSpace(nameController.text.trim(), emoji: emoji);
  }
  nameController.dispose();
}
