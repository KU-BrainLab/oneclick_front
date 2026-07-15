import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'dart:html' as html;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:image/image.dart' as img;
import 'package:omnifit_front/models/user_data.dart';
import 'package:omnifit_front/page/login_page.dart';
import 'package:omnifit_front/page/users_page.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class AppService extends ChangeNotifier {
  AppService._();
  factory AppService() => _instance;
  static final AppService _instance = AppService._();
  static AppService get instance => _instance;

  final Box storageBox = Hive.box('App Service Box');

  final navigatorKey = GlobalKey<NavigatorState>();

  final GlobalKey screenKey = GlobalKey();

  BuildContext get context => navigatorKey.currentContext!;

  final _kCurrentUserKey = 'current_user';
  UserData? currentUser;
  bool get isLoggedIn => currentUser != null;

  List<double>? intervals;

  int captureTargetWidthPx = 1200;
  double pdfContentScale = 1.0;
  double pdfMarginHorizontalMm = 20;
  double pdfMarginVerticalMm = 12;

  void initialize() {
    final user = storageBox.get(_kCurrentUserKey);
    if (user != null) currentUser = user;
  }

  void setUserData(UserData userData) {
    storageBox.put(_kCurrentUserKey, userData);
    currentUser = userData;
    notifyListeners();
  }

  void setIntervals(List<double> intervals) {
    this.intervals = intervals;
  }

  void manageBack() {
    final ctx = navigatorKey.currentContext;
    if (ctx != null && ctx.canPop()) ctx.pop();
  }

  void manageAutoLogout() {
    terminate();
    final ctx = navigatorKey.currentContext;
    if (ctx != null) ctx.go(LoginPage.route);
  }

  Future<void> terminate() async {
    currentUser = null;
    storageBox.clear();
  }

  OverlayEntry? _loadingOverlay;
  final ValueNotifier<String> _loadingMessage = ValueNotifier<String>('Loading...');

  void _showLoadingOverlay({String message = 'Generate PDF...'}) {
    _loadingMessage.value = message;
    if (_loadingOverlay != null) return;

    _loadingOverlay = OverlayEntry(
      builder: (_) => Stack(
        children: [
          const ModalBarrier(color: Colors.black54, dismissible: false),
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.95, end: 1),
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, 8))],
                ),
                width: 260,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 42, height: 42, child: _Spinner()),
                    const SizedBox(height: 14),
                    ValueListenableBuilder<String>(
                      valueListenable: _loadingMessage,
                      builder: (_, msg, __) => Text(
                        msg,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text('Please wait…', style: TextStyle(fontSize: 12, color: Colors.black54)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    final overlayState = navigatorKey.currentState?.overlay;
    if (overlayState != null) {
      overlayState.insert(_loadingOverlay!);
      return;
    }

    final ctx = navigatorKey.currentContext;
    if (ctx != null && ctx.mounted) {
      try {
        final found = Overlay.of(ctx, rootOverlay: true);
        found.insert(_loadingOverlay!);
        return;
      } catch (_) {}
    }

    if (ctx != null && ctx.mounted) {
      showDialog(
        context: ctx,
        barrierDismissible: false,
        builder: (_) => const Stack(
          children: [
            ModalBarrier(color: Colors.black54, dismissible: false),
            Center(child: CircularProgressIndicator()),
          ],
        ),
      );
    }
  }

  void _updateLoadingMessage(String msg) => _loadingMessage.value = msg;

  void _hideLoadingOverlay() {
    _loadingOverlay?.remove();
    _loadingOverlay = null;

    final ctx = navigatorKey.currentContext;
    if (ctx != null && ctx.mounted) {
      try {
        final root = Navigator.of(ctx, rootNavigator: true);
        if (root.canPop()) {
          root.pop();
        }
      } catch (_) {}
    }
  }


  bool _isCapturing = false;

  Future<void> managePdfDistribution({String? fileName, bool refreshAfter = false}) {
    return managePdfDistributionFromKey(
      repaintKey: screenKey,
      fileName: fileName,
      refreshAfter: refreshAfter,
    );
  }

  Future<void> managePdfDistributionFromKey({
    required GlobalKey repaintKey,
    String? fileName,
    bool refreshAfter = false,
  }) async {
    if (_isCapturing) return;
    _isCapturing = true;

    try {
      debugPrint('[PDF] (web) manage START | kIsWeb=$kIsWeb | key=$repaintKey');
      _showLoadingOverlay(message: 'Preparing capture…');

      await Future<void>.delayed(const Duration(milliseconds: 16));
      await WidgetsBinding.instance.endOfFrame;
      await WidgetsBinding.instance.endOfFrame;

      final boundary = await _resolveBoundarySafe(repaintKey);
      debugPrint('[PDF] (web) STEP2 ok (size=${boundary.size})');

      _updateLoadingMessage('Capturing screen…');

      await WidgetsBinding.instance.endOfFrame;

      final size = boundary.size;
      final double pixelRatio = (captureTargetWidthPx / size.width).clamp(1.0, 2.0);
      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (byteData == null) {
        throw StateError('byteData is null');
      }
      final Uint8List pngBytes = byteData.buffer.asUint8List();

      _updateLoadingMessage('Building PDF pages…');

      final Uint8List pdfBytes = await _buildPdfBytes(
        pngBytes,
        contentScale: pdfContentScale,
        hMarginMm: pdfMarginHorizontalMm,
        vMarginMm: pdfMarginVerticalMm,
      );

      final name = _sanitizeFileName((fileName == null || fileName.trim().isEmpty) ? 'report.pdf' : fileName.trim());
      _updateLoadingMessage('Saving file…');

      final blob = html.Blob([pdfBytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..download = name
        ..style.display = 'none';
      html.document.body?.append(anchor);
      anchor.click();
      // 브라우저가 다운로드를 시작할 때까지 URL 유지 후 정리
      Future.delayed(const Duration(seconds: 10), () {
        anchor.remove();
        html.Url.revokeObjectUrl(url);
      });
      debugPrint('[PDF] (web) download: $name');

      if (refreshAfter) {
        await Future<void>.delayed(const Duration(milliseconds: 150));
        html.window.location.reload();
      }
    } catch (e, st) {
      debugPrint('[PDF] (web) ERROR: $e\n$st');
      final ctx = navigatorKey.currentContext;
      if (ctx != null && ctx.mounted) {
        try {
          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('PDF 생성 중 오류가 발생했습니다: $e')));
        } catch (_) {}
      }
    } finally {
      _hideLoadingOverlay();
      _isCapturing = false;
      debugPrint('[PDF] (web) manage END');
    }
  }

  Future<RenderRepaintBoundary> _resolveBoundarySafe(GlobalKey key) async {
    final ctx = key.currentContext;
    if (ctx != null && ctx.mounted) {
      final ro = ctx.findRenderObject();
      if (ro is RenderRepaintBoundary) {
        return ro;
      }
    }

    final navCtx = navigatorKey.currentContext;
    if (navCtx == null || !navCtx.mounted) {
      throw StateError('navigatorKey.currentContext가 없습니다. MaterialApp.router의 navigatorKey 연결을 확인하세요.');
    }
    final rootRO = navCtx.findRenderObject();
    if (rootRO == null) {
      throw StateError('navigator renderObject를 찾지 못했습니다.');
    }

    final nearest = _searchNearestBoundary(rootRO);
    if (nearest != null) return nearest;

    throw StateError('화면 트리에서 RepaintBoundary를 찾지 못했습니다. 대상 위젯을 RepaintBoundary로 감싸고 key를 연결하세요.');
  }

  RenderRepaintBoundary? _searchNearestBoundary(RenderObject start) {
    final q = <RenderObject>[];
    void enqueueChildren(RenderObject node) {
      node.visitChildren((child) {
        if (child is RenderObject) q.add(child);
      });
    }
    enqueueChildren(start);
    int seen = 0;
    while (q.isNotEmpty && seen < 2000) {
      final cur = q.removeAt(0);
      seen++;
      if (cur is RenderRepaintBoundary) {
        return cur;
      }
      enqueueChildren(cur);
    }
    RenderObject? up = start.parent is RenderObject ? start.parent as RenderObject : null;
    int hop = 0;
    while (up != null && hop < 200) {
      if (up is RenderRepaintBoundary) return up;
      up = up.parent is RenderObject ? up.parent as RenderObject : null;
      hop++;
    }
    return null;
  }

  Future<void> testSimpleDownload() async {
    try {
      final bytes = Uint8List.fromList('hello'.codeUnits);
      final blob = html.Blob([bytes], 'text/plain');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final a = html.AnchorElement(href: url)..download = 'test.txt'..style.display = 'none';
      html.document.body?.append(a);
      a.click();
      a.remove();
      html.Url.revokeObjectUrl(url);
    } catch (_) {}
  }

  Future<void> testPdfWithoutCapture() async {
    try {
      final doc = pw.Document();
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (_) => pw.Center(child: pw.Text('PDF OK')),
        ),
      );
      final bytes = await doc.save();
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final a = html.AnchorElement(href: url)..download = 'test.pdf'..style.display = 'none';
      html.document.body?.append(a);
      a.click();
      a.remove();
      html.Url.revokeObjectUrl(url);
    } catch (_) {}
  }


  static String _sanitizeFileName(String name) {
    const illegal = r'\/:*?"<>|';
    final buf = StringBuffer();
    for (final code in name.runes) {
      final ch = String.fromCharCode(code);
      buf.write(illegal.contains(ch) ? '_' : ch);
    }
    return buf.toString();
  }
}

