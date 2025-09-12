import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:omnifit_front/models/graph1_model.dart';

class Graph1 extends StatelessWidget {
  final Graph1Model graph1model;

  const Graph1({Key? key, required this.graph1model}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          children: [
            const SizedBox(width: 45),
            Expanded(
              child: Text(
                'nni',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AspectRatio(
          aspectRatio: 3.5,
          child: LineChart(LineChartData(
            lineTouchData: const LineTouchData(enabled: false),
            gridData: FlGridData(
              show: true,
              drawHorizontalLine: true,
              verticalInterval: graph1model.intervalX,
              horizontalInterval: graph1model.intervalY,
              getDrawingVerticalLine: (value) {
                return FlLine(color: Colors.black.withOpacity(0.1), strokeWidth: 1);
              },
              getDrawingHorizontalLine: (value) {
                return FlLine(color: Colors.black.withOpacity(0.1), strokeWidth: 1);
              },
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                axisNameSize: 30,
                axisNameWidget: Row(
                  children: [
                    const SizedBox(width: 45), 
                    Expanded(
                      child: Text(
                        'Time(m)',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    interval: graph1model.intervalX,
                    getTitlesWidget: bottomTitleWidgets),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: true, getTitlesWidget: leftTitleWidgets, reservedSize: 40, interval: graph1model.intervalY),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: true, border: Border.all(color: const Color(0xff37434d))),
            minX: graph1model.minX,
            maxX: graph1model.maxX,
            minY: graph1model.minY,
            maxY: graph1model.maxY,
            lineBarsData: [
              LineChartBarData(spots: graph1model.dataList, isCurved: true, barWidth: 2, isStrokeCapRound: true, dotData: const FlDotData(show: false), color: Colors.blueAccent),
            ],
          )),
        ),
      ],
    );
  }

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.normal,
      fontSize: 12
    );

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text("${value.round().toInt()}", style: style),
    );
  }

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    if (value == meta.min) {
      return const SizedBox();
    }

    const style = TextStyle(
      fontWeight: FontWeight.normal,
      fontSize: 11
    );
    
    String text = value.toStringAsFixed(1);

    return Text(text, style: style, textAlign: TextAlign.left);
  }
}