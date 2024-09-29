// import 'package:flutter/material.dart';
// import 'package:syncfusion_flutter_charts/charts.dart';

// void main() {
//   runApp(GraphApp());
// }

// class GraphApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: GraphHomePage(),
//     );
//   }
// }

// class GraphHomePage extends StatefulWidget {
//   @override
//   _GraphHomePageState createState() => _GraphHomePageState();
// }

// class _GraphHomePageState extends State<GraphHomePage> {
//   late List<SalesData> chartData;

//   @override
//   void initState() {
//     chartData = [
//       SalesData('Jan', 35),
//       SalesData('Feb', 28),
//       SalesData('Mar', 34),
//       SalesData('Apr', 32),
//       SalesData('May', 40),
//     ];
//     super.initState();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         appBar: AppBar(title: Text('Syncfusion Flutter Chart Example')),
//         body: Center(
//           child: SfCartesianChart(
//             primaryXAxis: CategoryAxis(),
//             title: ChartTitle(text: 'Monthly Sales Analysis'),
//             legend: Legend(isVisible: true),
//             tooltipBehavior: TooltipBehavior(enable: true),
//             series: <CartesianSeries>[
//               LineSeries<SalesData, String>(
//                 dataSource: chartData,
//                 xValueMapper: (SalesData sales, _) => sales.month,
//                 yValueMapper: (SalesData sales, _) => sales.sales,
//                 name: 'Sales',
//                 dataLabelSettings: DataLabelSettings(isVisible: true),
//               )
//             ],
//           ),
//         ));
//   }
// }

// class SalesData {
//   final String month;
//   final double sales;

//   SalesData(this.month, this.sales);
// }

// ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- -----

// import 'package:flutter/material.dart';
// import 'package:fl_chart/fl_chart.dart';

// void main() {
//   runApp(GraphApp());
// }

// class GraphApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: GraphHomePage(),
//     );
//   }
// }

// class GraphHomePage extends StatelessWidget {
//   final List<FlSpot> dataPoints = [
//     FlSpot(0, 3),
//     FlSpot(1, 2),
//     FlSpot(2, 5),
//     FlSpot(3, 3.1),
//     FlSpot(4, 4),
//     FlSpot(5, 3),
//     FlSpot(6, 4),
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Flutter Graph Example')),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: LineChart(
//           LineChartData(
//             lineBarsData: [
//               LineChartBarData(
//                 spots: dataPoints,
//                 isCurved: true,
//                 barWidth: 2,
//                 color: Colors.blue,
//                 belowBarData: BarAreaData(
//                   show: true,
//                   color: Colors.blue.withOpacity(0.3),
//                 ),
//                 dotData: FlDotData(
//                   show: true,
//                 ),
//               ),
//             ],
//             titlesData: FlTitlesData(
//               bottomTitles: AxisTitles(
//                 sideTitles: SideTitles(
//                   showTitles: true,
//                   interval: 1,
//                   getTitlesWidget: bottomTitleWidgets,
//                 ),
//               ),
//               leftTitles: AxisTitles(
//                 sideTitles: SideTitles(
//                   showTitles: true,
//                   interval: 1,
//                 ),
//               ),
//             ),
//             gridData: FlGridData(
//               show: true,
//               drawVerticalLine: true,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// Widget bottomTitleWidgets(double value, TitleMeta meta) {
//   const style = TextStyle(
//     fontSize: 12,
//   );
//   String text;
//   switch (value.toInt()) {
//     case 0:
//       text = 'Jan';
//       break;
//     case 1:
//       text = 'Feb';
//       break;
//     case 2:
//       text = 'Mar';
//       break;
//     case 3:
//       text = 'Apr';
//       break;
//     case 4:
//       text = 'May';
//       break;
//     case 5:
//       text = 'Jun';
//       break;
//     case 6:
//       text = 'Jul';
//       break;
//     default:
//       text = '';
//       break;
//   }
//   return SideTitleWidget(
//     axisSide: meta.axisSide,
//     child: Text(text, style: style),
//   );
// }

// ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- -----

// import 'package:flutter/material.dart';
// import 'package:graphic/graphic.dart';

// void main() {
//   runApp(GraphApp());
// }

