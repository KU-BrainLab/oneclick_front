// file: general_summary_widget.dart

import 'package:flutter/material.dart';

class GeneralSummaryWidget extends StatelessWidget {
  const GeneralSummaryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // 텍스트 스타일을 미리 정의하여 재사용합니다.
    const headerStyle = TextStyle(fontWeight: FontWeight.bold, color: Colors.black87);
    const labelStyle = TextStyle(color: Colors.black87);
    const valueStyle = TextStyle(color: Colors.black87);

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 전체 제목
          const Text(
            '1. General Summary',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          // 2. 상단 정보
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('▷ 검사시작 ~ 종료일시   2017-03-09 23:20:00 ~ 2017-03-10 05:25:30'),
              Text('▷ KESS   7 / 27'),
            ],
          ),
          const Divider(height: 20, thickness: 1),

          // 3. 메인 테이블
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 왼쪽 테이블
                Expanded(
                  child: _buildLeftTable(headerStyle, labelStyle, valueStyle),
                ),
                // 세로 구분선
                const VerticalDivider(width: 20, thickness: 1),
                // 오른쪽 테이블
                Expanded(
                  child: _buildRightTable(headerStyle, labelStyle, valueStyle),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftTable(TextStyle headerStyle, TextStyle labelStyle, TextStyle valueStyle) {
    final data = [
      {'label': 'TIB', 'value': '이'},
      {'label': 'TST', 'value': '값'},
      {'label': 'TWT', 'value': '들'},
      {'label': 'WASO', 'value': '을'},
      {'label': 'Sleep Latency', 'value': '로'},
      {'label': 'REM Latency', 'value': '드'},
      {'label': 'Sleep efficiency %', 'value': '해야함'},
    ];

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(1),
      },
      border: const TableBorder(
        horizontalInside: BorderSide(width: 1, color: Color(0xFFEEEEEE)),
      ),
      children: [
        TableRow(
          children: [
            const SizedBox.shrink(),
            TableCell(
              verticalAlignment: TableCellVerticalAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text('min.', style: headerStyle, textAlign: TextAlign.center),
              ),
            ),
          ],
        ),
        ...data.map((item) {
          return TableRow(
            children: [
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
            ],
          );
        }).toList(),
      ],
    );
  }

  // 오른쪽 데이터 테이블을 만드는 위젯
  Widget _buildRightTable(TextStyle headerStyle, TextStyle labelStyle, TextStyle valueStyle) {
    final data = [
      {'label': 'Stage N1 sleep', 'min': 'ㅇㅅㅇ', 'tst': '=ㅅ='},
      {'label': 'Stage N2 sleep', 'min': 'ㅇㅅㅇ', 'tst': '=ㅅ='},
      {'label': 'Stage N3 sleep', 'min': 'ㅇㅅㅇ', 'tst': '=ㅅ='},
    ];
    final summaryData = [
      {'label': 'Total NREM sleep', 'min': '257.5', 'tst': '73.4'},
      {'label': 'REM sleep', 'min': '93.5', 'tst': '26.6'},
    ];

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2.2), // 라벨 열
        1: FlexColumnWidth(1),   // min 열
        2: FlexColumnWidth(1),   // % TST 열
      },
      border: const TableBorder(
        horizontalInside: BorderSide(width: 1, color: Color(0xFFEEEEEE)),
        verticalInside: BorderSide(width: 1, color: Color(0xFFEEEEEE)),
      ),
      children: [
        // 헤더 행
        TableRow(
          children: [
            const SizedBox.shrink(), // 빈 셀
            TableCell(
              verticalAlignment: TableCellVerticalAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text('min.', style: headerStyle, textAlign: TextAlign.center),
              ),
            ),
            TableCell(
              verticalAlignment: TableCellVerticalAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text('% TST', style: headerStyle, textAlign: TextAlign.center),
              ),
            ),
          ],
        ),
        // 데이터 행
        ...data.map((item) => _buildDataRow(item, labelStyle, valueStyle)),

          TableRow(
            children: [
              SizedBox(height: 28),
              SizedBox(height: 28),
              SizedBox(height: 28),
            ],
          ),

        ...summaryData.map((item) => _buildDataRow(item, labelStyle, valueStyle, hasTopBorder: true)),
      ],
    );
  }

  // 오른쪽 테이블의 데이터 행을 만드는 헬퍼 함수
  TableRow _buildDataRow(Map<String, String> item, TextStyle labelStyle, TextStyle valueStyle, {bool hasTopBorder = false}) {
    return TableRow(
      decoration: hasTopBorder
          ? const BoxDecoration(
              border: Border(top: BorderSide(width: 1, color: Color(0xFFBDBDBD))),
            )
          : null,
      children: [
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
            child: Text(item['min']!, style: valueStyle, textAlign: TextAlign.center),
          ),
        ),
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text(item['tst']!, style: valueStyle, textAlign: TextAlign.center),
          ),
        ),
      ],
    );
  }
}