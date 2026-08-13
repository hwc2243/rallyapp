import 'package:flutter/material.dart';

Future<void> showConnectionErrorModal(
  BuildContext context, {
  required VoidCallback onRetry,
  required VoidCallback onReconfigureRole,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      backgroundColor: Colors.black,
      title: const Text('Controller Connection Failed', style: TextStyle(color: Colors.white)),
      content: const Text(
        'Unable to connect to saved Controller display over Bluetooth.',
        style: TextStyle(color: Colors.white70),
      ),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.black),
          onPressed: () { Navigator.pop(context); onRetry(); },
          child: const Text('RETRY'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
          onPressed: () { Navigator.pop(context); onReconfigureRole(); },
          child: const Text('RECONFIGURE ROLE'),
        ),
      ],
    ),
  );
}
