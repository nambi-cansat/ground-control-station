import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class StreamSyncfusionLineChart2 extends StatefulWidget {
  final Stream<List<ChartData1>> dataStream;

  const StreamSyncfusionLineChart2({Key? key, required this.dataStream}) : super(key: key);

  @override
  _StreamSyncfusionLineChartState createState() => _StreamSyncfusionLineChartState();
}

class _StreamSyncfusionLineChartState extends State<StreamSyncfusionLineChart2> {
  late List<ChartData1> _dataPoints1;

  @override
  void initState() {
    super.initState();
    _dataPoints1 = [];
    widget.dataStream.listen((data) {
      setState(() {
        _dataPoints1 = data;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      child: SfCartesianChart(
        primaryXAxis: CategoryAxis(),
        series: <ChartSeries<ChartData1, String>>[
          LineSeries<ChartData1, String>(
            dataSource: _dataPoints1,
            xValueMapper: (ChartData1 data, _) => '${data.x.second}s', // Format DateTime to show only seconds
            yValueMapper: (ChartData1 data, _) => data.y,
          ),
        ],
      ),
    );
  }
}

class ChartData1 {
  final DateTime x;
  final double y;

  ChartData1(this.x, this.y);
}