class _Spinner extends StatefulWidget {
  const _Spinner();
  @override
  State<_Spinner> createState() => _SpinnerState();
}

class _SpinnerState extends State<_Spinner> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Transform.rotate(
        angle: _c.value * 6.283185307, // 2π
        child: CustomPaint(
          size: const Size.square(42),
          painter: const _SpinnerPainter(),
        ),
      ),
    );
  }
}

class _SpinnerPainter extends CustomPainter {
  const _SpinnerPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final r = s / 2;
    final stroke = r * 0.18;

    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = Colors.grey.shade300;

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = Colors.green;

    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, r - stroke, base);

    final rect = Rect.fromCircle(center: center, radius: r - stroke);
    const sweep = 4.188790205; // 240º
    const start = -1.047197551; // -60º
    canvas.drawArc(rect, start, sweep, false, arc);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Future<Uint8List> _buildPdfBytes(
  Uint8List pngBytes, {
  required double contentScale,
  required double hMarginMm,
  required double vMarginMm,
}) async {
  final params = _PdfBuildParams(
    bytes: pngBytes,
    contentScale: contentScale,
    hMarginMm: hMarginMm,
    vMarginMm: vMarginMm,
  );
  return _buildPdfBytesWorker(params);
}

class _PdfBuildParams {
  final Uint8List bytes;
  final double contentScale;
  final double hMarginMm;
  final double vMarginMm;
  const _PdfBuildParams({
    required this.bytes,
    required this.contentScale,
    required this.hMarginMm,
    required this.vMarginMm,
  });
}

