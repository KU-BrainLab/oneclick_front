import 'package:flutter/material.dart';
import 'package:omnifit_front/models/phase_defs.dart';

/// HRV 결과서에서 phase 를 고르는 탭 줄.
///
/// 탭은 폭 110 고정이다. 본문 폭 820px(페이지 900 - 좌우 여백 40 x 2)에는
/// 7개(770px)까지 들어가고, 8개부터는 줄 밖으로 넘친다 — 넘친 탭은 보이지도
/// 눌리지도 않는다 (9-phase 는 탭이 9개다). 그래서 8개 이상일 때만 줄의 실제
/// 폭을 탭 수로 나눠 쓴다 (820px 에 9개면 91px). 7개 이하는 예전 그대로다.
class PhaseTabBarWidget extends StatelessWidget {
  /// 탭 라벨 (세션에 있는 phase 만, 시간 순서).
  final List<String> labels;

  /// 지금 고른 탭.
  final int selected;
  final ValueChanged<int> onSelected;

  const PhaseTabBarWidget({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelected,
  });

  /// 탭 하나의 기본 폭.
  static const double _tabWidth = 110;

  /// 기본 폭으로 그리는 탭 수의 상한.
  static const int _fixedWidthTabs = 7;

  @override
  Widget build(BuildContext context) {
    if (labels.length <= _fixedWidthTabs) return _row(_tabWidth, fit: false);
    return LayoutBuilder(
      builder: (_, constraints) => _row(
        phaseImageWidth(
          columns: labels.length,
          available: constraints.maxWidth,
          maxWidth: _tabWidth,
        ),
        fit: true,
      ),
    );
  }

  /// [fit] 이면 라벨을 탭 폭 안에 가둔다 (그보다 넓으면 줄여 그린다).
  Widget _row(double width, {required bool fit}) {
    return Row(
      children: [
        for (int i = 0; i < labels.length; i++)
          MouseRegion(
            cursor: MaterialStateMouseCursor.clickable,
            child: GestureDetector(
              onTap: () => onSelected(i),
              child: Container(
                decoration: BoxDecoration(
                  color: selected == i ? Colors.grey.withOpacity(0.4) : Colors.white,
                  borderRadius: const BorderRadius.all(Radius.circular(4)),
                ),
                width: width,
                height: 30,
                child: Center(
                  child: fit
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(labels[i]),
                          ),
                        )
                      : Text(labels[i]),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
