import 'package:flutter/material.dart';
import 'package:omnifit_front/constants/constants.dart';
import 'package:omnifit_front/models/psd_spectrogram_model.dart';

class PsdSpectrogramWidget extends StatefulWidget {
  final PsdSpectrogramModel model;
  const PsdSpectrogramWidget({super.key, required this.model});

  @override
  State<PsdSpectrogramWidget> createState() => _PsdSpectrogramWidgetState();
}

class _PsdSpectrogramWidgetState extends State<PsdSpectrogramWidget> {
  String _selected = 'cz';

  // Normalized (x, y) positions within a 1.0×1.0 head bounding box.
  // Nose at top (y=0), occipital at bottom (y=1).
  static const Map<String, Offset> _chPos = {
    'fp1': Offset(0.37, 0.14),
    'fp2': Offset(0.63, 0.14),
    'f7':  Offset(0.14, 0.32),
    'f3':  Offset(0.36, 0.29),
    'f4':  Offset(0.64, 0.29),
    'f8':  Offset(0.86, 0.32),
    't3':  Offset(0.07, 0.50),
    'c3':  Offset(0.31, 0.50),
    'cz':  Offset(0.50, 0.50),
    'c4':  Offset(0.69, 0.50),
    't4':  Offset(0.93, 0.50),
    'p3':  Offset(0.34, 0.71),
    'p4':  Offset(0.66, 0.71),
  };

  static const Map<String, String> _chLabel = {
    'fp1': 'Fp1', 'fp2': 'Fp2',
    'f7':  'F7',  'f3':  'F3',  'f4': 'F4',  'f8': 'F8',
    't3':  'T3',  'c3':  'C3',  'cz': 'Cz',  'c4': 'C4', 't4': 'T4',
    'p3':  'P3',  'p4':  'P4',
  };

  String? _getUrl(String key) {
    switch (key) {
      case 'cz':  return widget.model.cz;
      case 'c3':  return widget.model.c3;
      case 'c4':  return widget.model.c4;
      case 'fp1': return widget.model.fp1;
      case 'fp2': return widget.model.fp2;
      case 'f3':  return widget.model.f3;
      case 'f4':  return widget.model.f4;
      case 'f7':  return widget.model.f7;
      case 'f8':  return widget.model.f8;
      case 't3':  return widget.model.t3;
      case 't4':  return widget.model.t4;
      case 'p3':  return widget.model.p3;
      case 'p4':  return widget.model.p4;
      default:    return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    const headSize = 240.0;
    const btnW = 34.0;
    const btnH = 22.0;
    final url = _getUrl(_selected);

    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 1)),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'EEG Spectrogram',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          const Text(
            '채널 버튼을 클릭하면 해당 채널의 스펙트로그램을 볼 수 있습니다.',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          // Brain diagram with channel buttons
          SizedBox(
            width: headSize,
            height: headSize * 1.08,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _HeadOutlinePainter()),
                ),
                ..._chPos.entries.map((e) {
                  final ch = e.key;
                  final pos = e.value;
                  final hasData = _getUrl(ch) != null;
                  final isSelected = _selected == ch;
                  return Positioned(
                    left: pos.dx * headSize - btnW / 2,
                    top: pos.dy * headSize * 1.08 - btnH / 2,
                    child: MouseRegion(
                      cursor: hasData
                          ? SystemMouseCursors.click
                          : MouseCursor.defer,
                      child: GestureDetector(
                        onTap: hasData
                            ? () => setState(() => _selected = ch)
                            : null,
                        child: Container(
                          width: btnW,
                          height: btnH,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.blue.withOpacity(0.85)
                                : (hasData
                                    ? Colors.white
                                    : Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.blue
                                  : (hasData
                                      ? Colors.black87
                                      : Colors.grey.shade400),
                              width: isSelected ? 1.8 : 1.0,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _chLabel[ch] ?? ch.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : (hasData
                                        ? Colors.black87
                                        : Colors.grey),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${_chLabel[_selected] ?? _selected.toUpperCase()} Channel',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          if (url != null)
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => _showDialog(context, '$BASE_URL$url'),
                child: Image.network(
                  '$BASE_URL$url',
                  width: double.infinity,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (context, error, stackTrace) => const SizedBox(
                    height: 100,
                    child: Center(child: Text('No spectrogram data')),
                  ),
                ),
              ),
            )
          else
            const SizedBox(
              height: 100,
              child: Center(child: Text('No data for this channel')),
            ),
        ],
      ),
    );
  }

  void _showDialog(BuildContext context, String image) {
    showDialog(
      context: context,
      builder: (context) => Container(
        color: Colors.black,
        child: Column(
          children: [
            Row(children: [
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(20),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.close, color: Colors.white, size: 30),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 20),
            Expanded(child: Center(child: Image.network(image))),
          ],
        ),
      ),
    );
  }
}

class _HeadOutlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    // Head oval center (offset slightly down to leave room for nose above)
    final cy = h * 0.50;
    final rx = w * 0.44;
    final ry = h * 0.46;

    // Head oval
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2),
      paint,
    );

    // Nose (at top)
    final nosePath = Path()
      ..moveTo(cx - w * 0.06, cy - ry + h * 0.04)
      ..lineTo(cx, cy - ry - h * 0.04)
      ..lineTo(cx + w * 0.06, cy - ry + h * 0.04);
    canvas.drawPath(nosePath, paint);

    // Left ear
    final lEar = Path()
      ..moveTo(cx - rx, cy - h * 0.06)
      ..lineTo(cx - rx - w * 0.035, cy - h * 0.02)
      ..lineTo(cx - rx - w * 0.04, cy)
      ..lineTo(cx - rx - w * 0.035, cy + h * 0.02)
      ..lineTo(cx - rx, cy + h * 0.06);
    canvas.drawPath(lEar, paint);

    // Right ear
    final rEar = Path()
      ..moveTo(cx + rx, cy - h * 0.06)
      ..lineTo(cx + rx + w * 0.035, cy - h * 0.02)
      ..lineTo(cx + rx + w * 0.04, cy)
      ..lineTo(cx + rx + w * 0.035, cy + h * 0.02)
      ..lineTo(cx + rx, cy + h * 0.06);
    canvas.drawPath(rEar, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
