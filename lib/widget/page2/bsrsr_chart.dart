import 'package:flutter/material.dart';
import 'package:omnifit_front/constants/constants.dart';
import 'package:omnifit_front/models/diff_topography_model.dart';
import 'package:omnifit_front/models/topography_model.dart';

class BsrsrChartWidget extends StatefulWidget {
  final List<TopographyModel> topographyList;
  final List<DiffTopographyModel> diffTopographyList;
  const BsrsrChartWidget({Key? key, required this.topographyList, required this.diffTopographyList}) : super(key: key);

  @override
  State<BsrsrChartWidget> createState() => _BsrsrChartWidgetState();
}

class _BsrsrChartWidgetState extends State<BsrsrChartWidget> {

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
                  child: Center(child: Text("Beta")),
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
                  child: Center(child: Text("Gamma")),
                ),
              ),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 1)),
          height: widget.diffTopographyList.isEmpty ? 200 : 400,
          width: double.infinity,
          child: _buildTab(),
        ),
      ],
    );
  }

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
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      showDialog1(context, "$BASE_URL${widget.topographyList[index].baseline}");
                    },
                    child: Image.network("$BASE_URL${widget.topographyList[index].baseline}", width: 150, filterQuality: FilterQuality.high)),
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
                      showDialog1(context, "$BASE_URL${widget.topographyList[index].stimulation1}");
                    },
                    child: Image.network("$BASE_URL${widget.topographyList[index].stimulation1}", width: 150, filterQuality: FilterQuality.high)),
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
                      showDialog1(context, "$BASE_URL${widget.topographyList[index].recovery1}");
                    },
                    child: Image.network("$BASE_URL${widget.topographyList[index].recovery1}", width: 150, filterQuality: FilterQuality.high)),
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
                      showDialog1(context, "$BASE_URL${widget.topographyList[index].stimulation2}");
                    },
                    child: Image.network("$BASE_URL${widget.topographyList[index].stimulation2}", width: 150, filterQuality: FilterQuality.high)),
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
                      showDialog1(context, "$BASE_URL${widget.topographyList[index].recovery2}");
                    },
                    child: Image.network("$BASE_URL${widget.topographyList[index].recovery2}", width: 150, filterQuality: FilterQuality.high)),
                ),
                Text("Recovery2"),
              ],
            ),
            const SizedBox(width: 20),
          ],
        ),
        if(widget.diffTopographyList.isNotEmpty) const SizedBox(height: 20),
        if(widget.diffTopographyList.isNotEmpty)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 20),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                        onTap: () {
                          showDialog1(context, "$BASE_URL${widget.diffTopographyList[index].diff1}");
                        },
                        child: Image.network("$BASE_URL${widget.diffTopographyList[index].diff1}", width: 150, filterQuality: FilterQuality.high)),
                  ),
                  const Text("Stimulation1-Baseline"),
                ],
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                        onTap: () {
                          showDialog1(context, "$BASE_URL${widget.diffTopographyList[index].diff2}");
                        },
                        child: Image.network("$BASE_URL${widget.diffTopographyList[index].diff2}", width: 150, filterQuality: FilterQuality.high)),
                  ),
                  const Text("Recovery1-Stimulation1"),
                ],
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                        onTap: () {
                          showDialog1(context, "$BASE_URL${widget.diffTopographyList[index].diff3}");
                        },
                        child: Image.network("$BASE_URL${widget.diffTopographyList[index].diff3}", width: 150, filterQuality: FilterQuality.high)),
                  ),
                  const Text("Stimulation2-Recovery1"),
                ],
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                        onTap: () {
                          showDialog1(context, "$BASE_URL${widget.diffTopographyList[index].diff4}");
                        },
                        child: Image.network("$BASE_URL${widget.diffTopographyList[index].diff4}", width: 150, filterQuality: FilterQuality.high)),
                  ),
                  const Text("Recovery2-Stimulation2"),
                ],
              ),
              const SizedBox(width: 20),
            ],
          ),
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
