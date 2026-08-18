import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:omnifit_front/constants/constants.dart';
import 'package:omnifit_front/model/user_model.dart';
import 'package:omnifit_front/service/app_service.dart';

// ─── 컬러 팔레트 ─────────────────────────────────────────────────────
// 차분한 임상 팔레트. 네이비/틸을 포인트로 쓰고, 판정 색은 세 가지만 쓴다.
const _kNavy      = PdfColor.fromInt(0xFF14304A); // 헤더·표지
const _kTeal      = PdfColor.fromInt(0xFF17726B); // 포인트
const _kStrength  = PdfColor.fromInt(0xFF1B7A3E); // 강점 = 초록
const _kWeakness  = PdfColor.fromInt(0xFFB3261E); // 약점 = 빨강
const _kCaution   = PdfColor.fromInt(0xFFB26A00); // 주의 = 주황
const _kStrengthBg = PdfColor.fromInt(0xFFEBF5EE);
const _kWeaknessBg = PdfColor.fromInt(0xFFFBECEA);
const _kCautionBg  = PdfColor.fromInt(0xFFFDF3E5);
const _kTealBg     = PdfColor.fromInt(0xFFEAF3F2);
const _kRowEven   = PdfColor.fromInt(0xFFF5F7F8);
const _kBorder    = PdfColor.fromInt(0xFFD3DCE0);
const _kGrey      = PdfColor.fromInt(0xFF667079);
const _kTextDark  = PdfColor.fromInt(0xFF1B2733);

const _kOrg = '고려대학교';
const _kReportTitle = '뇌·심장 종합 분석 리포트';

/// 대역 표시 이름. 리포트 본문에서는 별명(AI 가 생성)을 쓰고 여기선 식별만 한다.
const _kBandOrder = ['delta', 'theta', 'alpha', 'sigma', 'beta', 'gamma'];
const _kBandLabel = {
  'delta': 'Delta', 'theta': 'Theta', 'alpha': 'Alpha',
  'sigma': 'Sigma', 'beta': 'Beta', 'gamma': 'Gamma',
};
const _kPhaseOrder = ['baseline', 'stimulation1', 'recovery1', 'stimulation2', 'recovery2'];
const _kPhaseLabel = {
  'baseline': '기준', 'stimulation1': '1차 자극', 'recovery1': '1차 회복',
  'stimulation2': '2차 자극', 'recovery2': '2차 회복',
};

class AiReportPdfService {
  AiReportPdfService._();
  static final instance = AiReportPdfService._();

  late pw.Font _regular;
  late pw.Font _bold;
  bool _fontsLoaded = false;

  /// 그림 번호는 문서 전체에서 하나의 흐름으로 매겨진다("그림 N.").
  int _figNo = 0;
  int get _nextFig => ++_figNo;

  Future<void> _loadFonts() async {
    if (_fontsLoaded) return;
    // OTF CFF 폰트는 pdf 패키지와 호환 문제 → Google Fonts Noto Sans KR 사용
    _regular = await PdfGoogleFonts.notoSansKRRegular();
    _bold    = await PdfGoogleFonts.notoSansKRBold();
    _fontsLoaded = true;
  }