Future<Uint8List> _buildPdfBytesWorker(_PdfBuildParams params) async {
  final img.Image? decoded = img.decodePng(params.bytes);
  if (decoded == null) throw Exception('PNG 디코드 실패');

  // 캡처 대상 RepaintBoundary는 Scaffold(backgroundColor: Colors.white)의 "자손"이므로
  // boundary.toImage()가 만드는 이미지의 여백은 흰색이 아니라 투명(0,0,0,0)이다.
  // 아래의 모든 행/픽셀 술어(_isLightRow, _isPureMarkerRow, _isMarkerTintRow)는
  // "흰 배경 위에 합성된 RGB"를 가정하므로, 스캔 전에 반드시 불투명 흰색으로 평탄화한다.
  // (평탄화하지 않으면 _isLightRow가 항상 false → _isBlankRegion 무력화,
  //  _findSafeCutRow가 항상 idealY 반환으로 퇴화한다.)
  final img.Image full = _flattenOnWhite(decoded);

  const PdfPageFormat pageFormat = PdfPageFormat.a4;
  final double hMargin = params.hMarginMm * PdfPageFormat.mm;
  final double vMargin = params.vMarginMm * PdfPageFormat.mm;

  final double contentWidthPt = (pageFormat.width - hMargin * 2) * params.contentScale;
  final double contentHeightPt = (pageFormat.height - vMargin * 2) * params.contentScale;

  final double scale = contentWidthPt / full.width;
  final int idealSliceHeightPx = (contentHeightPt / scale).floor().clamp(1, full.height);
  // 페이지 높이의 40% 범위 안에서 안전한 절단선을 탐색
  final int searchWindow = (idealSliceHeightPx * 0.40).round();

  // 강제 분리 최소 슬라이스 높이. 마커가 페이지 시작점에 너무 가까우면
  // (예: PSQI/ISI 데이터가 없어 Questionnaire 섹션이 ~123px밖에 안 되는 피험자)
  // 그 마커를 채택했을 때 93% 이상이 흰 여백인 페이지가 나온다.
  // 그런 마커는 무시하고 다음 콘텐츠와 합쳐 한 페이지로 만든다.
  // (마커 밴드는 이미 흰색으로 덮여 있으므로 무시해도 핑크선이 노출되지 않는다.)
  final int minForcedSliceHeightPx = (idealSliceHeightPx * 0.25).round();

  // 강제 페이지 분리 마커 밴드 탐색 (Color 0xFFFF0080 = hot-pink)
  // pixelRatio가 비정수라 마커 위/아래에 안티앨리어싱 블렌드 행이 남는다 → 밴드로 확장한다.
  final List<_MarkerBand> bands = _findMarkerBands(full);

  // 슬라이싱 전에 모든 마커 밴드를 흰색으로 덮는다.
  // 행 인덱스는 그대로 유지되므로 밴드 start를 분리점으로 계속 사용할 수 있고,
  // 어떤 경로(마지막 슬라이스 포함)로도 핑크 픽셀이 PDF에 남지 않는다.
  for (final b in bands) {
    img.fillRect(
      full,
      x1: 0,
      y1: b.start,
      x2: full.width - 1,
      y2: b.end,
      color: img.ColorRgb8(255, 255, 255),
    );
  }

  final pdf = pw.Document();

  int y = 0;
  int guard = 0;
  int pageCount = 0;
  const int maxPages = 500;
  final int guardLimit = full.height + 16; // 매 반복 y가 최소 1 전진 → 이론적 상한
  while (y < full.height) {
    if (++guard > guardLimit || pageCount >= maxPages) {
      assert(false,
          'PDF slicer: 루프 가드 발동 (y=$y, height=${full.height}, pages=$pageCount)');
      break;
    }

    // y가 밴드 내부에 있으면(이론상 발생하지 않지만 방어적으로) 밴드를 건너뛴다.
    final _MarkerBand? containing = _bandContaining(bands, y);
    if (containing != null) {
      y = containing.end + 1;
      continue;
    }

    final int idealEnd = math.min(y + idealSliceHeightPx, full.height);

    // (y, idealEnd] 범위의 첫 마커 밴드 = 강제 분리점. idealEnd를 절대 넘기지 않는다.
    // 너무 짧은 조각을 만드는 마커는 건너뛴다.
    final _MarkerBand? forced =
        _firstBandInRange(bands, y, idealEnd, minForcedSliceHeightPx);

    final int cutY;
    final int nextY;
    if (forced != null) {
      cutY = forced.start; // 슬라이스 = [y, start-1] → 마커 밴드 제외
      nextY = forced.end + 1; // 다음 페이지 = 밴드 바로 다음 행
    } else if (idealEnd >= full.height) {
      cutY = full.height;
      nextY = full.height;
    } else {
      // 안전 절단선도 idealEnd 이하로 클램프 (초과분은 어차피 흰 여백이라 무손실)
      cutY = _findSafeCutRow(full, idealEnd, searchWindow).clamp(y + 1, idealEnd);
      nextY = cutY;
    }

    // 불변식: h는 절대 idealSliceHeightPx를 넘지 않는다
    // → _padSliceToPageHeight가 항상 패딩 경로를 타서 fitWidth의 중앙 크롭이 0이 된다.
    final int h = (cutY - y).clamp(1, math.min(idealSliceHeightPx, full.height - y));

    // 빈 페이지 방지: 마커가 바로 앞에 붙어 있거나 뒤쪽이 전부 여백이면 페이지를 만들지 않는다.
    // (단, 최소 1페이지는 항상 생성한다.)
    if (pageCount > 0 && _isBlankRegion(full, y, h)) {
      y = nextY > y ? nextY : y + h;
      continue;
    }

    final img.Image slice = img.copyCrop(full, x: 0, y: y, width: full.width, height: h);
    final img.Image padded = _padSliceToPageHeight(slice, idealSliceHeightPx);
    assert(padded.height == idealSliceHeightPx,
        'PDF slicer: 페이지 높이 불변식 위반 (${padded.height} != $idealSliceHeightPx)');
    pdf.addPage(_buildPdfPage(
        pageFormat, hMargin, vMargin, contentWidthPt, Uint8List.fromList(img.encodePng(padded))));
    pageCount++;

    // y는 매 반복 반드시 전진한다 (h >= 1 보장).
    y = nextY > y ? nextY : y + h;
  }

  return pdf.save();
}

