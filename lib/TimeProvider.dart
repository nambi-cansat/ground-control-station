import 'dart:async';
import 'package:flutter/material.dart';

class TimeProvider extends ChangeNotifier {
  String _currentTime = '';

  TimeProvider() {
    // Update time every second
    Timer.periodic(Duration(seconds: 1), (timer) {
      _currentTime = DateTime.now().hour.toString().padLeft(2, '0') +
          ":" +
          DateTime.now().minute.toString().padLeft(2, '0') +
          ":" +
          DateTime.now().second.toString().padLeft(2, '0');
      notifyListeners();
    });
  }

  String get currentTime => _currentTime;
}
