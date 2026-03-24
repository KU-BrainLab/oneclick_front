import 'package:flutter/material.dart';
import 'package:omnifit_front/constants/constants.dart';
import 'package:omnifit_front/models/psd_spectrogram_model.dart';

class PsdSpectrogramWidget extends StatelessWidget {
  final PsdSpectrogramModel model;
  const PsdSpectrogramWidget({super.key, required this.model});

  static const _channels = [
    ('cz',  'Cz'),
    ('c3',  'C3'),
    ('c4',  'C4'),
    ('fp1', 'Fp1'),
    ('fp2', 'Fp2'),
    ('f3',  'F3'),
    ('f4',  'F4'),
    ('f7',  'F7'),
    ('f8',  'F8'),
    ('t3',  'T3'),
    ('t4',  'T4'),
    ('p3',  'P3'),
    ('p4',  'P4'),
  ];

  String? _getUrl(String key) {
    switch (key) {
      case 'cz':  return model.cz;
      case 'c3':  return model.c3;
      case 'c4':  return model.c4;
      case 'fp1': return model.fp1;
      case 'fp2': return model.fp2;
      case 'f3':  return model.f3;
      case 'f4':  return model.f4;
      case 'f7':  return model.f7;
      case 'f8':  return model.f8;
      case 't3':  return model.t3;
      case 't4':  return model.t4;
      case 'p3':  return model.p3;
      case 'p4':  return model.p4;
      default:    return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _channels
        .where((ch) => _getUrl(ch.$1) != null)
        .toList();

    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 1)),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: items.map((ch) {
          final url = '$BASE_URL${_getUrl(ch.$1)}';
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => _showDialog(context, url),
                  child: Image.network(url, width: 150, filterQuality: FilterQuality.high),
                ),
              ),
              Text(ch.$2),
            ],
          );
        }).toList(),
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
            SizedBox(width: 800, height: 800, child: Center(child: Image.network(image))),
          ],
        ),
      ),
    );
  }
}