pw.Page _buildPdfPage(
    PdfPageFormat format, double hMargin, double vMargin, double contentWidth, Uint8List bytes) {
  return pw.Page(
    pageFormat: format,
    margin: pw.EdgeInsets.symmetric(horizontal: hMargin, vertical: vMargin),
    build: (ctx) =>
        pw.Center(child: pw.Image(pw.MemoryImage(bytes), width: contentWidth, fit: pw.BoxFit.fitWidth)),
  );
}

/// 알파 채널이 있는 캡처 이미지를 불투명 흰색 캔버스에 합성해 평탄화한다.
/// 이미 불투명(3채널)이면 그대로 반환한다.
img.Image _flattenOnWhite(img.Image src) {
  if (src.numChannels < 4) return src;
  final canvas = img.Image(width: src.width, height: src.height, numChannels: 3);
  img.fill(canvas, color: img.ColorRgb8(255, 255, 255));
  img.compositeImage(canvas, src, dstX: 0, dstY: 0);
  return canvas;
}

/// 강제 페이지 분리 마커 밴드. [start], [end] 모두 끝 포함(inclusive) 행 인덱스.
class _MarkerBand {
  final int start;
  final int end;
  const _MarkerBand(this.start, this.end);
}

/// 밴드 한쪽당 허용하는 최대 틴트 확장 행 수.
/// 마커 4 논리px × pixelRatio(최대 2.0) = 8물리px → 순수행 + 위아래 블렌드 1~2행이므로 4면 충분.
const int _kMaxTintExpandRows = 4;

