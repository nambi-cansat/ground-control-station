import 'package:flutter/material.dart';
class StateButton extends StatelessWidget {
  final String label;
  final String currentState;
  final String desiredState;
  final VoidCallback onPressed;

  const StateButton({
    required this.label,
    required this.currentState,
    required this.desiredState,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all<Color>(
          currentState == desiredState ? Colors.green : Colors.grey,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
        ),
      ),
    );
  }
}
