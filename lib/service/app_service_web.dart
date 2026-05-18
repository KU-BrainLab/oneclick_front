import 'dart:async';
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
                    const Text('잠시만 기다려주세요…', style: TextStyle(fontSize: 12, color: Colors.black54)),
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
      _showLoadingOverlay(message: '화면 캡처 준비 중…');

      await Future<void>.delayed(const Duration(milliseconds: 16));
      await WidgetsBinding.instance.endOfFrame;
      await WidgetsBinding.instance.endOfFrame;

      final boundary = await _resolveBoundarySafe(repaintKey);
      debugPrint('[PDF] (web) STEP2 ok (size=${boundary.size})');

      _updateLoadingMessage('이미지 캡처 중…');

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

      _updateLoadingMessage('PDF 페이지 구성 중…');

      final Uint8List pdfBytes = await _buildPdfBytes(
        pngBytes,
        contentScale: pdfContentScale,
        hMarginMm: pdfMarginHorizontalMm,
        vMarginMm: pdfMarginVerticalMm,
      );

      final name = _sanitizeFileName((fileName == null || fileName.trim().isEmpty) ? 'report.pdf' : fileName.trim());
      _updateLoadingMessage('파일 저장 준비 중…');

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
  final img.Image? full = img.decodePng(params.bytes);
  if (full == null) throw Exception('PNG 디코드 실패');

  const PdfPageFormat pageFormat = PdfPageFormat.a4;
  final double hMargin = params.hMarginMm * PdfPageFormat.mm;
  final double vMargin = params.vMarginMm * PdfPageFormat.mm;

  final double contentWidthPt = (pageFormat.width - hMargin * 2) * params.contentScale;
  final double contentHeightPt = (pageFormat.height - vMargin * 2) * params.contentScale;

  final double scale = contentWidthPt / full.width;
  final int idealSliceHeightPx = (contentHeightPt / scale).floor().clamp(1, full.height);
  // 페이지 높이의 40% 범위 안에서 안전한 절단선을 탐색
  final int searchWindow = (idealSliceHeightPx * 0.40).round();

  // 강제 페이지 분리 마커 행 탐색 (Color 0xFFFF0080 = hot-pink)
  final Set<int> markerRows = _findPageBreakMarkers(full).toSet();

  final pdf = pw.Document();

  int y = 0;
  while (y < full.height) {
    final int idealEnd = y + idealSliceHeightPx;

    if (idealEnd >= full.height) {
      final img.Image slice =
          img.copyCrop(full, x: 0, y: y, width: full.width, height: full.height - y);
      // 마지막(짧은) 슬라이스를 페이지 높이로 패딩 → 상단 정렬
      final img.Image padded = _padSliceToPageHeight(slice, idealSliceHeightPx);
      pdf.addPage(_buildPdfPage(
          pageFormat, hMargin, vMargin, contentWidthPt, Uint8List.fromList(img.encodePng(padded))));
      break;
    }

    // 현재 페이지 범위 내 강제 분리 마커 확인
    final int? forcedBreak = markerRows
        .where((r) => r > y && r <= idealEnd + searchWindow)
        .fold<int?>(null, (prev, r) => (prev == null || r < prev) ? r : prev);

    int cutY;
    if (forcedBreak != null) {
      // 마커 행 바로 앞까지 포함 (copyCrop height = forcedBreak-y → rows [y, forcedBreak-1])
      cutY = forcedBreak;
    } else {
      cutY = _findSafeCutRow(full, idealEnd, searchWindow);
    }

    final int h = (cutY - y).clamp(1, full.height - y);
    final img.Image slice = img.copyCrop(full, x: 0, y: y, width: full.width, height: h);
    // 강제 분리로 짧아진 슬라이스를 페이지 높이로 패딩 → 상단 정렬
    final img.Image padded = _padSliceToPageHeight(slice, idealSliceHeightPx);
    pdf.addPage(_buildPdfPage(
        pageFormat, hMargin, vMargin, contentWidthPt, Uint8List.fromList(img.encodePng(padded))));

    // 마커 행 건너뛰고 다음 페이지 시작 (직접 픽셀 확인으로 4행 모두 스킵)
    y += h;
    while (y < full.height && _isPageBreakMarkerRow(full, y)) y++;
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

/// 단일 행이 hot-pink 마커 행인지 직접 확인 (스킵 루프용)
bool _isPageBreakMarkerRow(img.Image image, int y) {
  int hit = 0, total = 0;
  for (int x = 0; x < image.width; x += 4) {
    final p = image.getPixel(x, y);
    if (p.r >= 240 && p.g <= 20 && p.b >= 120) hit++;
    total++;
  }
  return total > 0 && hit * 100 >= total * 50;
}

/// Color(0xFFFF0080) hot-pink 행을 찾아 강제 페이지 분리 위치로 반환.
/// 인접한 연속 마커 행은 첫 행만 반환.
List<int> _findPageBreakMarkers(img.Image image) {
  final List<int> result = [];
  for (int row = 0; row < image.height; row++) {
    int hit = 0, total = 0;
    for (int x = 0; x < image.width; x += 4) {
      final p = image.getPixel(x, row);
      if (p.r >= 240 && p.g <= 20 && p.b >= 120) hit++;
      total++;
    }
    if (total > 0 && hit * 100 >= total * 50) {
      // 직전 마커와 5행 이상 떨어진 경우만 새 마커로 기록
      if (result.isEmpty || row > result.last + 5) result.add(row);
    }
  }
  return result;
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
  final int forwardCap  = (idealY + searchWindow).clamp(0, image.height - 1);
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
