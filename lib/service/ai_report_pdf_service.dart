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

// ─── 컬러 팔레트 (NeuroTx 스타일) ────────────────────────────────────
const _kHeaderBg    = PdfColor.fromInt(0xFF0D1B2A); // 진한 네이비
const _kAccent      = PdfColor.fromInt(0xFF006B5E); // 딥 그린
const _kSectionNum  = PdfColor.fromInt(0xFF00A651); // 밝은 그린
const _kRowEven     = PdfColor.fromInt(0xFFF4F7F6);
const _kRowOdd      = PdfColors.white;
const _kTakeawayBg  = PdfColor.fromInt(0xFFE8F5F0);
const _kBorder      = PdfColor.fromInt(0xFFCCDDDB);
const _kGrey        = PdfColor.fromInt(0xFF6B7280);
const _kTextDark    = PdfColor.fromInt(0xFF1A1A2E);
// _kWhite70 / white60 이 패키지에 없으므로 직접 정의
const _kWhite70     = PdfColor.fromInt(0xFFD9D9D9); // 연한 회백색 (어두운 배경용)
const _kWhite60     = PdfColor.fromInt(0xFFB3B3B3); // 더 연한 회색 (어두운 배경용)

class AiReportPdfService {
  // 싱글턴
  AiReportPdfService._();
  static final instance = AiReportPdfService._();

  late pw.Font _regular;
  late pw.Font _bold;
  bool _fontsLoaded = false;

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

    // 1) 백엔드 호출 (Claude API 응답이 최대 2분 걸릴 수 있으므로 타임아웃 3분)
    onStatus?.call('AI 분석 중... (1~2분 소요)');
    final url = Uri.parse('${BASE_URL}api/v1/exp/${user.id}/ai-report/');
    final response = await http.post(
      url,
      headers: {'Authorization': 'JWT ${AppService.instance.currentUser?.id}'},
    ).timeout(const Duration(seconds: 180));

