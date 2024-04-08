import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_cube/flutter_cube.dart';

class TiltingCube extends StatefulWidget {
  final Object cansat;
  final Stream<List<double>> tiltStream;

  TiltingCube({required this.cansat, required this.tiltStream});

  @override
  _TiltingCubeState createState() => _TiltingCubeState();
}

class _TiltingCubeState extends State<TiltingCube> {
  late Scene _scene;
  late Object _cube;
  late StreamSubscription<List<double>> _tiltSubscription;

  @override
  void initState() {
    super.initState();
    _tiltSubscription = widget.tiltStream.listen((List<double> tiltData) {
      _updateCubeRotation(tiltData);
    });
  }

  @override
  void dispose() {
    _tiltSubscription.cancel();
    super.dispose();
  }

  void _onSceneCreated(Scene scene) {
    _scene = scene;
    _cube = widget.cansat;
    _scene.world.add(_cube);
    _scene.camera.zoom = 20;
  }

  void _updateCubeRotation(List<double> tiltData) {
    if (_cube != null && tiltData.length == 3) {
      setState(() {
        _cube.rotation.x = tiltData[0]+20;
        _cube.rotation.y = tiltData[1]+20;
        _cube.rotation.z = tiltData[2]+20;
      });
      _cube.updateTransform();
      _scene.update();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Cube(
      onSceneCreated: _onSceneCreated,
    );
  }
}