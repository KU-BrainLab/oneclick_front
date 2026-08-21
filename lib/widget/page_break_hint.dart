import 'package:flutter/material.dart';

/// "여기서 페이지를 나눠도 된다"는 표시.
///
/// PDF 슬라이서(app_service_web.dart)는 캡처한 한 장짜리 긴 이미지를 페이지
/// 높이로 자른다. 자를 위치는 여백을 찾아 정하는데, 차트가 여러 개 이어지면
/// 차트 사이 여백이 너무 좁아 안전한 지점을 못 찾고 차트를 관통해 자른다
/// (설문 7종을 넣자 IRLS 차트가 두 페이지에 걸쳐 잘렸다).
///
/// 그래서 잘라도 되는 지점을 코드가 직접 알려준다.
///
/// 색이 흰색이 아닌 이유: 슬라이서가 픽셀로 찾아야 하기 때문이다.
/// 색이 거의 흰색인 이유: 이 표시가 선택되지 않으면 이미지에 그대로 남는데,
/// 눈에 보이면 리포트에 정체불명의 선이 그어진다. 기존 마커(자홍색 4px)는
/// 선택될 때 잘려나가므로 보이지 않지만, 차트마다 넣는 이 표시는 대부분
/// 선택되지 않은 채 남는다.
const Color kPageBreakHintColor = Color(0xFFFEFFFE);

/// 슬라이서가 인식할 수 있는 최소 두께. 캡처 배율이 1.0~2.0 사이라
/// 3논리px 이면 최소 3물리행이 남아 안티앨리어싱에 다 먹히지 않는다.
const double kPageBreakHintHeight = 3;

/// 차트나 표처럼 잘리면 안 되는 요소 앞에 놓는다.
class PageBreakHint extends StatelessWidget {
  const PageBreakHint({super.key});

  @override
  Widget build(BuildContext context) => Container(
        height: kPageBreakHintHeight,
        color: kPageBreakHintColor,
      );
}
