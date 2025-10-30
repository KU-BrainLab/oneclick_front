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
