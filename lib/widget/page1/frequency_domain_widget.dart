import 'package:flutter/material.dart';
import 'package:omnifit_front/models/page1_tab_model.dart';

class FrequencyDomainWidget extends StatelessWidget {
  final Page1TabModel model;
  const FrequencyDomainWidget({Key? key, required this.model}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Column(
        children: [
          Container(
            decoration: const BoxDecoration(color: Colors.cyan, borderRadius: BorderRadius.all(Radius.circular(8))),
            height: 30,
            child: const Center(child: Text("Frequency-Domain", style: TextStyle(color: Colors.white, fontSize: 14))),
          ),
          Row(
            children: [
              const Text("vlf-rel-power"),
              const Spacer(),
              Text(model.vlf_rel_power.toStringAsFixed(2)),
            ],
          ),
          Row(
            children: [
              const Text("lf-rel-power"),
              const Spacer(),
              Text(model.lf_rel_power.toStringAsFixed(2)),
            ],
          ),
          Row(
            children: [
              const Text("hf-rel-power"),
              const Spacer(),
              Text(model.hf_rel_power.toStringAsFixed(2)),
            ],
          ),
          Row(
            children: [
              const Text("lh-ratio"),
              const Spacer(),
              Text(model.lh_ratio.toStringAsFixed(2)),
            ],
          ),
          Row(
            children: [
              const Text("norm-lf"),
              const Spacer(),
              Text(model.norm_lf.toStringAsFixed(2)),
            ],
          ),
          Row(
            children: [
              const Text("norm-hf"),
              const Spacer(),
              Text(model.norm_hf.toStringAsFixed(2)),
            ],
          ),
        ],
      ),
    );
  }
}
