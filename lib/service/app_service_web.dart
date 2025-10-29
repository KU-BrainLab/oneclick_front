// lib/service/app_service_web.dart
// ✅ Flutter Web 전용 AppService (printing 제거)
//    - RepaintBoundary 탐색 강화
//    - 디버그 전용 속성/문자열화 제거 (debugNeedsPaint 접근/렌더객체 직접 로그 금지)

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

// ignore: avoid_web_libraries_in_flutter
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

  /// MaterialApp(.router) 에 연결
  final navigatorKey = GlobalKey<NavigatorState>();

  /// 캡처 대상 RepaintBoundary에 연결
  final GlobalKey screenKey = GlobalKey();

  BuildContext get context => navigatorKey.currentContext!;

  final _kCurrentUserKey = 'current_user';
  UserData? currentUser;
  bool get isLoggedIn => currentUser != null;

  // ===== 캡처/레이아웃 파라미터 =====
  int captureTargetWidthPx = 1200;
  double pdfContentScale = 1.0;
  double pdfMarginHorizontalMm = 20;
  double pdfMarginVerticalMm = 0;

  void initialize() {
    final user = storageBox.get(_kCurrentUserKey);
    if (user != null) currentUser = user;
  }

  void setUserData(UserData userData) {
    storageBox.put(_kCurrentUserKey, userData);
    currentUser = userData;
    notifyListeners();
  }

  void manageBack() {
    if (context.canPop()) context.pop();
  }

  void manageAutoLogout() {
    terminate();
    context.go(LoginPage.route);
  }

  Future<void> terminate() async {
    currentUser = null;
    storageBox.clear();
  }

  // =================== Loading Overlay ===================

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
    final found = Overlay.of(ctx ?? navigatorKey.currentContext!, rootOverlay: true);
    if (found != null) {
      found.insert(_loadingOverlay!);
      return;
    }

    if (ctx != null) {
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
    if (ctx != null) {
      final root = Navigator.of(ctx, rootNavigator: true);
      if (root.canPop()) {
        root.pop();
      }
    }
  }

  // =================== PDF Generation (WEB) ===================

  bool _isCapturing = false;

  /// 기본 키로 캡처 시작
  Future<void> managePdfDistribution({String? fileName, bool refreshAfter = false}) {
    return managePdfDistributionFromKey(
      repaintKey: screenKey,
      fileName: fileName,
      refreshAfter: refreshAfter,
    );
  }

  /// 원하는 RepaintBoundary 키를 직접 넘겨 캡처
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

      // 프레임 두 번 대기 (페인트 완전 보장)
      await Future<void>.delayed(const Duration(milliseconds: 16));
      await WidgetsBinding.instance.endOfFrame;
      await WidgetsBinding.instance.endOfFrame;

      // STEP2: 안전한 boundary 탐색 (디버그 전용 속성 접근 금지)
      final boundary = await _resolveBoundarySafe(repaintKey);
      debugPrint('[PDF] (web) STEP2 ok (size=${boundary.size})');

      _updateLoadingMessage('이미지 캡처 중…');

      // 프레임 한 번 더 대기 후 캡처 (안정성↑)
      await WidgetsBinding.instance.endOfFrame;

      // STEP3: 이미지 캡처
      final size = boundary.size;
      final double pixelRatio = (captureTargetWidthPx / size.width).clamp(1.0, 2.0); // 최대 2.0 권장
      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (byteData == null) {
        throw StateError('byteData is null');
      }
      final Uint8List pngBytes = byteData.buffer.asUint8List();

      _updateLoadingMessage('PDF 페이지 구성 중…');

      // STEP4: PDF 생성
      final Uint8List pdfBytes = await _buildPdfBytes(
        pngBytes,
        contentScale: pdfContentScale,
        hMarginMm: pdfMarginHorizontalMm,
        vMarginMm: pdfMarginVerticalMm,
      );

      // STEP5: Blob 다운로드
      final name = _sanitizeFileName((fileName == null || fileName.trim().isEmpty) ? 'report.pdf' : fileName.trim());
      _updateLoadingMessage('파일 저장 준비 중…');

      final blob = html.Blob([pdfBytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..download = name
        ..style.display = 'none';
      html.document.body?.append(anchor);
      anchor.click();
      anchor.remove();
      html.Url.revokeObjectUrl(url);
      debugPrint('[PDF] (web) download: $name');

      if (refreshAfter) {
        await Future<void>.delayed(const Duration(milliseconds: 150));
        html.window.location.reload();
      }
    } catch (e, st) {
      debugPrint('[PDF] (web) ERROR: $e\n$st');
      final ctx = navigatorKey.currentContext;
      if (ctx != null) {
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('PDF 생성 중 오류가 발생했습니다: $e')));
      }
    } finally {
      _hideLoadingOverlay();
      _isCapturing = false;
      debugPrint('[PDF] (web) manage END');
    }
  }

  /// 디버그 전용 속성/문자열화를 건드리지 않는 boundary 탐색
  Future<RenderRepaintBoundary> _resolveBoundarySafe(GlobalKey key) async {
    // 1) 키로 직접
    final ctx = key.currentContext;
    if (ctx != null && ctx.mounted) {
      final ro = ctx.findRenderObject();
      // ❗ 렌더 객체 자체를 로그에 찍지 않습니다(toString 이슈 회피)
      if (ro is RenderRepaintBoundary) {
        // 디버그 전용 속성 접근 금지 (debugNeedsPaint 등)
        return ro;
      }
    }

    // 2) 네비게이터 컨텍스트를 시작점으로 전체 트리에서 가까운 Boundary 탐색
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
    // BFS로 하위 탐색
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
    // 상위로도 한 번 타보기
    RenderObject? up = start.parent is RenderObject ? start.parent as RenderObject : null;
    int hop = 0;
    while (up != null && hop < 200) {
      if (up is RenderRepaintBoundary) return up;
      up = up.parent is RenderObject ? up.parent as RenderObject : null;
      hop++;
    }
    return null;
  }

  /// 간단 파일 다운로드 테스트
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

  /// 캡처 없이 PDF 테스트
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

  // ===== 유틸 =====

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

