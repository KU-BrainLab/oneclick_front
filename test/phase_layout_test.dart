// 9-phase 화면 배치 테스트.
//
// 그림 줄(EEG 결과서의 지형도·wPLI·PLV·FAA, 통합·FC 통합 리포트)과 HRV phase
// 탭, RMSSD 범례가 7~9열에서도 줄 폭 안에 들어가는지, 그리고 기존 모드(6열
// 이하)의 폭·라벨·글자 크기가 그대로인지 실제로 그려서 확인한다.
//
// 넘침(RenderFlex overflow)은 글자 폭에 달려 있으므로 테스트 기본 글꼴이 아니라
// 앱 글꼴(DotumBold, assets/fonts/Dotum-Bold.otf)을 읽어 들여 앱과 같은 테마로
// 그린다. 네트워크 그림은 HttpOverrides 로 가짜 1x1 PNG 를 준다 (실제 서버로는
// 요청이 나가지 않는다).
//
// 페이지(page_1·page_2·report_merged·report_merged_fc)는 dart:html 을 쓰는
// 서비스를 import 해서 VM 테스트로 올릴 수 없다. 그래서 페이지가 쓰는 위젯을
// 페이지와 같은 틀(maxWidth 900, 같은 여백) 안에 넣어 그리고, 페이지 파일
// 자체는 소스를 글자로 읽어 phase 목록의 사본이 없는지만 본다.
//
//   flutter test --no-pub test/phase_layout_test.dart

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnifit_front/models/connectivity2_model.dart';
import 'package:omnifit_front/models/connectivity_model.dart';
import 'package:omnifit_front/models/diff_connectivity2_model.dart';
import 'package:omnifit_front/models/diff_connectivity_model.dart';
import 'package:omnifit_front/models/diff_stage_connectivity_model.dart';
import 'package:omnifit_front/models/diff_stage_topography_model.dart';
import 'package:omnifit_front/models/diff_topography_model.dart';
import 'package:omnifit_front/models/faa_model.dart';
import 'package:omnifit_front/models/multi_color_line_chart_model.dart';
import 'package:omnifit_front/models/phase_defs.dart';
import 'package:omnifit_front/models/topography_model.dart';
import 'package:omnifit_front/widget/page1/multi_color_line_chart_widget.dart';
import 'package:omnifit_front/widget/page1/phase_tab_bar_widget.dart';
import 'package:omnifit_front/widget/page2/bsrsr1_chart.dart';
import 'package:omnifit_front/widget/page2/bsrsr2_chart_widget.dart';
import 'package:omnifit_front/widget/page2/bsrsr_chart.dart';
import 'package:omnifit_front/widget/page2/diff_stage_widget.dart';
import 'package:omnifit_front/widget/page2/faa_widget.dart';
import 'package:omnifit_front/widget/phase_columns.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

// ─── 가짜 네트워크 ────────────────────────────────────────────────────

/// 1x1 PNG (불투명 회색 한 점).
const List<int> _png1x1 = [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0xDA, 0x63, 0x38, 0x71, 0xE2, 0xC4,
  0x7F, 0x00, 0x08, 0x0C, 0x03, 0x58, 0xC0, 0xA1, 0xA4, 0xE3, 0x00, 0x00,
  0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
];

/// 모든 요청에 [_png1x1] 을 돌려주는 HttpClient. 요청한 주소를 적어 둔다.
class _FakeHttpOverrides extends HttpOverrides {
  final List<Uri> requested = [];

  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      _FakeHttpClient(requested);
}

class _FakeHttpClient implements HttpClient {
  _FakeHttpClient(this._requested);
  final List<Uri> _requested;

  @override
  bool autoUncompress = true;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    _requested.add(url);
    return _FakeRequest();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeRequest implements HttpClientRequest {
  @override
  final HttpHeaders headers = _FakeHeaders();

  @override
  Future<HttpClientResponse> close() async => _FakeResponse();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHeaders implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeResponse extends Stream<List<int>> implements HttpClientResponse {
  @override
  int get statusCode => HttpStatus.ok;

  @override
  int get contentLength => _png1x1.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) =>
      Stream<List<int>>.value(_png1x1).listen(onData,
          onError: onError, onDone: onDone, cancelOnError: cancelOnError);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ─── 그리기 도우미 ────────────────────────────────────────────────────

/// 화면의 그림(Image.network)이 다 받아질 때까지 기다린다.
Future<void> _settleImages(WidgetTester tester) async {
  await tester.runAsync(() async {
    for (final e in find.byType(Image).evaluate().toList()) {
      await precacheImage((e.widget as Image).image, e);
    }
  });
  await tester.pump();
}

/// 폭 [windowWidth] 의 창에 [body] 를 앱과 같은 테마(글꼴 DotumBold)로 그린다.
/// [textScale] 은 글자 배율이다 (브라우저의 글자 크기 설정이 여기로 들어온다).
Future<void> _pumpPage(
  WidgetTester tester,
  Widget body, {
  double windowWidth = 1280,
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = Size(windowWidth, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(fontFamily: 'DotumBold'),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(child: body),
    ),
  ));
  await _settleImages(tester);
}

/// page_2.dart(EEG 결과서) 본문과 같은 틀: maxWidth 900, 사방 여백 30.
Widget _page2Frame(Widget child) => Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(30),
              child: Column(children: [child]),
            ),
          ],
        ),
      ),
    );

/// report_merged.dart / report_merged_fc.dart 의 캡처 영역과 같은 틀:
/// maxWidth 900, 좌우 여백 40, RepaintBoundary 안의 stretch Column.
Widget _reportFrame(Widget child, {Key? captureKey}) => Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: RepaintBoundary(
                key: captureKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [child],
                ),
              ),
            ),
          ],
        ),
      ),
    );

/// page_1.dart(HRV 결과서) 본문과 같은 틀: maxWidth 900, 좌우 여백 40.
Widget _page1Frame(Widget child) => Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [child],
              ),
            ),
          ],
        ),
      ),
    );

const _bands = ['delta', 'theta', 'alpha', 'sigma', 'beta', 'gamma'];
const _stages = ['wake', 'n1', 'n2', 'n3', 'rem'];

/// [phaseCount]-phase 세션의 EEG 응답 모양 (phase 와 diff 의 그림 경로가 다 있다).
Map<String, dynamic> _eegJson(int phaseCount) => {
      for (final p in phaseSeqFor(phaseCount))
        p.key: {
          for (final b in _bands) ...{
            'topography_$b': '/media/t_${p.key}_$b.png',
            'connectivity_$b': '/media/c_${p.key}_$b.png',
            'connectivity2_$b': '/media/c2_${p.key}_$b.png',
          },
        },
      for (final d in diffSeqFor(phaseCount))
        'diff${d.index + 1}': {
          for (final b in _bands) ...{
            'topography_$b': '/media/dt${d.index + 1}_$b.png',
            'connectivity_$b': '/media/dc${d.index + 1}_$b.png',
            'connectivity2_$b': '/media/dc2${d.index + 1}_$b.png',
            for (final s in _stages) ...{
              'topography_${b}_$s': '/media/dst${d.index + 1}_${b}_$s.png',
              'connectivity_${b}_$s': '/media/dsc${d.index + 1}_${b}_$s.png',
            },
          },
        },
    };

FaaModel _faa(int phaseCount) => FaaModel.fromJson({
      for (final p in phaseSeqFor(phaseCount))
        'faa_${p.key}': '/media/faa_${p.key}.png',
    });

