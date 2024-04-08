import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class MyUtils{
  void showToastMessge([String? message]){
    Fluttertoast.showToast(msg: message.toString(),
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.BOTTOM,
    backgroundColor: Colors.white,
      textColor: Colors.black,
      fontSize: 15
    );
  }
}

