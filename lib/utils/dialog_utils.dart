import 'package:flutter/material.dart';

class DialogUtils {
  // Show a success dialog
  static void showSuccessDialog({
    required BuildContext context,
    required String message,
    required VoidCallback onOkPressed,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: onOkPressed,
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Show an error dialog
  static void showErrorDialog({
    required BuildContext context,
    required String message,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}