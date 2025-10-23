import 'package:flutter/material.dart';
import 'package:omnifit_front/constants/constants.dart';
import 'package:omnifit_front/models/page1_tab_model.dart';
import 'package:omnifit_front/widget/page1/frequency_domain_widget.dart';
import 'package:omnifit_front/widget/page1/time_domain_widget.dart';
import 'package:omnifit_front/widget/page1/default_line_chart.dart';


class Page1Tab1 extends StatelessWidget {
  final Page1TabModel page1TabModel;
  // final TimeDomainModel timeDomainModel;
  // final FrequencyDomainModel frequencyDomainModel;
  // final NonLinearModel nonLinearModel;
  // const Page1Tab1({Key? key, required this.timeDomainModel, required this.frequencyDomainModel, required this.nonLinearModel}) : super(key: key);
  const Page1Tab1({Key? key, required this.page1TabModel}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 30),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              TimeDomainWidget(model: page1TabModel),
              FrequencyDomainWidget(model: page1TabModel),
            ],
          ),
          const SizedBox(height: 50),
          DefaultLineChart(model: page1TabModel.graph1model),
          const SizedBox(height: 50),
          Row(
            children: [
              const SizedBox(width: 40),
              Expanded(
                child: Text(
                  'Heart Rate Heat Plot',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Image.network("$BASE_URL${page1TabModel.heart_rate}", width: 500),
          ),
          const SizedBox(height: 50),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Image.network("$BASE_URL${page1TabModel.comparison}", width: 500),
          ),
        ],
      ),
    );
  }
}