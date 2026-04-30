import 'package:flutter/material.dart';
import 'package:omnifit_front/constants/constants.dart';
import 'package:omnifit_front/models/faa_model.dart';

class FaaWidget extends StatelessWidget {
  final FaaModel model;
  final bool hasPhase45;
  const FaaWidget({super.key, required this.model, this.hasPhase45 = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 1)),
          height: hasPhase45 ? 200 : 280,
          width: double.infinity,
          child: _buildTab(context),
        ),
      ],
    );
  }

  Widget _phaseColumn(BuildContext context, String label, String? path, double imgWidth) {
    if (path == null || path.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(width: imgWidth, height: imgWidth, child: const Center(child: Text("No data"))),
          Text(label),
        ],
      );
    }
    final url = "$BASE_URL$path";
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => showDialog1(context, url),
            child: Image.network(url, width: imgWidth, filterQuality: FilterQuality.high,
              errorBuilder: (_, __, ___) =>
                SizedBox(width: imgWidth, height: imgWidth, child: const Center(child: Text("No data"))),
            ),
          ),
        ),
        Text(label),
      ],
    );
  }

  Widget _buildTab(BuildContext context) {
    final double imgWidth = hasPhase45 ? 159.0 : 240.0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox(width: 20),
        _phaseColumn(context, "Baseline",     model.faa_baseline,     imgWidth),
        _phaseColumn(context, "Stimulation1", model.faa_stimulation1, imgWidth),
        _phaseColumn(context, "Recovery1",    model.faa_recovery1,    imgWidth),
        if (hasPhase45) _phaseColumn(context, "Stimulation2", model.faa_stimulation2, imgWidth),
        if (hasPhase45) _phaseColumn(context, "Recovery2",    model.faa_recovery2,    imgWidth),
        const SizedBox(width: 20),
      ],
    );
  }


  void showDialog1(BuildContext context, String image) {

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Container(
          color: Colors.black,
          child: Column(
            children: [
              Row(
                children: [
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                          },
                          child: const Icon(Icons.close, color: Colors.white, size: 30)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: 800,
                height: 800,
                child: Center(child: Image.network(image)),
              ),
            ],
          ),
        );
      },
    );
  }
}