// class GraphApp extends StatelessWidget {
//   const GraphApp({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: GraphHomePage(),
//     );
//   }
// }

// class GraphHomePage extends StatelessWidget {
//   GraphHomePage({Key? key}) : super(key: key);

//   final List<Map<String, dynamic>> data = [
//     {'month': 'Jan', 'value': 5},
//     {'month': 'Feb', 'value': 3},
//     {'month': 'Mar', 'value': 4},
//     {'month': 'Apr', 'value': 7},
//     {'month': 'May', 'value': 6},
//     {'month': 'Jun', 'value': 8},
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Graphic Package Chart Example')),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Chart(
//           data: data,
//           variables: {
//             'month': Variable(
//               accessor: (Map map) => map['month'] as String,
//             ),
//             'value': Variable(
//               accessor: (Map map) => map['value'] as num,
//             ),
//           },
//           marks: [
//             LineMark(
//               shape: ShapeEncode(value: BasicLineShape(smooth: true)),
//               size: SizeEncode(value: 2),
//               color: ColorEncode(value: Colors.blue),
//             ),
//             PointMark(
//               size: SizeEncode(value: 4),
//               color: ColorEncode(value: Colors.blue),
//             ),
//           ],
//           axes: [
//             Defaults.horizontalAxis,
//             Defaults.verticalAxis,
//           ],
//         ),
//       ),
//     );
//   }
// }

// ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- -----

// import 'package:flutter/material.dart';
// import 'package:syncfusion_flutter_charts/charts.dart';

// void main() => runApp(ChartApp());

// class ChartApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//         appBar: AppBar(title: const Text('Syncfusion Flutter Chart')),
//         body: ChartWidget(),
//       ),
//     );
//   }
// }

// class ChartWidget extends StatefulWidget {
//   @override
//   _ChartWidgetState createState() => _ChartWidgetState();
// }

// class _ChartWidgetState extends State<ChartWidget> {
//   final List<_ChartData> data = [
//     _ChartData('David', 25),
//     _ChartData('Steve', 38),
//     _ChartData('Jack', 34),
//     _ChartData('Others', 52),
//   ];

//   TooltipBehavior _tooltipBehavior = TooltipBehavior(enable: true);
//   int _tappedIndex = -1; // Track the tapped index to set explode effect

//   @override
//   Widget build(BuildContext context) {
//     return SfCircularChart(
//       tooltipBehavior: _tooltipBehavior,
//       series: <CircularSeries<_ChartData, String>>[
//         DoughnutSeries<_ChartData, String>(
//           dataSource: data,
//           xValueMapper: (_ChartData data, _) => data.x,
//           yValueMapper: (_ChartData data, _) => data.y,
//           name: 'Gold',
//           explode: true, // Enable explode behavior
//           explodeIndex: _tappedIndex, // Dynamically set the explode index
//           explodeOffset: '30%', // Set the explode offset
//           onPointTap: (ChartPointDetails details) {
//             setState(() {
//               _tappedIndex = details.pointIndex!;
//             });
//           },
//         )
//       ],
//     );
//   }
// }

// class _ChartData {
//   _ChartData(this.x, this.y);
//   final String x;
//   final double y;
// }

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

void main() => runApp(MaterialApp(home: ChartPage()));

class ChartPage extends StatelessWidget {
  final List<_ChartData> data = [_ChartData('CHN', 12), _ChartData('GER', 15), _ChartData('RUS', 30), _ChartData('BRZ', 6.4), _ChartData('IND', 14)];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Syncfusion Flutter Chart')),
      body: SfCartesianChart(
        primaryXAxis: CategoryAxis(),
        primaryYAxis: NumericAxis(minimum: 0, maximum: 40, interval: 10),
        tooltipBehavior: TooltipBehavior(enable: true),
        series: <CartesianSeries<_ChartData, String>>[
          BarSeries<_ChartData, String>(
            dataSource: data,
            xValueMapper: (_ChartData data, _) => data.x,
            yValueMapper: (_ChartData data, _) => data.y,
            name: 'Gold',
            color: Color.fromRGBO(8, 142, 255, 1),
          )
        ],
      ),
    );
  }
}

class _ChartData {
  _ChartData(this.x, this.y);
  final String x;
  final double y;
}
