import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
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
  /// Ensure to make this as a singleton class.
  AppService._();

  factory AppService() => _instance;

  static AppService get instance => _instance;
  static final AppService _instance = AppService._();

  final Box storageBox = Hive.box('App Service Box');

  /// Global navigator key (connect this to MaterialApp/MaterialApp.router)
  final navigatorKey = GlobalKey<NavigatorState>();

  /// Wrap the printable area with:
  ///   RepaintBoundary(key: AppService.instance.screenKey, child: ...)
  final GlobalKey screenKey = GlobalKey();

  BuildContext get context => navigatorKey.currentContext!;

  final _kCurrentUserKey = 'current_user';

  UserData? currentUser;

  bool get isLoggedIn => currentUser != null;

  // ====== 스케일 & 여백 손잡이 ======
  /// 캡처 시 목표 가로 픽셀(원본 이미지 해상도). 낮출수록 가벼워짐.
  int captureTargetWidthPx = 1200;

  /// PDF 안에서 이미지 배치 비율(0.1 ~ 1.0). 1.0은 콘텐츠 폭/높이에 딱 맞춤(슬라이스 계산에 사용).
  double pdfContentScale = 1.0;

  /// 가로(좌/우) 여백(mm)
  double pdfMarginHorizontalMm = 20;

  /// 세로(상/하) 여백(mm) — 요청대로 기본 0으로 설정 (세로 여백 제거)
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
    if (context.canPop()) {
      context.pop();
    }
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

    // 이미 떠 있으면 메시지만 갱신
    if (_loadingOverlay != null) return;

    _loadingOverlay = OverlayEntry(
      builder: (_) {
        return Stack(
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
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, 8)),
                    ],
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
        );
      },
    );

    // 1) 가장 안전: NavigatorState에서 overlay 직접 확보
    final overlayState = navigatorKey.currentState?.overlay;
    if (overlayState != null) {
      overlayState.insert(_loadingOverlay!);
      return;
    }

    // 2) 폴백: context 기반 탐색
    final ctx = navigatorKey.currentContext;
    final found = Overlay.of(ctx ?? navigatorKey.currentContext!, rootOverlay: true);
    if (found != null) {
      found.insert(_loadingOverlay!);
      return;
    }

    // 3) 최후 폴백: showDialog 사용 (간단한 로더)
    if (ctx != null) {
      showDialog(
        context: ctx,
        barrierDismissible: false,
        builder: (_) => Stack(
          children: const [
            ModalBarrier(color: Colors.black54, dismissible: false),
            Center(child: CircularProgressIndicator()),
          ],
        ),
      );
    }
  }

  void _updateLoadingMessage(String msg) {
    _loadingMessage.value = msg;
  }

  void _hideLoadingOverlay() {
    // OverlayEntry 제거
    _loadingOverlay?.remove();
    _loadingOverlay = null;

    // showDialog 폴백으로 떠 있었을 수도 있으니 닫기 시도
    final ctx = navigatorKey.currentContext;
    if (ctx != null) {
      final root = Navigator.of(ctx, rootNavigator: true);
      if (root.canPop()) {
        root.pop();
      }
    }
  }

  // =================== PDF Generation ===================

  bool _isCapturing = false;

  /// Capture the area wrapped by [screenKey] and generate a multi-page A4 PDF.
  /// Keeps aspect ratio and slices vertically to multiple pages.
  /// Heavy work (image decode + PDF build) runs on a background isolate.
  Future<void> managePdfDistribution() async {
    if (_isCapturing) return;
    _isCapturing = true;

    try {
      _showLoadingOverlay(message: '화면 캡처 준비 중…');

      // 오버레이가 실제로 그려질 시간을 줘서 애니메이션이 보이게 함 (매우 중요!)
      await Future<void>.delayed(const Duration(milliseconds: 16));
      await WidgetsBinding.instance.endOfFrame;

      // 1) Find repaint boundary
      final boundary = screenKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('캡처 대상을 찾지 못했습니다. RepaintBoundary에 screenKey를 연결했는지 확인하세요.');
      }

      // 2) Ensure frame is painted
      if (boundary.debugNeedsPaint) {
        await Future<void>.delayed(const Duration(milliseconds: 16));
        await WidgetsBinding.instance.endOfFrame;
      }

      _updateLoadingMessage('이미지 캡처 중…');

      // 3) Capture with a safe pixel ratio using captureTargetWidthPx
      final size = boundary.size;
      final double pixelRatio = (captureTargetWidthPx / size.width).clamp(1.0, 3.0);
      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('이미지 바이트 변환에 실패했습니다.');
      }
      final Uint8List pngBytes = byteData.buffer.asUint8List();

      _updateLoadingMessage('PDF 페이지 구성 중…');

      // 4) Build PDF bytes in a background isolate (세로 여백 0 적용)
      final pdfBytes = await _buildPdfBytes(
        pngBytes,
        contentScale: pdfContentScale,
        hMarginMm: pdfMarginHorizontalMm,
        vMarginMm: pdfMarginVerticalMm, // 기본 0
      );

      _updateLoadingMessage(kIsWeb ? '파일 공유 준비 중…' : '인쇄 미리보기 여는 중…');

      // 5) Open print/share UI
      if (kIsWeb) {
        await Printing.sharePdf(bytes: pdfBytes, filename: 'report.pdf');
      } else {
        await Printing.layoutPdf(onLayout: (format) async => pdfBytes);
      }
    } catch (e) {
      final ctx = navigatorKey.currentContext;
      if (ctx != null) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('PDF 생성 중 오류가 발생했습니다: $e')),
        );
      }
      debugPrint('PDF 생성 오류: $e');
    } finally {
      _hideLoadingOverlay();
      _isCapturing = false;
    }
  }
}

