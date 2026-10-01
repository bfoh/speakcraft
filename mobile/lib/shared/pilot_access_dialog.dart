import 'package:flutter/material.dart';

Future<String?> askForPilotAccessCode(BuildContext context) async {
  var input = '';
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Connect speech recognition'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Ask your facilitator for the pilot access code. It is used only while this app is open.',
          ),
          const SizedBox(height: 12),
          TextField(
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Access code'),
            onChanged: (value) => input = value,
            onSubmitted: (value) => Navigator.of(context).pop(value),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(input),
          child: const Text('Continue'),
        ),
      ],
    ),
  );
}
