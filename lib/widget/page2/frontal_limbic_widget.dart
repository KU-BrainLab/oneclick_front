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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox(width: 20,),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  showDialog1(context, "$BASE_URL${model.delta}");
                },
                child: Image.network("$BASE_URL${model.delta}", width: 150, filterQuality: FilterQuality.high)),
            ),
            const Text("Delta"),
          ],
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  showDialog1(context, "$BASE_URL${model.theta}");
                },
                child: Image.network("$BASE_URL${model.theta}", width: 150, filterQuality: FilterQuality.high)),
            ),
            const Text("Theta"),
          ],
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  showDialog1(context, "$BASE_URL${model.alpha}");
                },
                child: Image.network("$BASE_URL${model.alpha}", width: 150, filterQuality: FilterQuality.high)),
            ),
            const Text("Alpha"),
          ],
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  showDialog1(context, "$BASE_URL${model.beta}");
                },
                child: Image.network("$BASE_URL${model.beta}", width: 150, filterQuality: FilterQuality.high)),
            ),
            const Text("Beta"),
          ],
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  showDialog1(context, "$BASE_URL${model.gamma}");
                },
                child: Image.network("$BASE_URL${model.gamma}", width: 150, filterQuality: FilterQuality.high)),
            ),
            const Text("Gamma"),
          ],
        ),
        const SizedBox(width: 20,),
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
