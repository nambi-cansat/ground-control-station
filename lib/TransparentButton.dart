import 'package:flutter/material.dart';

class TransparentButton extends StatelessWidget {
  final String buttonName;

  const TransparentButton({required Key key, required this.buttonName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: Colors.white), // Change border color as needed
      ),
      child: Center(
        child: Text(
          buttonName,
          style: TextStyle(color: Colors.white), // Change text color as needed
        ),
      ),
    );
  }
}