/// 순수 마커 행: Color(0xFFFF0080) 그대로인 행.
bool _isPureMarkerRow(img.Image image, int y) {
  int hit = 0, total = 0;
  for (int x = 0; x < image.width; x += 4) {
    final p = image.getPixel(x, y);
    if (p.r >= 240 && p.g <= 20 && p.b >= 120) hit++;
    total++;
  }
  return total > 0 && hit * 100 >= total * 50;
}

/// 마커 틴트 행: 흰색 ↔ (255,0,128) 안티앨리어싱 블렌드 행.
///
/// 흰 배경 위 커버리지 c의 블렌드 궤적은 정확히
///   r = 255, g = 255(1-c), b = 255 - 127c
/// 이므로 c > 0인 모든 행이 r=255 && b > g && b < r 를 만족한다.
/// 예전 술어의 `g <= 220`은 c >= 13.7%를 요구해서, 그보다 옅은 블렌드 행
/// (예: c=0.05 → RGB(255,242,249))을 놓쳤고 그 행이 페이지 경계에 옅은
/// 핑크 헤어라인으로 남았다. 그래서 게이트를 흰색 쪽으로 최대한 붙인다.
///
/// 술어: r >= 250 && b > g && b < r && (r-g) >= 2
/// - b > g   : REM 섹션 헤더 0xFFe53935(229,57,53) 배제 (53 > 57 = false).
///             순수 흰색(255,255,255)도 배제한다 (255 > 255 = false).
/// - b < r   : 파랑/청록 계열 배제.
/// - r >= 250: grey.shade300(224), grey.shade50(250,250,250 → b>g에서 탈락),
///             N1/N2/N3 헤더, 알파 합성된 PSQI/ISI PlotBand(r≈197 이하)를 모두 배제.
/// - (r-g)>=2: 핑크 기운이 없는 행 배제. c >= 0.008 부터 통과 → 육안으로 보이는
///             모든 블렌드 행을 잡는다.
///
/// 확장은 순수 밴드에 인접한 경우에만, 한쪽당 최대 [_kMaxTintExpandRows]행까지 허용하므로
/// 설령 어떤 행이 이 술어를 통과해도 마커에 붙어 있지 않으면 영향이 없다.
bool _isMarkerTintRow(img.Image image, int y) {
  int hit = 0, total = 0;
  for (int x = 0; x < image.width; x += 4) {
    final p = image.getPixel(x, y);
    final num r = p.r, g = p.g, b = p.b;
    if (r >= 250 && b > g && b < r && (r - g) >= 2) hit++;
    total++;
  }
  return total > 0 && hit * 100 >= total * 50;
}

