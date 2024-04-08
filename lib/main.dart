import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cube/flutter_cube.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:gcsnambi/newmain.dart';
import 'package:libserialport/libserialport.dart';
import 'dart:ui' as ui;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:video_player/video_player.dart';
import 'HollowCylinder.dart';
import 'MapScreen.dart';
import 'MonitoringScreen3.dart';
import 'RealTimeLineChart.dart';

class MonitoringScreen extends StatefulWidget {
  const MonitoringScreen({Key? key}) : super(key: key);

  @override
  _MonitoringScreenState createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen> {

  //ports
  late List<String> availablePorts;
  SerialPort portSelect = SerialPort("No One");
  String? dropdownValue;

  //video controller background
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;

  //
  String currentState = 'Boot',idleState = 'Idle',launchState = 'launch',deployState = 'Deploy';

  //Model Object
  Object cansat =  Object(fileName: "images/tube.obj");

  //cansat streamed data
  late StreamController<List<double>> tiltStreamController;

  //CHART
  StreamController<List<FlSpot>> dataStreamController = StreamController<List<FlSpot>>();



  //data receving
  double tiltX = 0.0,tiltY=0.0,tiltZ = 0.0,gyroSpinRate = 0.0,temperature = 0.0, pressure = 0.0,altitude = 0.0,voltage=0.0,gpsLat=27.176670,gpsLong=78.008072;
  int packetCount = 0,mode = 0,gpsStats=0,softwareState=0;
  String time= '';
  Future<void> ReadData1(SerialPort portToRead) async {
    try {
      SerialPortReader portReader = SerialPortReader(portToRead);
      String partialLine = ''; // To store partial data from incomplete lines
      portReader.stream.listen((data) {
        String receivedData = utf8.decode(data); // Assuming UTF-8 encoding
        String combinedData = partialLine + receivedData; // Combine partial data with received data
        List<String> lines = combinedData.split('\n'); // Split into lines
        partialLine = lines.removeLast(); // Store the last line as it might be incomplete

        for (String line in lines) {
          List<String> values = line.split(',');
          if (values.length >= 10) { // Ensure at least 14 values are present
            try {
              double tiltXvalue = double.parse(values[0]);
              double tiltYvalue = double.parse(values[1]);
              double tiltZvalue = double.parse(values[2]);
              // Parse other values similarly...
              // double gyprSprinRateValue = double.parse(values[position]);
              double temperatureValue = double.parse(values[3]);
              double pressureValue = double.parse(values[4]);
              double altitudeValue = double.parse(values[7]);
              // double voltageValue = double.parse(values[position]);
              // double gpsLatVal = double.parse(values[position]);
              // double gpsLongVal = double.parse(values[position]);
              // double packetCountVal = double.parse(values[position]);
              // double gpsstatsVal = double.parse(values[position]);
              // double modeVal = double.parse(values[position]);
              // double softwareStatVal = double.parse(values[position]);

              setState(() {
                tiltX = tiltXvalue;
                tiltY = tiltYvalue;
                tiltZ = tiltZvalue;
                temperature = temperatureValue;
                pressure = pressureValue;
                altitude = altitudeValue + 20;
                // Update other state variables accordingly...
              });

              tiltStreamController.add([tiltX, tiltY, tiltZ]);
            } catch (e) {
              print('Error parsing values: $e');
            }
          } else {
            print('Incomplete line received: $line');
          }
        }
      }, onError: (error) {
        print('Error reading data: $error');
      }, onDone: () {
        print('Port reading finished');
        portToRead.close();
      });
    } on SerialPortError catch (err) {
      print('Serial port error: $err');
      if (portToRead != null) {
        portToRead.close();
      }
    }
  }


  Stream<List<ChartData>> _getDataStreamforpressure() async* {
    List<ChartData> initialData = [ChartData(DateTime.now(), 0)];
    yield initialData;
    while (true) {
      double newValue = pressure; // Assuming pressure is a global variable
      List<ChartData> newData = List.from(initialData); // Create a new list to avoid mutating the initial data
      newData.add(ChartData(DateTime.now(), newValue));
      yield newData;
      await Future.delayed(Duration(seconds: 1));
    }
  }

  Stream<List<ChartData>> _getDataStreamforaltitude() async* {
    List<ChartData> initialData = [ChartData(DateTime.now(), 0)];
    yield initialData;
    while (true) {
      double newValue = altitude; // Assuming altitude is a global variable
      List<ChartData> newData = List.from(initialData); // Create a new list to avoid mutating the initial data
      newData.add(ChartData(DateTime.now(), newValue));
      yield newData;
      await Future.delayed(Duration(seconds: 1));
    }
  }

  Stream<List<ChartData>> _getDataStreamforgyro() async* {
    List<ChartData> initialData = [ChartData(DateTime.now(), 0),];
    yield initialData;
    while (true) {
      double newValue = gyroSpinRate;
      initialData.add(ChartData(DateTime.now(), newValue));
      yield initialData;
      await Future.delayed(Duration(seconds: 1));
    }
  }

  Stream<List<ChartData>> _getDataStreamforgyrospin() async* {
    // Initial data point
    List<ChartData> initialData = [
      ChartData(DateTime.now(), 0), // Initial value with current timestamp
    ];

    // Emit initial data point
    yield initialData;

    // Simulate real-time data updates
    while (true) {
      // Fetch the latest double value (replace this with your actual logic)
      double newValue = tiltX;

      // Add the new value with current timestamp to the data list
      initialData.add(ChartData(DateTime.now(), newValue));

      // Yield the updated data list
      yield initialData;

      // Wait for 1 second before emitting the next update
      await Future.delayed(Duration(seconds: 1));
    }
  }

  @override
  void initState() {
    super.initState();
    tiltX = 0.0;
    availablePorts = SerialPort.availablePorts;
    _controller = VideoPlayerController.asset('images/backgroundvideo.mp4');
    _initializeVideoPlayerFuture = _controller.initialize().then((_) {
      _controller.setLooping(true);
      _controller.play();
    });
    tiltStreamController = StreamController<List<double>>();
    cansat.scale.setValues(0.5, 0.5, 0.5);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GROUND STATION NAMBI',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            FutureBuilder(
              future: _initializeVideoPlayerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  );
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              },
            ),
            // Blurred container
            Container(
              color: Colors.black.withOpacity(0.7), // Adjust opacity as needed
              width: double.infinity,
              height: double.infinity,
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0), // Adjust blur intensity as needed
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),
            // App name text
            SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(top: 0.0),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.topCenter,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 18.0),
                            child: Container(
                              child: Transform.rotate(
                                angle: 90 * (3.1415926535897932 / 180), // Convert degrees to radians
                                child: Image.asset(
                                  'images/battery.png',
                                  height: 160.0,
                                  width: 100.0,
                                ),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              const Text(
                                'GROUND CONTROL STATION',
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 10.0),
                                child: Image.asset(
                                  'images/logo.png', // Replace this with your image path
                                ),
                              ),
                            ],
                          ),
                          Image.asset(
                            'images/image1.png',
                            height: 100.0,
                            width: 160.0, // Replace this with your image path
                          )
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 20),
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Team Details',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18.0,
                                  ),
                                ),
                                Text(
                                  'Team ID: 2022ASI-046',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          color: Colors.transparent,
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              SizedBox(width: 20,),
                              Column(
                                children: [
                                  Icon(
                                    Icons.power_settings_new,
                                    color: currentState == 'Boot' ? Colors.green : Colors.white,
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    'Boot',
                                    style: TextStyle(
                                      color: currentState == 'Boot' ? Colors.green : Colors.white,
                                      fontSize: 19,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(width: 20,),
                              Column(
                                children: [
                                  Icon(
                                    Icons.hourglass_empty,
                                    color: currentState == 'Idle' ? Colors.green : Colors.white,
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    'Idle',
                                    style: TextStyle(
                                      color: currentState == 'Idle' ? Colors.green : Colors.white,
                                      fontSize: 19,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(width: 20,),
                              Column(
                                children: [
                                  Icon(
                                    Icons.launch,
                                    color: currentState == 'Launch' ? Colors.green : Colors.white,
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    'Launch',
                                    style: TextStyle(
                                      color: currentState == 'Launch' ? Colors.green : Colors.white,
                                      fontSize: 19,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(width: 20,),
                              Column(
                                children: [
                                  Icon(
                                    Icons.public,
                                    color: currentState == 'Deploy' ? Colors.green : Colors.white,
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    'Deploy',
                                    style: TextStyle(
                                      color: currentState == 'Deploy' ? Colors.green : Colors.white,
                                      fontSize: 19,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(width: 20,),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DropdownButton(
                              // Initial Value
                              value: dropdownValue,
                              // Down Arrow Icon
                              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                              // Array list of items
                              items: availablePorts.map((String items) {
                                return DropdownMenuItem(
                                  value: items,
                                  child: Text(
                                    items,
                                    style: TextStyle(color: Colors.green), // Text color
                                  ),
                                );
                              }).toList(),
                              // After selecting the desired option, it will
                              // change button value to selected value
                              onChanged: (String? newValue) {
                                setState(() {
                                  dropdownValue = newValue!;
                                  portSelect.close(); // Close the previous port
                                  portSelect = SerialPort(newValue);
                                  portSelect.openReadWrite(); // Start reading data
                                  WriteData(portSelect);
                                });
                              },
                              dropdownColor: Colors.white, // Dropdown background color
                              style: TextStyle(color: Colors.black), // Selected item text color
                            ),
                            Text(
                              'Connected to: $dropdownValue',
                              style: TextStyle(fontSize: 18, color: Colors.white),
                            ),
                            //SizedBox(height: 10,),
                            Row(
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    ReadData1(portSelect);
                                  }, style: ElevatedButton.styleFrom(
                                  primary: Colors.green, // Start button color
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10), // Rounded corners
                                  ),
                                ), child: const Text(
                                  "START TELEMETRY",
                                  style: TextStyle(color: Colors.white), // Text color
                                ),
                                ),
                                SizedBox(width: 10),
                                ElevatedButton(
                                  onPressed: () {
                                    // Stop button action
                                  },
                                  style: ElevatedButton.styleFrom(
                                    primary: Colors.red, // Stop button color
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10), // Rounded corners
                                    ),
                                  ),
                                  child: Text(
                                    "STOP",
                                    style: TextStyle(color: Colors.white), // Text color
                                  ),
                                ),
                                SizedBox(width: 10),
                                ElevatedButton(
                                  onPressed: () {
                                    // Pause button action
                                  },
                                  style: ElevatedButton.styleFrom(
                                    primary: Colors.white, // Pause button color
                                    onPrimary: Colors.black, // Text color
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10), // Rounded corners
                                    ),
                                  ),
                                  child: Text(
                                    "PAUSE",
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SingleChildScrollView(
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: Column(
                              children: [
                                Container(
                                  height: 190,
                                  width: 220,
                                  child:   Center(
                                    child:TiltingCube(cansat: cansat, tiltStream: tiltStreamController.stream),

                                  ),
                                ),

                                SingleChildScrollView(
                                  child: SizedBox(
                                    width: 240,
                                    child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              Text("X",style: TextStyle(color: Colors.white),),
                                              SizedBox(width: 20,),
                                              Text(tiltX.toString(),style: TextStyle(color: Colors.white),)
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Text("Y",style: TextStyle(color: Colors.white),),
                                              SizedBox(width: 20,),
                                              Text(tiltY.toString(),style: TextStyle(color: Colors.white),)
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Text("Z",style: TextStyle(color: Colors.white),),
                                              SizedBox(width: 20,),
                                              Text(tiltZ.toString(),style: TextStyle(color: Colors.white),)
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Text("Temperature",style: TextStyle(color: Colors.white),),
                                              SizedBox(width: 20,),
                                              Text(temperature.toString(),style: TextStyle(color: Colors.white),)
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Text("Pressure",style: TextStyle(color: Colors.white),),
                                              SizedBox(width: 20,),
                                              Text(pressure.toString(),style: TextStyle(color: Colors.white),)
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Text("Altitude",style: TextStyle(color: Colors.white),),
                                              SizedBox(width: 20,),
                                              Text(altitude.toString(),style: TextStyle(color: Colors.white),)
                                            ],
                                          ),
                                        ]
                                    ),
                                  ),
                                ),
                              ],),),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: <Widget>[
                            SizedBox(
                              width: 400,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  children: [
                                    Text("Pressure",style: TextStyle(color: Colors.white),),
                                    StreamSyncfusionLineChart(dataStream: _getDataStreamforpressure()),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 400,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  children: [
                                    Text("Gyro",style: TextStyle(color: Colors.white),),
                                    StreamSyncfusionLineChart(dataStream: _getDataStreamforgyro()),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            SizedBox(
                              width: 400,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  children: [
                                    Text("Altitude",style: TextStyle(color: Colors.white),),
                                    StreamSyncfusionLineChart(dataStream: _getDataStreamforaltitude()),

                                  ],
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 400,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  children: [
                                    Text("Gyro Spin",style: TextStyle(color: Colors.white),),
                                    StreamSyncfusionLineChart(dataStream: _getDataStreamforgyrospin()),

                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        Column(
                          children: [
                            SizedBox(
                              height: 300,
                              width: 300,
                              child: Scaffold(
                                body: FlutterMap(
                                  options: MapOptions(
                                    initialCenter: LatLng(gpsLat, gpsLong),
                                    initialZoom: 18,
                                  ),
                                  children: [
                                    TileLayer(
                                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                      userAgentPackageName: 'com.example.app',
                                    ),
                                    CircleLayer(
                                      circles: [
                                        CircleMarker(
                                          point: LatLng(gpsLat, gpsLong), // center of 't Gooi
                                          radius: 20,
                                          useRadiusInMeter: true,
                                          color: Colors.red.withOpacity(0.3),
                                          borderColor: Colors.red.withOpacity(0.7),
                                          borderStrokeWidth: 2,
                                        )
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 20,),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    // Start button action
                                  }, style: ElevatedButton.styleFrom(
                                  primary: Colors.green, // Start button color
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10), // Rounded corners
                                  ),
                                ), child: Text(
                                  "STR TEL",
                                  style: TextStyle(color: Colors.white), // Text color
                                ),
                                ),
                                SizedBox(width: 20,),
                                ElevatedButton(
                                  onPressed: () {
                                    // Start button action
                                  }, style: ElevatedButton.styleFrom(
                                  primary: Colors.green, // Start button color
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10), // Rounded corners
                                  ),
                                ), child: Text(
                                  "STP TEL",
                                  style: TextStyle(color: Colors.white), // Text color
                                ),
                                ),
                                SizedBox(width: 20,),
                                ElevatedButton(
                                  onPressed: () {
                                    // Start button action
                                  }, style: ElevatedButton.styleFrom(
                                  primary: Colors.green, // Start button color
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10), // Rounded corners
                                  ),
                                ), child: Text(
                                  "MISSION TIME",
                                  style: TextStyle(color: Colors.white), // Text color
                                ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20,),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    // Start button action
                                  }, style: ElevatedButton.styleFrom(
                                  primary: Colors.green, // Start button color
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10), // Rounded corners
                                  ),
                                ), child: Text(
                                  "ENB SIM",
                                  style: TextStyle(color: Colors.white), // Text color
                                ),
                                ),
                                SizedBox(width: 20,),
                                ElevatedButton(
                                  onPressed: () {
                                    // Start button action
                                  }, style: ElevatedButton.styleFrom(
                                  primary: Colors.green, // Start button color
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10), // Rounded corners
                                  ),
                                ), child: Text(
                                  "STR SIM",
                                  style: TextStyle(color: Colors.white), // Text color
                                ),
                                ),
                                SizedBox(width: 20,),
                                ElevatedButton(
                                  onPressed: () {
                                    // Start button action
                                  }, style: ElevatedButton.styleFrom(
                                  primary: Colors.green, // Start button color
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10), // Rounded corners
                                  ),
                                ), child: Text(
                                  "STP SIM",
                                  style: TextStyle(color: Colors.white), // Text color
                                ),
                                ),
                              ],
                            ),

                          ],
                        )
                      ],
                    ),

                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(MonitoringScreen2());
}

void WriteData(SerialPort portToWrite) {
  try {
    print(portToWrite.write(_stringToUint8List("hello")));
  } on SerialPortError catch (err) {
    print(err);
  }

}


Uint8List _stringToUint8List(String data) {
  List<int> codeUnits = data.codeUnits;
  Uint8List uint8list = Uint8List.fromList(codeUnits);
  return uint8list;
}






//altitude
//gyroscope
//pressure
//
