import 'package:flutter/material.dart';

class BuildErrorMsg {
  // Display an error message with an icon
  static Widget buildErrorMessage(String message) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        children: [
          Icon(
            Icons.error, // Error icon
            color: Colors.red,
            size: 16,
          ),
          const SizedBox(width: 5),
          Text(
            message,
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold, // Make error text bold
            ),
          ),
        ],
      ),
    );
  }
}