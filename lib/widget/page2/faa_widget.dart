import 'package:flutter/material.dart';
import 'package:omnifit_front/constants/constants.dart';
import 'package:omnifit_front/models/faa_model.dart';

class FaaWidget extends StatelessWidget {
  final FaaModel model;
  const FaaWidget({super.key, required this.model});

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
                  showDialog1(context, "$BASE_URL${model.faa_baseline}");
                },
                child: Image.network("$BASE_URL${model.faa_baseline}", width: 159, filterQuality: FilterQuality.high)),
            ),
            const Text("Baseline"),
          ],
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  showDialog1(context, "$BASE_URL${model.faa_stimulation1}");
                },
                child: Image.network("$BASE_URL${model.faa_stimulation1}", width: 159, filterQuality: FilterQuality.high)),
            ),
            const Text("Stimulation1"),
          ],
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  showDialog1(context, "$BASE_URL${model.faa_recovery1}");
                },
                child: Image.network("$BASE_URL${model.faa_recovery1}", width: 159, filterQuality: FilterQuality.high)),
            ),
            const Text("Recovery1"),
          ],
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  showDialog1(context, "$BASE_URL${model.faa_stimulation2}");
                },
                child: Image.network("$BASE_URL${model.faa_stimulation2}", width: 159, filterQuality: FilterQuality.high)),
            ),
            const Text("Stimulation2"),
          ],
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  showDialog1(context, "$BASE_URL${model.faa_recovery2}");
                },
                child: Image.network("$BASE_URL${model.faa_recovery2}", width: 159, filterQuality: FilterQuality.high)),
            ),
            const Text("Recovery2"),
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
