import 'package:flutter/material.dart';

class RespiratoryEventsWidget extends StatelessWidget {
  const RespiratoryEventsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // 공통 스타일 정의
    const headerStyle = TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 12);
    const labelStyle = TextStyle(color: Colors.black87, fontSize: 12);
    const valueStyle = TextStyle(color: Colors.black87, fontSize: 12);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('2. Respiratory Sleep Disturbance Events', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        // 1. 소제목을 사각형 밖으로 이동시켰습니다.
        const Padding(
          padding: EdgeInsets.only(bottom: 8.0), // 위젯 간의 간격을 위해 하단에만 padding 적용
          child: Text('1) NREM and REM sleep에서의 RDI', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 소제목이 있던 자리는 비워둡니다.
              _buildRdiTable(headerStyle, labelStyle, valueStyle),
              _buildO2SaturationRow(labelStyle, valueStyle),
              const Divider(height: 1, thickness: 1, color: Colors.black54),
              _buildDurationTable(labelStyle, valueStyle),
            ],
          ),
        ),
      ],
    );
  }

  /// RDI 테이블 위젯
  Widget _buildRdiTable(TextStyle headerStyle, TextStyle labelStyle, TextStyle valueStyle) {
    // 각 열의 너비 비율을 정의합니다. (flex 값)
    const columnFlex = [15, 10, 10, 10, 10, 12, 11, 11, 11];

    // 데이터 행을 만드는 헬퍼 위젯
    Widget buildDataRow(String title, List<String> values, {bool isHeader = false}) {
      final textStyle = isHeader ? headerStyle : valueStyle;
      final boldIndices = [5, 8]; // Total AHI, RDI 열 인덱스

      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 첫 번째 열 (레이블)
            Expanded(
              flex: columnFlex[0],
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                alignment: Alignment.centerLeft,
                child: Text(title, style: isHeader ? headerStyle : labelStyle),
              ),
            ),
            // 나머지 데이터 열
            for (int i = 0; i < values.length; i++)
              Expanded(
                flex: columnFlex[i + 1],
                child: Container(
                  decoration: BoxDecoration(
                    border: isHeader ? null : Border(left: BorderSide(color: Colors.grey.shade400))
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  alignment: Alignment.center,
                  child: Text(
                    values[i],
                    style: boldIndices.contains(i + 1)
                        ? textStyle.copyWith(fontWeight: FontWeight.bold)
                        : textStyle,
                  ),
                ),
              ),
          ],
        ),
      );
    }
    
    return Column(
      children: [
        // 첫 번째 헤더 행 (열 병합 및 세로선 구현)
        Container(
          decoration: const BoxDecoration(
             border: Border(top: BorderSide(color: Colors.grey), bottom: BorderSide(color: Colors.grey))
          ),
          child: Row(
            children: [
              Spacer(flex: columnFlex[0]),
              Expanded(
                flex: columnFlex[1] + columnFlex[2] + columnFlex[3] + columnFlex[4] + columnFlex[5],
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(
                    'Apnea and Hypopnea Index',
                    textAlign: TextAlign.center,
                    style: headerStyle,
                  ),
                ),
              ),
              Expanded(
                flex: columnFlex[6], 
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border(left: BorderSide(color: Colors.grey))
                  ),
                )
              ),
              Expanded(
                flex: columnFlex[7], 
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border(left: BorderSide(color: Colors.grey))
                  ),
                )
              ),
              Expanded(
                flex: columnFlex[8], 
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border(left: BorderSide(color: Colors.grey))
                  ),
                )
              ),
            ],
          ),
        ),
        // 두 번째 헤더 행
        Container(
          color: Colors.grey.shade100,
          child: buildDataRow(
            '',
            ['OSAI', 'MSAI', 'CSAI', 'HI', 'Total AHI', 'Arousal I.', 'RERA I.', 'RDI'],
            isHeader: true,
          ),
        ),
        const Divider(height: 1, thickness: 1, color: Colors.grey),
        // 2. 모든 데이터 값을 '0.0'으로 변경
        buildDataRow('Total', ['0.0', '0.0', '0.0', '0.0', '0.0', '0.0', '0.0', '0.0']),
        const Divider(height: 1, thickness: 1, color: Colors.grey),
        buildDataRow('REM', ['0.0', '0.0', '0.0', '0.0', '0.0', '0.0', '0.0', '0.0']),
        const Divider(height: 1, thickness: 1, color: Colors.grey),
        buildDataRow('NREM', ['0.0', '0.0', '0.0', '0.0', '0.0', '0.0', '0.0', '0.0']),
      ],
    );
  }

  /// 산소포화도 행 위젯
  Widget _buildO2SaturationRow(TextStyle labelStyle, TextStyle valueStyle) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey))
      ),
      child: Row(
        children: [
          Expanded(
              flex: 3,
              child: Text('Lowest O2 saturation in TIB (%)',
                  style: labelStyle.copyWith(fontWeight: FontWeight.bold))),
          Expanded(
            flex: 1,
            child: Text(
              "0.0", // 2. 데이터 값을 '0.0'으로 변경
              style: valueStyle.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
  
  /// 무호흡/저호흡 지속시간 테이블 위젯
  Widget _buildDurationTable(TextStyle labelStyle, TextStyle valueStyle) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 16.0),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(3),
          1: FlexColumnWidth(1.5),
          2: FlexColumnWidth(2),
          3: FlexColumnWidth(2),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.top,
        children: [
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text('Anpnea and Hypopnea duration (second)', style: labelStyle),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text('Apnea', style: labelStyle),
              ),
              // 2. 데이터 값을 '0.0'으로 변경
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text('Mean:   0.0', style: valueStyle),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text('Longest:   0.0', style: valueStyle),
              ),
            ],
          ),
          TableRow(
            children: [
              const SizedBox.shrink(),
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text('Hypopnea', style: labelStyle),
              ),
              // 2. 데이터 값을 '0.0'으로 변경
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text('Mean:    0.0', style: valueStyle),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text('Longest:    0.0', style: valueStyle),
              ),
            ],
          ),
        ],
      ),
    );
  }
}