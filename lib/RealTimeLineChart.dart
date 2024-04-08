import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class StreamSyncfusionLineChart extends StatefulWidget {
  final Stream<List<ChartData>> dataStream;
  const StreamSyncfusionLineChart({Key? key, required this.dataStream}) : super(key: key);

  @override
  _StreamSyncfusionLineChartState createState() => _StreamSyncfusionLineChartState();
}

class _StreamSyncfusionLineChartState extends State<StreamSyncfusionLineChart> {
  late List<ChartData> _dataPoints;

  @override
  void initState() {
    super.initState();
    _dataPoints = [];
    widget.dataStream.listen((data) {
      setState(() {
        _dataPoints = data;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      child: SfCartesianChart(
        plotAreaBackgroundColor: Colors.black, // Set plot area background color to black
        backgroundColor: Colors.black, // Set background color to black
        primaryXAxis: CategoryAxis(
          majorGridLines: MajorGridLines(
            width: 0.5, // Set the width of major grid lines
            color: Colors.grey[800], // Set color of major grid lines
          ),
          labelStyle: TextStyle(color: Colors.white), // Set label text color to white
        ),
        primaryYAxis: NumericAxis(
          majorGridLines: MajorGridLines(
            width: 0.5, // Set the width of major grid lines
            color: Colors.grey[800], // Set color of major grid lines
          ),
          labelStyle: TextStyle(color: Colors.white), // Set label text color to white
        ),
        series: <ChartSeries<ChartData, String>>[
          LineSeries<ChartData, String>(
            dataSource: _dataPoints,
            xValueMapper: (ChartData data, _) => '${data.x.second}s', // Format DateTime to show only seconds
            yValueMapper: (ChartData data, _) => data.y,
            color: Colors.blue, // Set line color to blue
            markerSettings: MarkerSettings(color: Colors.blue), // Set marker color to blue
          ),
        ],
      ),
    );
  }
}

class ChartData {
  final DateTime x;
  final double y;

  ChartData(this.x, this.y);
}
