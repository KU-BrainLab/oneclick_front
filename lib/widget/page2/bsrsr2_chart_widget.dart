import 'package:flutter/material.dart';
import 'package:omnifit_front/constants/constants.dart';
import 'package:omnifit_front/models/connectivity2_model.dart';
import 'package:omnifit_front/models/diff_connectivity2_model.dart';

class Bsrsr2ChartWidget extends StatefulWidget {
  final List<Connectivity2Model> connectivityList;
  final List<DiffConnectivity2Model> diffConnectivityList;
  final bool hasPhase45;
  const Bsrsr2ChartWidget({Key? key, required this.connectivityList, required this.diffConnectivityList, this.hasPhase45 = true}) : super(key: key);

  @override
  State<Bsrsr2ChartWidget> createState() => _Bsrsr2ChartWidgetState();
}

class _Bsrsr2ChartWidgetState extends State<Bsrsr2ChartWidget> {

  int index = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            MouseRegion(
              cursor: MaterialStateMouseCursor.clickable,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    index = 0;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                      color: index == 0 ? Colors.grey.withOpacity(0.4) : Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                      border: Border.all(color: Colors.black)
                  ),
                  width: 100,
                  height: 30,
                  child: Center(child: Text("Delta")),
                ),
              ),
            ),
            MouseRegion(
              cursor: MaterialStateMouseCursor.clickable,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    index = 1;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                      color: index == 1 ? Colors.grey.withOpacity(0.4) : Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                      border: Border.all(color: Colors.black)
                  ),
                  width: 100,
                  height: 30,
                  child: Center(child: Text("Theta")),
                ),
              ),
            ),
            MouseRegion(
              cursor: MaterialStateMouseCursor.clickable,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    index = 2;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                      color: index == 2 ? Colors.grey.withOpacity(0.4) : Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                      border: Border.all(color: Colors.black)
                  ),
                  width: 100,
                  height: 30,
                  child: Center(child: Text("Alpha")),
                ),
              ),
            ),
            MouseRegion(
              cursor: MaterialStateMouseCursor.clickable,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    index = 3;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                      color: index == 3 ? Colors.grey.withOpacity(0.4) : Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                      border: Border.all(color: Colors.black)
                  ),
                  width: 100,
                  height: 30,
                  child: Center(child: Text("Sigma")),
                ),
              ),
            ),
            MouseRegion(
              cursor: MaterialStateMouseCursor.clickable,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    index = 4;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                      color: index == 4 ? Colors.grey.withOpacity(0.4) : Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                      border: Border.all(color: Colors.black)
                  ),
                  width: 100,
                  height: 30,
                  child: Center(child: Text("Beta")),
                ),
              ),
            ),
            MouseRegion(
              cursor: MaterialStateMouseCursor.clickable,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    index = 5;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                      color: index == 5 ? Colors.grey.withOpacity(0.4) : Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                      border: Border.all(color: Colors.black)
                  ),
                  width: 100,
                  height: 30,
                  child: Center(child: Text("Gamma")),
                ),
              ),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 1)),
          height: widget.diffConnectivityList.isEmpty
              ? _imgWidth + 40
              : _imgWidth * 2 + 80,
          width: double.infinity,
          child: _buildTab(),
        ),
      ],
    );
  }

  double get _imgWidth => widget.hasPhase45 ? 150.0 : 230.0;

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
                _networkImage(widget.connectivityList[index].baseline),
                const Text("Baseline"),
              ],
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _networkImage(widget.connectivityList[index].stimulation1),
                const Text("Stimulation1"),
              ],
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _networkImage(widget.connectivityList[index].recovery1),
                const Text("Recovery1"),
              ],
            ),
            if (widget.hasPhase45) Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _networkImage(widget.connectivityList[index].stimulation2),
                const Text("Stimulation2"),
              ],
            ),
            if (widget.hasPhase45) Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _networkImage(widget.connectivityList[index].recovery2),
                const Text("Recovery2"),
              ],
            ),
            const SizedBox(width: 20),
          ],
        ),
        if(widget.diffConnectivityList.isNotEmpty) const SizedBox(height: 20),
        if(widget.diffConnectivityList.isNotEmpty)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 20),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _networkImage(widget.diffConnectivityList[index].diff1),
                  const Text("Stimulation1-Baseline"),
                ],
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _networkImage(widget.diffConnectivityList[index].diff2),
                  const Text("Recovery1-Stimulation1"),
                ],
              ),
              if (widget.hasPhase45) Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _networkImage(widget.diffConnectivityList[index].diff3),
                  const Text("Stimulation2-Recovery1"),
                ],
              ),
              if (widget.hasPhase45) Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _networkImage(widget.diffConnectivityList[index].diff4),
                  const Text("Recovery2-Stimulation2"),
                ],
              ),
              const SizedBox(width: 20),
            ],
          )
      ],
    );
  }

  Widget _networkImage(String? path) {
    final w = _imgWidth;
    if (path == null) {
      return SizedBox(width: w, height: w, child: const Center(child: Text("No data")));
    }
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => showDialog1(context, "$BASE_URL$path"),
        child: Image.network("$BASE_URL$path", width: w, filterQuality: FilterQuality.high,
          errorBuilder: (_, __, ___) =>
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
