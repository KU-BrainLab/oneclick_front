import 'package:flutter/material.dart';
import 'package:omnifit_front/constants/constants.dart';
import 'package:omnifit_front/models/diff_connectivity_model.dart';

class DiffConnectivityWidget extends StatefulWidget {
  final List<DiffConnectivityModel> list;
  const DiffConnectivityWidget({Key? key, required this.list}) : super(key: key);

  @override
  State<DiffConnectivityWidget> createState() => _DiffConnectivityWidgetState();
}

class _DiffConnectivityWidgetState extends State<DiffConnectivityWidget> {

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
          height: 200,
          width: double.infinity,
          child: _buildTab(),
        ),
      ],
    );
  }

  Widget _buildTab() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                  onTap: () {
                    showDialog1(context, "$BASE_URL${widget.list[index].diff1}");
                  },
                  child: Image.network("$BASE_URL${widget.list[index].diff1}", width: 150, filterQuality: FilterQuality.high)),
            ),
            const Text("Diff1"),
          ],
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                  onTap: () {
                    showDialog1(context, "$BASE_URL${widget.list[index].diff2}");
                  },
                  child: Image.network("$BASE_URL${widget.list[index].diff2}", width: 150, filterQuality: FilterQuality.high)),
            ),
            const Text("Diff2"),
          ],
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                  onTap: () {
                    showDialog1(context, "$BASE_URL${widget.list[index].diff3}");
                  },
                  child: Image.network("$BASE_URL${widget.list[index].diff3}", width: 150, filterQuality: FilterQuality.high)),
            ),
            const Text("Diff3"),
          ],
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                  onTap: () {
                    showDialog1(context, "$BASE_URL${widget.list[index].diff4}");
                  },
                  child: Image.network("$BASE_URL${widget.list[index].diff4}", width: 150, filterQuality: FilterQuality.high)),
            ),
            const Text("Diff4"),
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