/// EEG 결과서의 그림 줄 위젯 3종 (지형도, wPLI, PLV).
final Map<String, Widget Function(int phaseCount)> _bsrsr = {
  'BsrsrChartWidget(지형도)': (n) {
    final j = _eegJson(n);
    return BsrsrChartWidget(
      topographyList: [for (final b in _bands) TopographyModel.fromJson(j, b)],
      diffTopographyList: [
        for (final b in _bands) DiffTopographyModel.fromJson(j, b)
      ],
      phaseCount: n,
    );
  },
  'Bsrsr1ChartWidget(wPLI)': (n) {
    final j = _eegJson(n);
    return Bsrsr1ChartWidget(
      connectivityList: [
        for (final b in _bands) ConnectivityModel.fromJson(j, b)
      ],
      diffConnectivityList: [
        for (final b in _bands) DiffConnectivityModel.fromJson(j, b)
      ],
      phaseCount: n,
    );
  },
  'Bsrsr2ChartWidget(PLV)': (n) {
    final j = _eegJson(n);
    return Bsrsr2ChartWidget(
      connectivityList: [
        for (final b in _bands) Connectivity2Model.fromJson(j, b)
      ],
      diffConnectivityList: [
        for (final b in _bands) DiffConnectivity2Model.fromJson(j, b)
      ],
      phaseCount: n,
    );
  },
};

/// [inner] 가 좌우로 [outer] 안에 있다.
void _expectWithin(Rect inner, Rect outer, String what) {
  expect(inner.left, greaterThanOrEqualTo(outer.left - 0.01),
      reason: '$what: 왼쪽으로 넘침 ($inner / $outer)');
  expect(inner.right, lessThanOrEqualTo(outer.right + 0.01),
      reason: '$what: 오른쪽으로 넘침 ($inner / $outer)');
}

/// [text] 라벨이 한 줄로 그려졌다 (폭이 모자라 줄바꿈되지 않았다).
/// 줄바꿈된 글자는 상자 높이 밖으로 나가도 오류가 나지 않아 따로 본다.
void _expectOneLine(WidgetTester tester, String text) {
  final paragraph = tester.renderObject<RenderParagraph>(find.text(text));
  expect(paragraph.size.width,
      greaterThanOrEqualTo(paragraph.getMaxIntrinsicWidth(double.infinity) - 0.01),
      reason: '$text 라벨이 줄바꿈됐다');
}

/// 화면 좌표끼리 뺀 값은 부동소수 오차가 있어 정확히 같지 않을 수 있다.
Matcher _px(num v) => closeTo(v, 0.001);

/// [f] 에 걸린 위젯들의 화면 위치 (트리 순서).
List<Rect> _rects(WidgetTester tester, Finder f) => [
      for (final e in f.evaluate())
        () {
          final box = e.renderObject! as RenderBox;
          return box.localToGlobal(Offset.zero) & box.size;
        }(),
    ];

/// 화면에 있는 Bsrsr*ChartWidget 하나.
Finder _bsrsrWidget() => find.byWidgetPredicate(
    (w) => w.runtimeType.toString().startsWith('Bsrsr'));

