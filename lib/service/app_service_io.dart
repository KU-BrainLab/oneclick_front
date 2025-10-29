// lib/service/app_service_io.dart
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show compute, kIsWeb;
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
import 'package:printing/printing.dart';

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

  void manageBack() { if (context.canPop()) context.pop(); }
  void manageAutoLogout() { terminate(); context.go(LoginPage.route); }
  Future<void> terminate() async { currentUser = null; storageBox.clear(); }

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
                        msg, textAlign: TextAlign.center,
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
    if (overlayState != null) { overlayState.insert(_loadingOverlay!); return; }
    final ctx = navigatorKey.currentContext;
    final found = Overlay.of(ctx ?? navigatorKey.currentContext!, rootOverlay: true);
    if (found != null) { found.insert(_loadingOverlay!); return; }
    if (ctx != null) {
      showDialog(
        context: ctx, barrierDismissible: false,
        builder: (_) => const Stack(
          children: [ModalBarrier(color: Colors.black54, dismissible: false), Center(child: CircularProgressIndicator())],
        ),
      );
    }
  }
  void _updateLoadingMessage(String msg) => _loadingMessage.value = msg;
  void _hideLoadingOverlay() {
    _loadingOverlay?.remove(); _loadingOverlay = null;
    final ctx = navigatorKey.currentContext;
    if (ctx != null) {
      final root = Navigator.of(ctx, rootNavigator: true);
      if (root.canPop()) root.pop();
    }
  }

  bool _isCapturing = false;

  Future<void> managePdfDistribution({String? fileName, bool refreshAfter = false}) async {
    if (_isCapturing) return;
    _isCapturing = true;

    try {
      debugPrint('[PDF] (io) manage START | kIsWeb=$kIsWeb');
      _showLoadingOverlay(message: '화면 캡처 준비 중…');
      await Future<void>.delayed(const Duration(milliseconds: 16));
      await WidgetsBinding.instance.endOfFrame;

      final boundary = screenKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        debugPrint('[PDF] (io) ERROR: boundary null');
        throw Exception('캡처 대상을 찾지 못했습니다. RepaintBoundary에 screenKey를 연결했는지 확인하세요.');
      }
      if (boundary.debugNeedsPaint) {
        await Future<void>.delayed(const Duration(milliseconds: 16));
        await WidgetsBinding.instance.endOfFrame;
      }

      _updateLoadingMessage('이미지 캡처 중…');

      final size = boundary.size;
      final double pixelRatio = (captureTargetWidthPx / size.width).clamp(1.0, 3.0);
      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (byteData == null) {
        throw Exception('이미지 바이트 변환에 실패했습니다.');
      }
      final Uint8List pngBytes = byteData.buffer.asUint8List();

      _updateLoadingMessage('PDF 페이지 구성 중…');

      final Uint8List pdfBytes = await _buildPdfBytes(
        pngBytes,
        contentScale: pdfContentScale,
        hMarginMm: pdfMarginHorizontalMm,
        vMarginMm: pdfMarginVerticalMm,
      );

      final name = (fileName == null || fileName.trim().isEmpty) ? 'report.pdf' : fileName.trim();
      _updateLoadingMessage('인쇄 미리보기 여는 중…');

      await Printing.layoutPdf(onLayout: (format) async => pdfBytes, name: name);
      debugPrint('[PDF] (io) layoutPdf finished');
    } catch (e, st) {
      debugPrint('[PDF] (io) ERROR: $e\n$st');
      final ctx = navigatorKey.currentContext;
      if (ctx != null) {
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('PDF 생성 중 오류가 발생했습니다: $e')));
      }
    } finally {
      _hideLoadingOverlay();
      _isCapturing = false;
      debugPrint('[PDF] (io) manage END');
    }
  }
}

class _Spinner extends StatefulWidget { const _Spinner(); @override State<_Spinner> createState() => _SpinnerState(); }
class _SpinnerState extends State<_Spinner> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, __) => Transform.rotate(
      angle: _c.value * 6.283185307,
        child: CustomPaint(
        size: const Size.square(42),
        painter: const _SpinnerPainter(),
      ),
    ),
  );
}
class _SpinnerPainter extends CustomPainter {
  const _SpinnerPainter(); 
  @override void paint(Canvas canvas, Size size) {
    final s = size.shortestSide, r = s / 2, stroke = r * 0.18;
    final base = Paint()..style = PaintingStyle.stroke..strokeWidth = stroke..strokeCap = StrokeCap.round..color = Colors.grey.shade300;
    final arc = Paint()..style = PaintingStyle.stroke..strokeWidth = stroke..strokeCap = StrokeCap.round..color = Colors.green;
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, r - stroke, base);
    final rect = Rect.fromCircle(center: center, radius: r - stroke);
    const sweep = 4.188790205, start = -1.047197551;
    canvas.drawArc(rect, start, sweep, false, arc);
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------- PDF build (IO에서 compute 활용) ----------
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
  try {
    return await compute<_PdfBuildParams, Uint8List>(_buildPdfBytesWorker, params);
  } catch (e) {
    debugPrint('compute() 실패, 동기 경로로 폴백: $e');
    return await _buildPdfBytesWorker(params);
  }
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
          return pw.Center(child: pw.Image(pwImage, width: contentWidthPt, fit: pw.BoxFit.fitWidth));
        },
      ),
    );
    y += h;
  }
  return await pdf.save();
}