// ---------- PNG → PDF (웹: compute 미사용) ----------
Future<Uint8List> _buildPdfBytes(
  Uint8List pngBytes, {
  required double contentScale, // 0.1~1.0
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
  if (full == null) {
    throw Exception('PNG 디코드 실패');
  }

  const PdfPageFormat pageFormat = PdfPageFormat.a4;
  final double hMargin = params.hMarginMm * PdfPageFormat.mm;
  final double vMargin = params.vMarginMm * PdfPageFormat.mm;

  final double contentWidthPtFull = pageFormat.width - hMargin * 2;
  final double contentHeightPtFull = pageFormat.height - vMargin * 2;

  final double contentWidthPt = contentWidthPtFull * params.contentScale;
  final double contentHeightPt = contentHeightPtFull * params.contentScale;

  final double scale = contentWidthPt / full.width;
  final int sliceHeightPx = (contentHeightPt / scale).floor().clamp(1, full.height);

  final pdf = pw.Document();

  int y = 0;
  while (y < full.height) {
    final int h = (y + sliceHeightPx > full.height) ? (full.height - y) : sliceHeightPx;
    final img.Image slice = img.copyCrop(full, x: 0, y: y, width: full.width, height: h);
    final Uint8List sliceBytes = Uint8List.fromList(img.encodePng(slice));

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: pw.EdgeInsets.symmetric(horizontal: hMargin, vertical: vMargin),
        build: (context) {
          final pwImage = pw.MemoryImage(sliceBytes);
          return pw.Center(
            child: pw.Image(pwImage, width: contentWidthPt, fit: pw.BoxFit.fitWidth),
          );
        },
      ),
    );

    y += h;
  }

  return pdf.save();
}