/// 순수 마커 행들을 연속 그룹으로 묶고, 각 밴드의 위/아래로 틴트 행인 동안 확장한다.
/// 반환 리스트는 행 오름차순이며 서로 겹치지 않는다.
List<_MarkerBand> _findMarkerBands(img.Image image) {
  final List<_MarkerBand> bands = [];
  int row = 0;
  while (row < image.height) {
    if (!_isPureMarkerRow(image, row)) {
      row++;
      continue;
    }

    // 1) 순수 마커 행 연속 구간 확정
    int end = row;
    while (end + 1 < image.height && _isPureMarkerRow(image, end + 1)) {
      end++;
    }

    // 2) 확정된 순수 밴드 기준으로만 틴트 확장 (한쪽당 최대 4행)
    int bStart = row;
    for (int i = 0; i < _kMaxTintExpandRows; i++) {
      final int cand = bStart - 1;
      if (cand < 0 || !_isMarkerTintRow(image, cand)) break;
      bStart = cand;
    }
    int bEnd = end;
    for (int i = 0; i < _kMaxTintExpandRows; i++) {
      final int cand = bEnd + 1;
      if (cand >= image.height || !_isMarkerTintRow(image, cand)) break;
      bEnd = cand;
    }

    // 3) 직전 밴드와 겹치거나 맞닿으면 병합 (연속 밴드 처리)
    if (bands.isNotEmpty && bStart <= bands.last.end + 1) {
      final prev = bands.removeLast();
      bands.add(_MarkerBand(prev.start, math.max(prev.end, bEnd)));
    } else {
      bands.add(_MarkerBand(bStart, bEnd));
    }

    row = bEnd + 1;
  }
  return bands;
}

/// y를 포함하는 밴드 (없으면 null)
_MarkerBand? _bandContaining(List<_MarkerBand> bands, int y) {
  for (final b in bands) {
    if (y >= b.start && y <= b.end) return b;
  }
  return null;
}

