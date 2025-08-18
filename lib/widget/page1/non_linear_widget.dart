import 'package:flutter/material.dart';
import 'package:omnifit_front/models/non_linear_model.dart';

class NonLinearWidget extends StatelessWidget {
  final NonLinearModel nonLinearModel;
  const NonLinearWidget({Key? key, required this.nonLinearModel}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Column(
        children: [
          Container(
            decoration: const BoxDecoration(color: Colors.cyan, borderRadius: BorderRadius.all(Radius.circular(8))),
            height: 30,
            child: const Center(child: Text("Non-Linear", style: TextStyle(color: Colors.white, fontSize: 14))),
          ),
          Row(
            children: [
              const Text("SD1(ms)", textAlign: TextAlign.center),
              const Spacer(),
              Text("${nonLinearModel.sd1}", textAlign: TextAlign.center),
            ],
          ),
          Row(
            children: [
              const Text("SD2(ms)", textAlign: TextAlign.center),
              const Spacer(),
              Text("${nonLinearModel.sd2}"),
            ],
          ),
          Row(
            children: [
              const Text("SD1/SD2", textAlign: TextAlign.center),
              const Spacer(),
              Text("${nonLinearModel.sd1_sd2_ratio}", textAlign: TextAlign.center),
            ],
          ),
        ],
      ),
    );
  }
}