/// ===== Pretty spinner (independent of Theme) =====
class _Spinner extends StatefulWidget {
  const _Spinner();

  @override
  State<_Spinner> createState() => _SpinnerState();
}

class _SpinnerState extends State<_Spinner> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

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
          painter: _SpinnerPainter(),
        ),
      ),
    );
  }
}

class _SpinnerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final r = s / 2;
    final stroke = r * 0.18;

    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = Colors.grey.shade300;

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = Colors.green;

    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, r - stroke, basePaint);

    final rect = Rect.fromCircle(center: center, radius: r - stroke);
    // 240º짜리 아크
    const sweep = 4.188790205; // 240º in rad
    const start = -1.047197551; // -60º in rad
    canvas.drawArc(rect, start, sweep, false, arcPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// =================== Isolate worker ===================

/// Heavy work: decode PNG, slice to pages, build multipage A4 PDF.
/// Runs in a background isolate via `compute`.
Future<Uint8List> _buildPdfBytes(
  Uint8List pngBytes, {
  required double contentScale, // 0.1~1.0
  required double hMarginMm,
  required double vMarginMm, // ← 세로 여백
}) {
  return compute<_PdfBuildParams, Uint8List>(
    _buildPdfBytesWorker,
    _PdfBuildParams(
      bytes: pngBytes,
      contentScale: contentScale,
      hMarginMm: hMarginMm,
      vMarginMm: vMarginMm,
    ),
  );
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

  // PDF setup
  const PdfPageFormat pageFormat = PdfPageFormat.a4;
  final double hMargin = params.hMarginMm * PdfPageFormat.mm;
  final double vMargin = params.vMarginMm * PdfPageFormat.mm;

  // 콘텐츠 영역(여백 적용 후)
  final double contentWidthPtFull  = pageFormat.width  - hMargin * 2;
  final double contentHeightPtFull = pageFormat.height - vMargin * 2;

  // 배치 스케일 적용(0.1~1.0)
  final double contentWidthPt  = contentWidthPtFull  * params.contentScale;
  final double contentHeightPt = contentHeightPtFull * params.contentScale;

  // Scale based on width, preserve aspect ratio
  final double scale = contentWidthPt / full.width; // pt per px
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
        margin: pw.EdgeInsets.symmetric(horizontal: hMargin, vertical: vMargin), // ← 세로 여백 적용(0 가능)
        build: (context) {
          final pwImage = pw.MemoryImage(sliceBytes);
          return pw.Center(
            child: pw.Image(
              pwImage,
              width: contentWidthPt,      // 폭 기준 배치
              fit: pw.BoxFit.fitWidth,    // 비율 유지
            ),
          );
        },
      ),
    );

    y += h;
  }

  return await pdf.save();
}
