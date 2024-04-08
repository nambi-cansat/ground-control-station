import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:gcsnambi/TimeProvider.dart';
import 'package:provider/provider.dart';
import 'HollowCylinder.dart';
import 'package:file_picker/file_picker.dart';
import 'RealTimeLineChart.dart';
import 'dart:async';
import 'package:flutter_cube/flutter_cube.dart';
import 'package:libserialport/libserialport.dart';
import 'dart:ui' as ui;
import 'package:latlong2/latlong.dart';


class MonitoringScreen2 extends StatefulWidget {
  const MonitoringScreen2({super.key});

  @override
  State<MonitoringScreen2> createState() => _MonitoringScreen2State();
}

class _MonitoringScreen2State extends State<MonitoringScreen2> {

  String currentState = 'Boot',idleState = 'Idle',launchState = 'launch',deployState = 'Deploy';
  double tiltX = 0.0,tiltY=0.0,tiltZ = 0.0,gyroSpinRate = 0.0,temperature = 0.0, pressure = 0.0,altitude = 0.0,voltage=0.0,gpsLat=27.176670,gpsLong=78.008072,accelerometer = 0.0;
  Object cansat =  Object(fileName: "images/tube.obj");
  late StreamController<List<double>> tiltStreamController;
  late List<String> availablePorts;
  SerialPort portSelect = SerialPort("No One");
  String? dropdownValue;
  int packetCount = 0,mode = 0,gpsStats=0,softwareState=0;
  String time= '';
  List<Map<String, dynamic>> sensorData = [];
  ScrollController _scrollController = ScrollController();
  String timeGiven = '';



  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

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
          if (values.length >= 5) { // Ensure at least 14 values are present
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
                addSensorData(tiltZ,tiltY,tiltX);
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
  Stream<List<ChartData>> _getDataStreamfortemperature() async* {
    List<ChartData> initialData = [ChartData(DateTime.now(), 0),];
    yield initialData;
    while (true) {
      double newValue = temperature;
      List<ChartData> newData = List.from(initialData); // Create a new list to avoid mutating the initial data
      newData.add(ChartData(DateTime.now(), newValue));
      yield newData;
      await Future.delayed(Duration(seconds: 1));
    }
  }


  void addSensorData(double temperature, double altitude, double pressure) {
    setState(() {
      sensorData.add({
        'temperature': temperature,
        'altitude': altitude,
        'pressure': pressure,
      });
    });

    // Scroll to the bottom
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  bool isTelemetryRunning = false;

  void toggleTelemetry() {
    setState(() {
      isTelemetryRunning = !isTelemetryRunning;
    });
  }

  ElevatedButton buildTelemetryButton() {
    return ElevatedButton(
      onPressed: () {
        // Toggle telemetry status
        toggleTelemetry();
        if (isTelemetryRunning) {
          // Start telemetry
          ReadData1(portSelect);
          cansat.updateTransform();
        } else {
          // Stop telemetry
          // You might want to add logic to stop reading data here if needed
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isTelemetryRunning ? Colors.red : Colors.green,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Text(
          isTelemetryRunning ? "STOP TELEMETRY" : "START TELEMETRY",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    tiltX = 0.0;
    availablePorts = SerialPort.availablePorts;
    tiltStreamController = StreamController<List<double>>();
    cansat.scale.setValues(0.5, 0.5, 0.5);
    cansat.updateTransform();
    isTelemetryRunning = false;
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context)=> TimeProvider(),
      child: MaterialApp(
        color: Colors.black,
        home: Scaffold(
          backgroundColor: Colors.black,
          body: Container(
            height: double.infinity,
            width: double.infinity,
            child: Column(
              children: [
                //ROW 1
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          'images/cansatlogo.png',
                          height: 100,
                        ),
                        Row(
                          children: [
                            Image.asset(
                              'images/battery.png',
                              height: 80.0,
                            ),
                            Text(altitude.toString()+"%",style: TextStyle(color: Colors.white,fontSize: 20),)
                          ],
                        ),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(23)),
                        border: Border.all(
                          color: Colors.green,
                          width: 3,
                        )
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: const Center(
                          child: Text(
                            'GROUND CONTROL STATION',
                            style: TextStyle(
                              fontSize: 46,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top:2.0),
                      child: Image.asset(
                        'images/logo.png',
                        height: 100,
                      ),
                    ),
                    const Text(
                      'TEAM ID: \n2022ASI-046',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 18.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                    Row(
                      children: [
                        Icon(
                          Icons.power_settings_new,
                          color: currentState == 'Boot' ? Colors.green : Colors.white,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Boot',
                          style: TextStyle(
                            color: currentState == 'Boot' ? Colors.green : Colors.white,
                            fontSize: 29,
                          ),
                        ),
                      ],
                    ),
                      buildTelemetryButton(),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.orange,width: 3),
                        borderRadius: BorderRadius.all(Radius.circular(6))
                      ),
                      child: Consumer<TimeProvider>(
                        builder: (context, timeProvider, _) {
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              timeProvider.currentTime,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                      }, style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green, // Start button color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10), // Rounded corners
                      ),
                    ), child: Padding(
                      padding: const EdgeInsets.only(top: 12,bottom: 12),
                      child: const Text(
                        "DEPLOY PARACHUTE",
                        style: TextStyle(color: Colors.white,fontSize: 20), // Text color
                      ),
                    ),
                    ),
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
                          });
                        },
                        dropdownColor: Colors.white, // Dropdown background color
                        style: TextStyle(color: Colors.black), // Selected item text color
                      ),
                  ],),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Container(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 1.0,bottom: 1.0,left: 5,right: 5),
                                child: Text("Pressure",style: TextStyle(color: Colors.white,fontSize: 20),),
                              ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.red),
                              borderRadius: BorderRadius.circular(10)
                          ),),

                          StreamSyncfusionLineChart(dataStream: _getDataStreamforpressure()),
                        ],
                      ),
                      Column(
                        children: [
                          Container(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1.0,bottom: 1.0,left: 5,right: 5),
                              child: Text("Altitude",style: TextStyle(color: Colors.white,fontSize: 20),),
                            ),
                            decoration: BoxDecoration(
                                border: Border.all(color: Colors.red),
                                borderRadius: BorderRadius.circular(10)
                            ),),
                          StreamSyncfusionLineChart(dataStream: _getDataStreamforaltitude()),
                        ],
                      ),
                      Column(
                        children: [
                          Container(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 1.0,bottom: 1.0,left: 5,right: 5),
                              child: Text("Temperature",style: TextStyle(color: Colors.white,fontSize: 20),),
                            ),
                            decoration: BoxDecoration(
                                border: Border.all(color: Colors.red),
                                borderRadius: BorderRadius.circular(10)
                            ),),
                          StreamSyncfusionLineChart(dataStream: _getDataStreamfortemperature()),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white)
                        ),
                        child: Column(
                          children: [
                            SizedBox(height: 5,),
                            SizedBox(
                                height: 200,
                                width: 200,
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: TiltingCube(cansat: cansat, tiltStream: tiltStreamController.stream),
                                )),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                    Row(
                                      children: [
                                        Text("Tilt X = ",style: TextStyle(color: Colors.white,fontSize: 20),),
                                        SizedBox(width: 5,),
                                        Text(tiltX.toString(),style: TextStyle(color: Colors.white,fontSize: 20),)
                                      ],
                                    ),
                                    SizedBox(width: 10,),
                                    Row(
                                      children: [
                                        Text("Tilt Y = ",style: TextStyle(color: Colors.white,fontSize: 20),),
                                        SizedBox(width: 5,),
                                        Text(tiltY.toString(),style: TextStyle(color: Colors.white,fontSize: 20),)
                                      ],
                                    ),
                                      SizedBox(width: 10,),
                                      Row(
                                      children: [
                                        Text("Tilt Z = ",style: TextStyle(color: Colors.white,fontSize: 20),),
                                        SizedBox(width: 5,),
                                        Text(tiltZ.toString(),style: TextStyle(color: Colors.white,fontSize: 20),)
                                      ],
                                    ),
                                  ],),
                                  Row(
                                    children: [
                                      Text("Gyro Spin Rate = ",style: TextStyle(color: Colors.white,fontSize: 20),),
                                      SizedBox(width: 5,),
                                      Text(gyroSpinRate.toString(),style: TextStyle(color: Colors.white,fontSize: 20),)
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Text("Accelerometer = ",style: TextStyle(color: Colors.white,fontSize: 20),),
                                      SizedBox(width: 5,),
                                      Text(accelerometer.toString(),style: TextStyle(color: Colors.white,fontSize: 20),)
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                      height: 364,
                      width: 1100,
                      margin: EdgeInsets.all(5.0),
                      padding: EdgeInsets.all(10.0),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        border: Border.all(
                          color: Colors.white,
                          width: 1.0,
                        ),
                        borderRadius: BorderRadius.circular(5.0),),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                        Container(
                        height: 300,
                        width: double.infinity,
                        margin: EdgeInsets.all(5.0),
                        padding: EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          border: Border.all(
                            color: Colors.white,
                            width: 1.0,
                          ),
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          scrollDirection: Axis.vertical,
                          child: Container(
                            width: double.infinity,
                            child: DataTable(
                              columnSpacing: 10,
                              columns: [
                                DataColumn(label: Text('MissionTime', style: TextStyle(color: Colors.white))),
                                DataColumn(label: Text('PacketCount', style: TextStyle(color: Colors.white))),
                                DataColumn(label: Text('Altitude', style: TextStyle(color: Colors.white))),
                                DataColumn(label: Text('Pressure', style: TextStyle(color: Colors.white))),
                                DataColumn(label: Text('Temperature', style: TextStyle(color: Colors.white))),
                                DataColumn(label: Text('Voltage', style: TextStyle(color: Colors.white))),
                                DataColumn(label: Text('GNSSTime', style: TextStyle(color: Colors.white))),
                                DataColumn(label: Text('Latitude', style: TextStyle(color: Colors.white))),
                                DataColumn(label: Text('Longitude', style: TextStyle(color: Colors.white))),
                              ],
                              rows: sensorData.map((data) {
                                return DataRow(cells: [
                                  DataCell(Text(data['temperature'].toString(), style: TextStyle(color: Colors.white))),
                                  DataCell(Text(data['altitude'].toString(), style: TextStyle(color: Colors.white))),
                                  DataCell(Text(data['pressure'].toString(), style: TextStyle(color: Colors.white))),
                                  DataCell(Text(data['temperature'].toString(), style: TextStyle(color: Colors.white))),
                                  DataCell(Text(data['altitude'].toString(), style: TextStyle(color: Colors.white))),
                                  DataCell(Text(data['pressure'].toString(), style: TextStyle(color: Colors.white))),
                                  DataCell(Text(data['temperature'].toString(), style: TextStyle(color: Colors.white))),
                                  DataCell(Text(data['altitude'].toString(), style: TextStyle(color: Colors.white))),
                                  DataCell(Text(data['pressure'].toString(), style: TextStyle(color: Colors.white))),
                                ]);
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                          ElevatedButton(
                            onPressed: () {
                              _saveAsCSV();
                            }, style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange, // Start button color
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10), // Rounded corners
                            ),
                          ), child: const Text(
                            "Download CSV",
                            style: TextStyle(color: Colors.white), // Text color
                          ),
                          )
                        ],
                      )
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 260,
                          width: 290,
                          child: FlutterMap(
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
                        SizedBox(height: 10,),
                        Container(
                          width: 300,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white)
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text("Latitude= ",style: TextStyle(color: Colors.white,fontSize: 15),),
                                    SizedBox(width: 5,),
                                    Text(gpsLat.toString(),style: TextStyle(color: Colors.white,fontSize: 15),)
                                  ],
                                ),
                                SizedBox(width: 3,),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text("Longitude = ",style: TextStyle(color: Colors.white,fontSize: 15),),
                                    SizedBox(width: 5,),
                                    Text(gpsLong.toString(),style: TextStyle(color: Colors.white,fontSize: 15),)
                                  ],
                                ),
                                SizedBox(width: 3,),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text("GPS stats= ",style: TextStyle(color: Colors.white,fontSize: 15),),
                                    SizedBox(width: 5,),
                                    Text(gpsStats.toString(),style: TextStyle(color: Colors.white,fontSize: 15),)
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text("GPS altitde = ",style: TextStyle(color: Colors.white,fontSize: 15),),
                                    SizedBox(width: 5,),
                                    Text(altitude.toString(),style: TextStyle(color: Colors.white,fontSize: 15),)
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )
                      ],
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveAsCSV() async {
    final List<List<dynamic>> rows = [];
    final List<String> headers = [
      'MissionTime',
      'PacketCount',
      'Altitude',
      'Pressure',
      'Temperature',
      'Voltage',
      'GNSSTime',
      'Latitude',
      'Longitude',
    ];

    // Add headers
    rows.add(headers);

    // Add data
    sensorData.forEach((data) {
      rows.add([
        data['temperature'],
        data['PacketCount'],
        data['Altitude'],
        data['Pressure'],
        data['Temperature'],
        data['Voltage'],
        data['GNSSTime'],
        data['Latitude'],
        data['Longitude'],
      ]);
    });

    // Let the user choose the file location
    String? filePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save CSV File',
      fileName: 'sensor_data.csv',
    );

    if (filePath != null) {
      // Write to CSV file
      File csvFile = File(filePath);
      String csvData = const ListToCsvConverter().convert(rows);
      await csvFile.writeAsString(csvData);

      // Show a dialog or message to inform the user that the file has been saved
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('CSV Saved'),
          content: Text('CSV file saved successfully.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    } else {
      // Handle null file path
      print('File path is null');
    }
  }


}


