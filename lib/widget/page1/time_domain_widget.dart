import 'package:flutter/material.dart';
import 'package:omnifit_front/models/page1_tab_model.dart';

class TimeDomainWidget extends StatelessWidget {
  final Page1TabModel model;
  const TimeDomainWidget({Key? key, required this.model}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Column(
        children: [
          Container(
            decoration: const BoxDecoration(color: Colors.cyan, borderRadius: BorderRadius.all(Radius.circular(8))),
            height: 30,
            child: const Center(child: Text("Time-Domain", style: TextStyle(color: Colors.white, fontSize: 14))),
          ),
          Row(
            children: [
              const Text("sdnn"),
              const Spacer(),
              Text(model.sdnn.toStringAsFixed(2)),
            ],
          ),
          Row(
            children: [
              const Text("rmssd"),
              const Spacer(),
              Text(model.rmssd.toStringAsFixed(2)),
            ],
          ),
          Row(
            children: [
              const Text("sdsd"),
              const Spacer(),
              Text(model.sdsd.toStringAsFixed(2)),
            ],
          ),
          Row(
            children: [
              const Text("nn50"),
              const Spacer(),
              Text(model.nn50.toStringAsFixed(2)),
            ],
          ),
          Row(
            children: [
              const Text("pnn50"),
              const Spacer(),
              Text(model.pnn50.toStringAsFixed(2)),
            ],
          ),
          Row(
            children: [
              const Text("tri-index"),
              const Spacer(),
              Text(model.tri_index.toStringAsFixed(2)),
            ],
          ),
        ],
      ),
    );
  }
}
