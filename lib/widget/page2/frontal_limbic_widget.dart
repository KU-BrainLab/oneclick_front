import 'package:flutter/material.dart';
import 'package:omnifit_front/constants/constants.dart';
import 'package:omnifit_front/models/frontal_limbic_model.dart';

class FrontalLimbicWidget extends StatelessWidget {
  final FrontalLimbicModel model;
  const FrontalLimbicWidget({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 1)),
          height: 200,
          width: double.infinity,
          child: _buildTab(context),
        ),
      ],
    );
  }

  Widget _buildTab(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final colCount = model.sigma != null ? 6 : 5;
        final imgWidth = (constraints.maxWidth / colCount).clamp(0.0, 130.0);
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _imgCol(context, model.delta, "Delta", imgWidth),
            _imgCol(context, model.theta, "Theta", imgWidth),
            _imgCol(context, model.alpha, "Alpha", imgWidth),
            if (model.sigma != null)
              _imgCol(context, model.sigma!, "Sigma", imgWidth),
            _imgCol(context, model.beta, "Beta", imgWidth),
            _imgCol(context, model.gamma, "Gamma", imgWidth),
          ],
        );
      },
    );
  }

  Widget _imgCol(BuildContext context, String? path, String label, double width) {
    if (path == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(width: width, height: width, child: const Center(child: Text("No data"))),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => showDialog1(context, "$BASE_URL$path"),
            child: Image.network(
              "$BASE_URL$path",
              width: width,
              filterQuality: FilterQuality.high,
              errorBuilder: (context, error, stackTrace) =>
                SizedBox(width: width, height: width, child: const Center(child: Text("No data"))),
            ),
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 11)),
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