  // ─── 공개 메서드 ──────────────────────────────────────────────────
  Future<void> generateAndDownload(
    UserModel user,
    BuildContext context, {
    void Function(String)? onStatus,
  }) async {
    await _loadFonts();

    // 1) 백엔드 호출.
    // 타임아웃은 서버 쪽 한계보다 길어야 한다. 안 그러면 서버가 정상 응답을
    // 만들고 있는 도중에 프론트가 먼저 끊어버려 원인을 알 수 없는 실패가 된다.
    // 서버: AI_REPORT_DEADLINE_SEC=270 < harakiri=300 < http-timeout=320 이므로
    // 여기는 그보다 큰 330초로 잡는다.
    onStatus?.call('분석 중... (1~4분 소요)');
    final url = Uri.parse('${BASE_URL}api/v1/exp/${user.id}/ai-report/');
    final headers = {'Authorization': 'JWT ${AppService.instance.currentUser?.id}'};

    Map<String, dynamic>? data;
    String? postError;
    try {
      final response = await http
          .post(url, headers: headers)
          .timeout(const Duration(seconds: 330));
      if (response.statusCode == 200) {
        data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      } else {
        // 백엔드가 담아 보낸 안내 문구를 그대로 보여준다. 특히 503(일시 과부하)일 때
        // "잠시 후 다시 시도하면 된다"는 걸 사용자가 알아야 한다.
        postError = '서버 오류 ${response.statusCode}';
        try {
          final body = jsonDecode(utf8.decode(response.bodyBytes));
          if (body is Map && body['error'] is String) {
            postError = body['error'] as String;
          }
        } catch (_) {
          // 본문이 JSON 이 아니면 상태코드만 보여준다.
        }
        // 서버가 명확히 거절한 경우다. 폴링해봐야 결과가 생길 리 없다.
        throw Exception(postError);
      }
    } on TimeoutException {
      postError = null; // 아래에서 폴링으로 회수를 시도한다
    } catch (e) {
      // 연결이 끊겼을 수 있다. 서버는 계속 만들고 있을 것이므로 여기서 포기하지
      // 않는다. 다만 위에서 명시적으로 던진 서버 거절은 그대로 올려보낸다.
      if (postError != null) rethrow;
    }

    // 생성에 3분 넘게 걸리는 동안 연결에는 한 바이트도 흐르지 않는다. 중간의
    // 공유기·방화벽이 그런 유휴 세션을 끊어버리면, 서버는 리포트를 다 만들고도
    // 전달만 실패한다. 서버가 결과를 캐시에 남기므로 짧은 GET 으로 회수한다.
    if (data == null) {
      onStatus?.call('연결이 끊겼습니다. 결과를 다시 받아오는 중...');
      data = await _pollForReport(url, headers, onStatus: onStatus);
    }
    if (data == null) {
      throw Exception('리포트를 받아오지 못했습니다. 잠시 후 다시 시도해 주세요.');
    }

    onStatus?.call('리포트 생성 중...');
    final pdfBytes = await _buildPdf(data);

    final patient = data['patient'] as Map<String, dynamic>;
    final name    = patient['name'] ?? 'report';
    final date    = (patient['measurement_date'] ?? '').toString().replaceAll('-', '');
    final fileName = '${name}_뇌심장_종합분석_리포트_$date.pdf';

    final blob   = html.Blob([pdfBytes], 'application/pdf');
    final objUrl = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: objUrl)
      ..download = fileName
      ..style.display = 'none';
    html.document.body?.append(anchor);
    anchor.click();
    Future.delayed(const Duration(seconds: 10), () {
      anchor.remove();
      html.Url.revokeObjectUrl(objUrl);
    });
  }

  /// 서버가 저장해 둔 리포트를 짧은 GET 으로 회수한다.
  ///
  /// POST 는 3분 넘게 유휴 상태로 열려 있어야 해서 중간 장비에 끊기지만, GET 은
  /// 즉시 끝나므로 그럴 일이 없다. 아직 생성 중이면 404 가 오니 잠시 후 다시 묻는다.
  Future<Map<String, dynamic>?> _pollForReport(
    Uri url,
    Map<String, String> headers, {
    void Function(String)? onStatus,
    Duration interval = const Duration(seconds: 5),
    Duration limit = const Duration(minutes: 6),
  }) async {
    final deadline = DateTime.now().add(limit);
    var tries = 0;
    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(interval);
      tries++;
      try {
        final r = await http.get(url, headers: headers)
            .timeout(const Duration(seconds: 20));
        if (r.statusCode == 200) {
          return jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
        }
        // 404 = 아직 생성 중. 그 밖의 상태코드도 다음 차례에 다시 물어본다.
      } catch (_) {
        // 일시적 네트워크 오류는 무시하고 계속 기다린다.
      }
      final left = deadline.difference(DateTime.now()).inSeconds;
      onStatus?.call('결과를 기다리는 중... ($tries회 확인, 남은 시간 $left초)');
    }
    return null;
  }

  // ─── 이미지 로딩 ──────────────────────────────────────────────────
  Future<pw.ImageProvider?> _fetchImage(String? relUrl) async {
    if (relUrl == null || relUrl.isEmpty) return null;
    try {
      final base = BASE_URL.endsWith('/') ? BASE_URL.substring(0, BASE_URL.length - 1) : BASE_URL;
      final resp = await http.get(
        Uri.parse('$base$relUrl'),
        headers: {'Authorization': 'JWT ${AppService.instance.currentUser?.id}'},
      ).timeout(const Duration(seconds: 15));
      // 0바이트 파일이면 유효한 이미지가 아니므로 버린다.
      if (resp.statusCode == 200 && resp.bodyBytes.length > 100) {
        try {
          return pw.MemoryImage(resp.bodyBytes);
        } catch (_) {
          return null; // 디코딩 실패(포맷 오류 등)
        }
      }
    } catch (_) {}
    return null;
  }

  /// URL 다수를 동시에 받아온다.
  ///
  /// 고정 레이아웃이라 그림 수가 60장을 넘는다. 하나씩 순서대로 받으면 그것만으로
  /// 십수 초가 걸린다. 다만 전부 동시에 던지면 서버 워커를 고갈시키므로 묶음으로
  /// 나눠 보낸다.
  Future<Map<String, pw.ImageProvider?>> _fetchMany(Set<String> urls) async {
    const chunk = 8;
    final list = urls.where((u) => u.isNotEmpty).toList();
    final out = <String, pw.ImageProvider?>{};
    for (var i = 0; i < list.length; i += chunk) {
      final slice = list.sublist(i, (i + chunk).clamp(0, list.length));
      final imgs = await Future.wait(slice.map(_fetchImage));
      for (var j = 0; j < slice.length; j++) {
        out[slice[j]] = imgs[j];
      }
    }
    return out;
  }

  /// figures 트리에서 URL 문자열을 모두 긁어모은다.
  void _collectUrls(dynamic node, Set<String> into) {
    if (node is String) {
      if (node.isNotEmpty) into.add(node);
    } else if (node is Map) {
      for (final v in node.values) {
        _collectUrls(v, into);
      }
    } else if (node is List) {
      for (final v in node) {
        _collectUrls(v, into);
      }
    }
  }

  // ─── PDF 빌드 ─────────────────────────────────────────────────────
  Future<Uint8List> _buildPdf(Map<String, dynamic> data) async {
    _figNo = 0;
    final pdf = pw.Document();

    final patient   = data['patient']    as Map<String, dynamic>;
    final hrvPhases = data['hrv_phases'] as List<dynamic>? ?? [];
    final sleep     = data['sleep']      as Map<String, dynamic>? ?? {};
    final eeg       = data['eeg']        as Map<String, dynamic>? ?? {};
    final survey    = data['survey']     as List<dynamic>? ?? [];
    final figures   = data['figures']    as Map<String, dynamic>? ?? {};
    final ai        = data['ai']         as Map<String, dynamic>? ?? {};

    final headline = ai['headline'] as Map<String, dynamic>? ?? {};
    final bands    = ai['bands']    as List<dynamic>? ?? [];
    final domains  = ai['domains']  as List<dynamic>? ?? [];
    final profile  = ai['profile']  as Map<String, dynamic>? ?? {};
    final evidence = ai['evidence'] as Map<String, dynamic>? ?? {};
    final summary  = ai['summary']  as Map<String, dynamic>? ?? {};

    // 그림 일괄 다운로드 (고정 레이아웃이라 필요한 것이 미리 정해져 있다)
    // 고정 레이아웃이 실제로 그리는 것만 받는다. figures 트리를 통째로 훑으면
    // 렌더하지 않는 종류까지 받아 요청 수십 건이 그대로 낭비된다.
    final urls = <String>{};
    for (final k in ['topography', 'connectivity', 'faa', 'spectrogram']) {
      _collectUrls(figures[k], urls);
    }
    for (final h in (data['hrv_images'] as List<dynamic>? ?? [])) {
      final u = (h as Map<String, dynamic>)['heart_rate'];
      if (u is String && u.isNotEmpty) urls.add(u);
    }
    final imgs = await _fetchMany(urls);
    pw.ImageProvider? img(String? u) => u == null ? null : imgs[u];

    final pageTheme = pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.only(top: 42, bottom: 34, left: 38, right: 38),
      theme: pw.ThemeData.withFont(base: _regular, bold: _bold),
    );

    // ── 표지 ────────────────────────────────────────────────────
    pdf.addPage(pw.Page(
      pageTheme: pageTheme,
      build: (ctx) => _coverPage(patient),
    ));

    // ── 본문 ────────────────────────────────────────────────────
    pdf.addPage(pw.MultiPage(
      pageTheme: pageTheme,
      header: (ctx) => ctx.pageNumber == 1
          ? pw.SizedBox()
          : pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 12),
              padding: const pw.EdgeInsets.only(bottom: 5),
              decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: _kBorder, width: 0.7)),
              ),
              child: pw.Text(_kReportTitle, style: _st(8, color: _kGrey)),
            ),
      footer: (ctx) => pw.Container(
        alignment: pw.Alignment.center,
        margin: const pw.EdgeInsets.only(top: 10),
        child: pw.Text('$_kOrg  ·  ${ctx.pageNumber}', style: _st(8, color: _kGrey)),
      ),
      build: (ctx) => [
        ..._headlineSection(headline),
        ..._bandsSection(bands),
        ..._domainsSection(domains),
        ..._profileSection(profile),
        ..._evidenceSection(
          evidence: evidence,
          hrvPhases: hrvPhases,
          hrvImages: data['hrv_images'] as List<dynamic>? ?? [],
          eeg: eeg,
          sleep: sleep,
          survey: survey,
          figures: figures,
          img: img,
        ),
        ..._summarySection(summary),
      ],
    ));

    return pdf.save();
  }

  // ─── 표지 ─────────────────────────────────────────────────────────
  pw.Widget _coverPage(Map<String, dynamic> p) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(_kOrg, style: _st(12, color: _kNavy, bold: true)),
        pw.SizedBox(height: 4),
        pw.Container(height: 2, width: 54, color: _kTeal),
        pw.SizedBox(height: 120),
        pw.Text(_kReportTitle, style: _st(28, color: _kNavy, bold: true)),
        pw.SizedBox(height: 12),
        pw.Text('나의 뇌는 무엇을 잘하고, 무엇이 약할까',
            style: _st(14, color: _kTeal)),
        pw.SizedBox(height: 6),
        pw.Text('— 쉽게 읽는 나의 뇌 건강 리포트 —', style: _st(10, color: _kGrey)),
        pw.SizedBox(height: 56),
        pw.Table(
          border: pw.TableBorder.all(color: _kBorder, width: 0.7),
          columnWidths: {0: const pw.FlexColumnWidth(1), 1: const pw.FlexColumnWidth(2.6)},
          children: [
            _infoRow('이름', '${p['name'] ?? ''}'),
            _infoRow('성별 / 나이', '${p['sex'] ?? ''} / ${p['age'] ?? ''} 세'),
            _infoRow('측정일', '${p['measurement_date'] ?? ''}'),
            _infoRow('검사 종류', '뇌파(EEG) · 심박변이도(HRV) · 수면다원검사'),
          ],
        ),
        pw.SizedBox(height: 40),
        _callout(
          title: '이 리포트는 어떤 문서인가요?',
          body: '이 리포트는 검사에서 측정된 뇌 활동과 심장 신호를 바탕으로, '
              '당신의 뇌가 무엇을 잘하고 무엇이 약한지를 쉬운 말로 정리한 것입니다.\n\n'
              '앞부분에서 핵심 결론(뇌의 강점·약점)을 먼저 보여드리고, 뒷부분에는 그 판단의 '
              '근거가 된 상세 데이터를 그림과 함께 담았습니다. '
              '바쁘시면 앞의 1~3장만 읽으셔도 전체 그림을 파악할 수 있습니다.',
          color: _kTeal,
          bg: _kTealBg,
        ),
        pw.Spacer(),
        pw.Center(child: pw.Text('$_kOrg  ·  1', style: _st(8, color: _kGrey))),
      ],
    );
  }

  pw.TableRow _infoRow(String k, String v) => pw.TableRow(children: [
        pw.Container(
          color: _kRowEven,
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: pw.Text(k, style: _st(9.5, bold: true, color: _kNavy)),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: pw.Text(v, style: _st(9.5)),
        ),
      ]);

  // ─── 한눈에 보는 나의 뇌 ────────────────────────────────────────────
  List<pw.Widget> _headlineSection(Map<String, dynamic> h) {
    final one = h['one_liner']?.toString() ?? '';
    final detail = h['detail']?.toString() ?? '';
    if (one.isEmpty && detail.isEmpty) return [];
    return [
      // 제목 + 한 문장 박스 + 풀이는 리포트의 얼굴이라 절대 갈라지면 안 된다.
      _group([
        _partTitle('한눈에 보는 나의 뇌'),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: pw.BoxDecoration(
            color: _kTealBg,
            border: pw.Border.all(color: _kTeal, width: 1),
          ),
          child: pw.Text('"$one"',
              style: _st(14, bold: true, color: _kNavy, height: 1.5)),
        ),
        if (detail.isNotEmpty) ...[
          pw.SizedBox(height: 10),
          pw.Text(detail, style: _st(9.5, height: 1.6)),
        ],
      ]),
      pw.SizedBox(height: 22),
    ];
  }

  // ─── 1장. 밴드별 ──────────────────────────────────────────────────
  List<pw.Widget> _bandsSection(List<dynamic> bands) {
    if (bands.isEmpty) return [];

    // 각 대역 블록은 그 자체로 쪼개지지 않는 단위다(제목·불릿·강약점이 한 덩어리).
    final blocks = bands
        .map((raw) => _group([
              _bandBlock(raw as Map<String, dynamic>),
              pw.SizedBox(height: 14),
            ]))
        .toList();

    final rows = bands.map((raw) {
      final b = raw as Map<String, dynamic>;
      return [
        _kBandLabel[b['band']] ?? '${b['band']}',
        b['summary_state']?.toString() ?? '',
        b['summary_verdict']?.toString() ?? '',
      ];
    }).toList();

    return [
      // 장 제목과 안내문은 첫 대역 블록까지 붙여서 홀로 남지 않게 한다.
      ..._withHeader([
        _chapterTitle('1', '주파수 밴드별 — 무엇을 잘하고 무엇이 약한가'),
        pw.Text(
          '뇌는 빠르기가 다른 여러 리듬을 동시에 냅니다. 각 리듬이 담당하는 기능이 다르기 '
          '때문에, 리듬별로 보면 이 뇌가 어떤 기능을 잘 쓰고 어떤 기능이 약한지가 드러납니다.',
          style: _st(9.5, height: 1.6),
        ),
        pw.SizedBox(height: 14),
      ], blocks),
      ..._titledTable(
        _subTitle('밴드별 요약'),
        _zebraTable(
          headers: ['밴드', '이 뇌의 상태', '강점 / 약점'],
          rows: rows,
          widths: {0: 1.0, 1: 2.2, 2: 2.8},
          verdictColumn: 2,
        ),
        rows.length,
      ),
      pw.SizedBox(height: 22),
    ];
  }

  pw.Widget _bandBlock(Map<String, dynamic> b) {
    final label = _kBandLabel[b['band']] ?? '${b['band']}';
    final nickname = b['nickname']?.toString() ?? '';
    final verdict = b['verdict']?.toString() ?? '';
    final bullets = (b['bullets'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
    final strength = b['strength']?.toString() ?? '';
    final weakness = b['weakness']?.toString() ?? '';
    final meaning = b['meaning']?.toString() ?? '';

    return pw.Container(
      padding: const pw.EdgeInsets.only(left: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(left: pw.BorderSide(color: _kTeal, width: 3)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
            pw.Text(nickname.isEmpty ? label : '$label ($nickname)',
                style: _st(11.5, bold: true, color: _kNavy)),
            if (verdict.isNotEmpty) ...[
              pw.SizedBox(width: 8),
              _chip(verdict),
            ],
          ]),
          pw.SizedBox(height: 7),
          ...bullets.map((t) => _bullet(t)),
          pw.SizedBox(height: 7),
          if (strength.isNotEmpty)
            _miniCallout('강점', strength, _kStrength, _kStrengthBg),
          if (weakness.isNotEmpty) ...[
            pw.SizedBox(height: 5),
            _miniCallout('약점', weakness, _kWeakness, _kWeaknessBg),
          ],
          if (meaning.isNotEmpty) ...[
            pw.SizedBox(height: 5),
            _miniCallout('의미', meaning, _kCaution, _kCautionBg),
          ],
        ],
      ),
    );
  }

  // ─── 2장. 기능 영역별 ─────────────────────────────────────────────
  List<pw.Widget> _domainsSection(List<dynamic> domains) {
    if (domains.isEmpty) return [];

    final blocks = domains.map((raw) {
      final d = raw as Map<String, dynamic>;
      final bullets = (d['bullets'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
      final note = d['note']?.toString() ?? '';
      final verdict = d['verdict']?.toString() ?? '';
      return _group([
        pw.Container(
          padding: const pw.EdgeInsets.only(left: 12),
          decoration: pw.BoxDecoration(
            border: pw.Border(left: pw.BorderSide(color: _verdictColor(verdict), width: 3)),
          ),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Row(children: [
              pw.Text('${d['name'] ?? ''}', style: _st(11.5, bold: true, color: _kNavy)),
              if (verdict.isNotEmpty) ...[pw.SizedBox(width: 8), _chip(verdict)],
            ]),
            pw.SizedBox(height: 7),
            ...bullets.map((t) => _bullet(t)),
            if (note.isNotEmpty) ...[
              pw.SizedBox(height: 6),
              pw.Text(note, style: _st(9.5, height: 1.6, italic: true, color: _kTeal)),
            ],
          ]),
        ),
        pw.SizedBox(height: 14),
      ]);
    }).toList();

    return [
      ..._withHeader([
        _chapterTitle('2', '기능 영역별 — 종합 능력 평가'),
        pw.Text('개별 리듬을 넘어, 뇌를 큰 기능 단위로 묶어서 보겠습니다.',
            style: _st(9.5, height: 1.6)),
        pw.SizedBox(height: 14),
      ], blocks),
      pw.SizedBox(height: 8),
    ];
  }

  // ─── 3장. 성향 ────────────────────────────────────────────────────
  List<pw.Widget> _profileSection(Map<String, dynamic> p) {
    if (p.isEmpty) return [];
    final traits = (p['traits'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
    final watch = p['watch'] as List<dynamic>? ?? [];
    final reassuring = p['reassuring'] as List<dynamic>? ?? [];
    final approach = (p['approach'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();

    final reassureRows = reassuring.map((raw) {
      final r = raw as Map<String, dynamic>;
      return [r['title']?.toString() ?? '', r['note']?.toString() ?? ''];
    }).toList();

    return [
      // 장 제목 + 주의 문구 + 성향 박스 + 근거는 하나의 결론 단위다.
      _group([
        _chapterTitle('3', '어떤 성향의 뇌이고, 무엇을 눈여겨볼까'),
        pw.Text(
          '아래 내용은 진단이 아니라, 이번 데이터에서 읽히는 경향과 참고점입니다. '
          '실제 판단은 여러 차례의 검사와 전문의의 종합 소견이 필요합니다.',
          style: _st(9, height: 1.6, color: _kGrey),
        ),
        pw.SizedBox(height: 14),
        _subTitle('이 뇌의 성향'),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: const pw.BoxDecoration(color: _kNavy),
          child: pw.Text('"${p['type_label'] ?? ''}"',
              style: _st(13, bold: true, color: PdfColors.white, height: 1.4)),
        ),
        if ((p['rationale']?.toString() ?? '').isNotEmpty) ...[
          pw.SizedBox(height: 10),
          pw.Text(p['rationale'].toString(), style: _st(9.5, height: 1.6)),
        ],
      ]),
      if (traits.isNotEmpty)
        _group([
          pw.SizedBox(height: 12),
          pw.Text('이런 뇌는 흔히 다음과 같은 성향과 연결됩니다:',
              style: _st(9.5, bold: true, color: _kNavy)),
          pw.SizedBox(height: 5),
          ...traits.map((t) => _bullet(t)),
        ]),
      if (watch.isNotEmpty)
        ..._withHeader([
          pw.SizedBox(height: 16),
          _subTitle('눈여겨볼 만한 방향 (가능성 수준)'),
          pw.Text('데이터 패턴이 겹치는 영역입니다. 어느 것도 확정이 아닙니다.',
              style: _st(9, color: _kGrey)),
          pw.SizedBox(height: 8),
        ], watch.map((raw) {
          final w = raw as Map<String, dynamic>;
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 7),
            child: _miniCallout(
              '${w['title'] ?? ''} — ${w['level'] ?? ''}',
              w['evidence']?.toString() ?? '',
              _kCaution,
              _kCautionBg,
            ),
          );
        }).toList()),
      if (reassuring.isNotEmpty)
        ..._titledTable(
          _group([
            pw.SizedBox(height: 12),
            _subTitle('반대로, 안심할 수 있는 부분'),
            pw.Text('데이터상 시사되지 않는 것들입니다.', style: _st(9, color: _kGrey)),
            pw.SizedBox(height: 8),
          ]),
          _zebraTable(
            headers: ['항목', '근거'],
            rows: reassureRows,
            widths: {0: 1.2, 1: 3.0},
            headerColor: _kStrength,
          ),
          reassureRows.length,
        ),
      if (approach.isNotEmpty)
        _group([
          pw.SizedBox(height: 16),
          _subTitle('이 뇌에 맞을 법한 접근 (참고)'),
          ...approach.map((t) => _bullet(t)),
        ]),
      if ((p['one_sentence']?.toString() ?? '').isNotEmpty)
        _group([
          pw.SizedBox(height: 14),
          _callout(title: '한 문장 결론', body: p['one_sentence'].toString(),
              color: _kTeal, bg: _kTealBg),
        ]),
      pw.SizedBox(height: 22),
    ];
  }

  // ─── 근거 자료 (4~7장) ────────────────────────────────────────────
  List<pw.Widget> _evidenceSection({
    required Map<String, dynamic> evidence,
    required List<dynamic> hrvPhases,
    required List<dynamic> hrvImages,
    required Map<String, dynamic> eeg,
    required Map<String, dynamic> sleep,
    required List<dynamic> survey,
    required Map<String, dynamic> figures,
    required pw.ImageProvider? Function(String?) img,
  }) {
    final hrv = evidence['hrv'] as Map<String, dynamic>? ?? {};
    final eegE = evidence['eeg'] as Map<String, dynamic>? ?? {};
    final sleepE = evidence['sleep'] as Map<String, dynamic>? ?? {};
    final clinical = evidence['clinical'] as Map<String, dynamic>? ?? {};

    final out = <pw.Widget>[
      pw.NewPage(),
      _partTitle('근거 자료'),
      pw.Text('앞의 결론이 어떤 측정에서 나왔는지, 그림과 함께 보여드립니다.',
          style: _st(9.5, height: 1.6)),
      if ((evidence['intro']?.toString() ?? '').isNotEmpty) ...[
        pw.SizedBox(height: 12),
        _callout(title: '먼저 알아두면 좋은 점', body: evidence['intro'].toString(),
            color: _kTeal, bg: _kTealBg),
      ],
      pw.SizedBox(height: 20),
    ];

    // ── 4. HRV ───────────────────────────────────────────────
    final hrvFigs = <pw.Widget>[];
    for (final raw in hrvImages) {
      final h = raw as Map<String, dynamic>;
      final im = img(h['heart_rate'] as String?);
      if (im == null) continue;
      // 그림과 그 캡션은 한 덩어리로 움직여야 한다.
      hrvFigs.add(_group([
        _figure(im, '${h['name_ko']} 구간의 심박 흐름', maxHeight: 150),
        pw.SizedBox(height: 10),
      ]));
    }
    out.addAll(_withHeader([
      _chapterTitle('4', '심박변이도 — 자율신경 상태'),
      if ((hrv['what_is']?.toString() ?? '').isNotEmpty) ...[
        _callout(title: '심박변이도란?', body: hrv['what_is'].toString(),
            color: _kGrey, bg: _kRowEven),
        pw.SizedBox(height: 12),
      ],
    ], hrvFigs));
    if ((hrv['flow']?.toString() ?? '').isNotEmpty) {
      out.addAll([pw.Text(hrv['flow'].toString(), style: _st(9.5, height: 1.6)),
        pw.SizedBox(height: 12)]);
    }
    // 구간별 숫자 표
    if (hrvPhases.isNotEmpty) {
      final notes = <String, String>{};
      for (final raw in (hrv['phase_notes'] as List<dynamic>? ?? [])) {
        final n = raw as Map<String, dynamic>;
        // 백엔드가 영문 키(baseline 등)로 달라고 지시한다. 한글 라벨로 맞추면
        // 표기가 조금만 달라도 조회가 빗나가 '한 줄 해석' 열이 통째로 빈다.
        final k = (n['phase'] ?? n['phase_ko'] ?? '').toString().toLowerCase();
        notes[k] = n['note']?.toString() ?? '';
      }
      final hrvRows = hrvPhases.map((raw) {
        final p = raw as Map<String, dynamic>;
        final ko = p['name_ko']?.toString() ?? '';
        // 영문 키(baseline 등)로 먼저 찾고, 옛 응답 호환으로 한글 라벨도 본다.
        final key = (p['name'] ?? '').toString().toLowerCase();
        return [ko, _num(p['rmssd']), _num(p['lh_ratio']),
                notes[key] ?? notes[ko] ?? ''];
      }).toList();
      out.addAll(_titledTable(
        _subTitle('구간별 핵심 숫자'),
        _zebraTable(
          headers: ['구간', '이완 지표', '긴장 균형', '한 줄 해석'],
          rows: hrvRows,
          widths: {0: 1.2, 1: 1.0, 2: 1.0, 3: 2.4},
        ),
        hrvRows.length,
      ));
      out.add(pw.SizedBox(height: 12));
    }
    if ((hrv['comparison']?.toString() ?? '').isNotEmpty) {
      out.addAll([pw.Text(hrv['comparison'].toString(), style: _st(9.5, height: 1.6)),
        pw.SizedBox(height: 10)]);
    }
    if ((hrv['key_point']?.toString() ?? '').isNotEmpty) {
      out.add(_callout(title: '4장 요점', body: hrv['key_point'].toString(),
          color: _kTeal, bg: _kTealBg));
    }
    out.add(pw.SizedBox(height: 22));

    // ── 5. EEG ───────────────────────────────────────────────
    // 장마다 NewPage 를 넣으면 내용이 짧을 때 거의 빈 페이지가 생긴다.
    // 대신 제목이 홀로 남지 않도록 첫 대역 블록까지 묶어서 흘려보낸다.
    final eegHeader = <pw.Widget>[
      _chapterTitle('5', '뇌파 — 뇌 활동 상태'),
      if ((eegE['how_to_read']?.toString() ?? '').isNotEmpty) ...[
        _callout(title: '그림 보는 법', body: eegE['how_to_read'].toString(),
            color: _kGrey, bg: _kRowEven),
        pw.SizedBox(height: 14),
      ],
    ];
    final eegBlocks = <pw.Widget>[];
    final captions = <String, String>{};
    for (final raw in (eegE['band_captions'] as List<dynamic>? ?? [])) {
      final c = raw as Map<String, dynamic>;
      captions[(c['band'] ?? '').toString().toLowerCase()] =
          c['caption']?.toString() ?? '';
    }
    final topo = figures['topography'] as Map<String, dynamic>? ?? {};
    final conn = figures['connectivity'] as Map<String, dynamic>? ?? {};
    var sub = 0;
    for (final band in _kBandOrder) {
      final topoRow = <pw.ImageProvider>[];
      final connRow = <pw.ImageProvider>[];
      final labels = <String>[];
      for (final ph in _kPhaseOrder) {
        final t = img((topo[ph] as Map<String, dynamic>?)?[band] as String?);
        final c = img((conn[ph] as Map<String, dynamic>?)?[band] as String?);
        if (t == null && c == null) continue;
        labels.add(_kPhaseLabel[ph] ?? ph);
        if (t != null) topoRow.add(t);
        if (c != null) connRow.add(c);
      }
      if (topoRow.isEmpty && connRow.isEmpty) continue;
      sub++;
      // 소제목·그림 두 줄·캡션은 한 덩어리다. 갈라지면 캡션만 다음 쪽으로 넘어간다.
      eegBlocks.add(_group([
        _subTitle('5-$sub. ${_kBandLabel[band] ?? band}'),
        if (topoRow.isNotEmpty) _imageRow(topoRow, labels),
        if (connRow.isNotEmpty) ...[pw.SizedBox(height: 4), _imageRow(connRow, const [])],
        pw.SizedBox(height: 5),
        _caption('그림 $_nextFig. ${_kBandLabel[band] ?? band}'
            '${(captions[band] ?? '').isEmpty ? '' : ' — ${captions[band]}'}'),
        pw.SizedBox(height: 14),
      ]));
    }
    out.addAll(_withHeader(eegHeader, eegBlocks));

    // 정서 균형 (FAA)
    final faa = figures['faa'] as Map<String, dynamic>? ?? {};
    final faaImgs = <pw.ImageProvider>[];
    final faaLabels = <String>[];
    for (final ph in _kPhaseOrder) {
      final im = img(faa[ph] as String?);
      if (im == null) continue;
      faaImgs.add(im);
      faaLabels.add(_kPhaseLabel[ph] ?? ph);
    }
    if (faaImgs.isNotEmpty || (eegE['faa']?.toString() ?? '').isNotEmpty) {
      out.add(_group([
        _subTitle('정서 균형 지표 (좌우 이마 균형)'),
        if (faaImgs.isNotEmpty) ...[
          _imageRow(faaImgs, faaLabels),
          pw.SizedBox(height: 5),
          _caption('그림 $_nextFig. 구간별 좌우 이마 균형'),
        ],
        if ((eegE['faa']?.toString() ?? '').isNotEmpty) ...[
          pw.SizedBox(height: 8),
          pw.Text(eegE['faa'].toString(), style: _st(9.5, height: 1.6)),
        ],
      ]));
      out.add(pw.SizedBox(height: 22));
    }

    // ── 6. 휴식 구조 ──────────────────────────────────────────
    // 장마다 NewPage 를 넣으면 내용이 짧을 때 거의 빈 페이지가 생긴다.
    final spec = figures['spectrogram'] as Map<String, dynamic>? ?? {};
    final specImgs = <pw.ImageProvider>[];
    for (final ch in ['fp1', 'fp2']) {
      final im = img(spec[ch] as String?);
      if (im != null) specImgs.add(im);
    }
    if (specImgs.isNotEmpty) {
      out.add(_group([
        _chapterTitle('6', '휴식 구조 — 실제로 무슨 일이 있었나'),
        _subTitle('6-1. 시간에 따른 뇌파 변화'),
        for (final im in specImgs) ...[
          _figure(im, null, maxHeight: 170),
          pw.SizedBox(height: 6),
        ],
        _caption('그림 $_nextFig. 시간에 따른 뇌파 변화 (빨강=강함, 파랑=약함)'),
        if ((sleepE['spectrogram']?.toString() ?? '').isNotEmpty) ...[
          pw.SizedBox(height: 8),
          pw.Text(sleepE['spectrogram'].toString(), style: _st(9.5, height: 1.6)),
        ],
      ]));
      out.add(pw.SizedBox(height: 16));
    } else {
      out.add(_chapterTitle('6', '휴식 구조 — 실제로 무슨 일이 있었나'));
    }
    if (eeg['psd_bands'] != null) {
      final pb = eeg['psd_bands'] as Map<String, dynamic>;
      out.add(_group([
        _subTitle('6-2. 밴드별 비중'),
        _zebraTable(
          headers: ['밴드', '비중'],
          rows: _kBandOrder
              .where((b) => pb[b] != null)
              .map((b) => [_kBandLabel[b] ?? b, '${pb[b]}%'])
              .toList(),
          widths: {0: 1.4, 1: 1.0},
        ),
        if ((sleepE['symmetry']?.toString() ?? '').isNotEmpty) ...[
          pw.SizedBox(height: 10),
          pw.Text(sleepE['symmetry'].toString(), style: _st(9.5, height: 1.6)),
        ],
      ]));
      out.add(pw.SizedBox(height: 16));
    }
    if ((sleepE['coupling']?.toString() ?? '').isNotEmpty) {
      out.add(_group([
        _subTitle('6-3. 기억 정리 결합 — 휴식의 질'),
        pw.Text(sleepE['coupling'].toString(), style: _st(9.5, height: 1.6)),
      ]));
      out.add(pw.SizedBox(height: 16));
    }
    if (eeg['staging_dist'] != null) {
      final sd = eeg['staging_dist'] as Map<String, dynamic>;
      const nice = {'W': '각성', 'N1': '얕은 진입', 'N2': '안정 휴식',
                    'N3': '깊은 휴식', 'REM': '꿈 단계'};
      out.add(_group([
        _subTitle('6-4. 상태 비율'),
        _zebraTable(
          headers: ['상태', '비율'],
          rows: ['W', 'N1', 'N2', 'N3', 'REM']
              .where((k) => sd[k] != null)
              .map((k) => [nice[k] ?? k, '${sd[k]}%'])
              .toList(),
          widths: {0: 1.6, 1: 1.0},
        ),
        if ((sleepE['stage_ratio']?.toString() ?? '').isNotEmpty) ...[
          pw.SizedBox(height: 10),
          pw.Text(sleepE['stage_ratio'].toString(), style: _st(9.5, height: 1.6)),
        ],
      ]));
      out.add(pw.SizedBox(height: 12));
    }
    if ((sleepE['resolution']?.toString() ?? '').isNotEmpty) {
      out.add(_callout(title: '교차 검증', body: sleepE['resolution'].toString(),
          color: _kCaution, bg: _kCautionBg));
      out.add(pw.SizedBox(height: 22));
    }

    // ── 7. 임상 배경 ──────────────────────────────────────────
    if (survey.isNotEmpty || sleep.isNotEmpty) {
      out.add(_chapterTitle('7', '임상 배경 — 원래 어떤 상태인가'));
    }
    if (survey.isNotEmpty) {
      final surveyRows = survey.map((raw) {
        final q = raw as Map<String, dynamic>;
        return [
          q['label']?.toString() ?? '',
          '${q['score'] ?? ''}',
          q['measures']?.toString() ?? '',
          q['reference']?.toString() ?? '',
        ];
      }).toList();
      out.addAll(_titledTable(
        _subTitle('7-1. 설문 점수 (본인이 느끼는 증상)'),
        _zebraTable(
          headers: ['척도', '점수', '무엇을 재나', '기준'],
          rows: surveyRows,
          widths: {0: 1.1, 1: 0.6, 2: 1.4, 3: 2.6},
        ),
        surveyRows.length,
      ));
      out.add(pw.SizedBox(height: 10));
      if ((clinical['survey']?.toString() ?? '').isNotEmpty) {
        out.add(_group([
          _callout(title: '설문 요점', body: clinical['survey'].toString(),
              color: _kTeal, bg: _kTealBg),
        ]));
        out.add(pw.SizedBox(height: 16));
      }
    }
    if (sleep.isNotEmpty) {
      // 두 표는 5행/4행이라 제목과 함께 한 페이지에 들어간다.
      out.add(_group([
        _subTitle('7-2. 휴식 구조 요약'),
        _zebraTable(
          headers: ['항목', '값', '의미'],
          rows: [
            ['총 측정 시간', _min(sleep['tib']), '검사 총 시간'],
            ['실제 휴식 시간', _min(sleep['tst']), '실제로 쉰 시간'],
            ['중간에 깬 시간', _min(sleep['waso']), '중간 각성'],
            ['진입까지 걸린 시간', _min(sleep['sleep_latency']), '쉼에 들어가기까지'],
            ['휴식 효율', _pct(sleep['sleep_eff']), '정상 85% 이상'],
          ],
          widths: {0: 1.6, 1: 1.0, 2: 2.0},
        ),
      ]));
      out.add(pw.SizedBox(height: 10));
      out.add(_group([
        _zebraTable(
          headers: ['단계', '시간', '비율'],
          rows: [
            ['얕은 진입', _min(sleep['n1_min']), _pct(sleep['n1_pct'])],
            ['안정 휴식', _min(sleep['n2_min']), _pct(sleep['n2_pct'])],
            ['깊은 휴식', _min(sleep['n3_min']), _pct(sleep['n3_pct'])],
            ['꿈 단계', _min(sleep['rem_min']), _pct(sleep['rem_pct'])],
          ],
          widths: {0: 1.6, 1: 1.0, 2: 1.0},
        ),
        if ((clinical['psg']?.toString() ?? '').isNotEmpty) ...[
          pw.SizedBox(height: 10),
          _callout(title: '구조 요점', body: clinical['psg'].toString(),
              color: _kTeal, bg: _kTealBg),
        ],
      ]));
      out.add(pw.SizedBox(height: 22));
    }
    return out;
  }

  // ─── 종합 평가 ────────────────────────────────────────────────────
  List<pw.Widget> _summarySection(Map<String, dynamic> s) {
    if (s.isEmpty) return [];
    final table = s['domain_table'] as List<dynamic>? ?? [];
    final strengths = (s['strengths'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
    final weaknesses = (s['weaknesses'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
    final conclusions = (s['conclusions'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();

    final tableRows = table.map((raw) {
      final t = raw as Map<String, dynamic>;
      return [
        t['domain']?.toString() ?? '',
        t['verdict']?.toString() ?? '',
        t['key']?.toString() ?? '',
      ];
    }).toList();

    return [
      pw.NewPage(),
      // 마무리는 리포트의 결론부라 제목과 첫 표가 갈라지면 안 된다.
      _group([
        _partTitle('종합 평가'),
        pw.Text('내 뇌는 무엇을 잘하고, 무엇을 챙기면 좋을까', style: _st(11, color: _kTeal)),
        pw.SizedBox(height: 16),
        if (tableRows.isNotEmpty) ...[
          _subTitle('영역별 한눈 정리'),
          _zebraTable(
            headers: ['영역', '평가', '핵심'],
            rows: tableRows,
            widths: {0: 1.3, 1: 0.8, 2: 3.0},
            verdictColumn: 1,
          ),
        ],
      ]),
      if (tableRows.isNotEmpty) pw.SizedBox(height: 18),
      if (strengths.isNotEmpty)
        _group([
          _subTitle('강점 — 내 뇌가 잘하는 것', color: _kStrength),
          ...strengths.map((t) => _bullet(t, dot: _kStrength)),
          pw.SizedBox(height: 14),
        ]),
      if (weaknesses.isNotEmpty)
        _group([
          _subTitle('약점 — 챙기면 좋은 것', color: _kWeakness),
          ...weaknesses.map((t) => _bullet(t, dot: _kWeakness)),
          pw.SizedBox(height: 14),
        ]),
      if (conclusions.isNotEmpty)
        ..._withHeader([_subTitle('결론')],
            List.generate(conclusions.length, (i) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Container(
                  width: 16,
                  child: pw.Text('${i + 1}.', style: _st(9.5, bold: true, color: _kNavy)),
                ),
                pw.Expanded(child: pw.Text(conclusions[i], style: _st(9.5, height: 1.6))),
              ]),
            ))),
      if (conclusions.isNotEmpty) pw.SizedBox(height: 16),
      _callout(
        title: '꼭 기억해 주세요',
        body: (s['disclaimer']?.toString() ?? '').isNotEmpty
            ? s['disclaimer'].toString()
            : '이 리포트는 한 차례 검사 데이터에 기반하므로 확정된 진단이 아니라 경향과 '
              '참고점입니다. 정확한 판단과 관리 방향은 반드시 담당 전문의와 상의해 '
              '결정하시기 바랍니다.',
        color: _kWeakness,
        bg: _kWeaknessBg,
      ),
      pw.SizedBox(height: 20),
      pw.Center(child: pw.Text('— 리포트 끝 —', style: _st(9, color: _kGrey))),
    ];
  }

  // ─── 공통 위젯 ────────────────────────────────────────────────────
  pw.TextStyle _st(double size,
          {PdfColor color = _kTextDark,
          bool bold = false,
          bool italic = false,
          double? height}) =>
      pw.TextStyle(
        font: bold ? _bold : _regular,
        fontBold: _bold,
        fontSize: size,
        color: color,
        height: height,
        fontStyle: italic ? pw.FontStyle.italic : pw.FontStyle.normal,
      );

  // ─── 쪽 나눔 제어 ──────────────────────────────────────────────────
  // MultiPage 는 build 가 돌려준 "최상위 위젯" 사이에서만 쪽을 나눈다.
  // 따라서 잘게 쪼개 내보내면 제목만 페이지 끝에 남고 본문이 다음 쪽으로 가는
  // 일이 생긴다. 아래 헬퍼로 논리 단위를 하나의 위젯으로 묶어 통째로 넘긴다.

  /// 여러 위젯을 쪼개지지 않는 한 덩어리로 만든다.
  ///
  /// Column 은 쪽을 넘겨 이어질 수 없으므로 페이지 경계에서 통째로 다음 쪽으로
  /// 이동한다. 반대로 한 페이지보다 큰 덩어리를 만들면 넘치는 부분이 잘리므로,
  /// 확실히 한 페이지에 들어갈 것만 묶어야 한다.
  pw.Widget _group(List<pw.Widget> children) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: children,
      );

  /// 제목이 페이지 끝에 홀로 남지 않게 첫 항목까지 붙여서 내보낸다.
  ///
  /// 전부 묶어버리면 항목이 많을 때 한 페이지를 넘겨 잘리므로, 제목 + 첫 항목만
  /// 묶고 나머지는 자유롭게 흐르게 둔다.
  List<pw.Widget> _withHeader(List<pw.Widget> header, List<pw.Widget> items) {
    if (items.isEmpty) return header.isEmpty ? [] : [_group(header)];
    return [_group([...header, items.first]), ...items.skip(1)];
  }

  /// 표 앞의 제목 처리.
  ///
  /// 짧은 표는 제목과 한 덩어리로 움직여야 보기 좋다. 긴 표는 묶어버리면 한
  /// 페이지를 넘겨 잘리므로, 표가 스스로 쪽을 나눠 이어지도록 따로 둔다
  /// (그 경우 헤더 행이 각 쪽에 반복된다).
  ///
  /// 기준을 8행으로 둔 이유: 셀이 3줄까지 늘어나도 8행이면 약 380pt 라
  /// 한 페이지 본문 높이(약 730pt)에 여유 있게 들어간다.
  List<pw.Widget> _titledTable(pw.Widget title, pw.Widget table, int rowCount) {
    if (rowCount <= 8) return [_group([title, table])];
    return [title, table];
  }

  pw.Widget _partTitle(String text) => pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 12),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(text, style: _st(18, bold: true, color: _kNavy)),
          pw.SizedBox(height: 5),
          pw.Container(height: 2, width: 46, color: _kTeal),
        ]),
      );

  pw.Widget _chapterTitle(String number, String title) => pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 8),
        child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
          pw.Container(
            width: 22, height: 22,
            alignment: pw.Alignment.center,
            color: _kTeal,
            child: pw.Text(number, style: _st(11, bold: true, color: PdfColors.white)),
          ),
          pw.SizedBox(width: 9),
          pw.Expanded(child: pw.Text(title, style: _st(13, bold: true, color: _kNavy))),
        ]),
      );

  pw.Widget _subTitle(String text, {PdfColor color = _kNavy}) => pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 7),
        child: pw.Text(text, style: _st(10.5, bold: true, color: color)),
      );

  pw.Widget _bullet(String text, {PdfColor dot = _kTeal}) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Container(
            width: 10,
            padding: const pw.EdgeInsets.only(top: 4.5),
            child: pw.Container(width: 3, height: 3,
                decoration: pw.BoxDecoration(color: dot, shape: pw.BoxShape.circle)),
          ),
          pw.Expanded(child: pw.Text(text, style: _st(9.5, height: 1.55))),
        ]),
      );

  /// 좌측 두꺼운 테두리의 색 박스.
  pw.Widget _callout({
    required String title,
    required String body,
    required PdfColor color,
    required PdfColor bg,
  }) =>
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.fromLTRB(13, 11, 13, 11),
        decoration: pw.BoxDecoration(
          color: bg,
          border: pw.Border(left: pw.BorderSide(color: color, width: 3.5)),
        ),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          if (title.isNotEmpty) ...[
            pw.Text(title, style: _st(10, bold: true, color: color)),
            pw.SizedBox(height: 5),
          ],
          pw.Text(body, style: _st(9.5, height: 1.6)),
        ]),
      );

  /// 라벨과 본문이 한 줄로 이어지는 작은 callout (강점/약점/의미).
  pw.Widget _miniCallout(String label, String body, PdfColor color, PdfColor bg) =>
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.fromLTRB(10, 7, 10, 7),
        decoration: pw.BoxDecoration(
          color: bg,
          border: pw.Border(left: pw.BorderSide(color: color, width: 2.5)),
        ),
        child: pw.RichText(
          text: pw.TextSpan(children: [
            pw.TextSpan(text: '$label: ', style: _st(9.5, bold: true, color: color)),
            pw.TextSpan(text: body, style: _st(9.5, height: 1.55)),
          ]),
        ),
      );

  pw.Widget _chip(String text) => pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: pw.BoxDecoration(
          color: _verdictBg(text),
          border: pw.Border.all(color: _verdictColor(text), width: 0.7),
        ),
        child: pw.Text(text, style: _st(8, bold: true, color: _verdictColor(text))),
      );

  // 주의 계열을 먼저 본다. '강점이자 함정' 처럼 두 단어가 같이 오는 판정이
  // 있어서, 강점을 먼저 검사하면 함정인데 초록으로 칠해진다.
  PdfColor _verdictColor(String v) {
    if (v.contains('함정') || v.contains('예민') || v.contains('주의')) return _kCaution;
    if (v.contains('약점')) return _kWeakness;
    if (v.contains('강점')) return _kStrength;
    return _kTeal;
  }

  PdfColor _verdictBg(String v) {
    if (v.contains('함정') || v.contains('예민') || v.contains('주의')) return _kCautionBg;
    if (v.contains('약점')) return _kWeaknessBg;
    if (v.contains('강점')) return _kStrengthBg;
    return _kTealBg;
  }

  /// 헤더 색 채움 + 얼룩(zebra) 행 표.
  pw.Widget _zebraTable({
    required List<String> headers,
    required List<List<String>> rows,
    Map<int, double>? widths,
    PdfColor headerColor = _kNavy,
    int? verdictColumn,
  }) {
    final cw = <int, pw.TableColumnWidth>{};
    widths?.forEach((k, v) => cw[k] = pw.FlexColumnWidth(v));
    return pw.Table(
      border: pw.TableBorder.all(color: _kBorder, width: 0.5),
      columnWidths: cw.isEmpty ? null : cw,
      children: [
        pw.TableRow(
          // 표가 쪽을 넘겨 이어질 때 헤더 행을 각 쪽에 다시 그린다.
          // 없으면 두 번째 쪽부터 어떤 열이 무엇인지 알 수 없다.
          repeat: true,
          decoration: pw.BoxDecoration(color: headerColor),
          children: headers
              .map((h) => pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 6),
                    child: pw.Text(h, style: _st(9, bold: true, color: PdfColors.white)),
                  ))
              .toList(),
        ),
        ...List.generate(rows.length, (i) {
          final r = rows[i];
          return pw.TableRow(
            decoration: pw.BoxDecoration(color: i.isEven ? _kRowEven : PdfColors.white),
            children: List.generate(r.length, (j) {
              // 판정 열은 색으로 강조한다.
              final isVerdict = verdictColumn != null && j == verdictColumn;
              return pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                child: pw.Text(
                  r[j],
                  style: _st(8.5,
                      height: 1.45,
                      bold: isVerdict || j == 0,
                      color: isVerdict ? _verdictColor(r[j]) : _kTextDark),
                ),
              );
            }),
          );
        }),
      ],
    );
  }

  /// 그림 한 장 + 캡션. 원본 비율을 유지한 채 높이만 제한한다.
  pw.Widget _figure(pw.ImageProvider image, String? caption, {double maxHeight = 200}) =>
      pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Center(
          child: pw.ConstrainedBox(
            constraints: pw.BoxConstraints(maxHeight: maxHeight),
            child: pw.Image(image, fit: pw.BoxFit.contain),
          ),
        ),
        if (caption != null) ...[
          pw.SizedBox(height: 4),
          _caption('그림 $_nextFig. $caption'),
        ],
      ]);

  /// 그림 여러 장을 한 줄로. labels 가 있으면 각 칸 위에 구간명을 단다.
  pw.Widget _imageRow(List<pw.ImageProvider> images, List<String> labels) {
    if (images.isEmpty) return pw.SizedBox();
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: List.generate(images.length, (i) {
        return pw.Expanded(
          child: pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 1.5),
            child: pw.Column(children: [
              if (i < labels.length) ...[
                pw.Text(labels[i], style: _st(7, color: _kGrey)),
                pw.SizedBox(height: 2),
              ],
              pw.Image(images[i], fit: pw.BoxFit.contain),
            ]),
          ),
        );
      }),
    );
  }

  pw.Widget _caption(String text) => pw.Text(text, style: _st(8, color: _kGrey));

  // ─── 숫자 포맷 ────────────────────────────────────────────────────
  String _num(dynamic v) {
    if (v == null) return '-';
    if (v is num) return v.toStringAsFixed(2);
    return v.toString();
  }

  String _min(dynamic v) => v == null ? '-' : '${_num(v)} 분';
  String _pct(dynamic v) => v == null ? '-' : '${_num(v)}%';
}