/// (y, idealEnd] 범위에서 시작하면서, 슬라이스 높이가 [minSliceHeight] 이상이 되는
/// 첫 밴드 (없으면 null). bands는 오름차순.
///
/// 조건을 만족하지 못하는 밴드는 건너뛴다 → 해당 마커는 이번 페이지에서 무시되고
/// 슬라이스가 그 위를 가로지른다. 밴드는 이미 흰색으로 덮여 있으므로 안전하다.
_MarkerBand? _firstBandInRange(
    List<_MarkerBand> bands, int y, int idealEnd, int minSliceHeight) {
  for (final b in bands) {
    if (b.start <= y) continue;
    if (b.start > idealEnd) break; // 오름차순 → 이후 밴드도 모두 범위 밖
    if (b.start - y < minSliceHeight) continue; // 거의 빈 페이지 방지
    return b;
  }
  return null;
}

/// [y, y+h) 구간이 전부 여백인지 확인 (빈 페이지 방지용)
bool _isBlankRegion(img.Image image, int y, int h) {
  final int end = math.min(y + h, image.height);
  for (int row = y; row < end; row++) {
    if (!_isLightRow(image, row)) return false;
  }
  return true;
}

/// idealY ± searchWindow 범위에서 연속 밝은 구간(≥ minRun행)을 찾아
/// 그 구간의 【끝 행】에서 절단한다.
///
/// "끝 행에서 절단" = 다음 페이지가 공백 없이 바로 콘텐츠로 시작함.
///
/// 동작 원리:
///   SizedBox(height:300) → 300행 연속 밝은 구간 감지 → 구간 끝(콘텐츠 직전)에서 절단
///   차트 내부 흰 영역   → 174행 미만 → minRun(250) 미달 → 무시 → 차트 내부 절단 안 함
int _findSafeCutRow(img.Image image, int idealY, int searchWindow) {
  final int searchLimit = (idealY - searchWindow).clamp(0, idealY);
  // 전진 스캔은 절대 idealY를 넘지 않는다. 넘어가면 슬라이스가 페이지보다 커져
  // pw.Center + BoxFit.fitWidth가 위/아래를 대칭으로 잘라낸다.
  final int forwardCap = idealY.clamp(0, image.height - 1);
  const int minRun = 250;

  int run = 0;
  for (int row = idealY; row >= searchLimit; row--) {
    if (_isLightRow(image, row)) {
      run++;
      if (run >= minRun) {
        // 여백 구간 발견 → 앞 방향으로 끝까지 스캔
        int endRow = row + minRun - 1;
        while (endRow < forwardCap && _isLightRow(image, endRow + 1)) {
          endRow++;
        }
        // 여백 구간의 마지막 행에서 절단 → 다음 페이지 = 콘텐츠 시작
        return endRow;
      }
    } else {
      run = 0;
    }
  }

  return idealY; // 적합한 여백 없음 → 원래 위치에서 절단
}

/// 슬라이스 이미지를 [targetHeight]까지 하단에 흰색 패딩을 추가해 반환.
/// 이미 충분히 크면 그대로 반환. 이 함수로 짧은 슬라이스도 항상 상단 정렬됨.
img.Image _padSliceToPageHeight(img.Image slice, int targetHeight) {
  if (slice.height >= targetHeight) return slice;
  final padded = img.Image(width: slice.width, height: targetHeight);
  // 흰색으로 초기화
  img.fill(padded, color: img.ColorRgb8(255, 255, 255));
  // 슬라이스를 상단에 복사
  img.compositeImage(padded, slice, dstX: 0, dstY: 0);
  return padded;
}

/// 한 행에서 4픽셀 간격으로 샘플링해 95% 이상이 밝으면(RGB ≥ 230) true
bool _isLightRow(img.Image image, int y, {int sampleStep = 4}) {
  int light = 0, total = 0;
  for (int x = 0; x < image.width; x += sampleStep) {
    final p = image.getPixel(x, y);
    if (p.r >= 230 && p.g >= 230 && p.b >= 230) light++;
    total++;
  }
  return total > 0 && light * 100 >= total * 95;
}