double? _fontSize(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style?.fontSize;

void main() {
  final http = _FakeHttpOverrides();

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // 그림 요청은 전부 가짜 응답으로 받는다.
    HttpOverrides.global = http;
    // 앱 글꼴. 없으면 테스트 글꼴(글자가 정사각형)이 쓰여 폭이 실제와 달라진다.
    final bytes = File('assets/fonts/Dotum-Bold.otf').readAsBytesSync();
    final loader = FontLoader('DotumBold')
      ..addFont(Future.value(ByteData.view(bytes.buffer)));
    await loader.load();
  });

  tearDownAll(() => HttpOverrides.global = null);

  group('테스트 환경', () {
    testWidgets('앱 글꼴로 그린다 (글자 폭이 테스트 글꼴과 다르다)', (tester) async {
      await _pumpPage(tester, const Center(child: Text('Stimulation1')));
      final size = tester.getSize(find.text('Stimulation1'));
      // 테스트 글꼴이면 12자 x 14px = 168px 다. DotumBold 로는 약 82px.
      expect(size.width, inInclusiveRange(70, 95));
    });

    testWidgets('네트워크 그림은 가짜 PNG 로 받아진다', (tester) async {
      http.requested.clear();
      await _pumpPage(tester, _page2Frame(FaaWidget(model: _faa(3), phaseCount: 3)));
      expect(tester.takeException(), isNull);
      expect(http.requested, hasLength(3));
      // 받아진 그림은 지정한 폭의 정사각형으로 그려진다 (1x1 PNG).
      for (final r in _rects(tester, find.byType(Image))) {
        expect(r.width, _px(180));
        expect(r.height, _px(180));
      }
      for (final raw in tester.widgetList<RawImage>(find.byType(RawImage))) {
        expect(raw.image, isNotNull);
      }
    });
  });

  group('합집합에서 뽑은 목록 (화면마다 손으로 적어 두던 사본)', () {
    // 9-phase 전에 화면들이 하드코딩하던 8키 목록과 라벨.
    const oldKeys = ['baseline', 'stimulation1', 'recovery1', 'stimulation2',
        'recovery2', 'stimulation3', 'stimulation4', 'recovery'];
    // page_1 의 탭 라벨
    const oldSpaced = ['Baseline', 'Stimulation 1', 'Recovery 1',
        'Stimulation 2', 'Recovery 2', 'Stimulation 3', 'Stimulation 4', 'Recovery'];
    // SO-Spindle 표 머리글 (page_2, report_merged, report_merged_fc)
    const oldShort = ['Baseline', 'Stim1', 'Rec1', 'Stim2', 'Rec2',
        'Stim3', 'Stim4', 'Rec'];
    // 통합·FC 통합 리포트의 그림 라벨
    const oldLabel = ['Baseline', 'Stimulation1', 'Recovery1', 'Stimulation2',
        'Recovery2', 'Stimulation3', 'Stimulation4', 'Recovery'];

    final kept = [
      for (final p in kPhaseSuperset)
        if (p.key != 'recovery3' && p.key != 'recovery4') p,
    ];

    test('새 키 둘을 빼면 예전 8키와 순서·문구가 같다', () {
      expect([for (final p in kept) p.key], oldKeys);
      expect([for (final p in kept) p.spaced], oldSpaced);
      expect([for (final p in kept) p.short], oldShort);
      expect([for (final p in kept) p.label], oldLabel);
    });

    test('새 키는 stimulation3·stimulation4 바로 뒤에 온다', () {
      final keys = [for (final p in kPhaseSuperset) p.key];
      expect(keys.indexOf('recovery3'), keys.indexOf('stimulation3') + 1);
      expect(keys.indexOf('recovery4'), keys.indexOf('stimulation4') + 1);
      expect(keys.last, 'recovery');
    });

    test('ReportPhaseImageRow.present: 세션에 있는 phase 만, 시간 순서로', () {
      for (final n in [1, 3, 5, 6, 9, 2, 4, 7, 8]) {
        final topo = TopographyModel.fromJson(_eegJson(n), 'delta');
        final cols = ReportPhaseImageRow.present(topo.byKey);
        expect([for (final c in cols) c.$1.key],
            [for (final p in phaseSeqFor(n)) p.key],
            reason: '$n-phase');
        expect([for (final c in cols) c.$2],
            [for (final p in phaseSeqFor(n)) '/media/t_${p.key}_delta.png'],
            reason: '$n-phase');
      }
    });

    test('ReportPhaseImageRow.present: Baseline 은 그림이 없어도 열을 둔다', () {
      final none = TopographyModel.fromJson(const {}, 'delta');
      final cols = ReportPhaseImageRow.present(none.byKey);
      expect(cols, hasLength(1));
      expect(cols.single.$1.key, 'baseline');
      expect(cols.single.$2, isNull);
    });

    test('ReportPhaseImageRow.present: 가운데 phase 가 비면 그 열만 빠진다', () {
      final j = _eegJson(9)..remove('recovery3');
      final cols =
          ReportPhaseImageRow.present(TopographyModel.fromJson(j, 'delta').byKey);
      expect([for (final c in cols) c.$1.key], [
        'baseline', 'stimulation1', 'recovery1', 'stimulation2', 'recovery2',
        'stimulation3', 'stimulation4', 'recovery4',
      ]);
    });
  });

  group('페이지 소스 점검 (페이지 파일은 테스트로 올릴 수 없어 글자로 본다)', () {
    // phase 목록을 쓰는 화면 코드. 전에는 파일마다 8키 목록을 손으로 적어 두어서,
    // 한 곳만 빠뜨려도 그 화면에서만 새 phase 가 조용히 사라졌다.
    const sources = [
      'lib/page/page_1.dart',
      'lib/page/page_2.dart',
      'lib/page/report_merged.dart',
      'lib/page/report_merged_fc.dart',
      'lib/service/ai_report_pdf_service.dart',
    ];
    // 손으로 적은 phase 목록의 흔적: 키·짧은 표기·띄어 쓴 표기가 나란히 나온다.
    final handWritten = RegExp(
        r"'stimulation3',\s*'stimulation4'|'Stim3',\s*'Stim4'"
        r"|'Stimulation 3',\s*'Stimulation 4'|'Stimulation3'");

    for (final path in sources) {
      test('$path: phase 목록을 kPhaseSuperset 에서 가져온다', () {
        final src = File(path).readAsStringSync();
        expect(src, contains('kPhaseSuperset'));
        expect(handWritten.hasMatch(src), isFalse,
            reason: '손으로 적은 phase 목록이 있다');
      });
    }

    test('page_2.dart: phase 개수 판정을 phase_defs 의 함수로 한다', () {
      final src = File('lib/page/page_2.dart').readAsStringSync();
      expect(src,
          contains('phaseCount = phaseCountFromBoundaries(triggerList.length);'));
      expect(src, contains('phaseCount = phaseCountFromKeys(['));
      // trigger 가 없을 때는 비어 있지 않은 phase 객체만 센다 (예전과 같은 기준).
      expect(src, contains('(valueMap[p.key] as Map).isNotEmpty'));
      // 예전 인라인 판정(6 에서 멈춘다)의 흔적이 없다.
      expect(src, isNot(contains('phaseCount = 6')));
      expect(src, isNot(contains('hasStim3')));
    });

    test('화면마다 쓰는 표기가 그대로다 (탭은 띄어 쓴 표기, 표 머리글은 짧은 표기)', () {
      // 표기를 바꾸면 1/3/5/6-phase 화면의 문구가 달라진다.
      final page1 = File('lib/page/page_1.dart').readAsStringSync();
      expect(page1, contains('availablePhaseLabels.add(p.spaced);'));
      // 탭 줄에는 그 라벨 목록과 지금 고른 탭 번호를 넘긴다.
      expect(
          RegExp(r'PhaseTabBarWidget\(\s*labels: availablePhaseLabels,\s*selected: index,')
              .hasMatch(page1),
          isTrue);
      for (final path in [
        'lib/page/page_2.dart',
        'lib/page/report_merged.dart',
        'lib/page/report_merged_fc.dart',
      ]) {
        final src = File(path).readAsStringSync();
        // SO-Spindle 표: 키와 머리글을 같은 목록에서 뽑는다.
        expect(src,
            contains('final phaseOrder = [for (final p in kPhaseSuperset) p.key];'),
            reason: path);
        expect(src,
            contains('final phaseLabels = [for (final p in kPhaseSuperset) p.short];'),
            reason: path);
      }
    });

    test('리포트의 그림 줄 정렬이 그대로다 (통합 spaceEvenly, FC 통합 spaceBetween)', () {
      final call = RegExp(
          r'ReportPhaseImageRow\(\s*phases: ReportPhaseImageRow\.present\((\w+(?:\.\w+)?)\),'
          r'\s*mainAxisAlignment: MainAxisAlignment\.(\w+),');
      final merged =
          call.allMatches(File('lib/page/report_merged.dart').readAsStringSync());
      expect([for (final m in merged) '${m.group(1)} ${m.group(2)}'],
          ['topo.byKey spaceEvenly']);
      final fc = call
          .allMatches(File('lib/page/report_merged_fc.dart').readAsStringSync());
      expect([for (final m in fc) '${m.group(1)} ${m.group(2)}'],
          ['byKey spaceBetween']);
    });

    test('ai_report_pdf_service.dart: 합집합의 모든 키에 한글 라벨이 있다', () {
      final src =
          File('lib/service/ai_report_pdf_service.dart').readAsStringSync();
      final body = RegExp(r'const _kPhaseLabel = \{(.*?)\};', dotAll: true)
          .firstMatch(src)!
          .group(1)!;
      final labels = {
        for (final m in RegExp(r"'(\w+)': '([^']+)'").allMatches(body))
          m.group(1)!: m.group(2)!,
      };
      expect(labels.keys.toList(), [for (final p in kPhaseSuperset) p.key]);
      // 백엔드 CONNECTIVITY_PHASES 와 같은 문자열이어야 한다 (계약).
      expect(labels['recovery3'], '3차 회복');
      expect(labels['recovery4'], '4차 회복');
      expect(labels['recovery'], '회복');
      expect(labels['baseline'], '기준');
    });

    test('report_merged.dart: SO-Spindle 표 앞의 쪽 나눔 마커는 좁은 배치(7열 이상)일 때만', () {
      // 9-phase 는 그림 줄이 낮아져(9열 84px) 표의 앞부분이 Sleep Stage 와 같은
      // 쪽으로 올라오고, 쪽 경계가 표의 행 한가운데를 가른다. 그래서 표를 새 쪽에서
      // 시작시키는데, 6열 이하는 기존 세션의 쪽 나눔이 그대로여야 하므로 조건부다.
      final src = File('lib/page/report_merged.dart').readAsStringSync();
      const marker = 'Container(height: 4, color: const Color(0xFFFF0080)),';
      expect(
          RegExp(r'if \(_compactPhaseRows\)\s*' +
                  RegExp.escape(marker) +
                  r'\s*// 5\. SO-Spindle Coupling')
              .hasMatch(src),
          isTrue);
      // 조건: 어느 대역이든 그림 줄이 좁은 배치(7열 이상)인 세션.
      expect(
          RegExp(r'bool get _compactPhaseRows => topographyList\.any\(\s*'
                  r'\(t\) => isCompactPhaseRow\(ReportPhaseImageRow\.present\(t\.byKey\)\.length\)\);')
              .hasMatch(src),
          isTrue);
      // 마커는 넷이다: Gamma 앞(i == 4), 이 조건부 마커, 표 뒤, HRV 앞.
      expect(marker.allMatches(src).length, 4);
      expect(
          RegExp(r'if \(i == 4\)\s*' + RegExp.escape(marker)).hasMatch(src), isTrue);
    });

    test('ai_report_pdf_service.dart: 제목+표 묶음 기준은 구간별 표만 9행, 나머지는 8행', () {
      // 기준을 표 전체에 올리면 행 수를 AI 가 정하는 표('안심할 수 있는 부분')가
      // 9~10행일 때 기존 세션의 쪽 나눔이 달라질 수 있다. 구간별 표(행 수 = phase
      // 수)만 9-phase 의 9행까지 묶는다.
      final src =
          File('lib/service/ai_report_pdf_service.dart').readAsStringSync();
      expect(src, contains('{int groupUpTo = 8}'));
      expect(src, contains('if (rowCount <= groupUpTo) return [_group([title, table])];'));
      // 기준을 올려 부르는 곳은 구간별 표 하나뿐이다.
      final raised = RegExp(r'(\w+)\.length,\s*(?://[^\n]*\s*)*groupUpTo: (\w+),')
          .allMatches(src)
          .map((m) => '${m.group(1)} ${m.group(2)}')
          .toList();
      expect(raised, ['hrvRows kMaxPhases']);
      expect('groupUpTo:'.allMatches(src).length, 1);
      expect(kMaxPhases, 9);
      // 묶음 여부를 정하는 표는 네 개다 (밴드 요약, 안심할 수 있는 부분, 구간별, 설문).
      expect('_titledTable('.allMatches(src).length, 5); // 호출 4 + 정의 1
    });
  });

  group('배치 규칙 (phase_columns.dart)', () {
    test('7열부터 좁은 배치다', () {
      expect(kShortLabelColumns, 7);
      for (int n = 0; n <= 6; n++) {
        expect(isCompactPhaseRow(n), isFalse, reason: '$n열');
      }
      for (int n = 7; n <= 9; n++) {
        expect(isCompactPhaseRow(n), isTrue, reason: '$n열');
      }
    });

    test('6열 이하의 폭은 가용 폭과 상관없이 기존 값이다', () {
      for (int n = 1; n <= 6; n++) {
        for (final available in [0.0, 100.0, 798.0, 5000.0, double.infinity]) {
          expect(
              phaseColumnWidth(
                  columns: n, available: available, legacyWidth: 110),
              110,
              reason: '$n열, 가용 폭 $available');
        }
      }
    });

    test('7열 이상의 폭은 가용 폭을 열 수로 나눈 값까지 줄어든다', () {
      // EEG 결과서: 줄 838px - 양끝 여백 40px
      expect(phaseColumnWidth(columns: 7, available: 798, legacyWidth: 110), 110);
      expect(phaseColumnWidth(columns: 8, available: 798, legacyWidth: 110), 99);
      expect(phaseColumnWidth(columns: 9, available: 798, legacyWidth: 110), 88);
      // 통합 리포트: 줄 820px - 양끝 여백 40px, 칸마다 테두리 2px
      expect(
          phaseColumnWidth(
              columns: 9, available: 780, legacyWidth: 120, perColumnExtra: 2),
          84);
      // 넓으면 기존 값을 넘지 않는다.
      expect(phaseColumnWidth(columns: 9, available: 5000, legacyWidth: 110), 110);
    });

    test('6열 이하의 라벨은 긴 표기 Text 그대로다', () {
      for (int n = 1; n <= 6; n++) {
        final w = phaseColumnLabel(kStim1, columns: n, width: 110);
        expect(w, isA<Text>());
        expect((w as Text).data, 'Stimulation1');
        expect(w.style, isNull);
        const given = Text('x');
        expect(identical(fitColumnLabel(given, columns: n, width: 110), given),
            isTrue);
      }
    });

    test('7열 이상의 라벨은 짧은 표기·12px 이고 그림 폭에 갇힌다', () {
      final w = phaseColumnLabel(kStim1, columns: 9, width: 88);
      expect(w, isA<SizedBox>());
      expect((w as SizedBox).width, 88);
      final fitted = w.child! as FittedBox;
      expect(fitted.fit, BoxFit.scaleDown);
      final text = fitted.child! as Text;
      expect(text.data, 'Stim1');
      expect(text.style?.fontSize, 12);
    });
  });

  group('EEG 결과서의 그림 줄 (지형도·wPLI·PLV)', () {
    // 테두리 안쪽 폭 838px (900 - 여백 60 - 테두리 2), 줄 양끝 여백 20px.
    // phase 줄: 열 수 -> 그림 폭
    const phaseWidth = {2: 190.0, 3: 190.0, 4: 190.0, 5: 130.0, 6: 110.0,
        7: 110.0, 8: 99.0, 9: 88.0};
    // diff 줄은 phase 수 - 1 열이다: phase 수 -> 그림 폭
    const diffWidth = {2: 190.0, 3: 190.0, 4: 190.0, 5: 130.0, 6: 110.0,
        7: 110.0, 8: 110.0, 9: 99.0};

    for (final entry in _bsrsr.entries) {
      for (final n in [7, 8, 9]) {
        testWidgets('${entry.key}: $n-phase 가 한 줄에 들어간다', (tester) async {
          await _pumpPage(tester, _page2Frame(entry.value(n)));
          expect(tester.takeException(), isNull);

          final phases = phaseSeqFor(n);
          final diffs = diffSeqFor(n);
          final images = _rects(tester, find.byType(Image));
          expect(images, hasLength(phases.length + diffs.length));
          // 그림이 놓일 수 있는 범위: 위젯(840px)에서 테두리 1px 과 줄 양끝
          // 여백 20px 을 뺀 안쪽.
          final box = tester.getRect(_bsrsrWidget());
          expect(box.width, _px(840));
          final inner = Rect.fromLTRB(
              box.left + 21, box.top, box.right - 21, box.bottom);

          for (int i = 0; i < phases.length; i++) {
            expect(images[i].width, _px(phaseWidth[n]!), reason: 'phase 그림 폭');
            _expectWithin(images[i], inner, '${phases[i].key} 그림');
            // 짧은 표기·12px, 그림 폭 안에 있다. 페이지 폭에서는 라벨이 그림보다
            // 좁아서 줄여 그리지 않는다 (12px 한 줄의 높이 17px 그대로).
            expect(_fontSize(tester, phases[i].short), 12);
            final label = tester.getRect(find.text(phases[i].short));
            _expectWithin(label, images[i], '${phases[i].short} 라벨');
            expect(label.height, _px(17), reason: '${phases[i].short} 라벨');
          }
          // 같은 줄이다 (줄바꿈되지 않았다).
          expect({for (int i = 0; i < phases.length; i++) images[i].top},
              hasLength(1));
          // 긴 표기는 쓰지 않는다.
          expect(find.text('Stimulation1'), findsNothing);

          for (int i = 0; i < diffs.length; i++) {
            final r = images[phases.length + i];
            expect(r.width, _px(diffWidth[n]!), reason: 'diff 그림 폭');
            _expectWithin(r, inner, '${diffs[i].short} 그림');
            expect(_fontSize(tester, diffs[i].short), 12);
          }
          expect({for (int i = 0; i < diffs.length; i++) images[phases.length + i].top},
              hasLength(1));
          // 좁은 배치(7열 이상)의 diff 라벨은 그림 폭 안에 있다.
          if (diffs.length >= kShortLabelColumns) {
            for (int i = 0; i < diffs.length; i++) {
              final label = tester.getRect(find.text(diffs[i].short));
              _expectWithin(
                  label, images[phases.length + i], '${diffs[i].short} 라벨');
              expect(label.height, _px(17), reason: '${diffs[i].short} 라벨');
            }
          }
        });
      }

      testWidgets('${entry.key}: 9-phase 는 창이 좁아도 줄 안에 들어간다', (tester) async {
        // 창 700px -> 페이지 700px -> 줄 638px. 6열용 폭이면 넘친다.
        await _pumpPage(tester, _page2Frame(entry.value(9)), windowWidth: 700);
        expect(tester.takeException(), isNull);
        final box = tester.getRect(_bsrsrWidget());
        expect(box.width, _px(640));
        final inner =
            Rect.fromLTRB(box.left + 21, box.top, box.right - 21, box.bottom);
        final images = _rects(tester, find.byType(Image));
        expect(images, hasLength(17));
        for (int i = 0; i < 9; i++) {
          expect(images[i].width, _px(66)); // (638 - 40) / 9 = 66.4
          _expectWithin(images[i], inner, 'phase ${i + 1}');
        }
        for (int i = 9; i < 17; i++) {
          expect(images[i].width, _px(74)); // (638 - 40) / 8 = 74.75
          _expectWithin(images[i], inner, 'diff ${i - 8}');
        }
      });

      testWidgets('${entry.key}: 9-phase 는 글자가 커져도(배율 1.5) 줄 안에 들어간다', (tester) async {
        // diff 라벨('Stim1-Base', 12px 로 약 68px)은 1.5배면 약 102px 로 그림
        // (99px)보다 넓다. 그림 폭 안에 가두지 않으면 열 폭이 라벨을 따라가
        // 줄이 넘친다.
        await _pumpPage(tester, _page2Frame(entry.value(9)), textScale: 1.5);
        expect(tester.takeException(), isNull);
        final box = tester.getRect(_bsrsrWidget());
        final inner =
            Rect.fromLTRB(box.left + 21, box.top, box.right - 21, box.bottom);
        final phases = phaseSeqFor(9);
        final diffs = diffSeqFor(9);
        final images = _rects(tester, find.byType(Image));
        expect(images, hasLength(17));
        for (int i = 0; i < 9; i++) {
          expect(images[i].width, _px(88));
          _expectWithin(images[i], inner, '${phases[i].key} 그림');
          _expectWithin(tester.getRect(find.text(phases[i].short)), images[i],
              '${phases[i].short} 라벨');
          _expectOneLine(tester, phases[i].short);
        }
        for (int i = 0; i < 8; i++) {
          expect(images[9 + i].width, _px(99));
          _expectWithin(images[9 + i], inner, '${diffs[i].short} 그림');
          _expectWithin(tester.getRect(find.text(diffs[i].short)),
              images[9 + i], '${diffs[i].short} 라벨');
          _expectOneLine(tester, diffs[i].short);
        }
      });

      for (final n in [2, 3, 4, 5, 6]) {
        testWidgets('${entry.key}: $n-phase 는 기존 폭·라벨 그대로다', (tester) async {
          await _pumpPage(tester, _page2Frame(entry.value(n)));
          expect(tester.takeException(), isNull);
          final phases = phaseSeqFor(n);
          final diffs = diffSeqFor(n);
          final images = _rects(tester, find.byType(Image));
          expect(images, hasLength(phases.length + diffs.length));
          for (final r in images) {
            expect(r.width, _px(phaseWidth[n]!));
          }
          // phase 라벨: 긴 표기, 글자 크기를 따로 주지 않는다 (기본 14px).
          for (final p in phases) {
            expect(tester.widget<Text>(find.text(p.label)).style, isNull,
                reason: p.label);
          }
          // diff 라벨: 5열 이상(6-phase)만 짧은 표기·12px, 그 밖은 긴 표기·14px.
          for (final d in diffs) {
            if (diffs.length >= 5) {
              expect(_fontSize(tester, d.short), 12);
            } else {
              expect(_fontSize(tester, d.label), 14);
            }
          }
          // 라벨을 가두는 상자(FittedBox)는 좁은 배치에만 있다.
          expect(find.byType(FittedBox), findsNothing);
        });
      }

      testWidgets('${entry.key}: 6-phase 는 창 800px 에서도 폭 110 그대로다', (tester) async {
        await _pumpPage(tester, _page2Frame(entry.value(6)), windowWidth: 800);
        expect(tester.takeException(), isNull);
        for (final r in _rects(tester, find.byType(Image))) {
          expect(r.width, _px(110));
        }
      });

      testWidgets('${entry.key}: 1-phase 는 6대역 한 줄 보기 그대로다', (tester) async {
        await _pumpPage(tester, _page2Frame(entry.value(1)));
        expect(tester.takeException(), isNull);
        final images = _rects(tester, find.byType(Image));
        expect(images, hasLength(6));
        for (final r in images) {
          expect(r.width, _px(120));
        }
        expect(find.text('Delta'), findsOneWidget);
        expect(find.text('Baseline'), findsNothing);
      });
    }

    testWidgets('그림 경로가 없으면 같은 폭의 No data 칸이 된다 (9-phase)', (tester) async {
      final j = _eegJson(9)
        ..remove('recovery3')
        ..remove('diff6');
      await _pumpPage(
          tester,
          _page2Frame(BsrsrChartWidget(
            topographyList: [
              for (final b in _bands) TopographyModel.fromJson(j, b)
            ],
            diffTopographyList: [
              for (final b in _bands) DiffTopographyModel.fromJson(j, b)
            ],
            phaseCount: 9,
          )));
      expect(tester.takeException(), isNull);
      expect(find.byType(Image), findsNWidgets(15));
      final noData = _rects(tester, find.text('No data'));
      expect(noData, hasLength(2));
      // 열은 그대로 9개·8개다 (빈 칸도 자리를 차지한다).
      expect(find.text('Rec3'), findsOneWidget);
      expect(find.text('Rec3-Stim3'), findsOneWidget);
    });
  });

  group('FaaWidget', () {
    const widthOf = {1: 250.0, 2: 250.0, 3: 180.0, 4: 180.0, 5: 130.0,
        6: 110.0, 7: 110.0, 8: 99.0, 9: 88.0};

    for (final n in [7, 8, 9]) {
      testWidgets('$n-phase 가 한 줄에 들어간다', (tester) async {
        await _pumpPage(tester, _page2Frame(FaaWidget(model: _faa(n), phaseCount: n)));
        expect(tester.takeException(), isNull);
        final box = tester.getRect(find.byType(FaaWidget));
        expect(box.width, _px(840));
        final inner =
            Rect.fromLTRB(box.left + 21, box.top, box.right - 21, box.bottom);
        final phases = phaseSeqFor(n);
        final images = _rects(tester, find.byType(Image));
        expect(images, hasLength(n));
        for (int i = 0; i < n; i++) {
          expect(images[i].width, _px(widthOf[n]!));
          _expectWithin(images[i], inner, '${phases[i].key} 그림');
          expect(_fontSize(tester, phases[i].short), 12);
          _expectWithin(tester.getRect(find.text(phases[i].short)), images[i],
              '${phases[i].short} 라벨');
        }
        expect({for (final r in images) r.top}, hasLength(1));
      });
    }

    testWidgets('9-phase 는 창이 좁아도 줄 안에 들어간다 (라벨도 그림 폭 안)', (tester) async {
      // 창 500px -> 줄 438px -> 그림 44px. 'Baseline'(12px, 약 48px)은 그림보다
      // 넓어서 줄여 그려진다 — 열 폭이 라벨을 따라가면 다시 넘친다.
      await _pumpPage(tester, _page2Frame(FaaWidget(model: _faa(9), phaseCount: 9)),
          windowWidth: 500);
      expect(tester.takeException(), isNull);
      final images = _rects(tester, find.byType(Image));
      final phases = phaseSeqFor(9);
      for (int i = 0; i < 9; i++) {
        expect(images[i].width, _px(44));
        _expectWithin(tester.getRect(find.text(phases[i].short)), images[i],
            '${phases[i].short} 라벨');
      }
    });

    testWidgets('9-phase 는 글자가 커져도(배율 2) 줄 안에 들어간다', (tester) async {
      // 'Baseline'(12px 로 약 48px)은 2배면 약 96px 로 그림(88px)보다 넓다.
      await _pumpPage(tester, _page2Frame(FaaWidget(model: _faa(9), phaseCount: 9)),
          textScale: 2.0);
      expect(tester.takeException(), isNull);
      final images = _rects(tester, find.byType(Image));
      final phases = phaseSeqFor(9);
      for (int i = 0; i < 9; i++) {
        expect(images[i].width, _px(88));
        _expectWithin(tester.getRect(find.text(phases[i].short)), images[i],
            '${phases[i].short} 라벨');
      }
    });

    for (final n in [1, 2, 3, 4, 5, 6]) {
      testWidgets('$n-phase 는 기존 폭·라벨 그대로다', (tester) async {
        await _pumpPage(tester, _page2Frame(FaaWidget(model: _faa(n), phaseCount: n)));
        expect(tester.takeException(), isNull);
        final images = _rects(tester, find.byType(Image));
        expect(images, hasLength(n));
        for (final r in images) {
          expect(r.width, _px(widthOf[n]!));
        }
        for (final p in phaseSeqFor(n)) {
          expect(tester.widget<Text>(find.text(p.label)).style, isNull);
        }
        expect(find.byType(FittedBox), findsNothing);
      });
    }
  });

  group('통합·FC 통합 리포트의 그림 줄 (화면 캡처 = PDF)', () {
    // 캡처 영역 820px (900 - 좌우 여백 80), 줄 양끝 여백 20px, 칸마다 테두리 2px.
    const widthOf = {1: 150.0, 2: 150.0, 3: 150.0, 4: 150.0, 5: 150.0,
        6: 120.0, 7: 109.0, 8: 95.0, 9: 84.0};
    const captureKey = ValueKey('capture');

    List<(PhaseCol, String?)> columns(int n) => ReportPhaseImageRow.present(
        TopographyModel.fromJson(_eegJson(n), 'delta').byKey);

    for (final alignment in [
      MainAxisAlignment.spaceEvenly, // 통합 리포트
      MainAxisAlignment.spaceBetween, // FC 통합 리포트
    ]) {
      for (final n in [7, 8, 9]) {
        testWidgets('$n열이 캡처 영역 안에 다 들어온다 (${alignment.name})', (tester) async {
          await _pumpPage(
              tester,
              _reportFrame(
                ReportPhaseImageRow(
                    phases: columns(n), mainAxisAlignment: alignment),
                captureKey: captureKey,
              ));
          expect(tester.takeException(), isNull);
          final capture = tester.getRect(find.byKey(captureKey));
          expect(capture.width, _px(820));
          final inner = Rect.fromLTRB(capture.left + 20, capture.top,
              capture.right - 20, capture.bottom);
          final phases = phaseSeqFor(n);
          final images = _rects(tester, find.byType(Image));
          expect(images, hasLength(n));
          for (int i = 0; i < n; i++) {
            expect(images[i].width, _px(widthOf[n]!));
            // 테두리 1px 까지 포함한 칸이 안에 있어야 한다.
            _expectWithin(images[i].inflate(1), inner, '${phases[i].key} 칸');
            expect(_fontSize(tester, phases[i].short), 12);
            final label = tester.getRect(find.text(phases[i].short));
            _expectWithin(label, images[i], '${phases[i].short} 라벨');
            expect(label.height, _px(17), reason: '${phases[i].short} 라벨');
          }
          expect({for (final r in images) r.top}, hasLength(1));
          expect(find.text('Stimulation1'), findsNothing);
        });
      }

      for (final n in [1, 3, 5, 6]) {
        testWidgets('$n열은 기존 폭·라벨 그대로다 (${alignment.name})', (tester) async {
          await _pumpPage(
              tester,
              _reportFrame(ReportPhaseImageRow(
                  phases: columns(n), mainAxisAlignment: alignment)));
          expect(tester.takeException(), isNull);
          final images = _rects(tester, find.byType(Image));
          expect(images, hasLength(n));
          for (final r in images) {
            expect(r.width, _px(widthOf[n]!));
          }
          for (final p in phaseSeqFor(n)) {
            expect(tester.widget<Text>(find.text(p.label)).style, isNull);
          }
          expect(find.byType(FittedBox), findsNothing);
        });
      }
    }

    testWidgets('정렬: 통합은 spaceEvenly, FC 통합은 spaceBetween 자리에 놓인다', (tester) async {
      // 3열(칸 152px x 3 + 양끝 여백 40 = 496px)을 820px 줄에 놓으면 남는 324px 를
      // spaceEvenly 는 6곳(54px 씩), spaceBetween 은 4곳(81px 씩)에 나눈다.
      Future<List<Rect>> place(MainAxisAlignment a) async {
        await _pumpPage(
            tester,
            _reportFrame(
              KeyedSubtree(
                key: ValueKey(a),
                child: ReportPhaseImageRow(
                    phases: columns(3), mainAxisAlignment: a),
              ),
              captureKey: captureKey,
            ));
        expect(tester.takeException(), isNull);
        final left = tester.getRect(find.byKey(captureKey)).left;
        return [
          for (final r in _rects(tester, find.byType(Image))) r.shift(Offset(-left, 0))
        ];
      }

      final evenly = await place(MainAxisAlignment.spaceEvenly);
      // 54 + 20 + 54 + 테두리 1 = 129, 그 뒤로 칸 152 + 간격 54 씩
      expect([for (final r in evenly) r.left],
          [_px(129), _px(129 + 206), _px(129 + 412)]);
      final between = await place(MainAxisAlignment.spaceBetween);
      // 20 + 81 + 테두리 1 = 102, 그 뒤로 칸 152 + 간격 81 씩
      expect([for (final r in between) r.left],
          [_px(102), _px(102 + 233), _px(102 + 466)]);
    });

    testWidgets('9-phase 에서 한 phase 가 비면 8열로 계산한다', (tester) async {
      final j = _eegJson(9)..remove('recovery3');
      final cols =
          ReportPhaseImageRow.present(TopographyModel.fromJson(j, 'delta').byKey);
      expect(cols, hasLength(8));
      await _pumpPage(
          tester,
          _reportFrame(
            ReportPhaseImageRow(
                phases: cols, mainAxisAlignment: MainAxisAlignment.spaceEvenly),
            captureKey: captureKey,
          ));
      expect(tester.takeException(), isNull);
      final capture = tester.getRect(find.byKey(captureKey));
      final images = _rects(tester, find.byType(Image));
      expect(images, hasLength(8));
      for (final r in images) {
        expect(r.width, _px(95));
        _expectWithin(r.inflate(1), capture.deflate(20), '칸');
      }
      expect(find.text('Rec3'), findsNothing);
    });

    testWidgets('그림이 없는 칸(No data)도 같은 폭이다', (tester) async {
      final cols = [for (final p in phaseSeqFor(9)) (p, null as String?)];
      await _pumpPage(
          tester,
          _reportFrame(
            ReportPhaseImageRow(
                phases: cols, mainAxisAlignment: MainAxisAlignment.spaceBetween),
            captureKey: captureKey,
          ));
      expect(tester.takeException(), isNull);
      expect(find.byType(Image), findsNothing);
      final capture = tester.getRect(find.byKey(captureKey));
      final boxes = _rects(
          tester,
          find.byWidgetPredicate(
              (w) => w is SizedBox && w.width == 84 && w.height == 84));
      expect(boxes, hasLength(9));
      for (final r in boxes) {
        _expectWithin(r.inflate(1), capture.deflate(20), 'No data 칸');
      }
    });

    testWidgets('9열은 글자가 커져도(배율 2) 캡처 영역 안에 들어온다', (tester) async {
      await _pumpPage(
          tester,
          _reportFrame(
            ReportPhaseImageRow(
                phases: columns(9),
                mainAxisAlignment: MainAxisAlignment.spaceBetween),
            captureKey: captureKey,
          ),
          textScale: 2.0);
      expect(tester.takeException(), isNull);
      final capture = tester.getRect(find.byKey(captureKey));
      final images = _rects(tester, find.byType(Image));
      final phases = phaseSeqFor(9);
      for (int i = 0; i < 9; i++) {
        expect(images[i].width, _px(84));
        _expectWithin(images[i].inflate(1), capture.deflate(20), '칸');
        _expectWithin(tester.getRect(find.text(phases[i].short)), images[i],
            '${phases[i].short} 라벨');
      }
    });

    testWidgets('9열은 창이 좁아도 캡처 영역 안에 들어온다', (tester) async {
      // 창 760px -> 캡처 영역 680px -> 그림 69px ((680 - 40) / 9 - 2 = 69.1).
      await _pumpPage(
          tester,
          _reportFrame(
            ReportPhaseImageRow(
                phases: columns(9),
                mainAxisAlignment: MainAxisAlignment.spaceEvenly),
            captureKey: captureKey,
          ),
          windowWidth: 760);
      expect(tester.takeException(), isNull);
      final capture = tester.getRect(find.byKey(captureKey));
      expect(capture.width, _px(680));
      for (final r in _rects(tester, find.byType(Image))) {
        expect(r.width, _px(69));
        _expectWithin(r.inflate(1), capture.deflate(20), '칸');
      }
    });
  });

  group('HRV phase 탭 (PhaseTabBarWidget)', () {
    Future<List<int>> pumpTabs(WidgetTester tester, List<String> labels,
        {double windowWidth = 1280}) async {
      final taps = <int>[];
      int selected = 0;
      await _pumpPage(
          tester,
          _page1Frame(StatefulBuilder(
            builder: (_, setState) => PhaseTabBarWidget(
              labels: labels,
              selected: selected,
              onSelected: (i) => setState(() {
                selected = i;
                taps.add(i);
              }),
            ),
          )),
          windowWidth: windowWidth);
      return taps;
    }

    List<String> labelsOf(int n) => [for (final p in phaseSeqFor(n)) p.spaced];

    for (final n in [8, 9]) {
      testWidgets('$n개가 줄 폭 안에 모두 보이고 눌린다', (tester) async {
        final labels = labelsOf(n);
        final taps = await pumpTabs(tester, labels);
        expect(tester.takeException(), isNull);
        final bar = tester.getRect(find.byType(PhaseTabBarWidget));
        expect(bar.width, _px(820));
        final tabs = _rects(
            tester,
            find.descendant(
                of: find.byType(PhaseTabBarWidget),
                matching: find.byType(GestureDetector)));
        expect(tabs, hasLength(n));
        for (int i = 0; i < n; i++) {
          expect(tabs[i].width, _px(n == 9 ? 91 : 102)); // 820 / n 의 정수 부분
          expect(tabs[i].height, _px(30));
          _expectWithin(tabs[i], bar, '${labels[i]} 탭');
          // 라벨은 탭 안에 한 줄로 있다 (14px 한 줄의 높이는 20px).
          final label = tester.getRect(find.text(labels[i]));
          _expectWithin(label, tabs[i], '${labels[i]} 라벨');
          // 페이지 폭(820px)에서는 글자를 줄이지 않고 14px 그대로 쓴다.
          expect(label.height, _px(20),
              reason: '${labels[i]} 라벨의 크기가 바뀌었다');
          _expectOneLine(tester, labels[i]);
          expect(label.top, greaterThanOrEqualTo(tabs[i].top));
          expect(label.bottom, lessThanOrEqualTo(tabs[i].bottom));
        }
        // 하나씩 눌러 본다 (탭 가운데, 그리고 양끝 근처).
        for (int i = 0; i < n; i++) {
          await tester.tapAt(tabs[i].center);
          await tester.tapAt(tabs[i].centerLeft + const Offset(2, 0));
          await tester.tapAt(tabs[i].centerRight - const Offset(2, 0));
        }
        await tester.pump();
        expect(taps, [for (int i = 0; i < n; i++) ...[i, i, i]]);
      });
    }

    testWidgets('9개는 창이 좁아도 모두 줄 안에 있다', (tester) async {
      final labels = labelsOf(9);
      final taps = await pumpTabs(tester, labels, windowWidth: 600);
      expect(tester.takeException(), isNull);
      final bar = tester.getRect(find.byType(PhaseTabBarWidget));
      expect(bar.width, _px(520));
      final tabs = _rects(
          tester,
          find.descendant(
              of: find.byType(PhaseTabBarWidget),
              matching: find.byType(GestureDetector)));
      for (int i = 0; i < 9; i++) {
        expect(tabs[i].width, _px(57)); // 520 / 9 = 57.8
        _expectWithin(tabs[i], bar, '${labels[i]} 탭');
        // 'Stimulation 1'(약 86px)은 탭보다 넓어서 줄여 그려진다. 줄바꿈되어
        // 탭 높이 밖으로 나가면 안 된다.
        final label = tester.getRect(find.text(labels[i]));
        _expectWithin(label, tabs[i], '${labels[i]} 라벨');
        expect(label.top, greaterThanOrEqualTo(tabs[i].top),
            reason: '${labels[i]} 라벨이 탭 위로 나갔다');
        expect(label.bottom, lessThanOrEqualTo(tabs[i].bottom),
            reason: '${labels[i]} 라벨이 탭 아래로 나갔다');
        _expectOneLine(tester, labels[i]);
      }
      await tester.tapAt(tabs[8].center);
      expect(taps, [8]);
    });

    testWidgets('9개는 글자가 커져도(배율 1.5) 탭 안에 한 줄로 들어간다', (tester) async {
      final labels = labelsOf(9);
      final taps = <int>[];
      await _pumpPage(
          tester,
          _page1Frame(PhaseTabBarWidget(
              labels: labels, selected: 0, onSelected: taps.add)),
          textScale: 1.5);
      expect(tester.takeException(), isNull);
      final tabs = _rects(
          tester,
          find.descendant(
              of: find.byType(PhaseTabBarWidget),
              matching: find.byType(GestureDetector)));
      for (int i = 0; i < 9; i++) {
        expect(tabs[i].width, _px(91));
        final label = tester.getRect(find.text(labels[i]));
        _expectWithin(label, tabs[i], '${labels[i]} 라벨');
        expect(label.top, greaterThanOrEqualTo(tabs[i].top));
        expect(label.bottom, lessThanOrEqualTo(tabs[i].bottom));
        _expectOneLine(tester, labels[i]);
      }
      await tester.tapAt(tabs[8].center);
      expect(taps, [8]);
    });

    for (final n in [1, 3, 5, 6, 7]) {
      testWidgets('$n개는 예전 그대로다 (폭 110 고정)', (tester) async {
        final labels = labelsOf(n);
        final taps = await pumpTabs(tester, labels);
        expect(tester.takeException(), isNull);
        final bar = tester.getRect(find.byType(PhaseTabBarWidget));
        final tabs = _rects(
            tester,
            find.descendant(
                of: find.byType(PhaseTabBarWidget),
                matching: find.byType(GestureDetector)));
        expect(tabs, hasLength(n));
        for (int i = 0; i < n; i++) {
          expect(
              tabs[i],
              rectMoreOrLessEquals(
                  Rect.fromLTWH(bar.left + 110.0 * i, bar.top, 110, 30),
                  epsilon: 0.001));
        }
        expect(find.byType(FittedBox), findsNothing);
        expect(find.byType(LayoutBuilder), findsNothing);
        await tester.tapAt(tabs.last.center);
        expect(taps, [n - 1]);
      });
    }

    testWidgets('고른 탭만 회색이다', (tester) async {
      await pumpTabs(tester, labelsOf(9));
      Color? colorOf(int i) {
        final c = tester.widget<Container>(find
            .ancestor(
                of: find.text(labelsOf(9)[i]), matching: find.byType(Container))
            .first);
        return (c.decoration as BoxDecoration).color;
      }

      expect(colorOf(0), isNot(Colors.white));
      expect(colorOf(8), Colors.white);
      await tester.tap(find.text('Recovery 4'));
      await tester.pump();
      expect(colorOf(0), Colors.white);
      expect(colorOf(8), isNot(Colors.white));
    });
  });

  group('RMSSD 범례 (MultiColorLineChartWidget)', () {
    MultiColorLineChartModel rmssd(int segments) =>
        MultiColorLineChartModel.fromJson(
          [for (int i = 0; i < 180; i++) 20.0 + (i * 7) % 13],
          finalAxisMaxX: segments * 5.0,
          intervals: [for (int i = 0; i <= segments; i++) i * 5.0],
        );

    Finder overlay() => find.byWidgetPredicate(
        (w) => w is Align && w.alignment == Alignment.topRight);

    for (final n in [1, 3, 5, 6]) {
      testWidgets('$n구간: 범례는 예전처럼 차트 오른쪽 위에 겹친다', (tester) async {
        final model = rmssd(n);
        await _pumpPage(tester,
            _page1Frame(MultiColorLineChartWidget(model: model, maxX: model.maxX)));
        expect(tester.takeException(), isNull);
        expect(overlay(), findsOneWidget);
        expect(find.byType(Wrap), findsNothing);
        final chart = tester.getRect(find.byType(SfCartesianChart));
        // Syncfusion 차트는 높이 제한이 없으면 300 + 바깥 여백 10 x 2 로 그려진다.
        expect(chart.width, _px(820));
        expect(chart.height, _px(320));
        // 위젯 전체가 차트와 같은 크기다 (범례가 자리를 따로 차지하지 않는다).
        expect(tester.getRect(find.byType(MultiColorLineChartWidget)),
            rectMoreOrLessEquals(chart, epsilon: 0.001));
        final box = tester.getRect(find
            .descendant(of: overlay(), matching: find.byType(Container))
            .first);
        expect(box.width, _px(140));
        expect(box.right, _px(chart.right));
        expect(box.top, _px(chart.top));
        for (final p in phaseSeqFor(n)) {
          expect(find.text(p.spaced), findsOneWidget);
        }
      });
    }

    for (final n in [7, 8, 9]) {
      testWidgets('$n구간: 범례를 차트 아래에 둔다 (차트를 가리지 않는다)', (tester) async {
        final model = rmssd(n);
        await _pumpPage(tester,
            _page1Frame(MultiColorLineChartWidget(model: model, maxX: model.maxX)));
        expect(tester.takeException(), isNull);
        expect(overlay(), findsNothing);
        final chart = tester.getRect(find.byType(SfCartesianChart));
        // Syncfusion 차트는 높이 제한이 없으면 300 + 바깥 여백 10 x 2 로 그려진다.
        expect(chart.width, _px(820));
        expect(chart.height, _px(320));
        final whole = tester.getRect(find.byType(MultiColorLineChartWidget));
        final phases = phaseSeqFor(n);
        final tops = <double>{};
        for (int s = 0; s < n; s++) {
          final label = tester.getRect(find.text(phases[s].spaced));
          expect(label.top, greaterThanOrEqualTo(chart.bottom),
              reason: '${phases[s].spaced} 가 차트와 겹친다');
          _expectWithin(label, whole, phases[s].spaced);
          expect(label.bottom, lessThanOrEqualTo(whole.bottom));
          tops.add(label.top);
        }
        // 한 줄에 5개씩: 7~9구간은 두 줄이다.
        expect(tops, hasLength(2));
        // 색 견본은 구간 순서대로 팔레트 색이다.
        final swatches = [
          for (final c in tester.widgetList<Container>(find.descendant(
              of: find.byType(Wrap), matching: find.byType(Container))))
            c.color,
        ];
        expect(swatches, kSegmentColors.sublist(0, n));
      });
    }

    testWidgets('page_1 처럼 가운데 정렬 Column 안에 있어도 폭이 같다 (6·9구간)', (tester) async {
      // page_1.dart 는 이 위젯을 crossAxisAlignment.center 인 Column 에 넣는다
      // (폭 제약이 느슨하다). 통합 리포트는 stretch Column 에 바로 넣는다.
      for (final n in [6, 9]) {
        final model = rmssd(n);
        await _pumpPage(
            tester,
            _page1Frame(Column(
              key: ValueKey(n),
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                MultiColorLineChartWidget(model: model, maxX: model.maxX),
              ],
            )));
        expect(tester.takeException(), isNull);
        final chart = tester.getRect(find.byType(SfCartesianChart));
        expect(chart.width, _px(820), reason: '$n구간');
        expect(chart.height, _px(320), reason: '$n구간');
        final whole = tester.getRect(find.byType(MultiColorLineChartWidget));
        expect(whole.width, _px(820), reason: '$n구간');
        for (final p in phaseSeqFor(n)) {
          _expectWithin(tester.getRect(find.text(p.spaced)), whole, p.spaced);
        }
      }
    });

    testWidgets('9구간: 글자가 커져도(배율 2) 범례가 넘치지 않는다', (tester) async {
      final model = rmssd(9);
      await _pumpPage(tester,
          _page1Frame(MultiColorLineChartWidget(model: model, maxX: model.maxX)),
          textScale: 2.0);
      expect(tester.takeException(), isNull);
      final whole = tester.getRect(find.byType(MultiColorLineChartWidget));
      final chart = tester.getRect(find.byType(SfCartesianChart));
      for (final p in phaseSeqFor(9)) {
        final label = tester.getRect(find.text(p.spaced));
        _expectWithin(label, whole, p.spaced);
        expect(label.top, greaterThanOrEqualTo(chart.bottom));
      }
    });

    testWidgets('9구간: 창이 좁으면 범례 줄이 늘어날 뿐 넘치지 않는다', (tester) async {
      final model = rmssd(9);
      await _pumpPage(tester,
          _page1Frame(MultiColorLineChartWidget(model: model, maxX: model.maxX)),
          windowWidth: 500);
      expect(tester.takeException(), isNull);
      final whole = tester.getRect(find.byType(MultiColorLineChartWidget));
      for (final p in phaseSeqFor(9)) {
        _expectWithin(tester.getRect(find.text(p.spaced)), whole, p.spaced);
      }
    });
  });

  group('DiffStageWidget 의 diff 탭', () {
    DiffStageWidget widgetFor(int n) {
      final j = _eegJson(n);
      return DiffStageWidget(
        diffStageTopoList: [
          for (final b in _bands)
            [for (final s in _stages) DiffStageTopographyModel.fromJson(j, b, s)],
        ],
        diffStageConnList: [
          for (final b in _bands)
            [for (final s in _stages) DiffStageConnectivityModel.fromJson(j, b, s)],
        ],
        phaseCount: n,
      );
    }

    testWidgets('9-phase: 탭 8개가 한 줄에 들어가고 8번째 탭의 그림이 나온다', (tester) async {
      await _pumpPage(tester, _page2Frame(widgetFor(9)));
      expect(tester.takeException(), isNull);
      final box = tester.getRect(find.byType(DiffStageWidget));
      expect(box.width, _px(840));
      final tabs = [
        for (final d in diffSeqFor(9)) tester.getRect(find.text(d.short))
      ];
      expect(tabs, hasLength(8));
      expect({for (final r in tabs) r.top}, hasLength(1));
      for (final r in tabs) {
        _expectWithin(r, box, 'diff 탭');
      }
      // 마지막 탭(diff8 = Rec4-Stim4)을 누르면 그 슬롯의 그림 12장이 나온다.
      await tester.tap(find.text('Rec4-Stim4'));
      await tester.pump();
      await _settleImages(tester);
      expect(tester.takeException(), isNull);
      final urls = [
        for (final im in tester.widgetList<Image>(find.byType(Image)))
          (im.image as NetworkImage).url,
      ];
      expect(urls, hasLength(12));
      expect(urls.every((u) => u.contains('/media/dst8_') || u.contains('/media/dsc8_')),
          isTrue,
          reason: urls.join('\n'));
    });

    testWidgets('5·6-phase: 탭 수와 라벨이 그대로다', (tester) async {
      for (final n in [5, 6]) {
        await _pumpPage(tester, _page2Frame(KeyedSubtree(
            key: ValueKey(n), child: widgetFor(n))));
        expect(tester.takeException(), isNull);
        for (final d in diffSeqFor(n)) {
          expect(find.text(d.short), findsOneWidget);
        }
        expect(find.text('Rec3-Stim3'), findsNothing);
      }
    });
  });
}
