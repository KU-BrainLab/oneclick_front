import 'package:flutter/material.dart';
import 'package:omnifit_front/constants/constants.dart';
import 'package:omnifit_front/models/diff_topography_model.dart';
import 'package:omnifit_front/models/topography_model.dart';

class BsrsrChartWidget extends StatefulWidget {
  final List<TopographyModel> topographyList;
  final List<DiffTopographyModel> diffTopographyList;
  final int phaseCount;
  const BsrsrChartWidget({Key? key, required this.topographyList, required this.diffTopographyList, this.phaseCount = 5}) : super(key: key);

  @override
  State<BsrsrChartWidget> createState() => _BsrsrChartWidgetState();
}

class _BsrsrChartWidgetState extends State<BsrsrChartWidget> {

  int index = 0;

  static const _bandLabels = ['Delta', 'Theta', 'Alpha', 'Sigma', 'Beta', 'Gamma'];
  static const _oneBandImgWidth = 120.0;

  @override
  Widget build(BuildContext context) {
    if (widget.phaseCount == 1) {
      return _buildAllBandsView();
    }
    return Column(
      children: [
        Row(
          children: [
            _tabButton("Delta", 0),
            _tabButton("Theta", 1),
            _tabButton("Alpha", 2),
            _tabButton("Sigma", 3),
            _tabButton("Beta", 4),
            _tabButton("Gamma", 5),
          ],
        ),
        Container(
          decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 1)),
          width: double.infinity,
          child: _buildTab(),
        ),
      ],
    );
  }

  Widget _tabButton(String label, int i) {
    return MouseRegion(
      cursor: MaterialStateMouseCursor.clickable,
      child: GestureDetector(
        onTap: () => setState(() => index = i),
        child: Container(
          decoration: BoxDecoration(
            color: index == i ? Colors.grey.withOpacity(0.4) : Colors.white,
            borderRadius: const BorderRadius.all(Radius.circular(4)),
            border: Border.all(color: Colors.black),
          ),
          width: 100,
          height: 30,
          child: Center(child: Text(label)),
        ),
      ),
    );
  }

  // 1-phase: 6개 대역 한 번에 표시 (1×6)
  Widget _buildAllBandsView() {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 1)),
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (int i = 0; i < _bandLabels.length; i++)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_bandLabels[i],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  _networkImage(widget.topographyList[i].baseline, width: _oneBandImgWidth),
                  const Text("Baseline"),
                ],
              ),
          ],
        ),
      ),
    );
  }

  double get _imgWidth => widget.phaseCount >= 5 ? 130.0 : 190.0;

  Widget _buildTab() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(width: 20),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _networkImage(widget.topographyList[index].baseline),
                const Text("Baseline"),
              ],
            ),
            if (widget.phaseCount >= 3) Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _networkImage(widget.topographyList[index].stimulation1),
                const Text("Stimulation1"),
              ],
            ),
            if (widget.phaseCount >= 3) Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _networkImage(widget.topographyList[index].recovery1),
                const Text("Recovery1"),
              ],
            ),
            if (widget.phaseCount >= 5) Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _networkImage(widget.topographyList[index].stimulation2),
                const Text("Stimulation2"),
              ],
            ),
            if (widget.phaseCount >= 5) Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _networkImage(widget.topographyList[index].recovery2),
                const Text("Recovery2"),
              ],
            ),
            const SizedBox(width: 20),
          ],
        ),
        if(widget.diffTopographyList.isNotEmpty && widget.phaseCount >= 3) const SizedBox(height: 20),
        if(widget.diffTopographyList.isNotEmpty && widget.phaseCount >= 3)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 20),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _networkImage(widget.diffTopographyList[index].diff1),
                  const Text("Stimulation1-Baseline"),
                ],
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _networkImage(widget.diffTopographyList[index].diff2),
                  const Text("Recovery1-Stimulation1"),
                ],
              ),
              if (widget.phaseCount >= 5) Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _networkImage(widget.diffTopographyList[index].diff3),
                  const Text("Stimulation2-Recovery1"),
                ],
              ),
              if (widget.phaseCount >= 5) Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _networkImage(widget.diffTopographyList[index].diff4),
                  const Text("Recovery2-Stimulation2"),
                ],
              ),
              const SizedBox(width: 20),
            ],
          ),
      ],
    );
  }

  Widget _networkImage(String? path, {double? width}) {
    final w = width ?? _imgWidth;
    if (path == null) {
      return SizedBox(width: w, height: w, child: const Center(child: Text("No data")));
    }
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => showDialog1(context, "$BASE_URL$path"),
        child: Image.network(
            "$BASE_URL$path",
            width: w,
            filterQuality: FilterQuality.high,
            errorBuilder: (context, error, stackTrace) =>
              SizedBox(width: w, height: w, child: const Center(child: Text("No data"))),
          ),
      ),
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
