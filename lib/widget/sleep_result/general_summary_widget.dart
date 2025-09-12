import 'package:flutter/material.dart';
import 'package:omnifit_front/models/general_summary_model.dart';
// 1. 새로 만든 위젯 파일을 import 합니다.
import 'package:omnifit_front/widget/sleep_result/respiratory_events_widget.dart';

class GeneralSummaryWidget extends StatelessWidget {
  final GeneralSummaryModel data;

  const GeneralSummaryWidget({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    const headerStyle = TextStyle(fontWeight: FontWeight.bold, color: Colors.black87);
    const labelStyle = TextStyle(color: Colors.black87);
    const valueStyle = TextStyle(color: Colors.black87);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- 1번 섹션 ---
        _buildGeneralSummarySection(headerStyle, labelStyle, valueStyle),
        
        const SizedBox(height: 24), // 섹션 간 간격

        // --- 2. 새로 만든 RespiratoryEventsWidget을 여기에 추가합니다 ---
        const RespiratoryEventsWidget(),
      ],
    );
  }

  /// 1. General Summary 섹션을 그리는 위젯
  Widget _buildGeneralSummarySection(TextStyle headerStyle, TextStyle labelStyle, TextStyle valueStyle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('1. General Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            //Text('▷ 검사시작 ~ 종료일시   2017-03-09 23:20:00 ~ 2017-03-10 05:25:30'),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildLeftTable(headerStyle, labelStyle, valueStyle)),
                const VerticalDivider(width: 20, thickness: 1),
                Expanded(child: _buildRightTable(headerStyle, labelStyle, valueStyle)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- 기존 Helper 위젯들은 그대로 유지됩니다 ---
  Widget _buildLeftTable(TextStyle headerStyle, TextStyle labelStyle, TextStyle valueStyle) {
    final displayData = [
      {'label': 'TIB', 'value': data.tib.toStringAsFixed(1)},
      {'label': 'TST', 'value': data.tst.toStringAsFixed(1)},
      {'label': 'TWT', 'value': data.twt.toStringAsFixed(1)},
      {'label': 'WASO', 'value': data.waso.toStringAsFixed(1)},
      {'label': 'Sleep Latency', 'value': data.sleepLatency.toStringAsFixed(1)},
      {'label': 'REM Latency', 'value': data.remLatency.toStringAsFixed(1)},
      {'label': 'Sleep efficiency %', 'value': data.sleepEfficiency.toStringAsFixed(1)},
    ];

    return Table(
      columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(1)},
      border: const TableBorder(horizontalInside: BorderSide(width: 1, color: Color(0xFFEEEEEE))),
      children: [
        TableRow(children: [
          const SizedBox.shrink(),
          TableCell(
            verticalAlignment: TableCellVerticalAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text('min.', style: headerStyle, textAlign: TextAlign.center),
            ),
          ),
        ]),
        ...displayData.map((item) {
          return TableRow(children: [
            TableCell(
              verticalAlignment: TableCellVerticalAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                child: Text(item['label']!, style: labelStyle),
              ),
            ),
            TableCell(
              verticalAlignment: TableCellVerticalAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(item['value']!, style: valueStyle, textAlign: TextAlign.center),
              ),
            ),
          ]);
        }).toList(),
      ],
    );
  }

  Widget _buildRightTable(TextStyle headerStyle, TextStyle labelStyle, TextStyle valueStyle) {
    return Table(
      columnWidths: const {0: FlexColumnWidth(2.2), 1: FlexColumnWidth(1), 2: FlexColumnWidth(1)},
      border: const TableBorder(
          horizontalInside: BorderSide(width: 1, color: Color(0xFFEEEEEE)),
          verticalInside: BorderSide(width: 1, color: Color(0xFFEEEEEE))),
      children: [
        TableRow(children: [
          const SizedBox.shrink(),
          TableCell(
              child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text('min.', style: headerStyle, textAlign: TextAlign.center))),
          TableCell(
              child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text('% TST', style: headerStyle, textAlign: TextAlign.center))),
        ]),
        ...data.sleepStages.map((item) => _buildDataRow(item, labelStyle, valueStyle)),
        const TableRow(children: [SizedBox(height: 28), SizedBox(height: 28), SizedBox(height: 28)]),
        ...data.summaryStages.map((item) => _buildDataRow(item, labelStyle, valueStyle, hasTopBorder: true)),
      ],
    );
  }

  TableRow _buildDataRow(SleepMetrics item, TextStyle labelStyle, TextStyle valueStyle, {bool hasTopBorder = false}) {
    return TableRow(
      decoration: hasTopBorder ? const BoxDecoration(border: Border(top: BorderSide(width: 1, color: Color(0xFFBDBDBD)))) : null,
      children: [
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
            child: Text(item.label, style: labelStyle),
          ),
        ),
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text(item.min.toStringAsFixed(1), style: valueStyle, textAlign: TextAlign.center),
          ),
        ),
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text(item.tst.toStringAsFixed(1), style: valueStyle, textAlign: TextAlign.center),
          ),
        ),
      ],
    );
  }
}