    if (response.statusCode != 200) {
      throw Exception('서버 오류 ${response.statusCode}');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

    // 2) PDF 빌드
    onStatus?.call('PDF 생성 중...');
    final pdfBytes = await _buildPdf(data);

    // 3) 다운로드
    final patient = data['patient'] as Map<String, dynamic>;
    final name    = patient['name'] ?? 'report';
    final date    = (patient['measurement_date'] ?? '').toString().replaceAll('-', '');
    final fileName = '${name}_AI_Clinical_Report_$date.pdf';

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

  // ─── 이미지 다운로드 ──────────────────────────────────────────────
  Future<pw.ImageProvider?> _fetchImage(String? relUrl) async {
    if (relUrl == null) return null;
    try {
      final base = BASE_URL.endsWith('/') ? BASE_URL.substring(0, BASE_URL.length - 1) : BASE_URL;
      final uri = Uri.parse('$base$relUrl');
      final resp = await http.get(
        uri,
        headers: {'Authorization': 'JWT ${AppService.instance.currentUser?.id}'},
      ).timeout(const Duration(seconds: 15));
      // 0바이트 파일이면 유효한 이미지가 아니므로 null 반환 (최소 100바이트)
      if (resp.statusCode == 200 && resp.bodyBytes.length > 100) {
        try {
          return pw.MemoryImage(resp.bodyBytes);
        } catch (_) {
          // 이미지 디코딩 실패 (포맷 오류 등)
          return null;
        }
      }
    } catch (_) {}
    return null;
  }

  /// HRV 단계별 heart_rate 이미지 리스트
  Future<List<Map<String, dynamic>>> _fetchHrvImages(List<dynamic>? phases) async {
    if (phases == null || phases.isEmpty) return [];
    final result = <Map<String, dynamic>>[];
    for (final p in phases) {
      final phase = p as Map<String, dynamic>;
      final img = await _fetchImage(phase['heart_rate'] as String?);
      if (img != null) result.add({'label': phase['name_ko'] as String, 'image': img});
    }
    return result;
  }

  /// EEG Baseline topography / COH / PLV 이미지
  Future<Map<String, List<Map<String, dynamic>>>> _fetchEegImages(
      Map<String, dynamic>? eegImages) async {
    if (eegImages == null || eegImages.isEmpty) return {};
    const bandLabels = {'delta': 'δ Delta', 'theta': 'θ Theta', 'alpha': 'α Alpha', 'beta': 'β Beta', 'gamma': 'γ Gamma'};
    final result = <String, List<Map<String, dynamic>>>{};
    for (final key in ['topography', 'connectivity_coh', 'connectivity_plv']) {
      final bands = eegImages[key] as Map<String, dynamic>?;
      if (bands == null) continue;
      final list = <Map<String, dynamic>>[];
      for (final band in ['delta', 'theta', 'alpha', 'beta', 'gamma']) {
        final img = await _fetchImage(bands[band] as String?);
        if (img != null) list.add({'label': bandLabels[band] ?? band, 'image': img});
      }
      if (list.isNotEmpty) result[key] = list;
    }
    return result;
  }

  // ─── PDF 빌드 ─────────────────────────────────────────────────────
  Future<Uint8List> _buildPdf(Map<String, dynamic> data) async {
    final pdf = pw.Document();

    final patient    = data['patient']    as Map<String, dynamic>;
    final hrvPhases  = data['hrv_phases'] as List<dynamic>;
    final sleep      = data['sleep']      as Map<String, dynamic>? ?? {};
    final eeg        = data['eeg']        as Map<String, dynamic>? ?? {};
    final ai         = data['ai']         as Map<String, dynamic>? ?? {};
    final sections   = ai['sections']     as List<dynamic>? ?? [];

    // 이미지 사전 다운로드
    final hrvImgs = await _fetchHrvImages(data['hrv_images'] as List<dynamic>?);
    final eegImgs = await _fetchEegImages(data['eeg_images'] as Map<String, dynamic>?);

    final pageTheme = pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      buildBackground: (ctx) => pw.FullPage(
        ignoreMargins: true,
        child: pw.Stack(children: [
          // 상단 헤더 바
          pw.Positioned(
            top: 0, left: 0, right: 0,
            child: pw.Container(
              height: 28,
              color: _kHeaderBg,
              padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 6),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Clinical Neurophysiology Division  |  ${patient['name']}',
                    style: _style(8, color: PdfColors.white, bold: false),
                  ),
                  pw.Text(
                    '측정일: ${patient['measurement_date']}',
                    style: _style(8, color: _kWhite70, bold: false),
                  ),
                ],
              ),
            ),
          ),
          // 하단 푸터
          pw.Positioned(
            bottom: 0, left: 0, right: 0,
            child: pw.Container(
              height: 20,
              color: _kHeaderBg,
              padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('CONFIDENTIAL · Prepared for clinical decision support',
                      style: _style(7, color: _kWhite60, bold: false)),
                  pw.Text('Page ${ctx.pageNumber} / ${ctx.pagesCount}',
                      style: _style(7, color: _kWhite60, bold: false)),
                ],
              ),
            ),
          ),
        ]),
      ),
      margin: const pw.EdgeInsets.only(top: 44, bottom: 36, left: 36, right: 36),
    );

    // ── 표지 페이지 ──────────────────────────────────────────────
    pdf.addPage(pw.Page(
      pageTheme: pageTheme,
      build: (ctx) => _buildCoverPage(patient),
    ));

    // ── 본문 (MultiPage) ─────────────────────────────────────────
    pdf.addPage(pw.MultiPage(
      pageTheme: pageTheme,
      build: (ctx) => [
        // Executive Summary
        _sectionBlock(
          number: '',
          titleKo: 'EXECUTIVE SUMMARY',
          titleEn: '임상 통합 요약',
          content: ai['executive_summary']?.toString() ?? '',
          extra: ai['so_what'] != null
              ? _soWhatBox(ai['so_what'].toString())
              : null,
        ),
        pw.SizedBox(height: 16),

        // HRV 데이터 테이블
        _boldLabel('HRV 단계별 측정 데이터'),
        pw.SizedBox(height: 6),
        _hrvTable(hrvPhases),
        pw.SizedBox(height: 14),

        // HRV 이미지 (단계별 심박 그래프)
        if (hrvImgs.isNotEmpty) ...[
          _boldLabel('HRV 단계별 심박 그래프 (Heart Rate Variability)'),
          pw.SizedBox(height: 6),
          _imageGrid(hrvImgs, cols: 5),
          pw.SizedBox(height: 20),
        ],

        // 수면 데이터 테이블
        if (sleep.isNotEmpty) ...[
          _boldLabel('수면 구조 데이터 (Sleep Architecture)'),
          pw.SizedBox(height: 6),
          _sleepTable(sleep),
          pw.SizedBox(height: 20),
        ],

        // EEG 수치 데이터
        if (eeg['has_data'] == true) ...[
          _boldLabel('EEG 분석 데이터'),
          pw.SizedBox(height: 6),
          _eegTable(eeg),
          pw.SizedBox(height: 14),
        ],

        // EEG 이미지 — Topography
        if (eegImgs['topography']?.isNotEmpty == true) ...[
          _imageGroupBlock(
            title: 'EEG Topography — Baseline',
            subtitle: '주파수 대역별 두피 전력 분포',
            items: eegImgs['topography']!,
            cols: 5,
          ),
          pw.SizedBox(height: 14),
        ],

        // EEG 이미지 — Connectivity wPLI
        if (eegImgs['connectivity_coh']?.isNotEmpty == true) ...[
          _imageGroupBlock(
            title: 'EEG Connectivity (wPLI) — Baseline',
            subtitle: 'Weighted Phase Lag Index (가중 위상 지연 지수)',
            items: eegImgs['connectivity_coh']!,
            cols: 5,
          ),
          pw.SizedBox(height: 14),
        ],

        // EEG 이미지 — Connectivity PLV
        if (eegImgs['connectivity_plv']?.isNotEmpty == true) ...[
          _imageGroupBlock(
            title: 'EEG Connectivity (PLV) — Baseline',
            subtitle: 'Phase Locking Value (위상 고정)',
            items: eegImgs['connectivity_plv']!,
            cols: 5,
          ),
          pw.SizedBox(height: 20),
        ],

        // AI 분석 섹션 01-05
        for (final sec in sections) ...[
          _sectionBlock(
            number:    sec['number']?.toString() ?? '',
            titleKo:   sec['title_ko']?.toString() ?? '',
            titleEn:   sec['title_en']?.toString() ?? '',
            content:   sec['content']?.toString() ?? '',
            takeaway:  sec['key_takeaway']?.toString(),
          ),
          pw.SizedBox(height: 20),
        ],

        // Concluding Remarks
        _concludingBlock(ai['concluding_remarks']?.toString() ?? ''),
        pw.SizedBox(height: 24),

        // 면책 조항
        _disclaimer(),
      ],
    ));

    return pdf.save();
  }

  // ─── 표지 ─────────────────────────────────────────────────────────
  pw.Widget _buildCoverPage(Map<String, dynamic> patient) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 40),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(20),
          decoration: pw.BoxDecoration(color: _kHeaderBg, borderRadius: pw.BorderRadius.circular(4)),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('Clinical Neurophysiology Division',
                style: _style(10, color: _kWhite60, bold: false)),
            pw.SizedBox(height: 8),
            pw.Text('임상 분석 보고서',
                style: _style(26, color: PdfColors.white, bold: true)),
            pw.Text('Clinical Neurophysiology Report',
                style: _style(12, color: _kWhite70, bold: false)),
            pw.SizedBox(height: 12),
            pw.Text('수면 · 자율신경계 · 뇌 네트워크 정밀 분석',
                style: _style(11, color: _kSectionNum, bold: true)),
            pw.Text('Sleep, Autonomic & Brain Network Precision Analysis',
                style: _style(9, color: _kWhite60, bold: false)),
          ]),
        ),
        pw.SizedBox(height: 32),
        _infoRow('PATIENT',          patient['name'] ?? 'N/A'),
        _infoRow('AGE / SEX',        '${patient['age'] ?? 'N/A'} / ${patient['sex'] ?? 'N/A'}'),
        _infoRow('DATE OF BIRTH',    patient['birth'] ?? 'N/A'),
        _infoRow('ASSESSMENT DATE',  patient['measurement_date'] ?? 'N/A'),
        pw.SizedBox(height: 40),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _kBorder),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            'CONFIDENTIAL\n본 보고서는 임상 의사결정 지원을 위한 AI 기반 정밀 신경생리학 분석 자료이며,\n'
            '단독으로 진단의 근거가 되거나 치료적 결정을 대체하지 않습니다.',
            style: _style(9, color: _kGrey, bold: false),
          ),
        ),
      ],
    );
  }

  // ─── 섹션 블록 ───────────────────────────────────────────────────
  pw.Widget _sectionBlock({
    required String number,
    required String titleKo,
    required String titleEn,
    required String content,
    String? takeaway,
    pw.Widget? extra,
  }) {
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: const pw.BoxDecoration(
          border: pw.Border(left: pw.BorderSide(color: _kAccent, width: 4)),
          color: PdfColor.fromInt(0xFFF0FAF7),
        ),
        child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          if (number.isNotEmpty) ...[
            pw.Text(number, style: _style(28, color: _kSectionNum, bold: true)),
            pw.SizedBox(width: 14),
          ],
          pw.Expanded(
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(titleKo, style: _style(14, color: _kTextDark, bold: true)),
              if (titleEn.isNotEmpty)
                pw.Text(titleEn, style: _style(9, color: _kGrey, bold: false)),
            ]),
          ),
        ]),
      ),
      pw.SizedBox(height: 8),
      pw.Text(content, style: _style(10, bold: false), textAlign: pw.TextAlign.justify),
      if (extra != null) ...[pw.SizedBox(height: 8), extra],
      if (takeaway != null) ...[pw.SizedBox(height: 8), _takeawayBox(takeaway)],
    ]);
  }

  // ─── SO WHAT 박스 ────────────────────────────────────────────────
  pw.Widget _soWhatBox(String text) => pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: _kHeaderBg,
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('SO WHAT — 임상적 시사점',
              style: _style(9, color: _kSectionNum, bold: true)),
          pw.SizedBox(height: 4),
          pw.Text(text, style: _style(10, color: PdfColors.white, bold: false)),
        ]),
      );

  // ─── Key Takeaway 박스 ───────────────────────────────────────────
  pw.Widget _takeawayBox(String text) => pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: _kTakeawayBg,
          border: pw.Border.all(color: _kAccent),
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('Key takeaway  ', style: _style(9, color: _kAccent, bold: true)),
          pw.Expanded(child: pw.Text(text, style: _style(9, bold: false))),
        ]),
      );

  // ─── Concluding Remarks ───────────────────────────────────────────
  pw.Widget _concludingBlock(String text) => pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          color: _kHeaderBg,
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('CONCLUDING REMARKS — 임상 종합 결론',
              style: _style(12, color: _kSectionNum, bold: true)),
          pw.SizedBox(height: 8),
          pw.Text(text, style: _style(10, color: PdfColors.white, bold: false)),
        ]),
      );

  // ─── HRV 테이블 ──────────────────────────────────────────────────
  pw.Widget _hrvTable(List<dynamic> phases) {
    const headers = ['단계', 'SDNN(ms)', 'RMSSD(ms)', 'pNN50(%)', 'LF/HF', 'VLF(%)', 'LF(%)', 'HF(%)'];
    final rows = <List<String>>[];
    String? prevRmssd;

    for (final p in phases) {
      final m = p as Map<String, dynamic>;
      final rmssd = m['rmssd']?.toString();
      String sym = '─';
      if (prevRmssd != null && rmssd != null) {
        try {
          final diff = double.parse(rmssd) - double.parse(prevRmssd);
          sym = diff > 1 ? '▲' : diff < -1 ? '▼' : '─';
        } catch (_) {}
      }
      rows.add([
        '${m['name_ko'] ?? m['name']}',
        _f(m['sdnn']), '${_f(m['rmssd'])} $sym',
        _f(m['pnn50']), _f(m['lh_ratio']),
        _f(m['vlf']), _f(m['lf']), _f(m['hf']),
      ]);
      prevRmssd = rmssd;
    }
    return _dataTable(headers, rows);
  }

  // ─── 수면 테이블 ─────────────────────────────────────────────────
  pw.Widget _sleepTable(Map<String, dynamic> s) {
    final rows = [
      ['침대 내 총 시간 (TIB)',     '${_f(s['tib'])} min'],
      ['총 수면 시간 (TST)',        '${_f(s['tst'])} min'],
      ['총 각성 시간 (TWT)',        '${_f(s['twt'])} min'],
      ['수면 후 각성 (WASO)',       '${_f(s['waso'])} min'],
      ['수면 잠복기',               '${_f(s['sleep_latency'])} min'],
      ['REM 잠복기',               '${_f(s['rem_latency'])} min'],
      ['수면 효율',                 '${_f(s['sleep_eff'])} %'],
      ['N1 (정상 5–10%)',         '${_f(s['n1_pct'])}% · ${_f(s['n1_min'])}min'],
      ['N2 (정상 45–55%)',        '${_f(s['n2_pct'])}% · ${_f(s['n2_min'])}min'],
      ['N3 (정상 13–23%)',        '${_f(s['n3_pct'])}% · ${_f(s['n3_min'])}min'],
      ['NREM 합계',               '${_f(s['nrem_pct'])}% · ${_f(s['nrem_min'])}min'],
      ['REM (정상 20–25%)',       '${_f(s['rem_pct'])}% · ${_f(s['rem_min'])}min'],
    ];
    return _dataTable(['항목', '수치'], rows, headerRow: false);
  }

  // ─── EEG 테이블 ──────────────────────────────────────────────────
  pw.Widget _eegTable(Map<String, dynamic> eeg) {
    final rows = <List<String>>[];
    if (eeg['staging_dist'] != null) {
      final sd = eeg['staging_dist'] as Map<String, dynamic>;
      rows.addAll([
        ['W (Wake)',  '${sd['W']}%', '정상 범위 내'],
        ['N1',        '${sd['N1']}%', '5–10% 정상'],
        ['N2',        '${sd['N2']}%', '45–55% 정상'],
        ['N3',        '${sd['N3']}%', '13–23% 정상'],
        ['REM',       '${sd['REM']}%', '20–25% 정상'],
      ]);
    }
    if (eeg['psd_bands'] != null) {
      final pb = eeg['psd_bands'] as Map<String, dynamic>;
      pb.forEach((k, v) => rows.add(['PSD · ${k.toString().capitalize}', '$v%', '상대 파워']));
    }
    return rows.isEmpty
        ? pw.Text('EEG 데이터 없음', style: _style(9, color: _kGrey, bold: false))
        : _dataTable(['대역 / 지표', '값', '참고'], rows);
  }

  // ─── 공통 테이블 ─────────────────────────────────────────────────
  pw.Widget _dataTable(
    List<String> headers,
    List<List<String>> rows, {
    bool headerRow = true,
  }) {
    final allRows = <pw.TableRow>[];

    if (headerRow) {
      allRows.add(pw.TableRow(
        decoration: const pw.BoxDecoration(color: _kAccent),
        children: headers.map((h) => _cell(h, isHeader: true)).toList(),
      ));
    }

    for (var i = 0; i < rows.length; i++) {
      allRows.add(pw.TableRow(
        decoration: pw.BoxDecoration(color: i.isEven ? _kRowEven : _kRowOdd),
        children: rows[i].map((c) => _cell(c)).toList(),
      ));
    }

    return pw.Table(
      border: pw.TableBorder.all(color: _kBorder, width: 0.5),
      columnWidths: {
        for (var i = 0; i < headers.length; i++)
          i: const pw.FlexColumnWidth(),
      },
      children: allRows,
    );
  }

  pw.Widget _cell(String text, {bool isHeader = false}) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        child: pw.Text(
          text,
          style: _style(9, color: isHeader ? PdfColors.white : _kTextDark, bold: isHeader),
        ),
      );

  // ─── 헬퍼 ────────────────────────────────────────────────────────
  pw.Widget _boldLabel(String text) => pw.Text(
        text,
        style: _style(11, color: _kTextDark, bold: true),
      );

  pw.Widget _infoRow(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        child: pw.Row(children: [
          pw.SizedBox(
            width: 130,
            child: pw.Text(label, style: _style(9, color: _kGrey, bold: false)),
          ),
          pw.Text(value, style: _style(11, bold: true)),
        ]),
      );

  // ─── 이미지 그리드 ───────────────────────────────────────────────
  /// items: [{'label': 'δ Delta', 'image': pw.ImageProvider}, ...]
  pw.Widget _imageGrid(List<Map<String, dynamic>> items, {int cols = 4}) {
    if (items.isEmpty) return pw.SizedBox();
    final rows = <pw.Widget>[];
    for (var i = 0; i < items.length; i += cols) {
      final rowItems = items.skip(i).take(cols).toList();
      // 유효한 이미지만 렌더링 — 빈 칸 패딩 없이 실제 개수로 균등 분배
      rows.add(pw.Row(
        children: rowItems.map((item) => pw.Expanded(
          child: pw.Padding(
            padding: const pw.EdgeInsets.all(3),
            child: item['image'] != null
                ? pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Image(item['image'] as pw.ImageProvider,
                          height: 90, fit: pw.BoxFit.contain),
                      pw.SizedBox(height: 2),
                      pw.Text(item['label'] as String,
                          style: _style(7, color: _kGrey, bold: false),
                          textAlign: pw.TextAlign.center),
                    ],
                  )
                : pw.SizedBox(),
          ),
        )).toList(),
      ));
    }
    return pw.Column(children: rows);
  }

  /// 제목 + 부제 + 이미지 그리드를 하나의 블록으로 묶음
  pw.Widget _imageGroupBlock({
    required String title,
    required String subtitle,
    required List<Map<String, dynamic>> items,
    int cols = 4,
  }) {
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        decoration: const pw.BoxDecoration(
          border: pw.Border(left: pw.BorderSide(color: _kAccent, width: 3)),
          color: PdfColor.fromInt(0xFFF0FAF7),
        ),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(title, style: _style(10, color: _kTextDark, bold: true)),
          pw.Text(subtitle, style: _style(8, color: _kGrey, bold: false)),
        ]),
      ),
      pw.SizedBox(height: 6),
      _imageGrid(items, cols: cols),
    ]);
  }

  pw.Widget _disclaimer() => pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _kBorder),
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Text(
          '본 보고서는 AI 기반 임상 의사결정 지원 자료입니다. '
          '단독으로 진단의 근거가 되거나 치료적 결정을 대체하지 않으며, '
          '환자의 임상적 결정은 주치의의 종합적 판단에 따라야 합니다.',
          style: _style(8, color: _kGrey, bold: false),
        ),
      );

  pw.TextStyle _style(double size, {PdfColor? color, bool bold = true}) => pw.TextStyle(
        font: bold ? _bold : _regular,
        fontSize: size,
        color: color ?? _kTextDark,
      );

  String _f(dynamic v) {
    if (v == null) return 'N/A';
    try {
      final d = double.parse(v.toString());
      return d == d.roundToDouble() ? d.toInt().toString() : d.toStringAsFixed(1);
    } catch (_) {
      return v.toString();
    }
  }
}

extension _StrExt on String {
  String get capitalize => isEmpty ? this : this[0].toUpperCase() + substring(1);
}
