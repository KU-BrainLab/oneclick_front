import 'package:flutter/material.dart';
import 'package:omnifit_front/constants/constants.dart';
import 'package:omnifit_front/models/diff_stage_connectivity_model.dart';
import 'package:omnifit_front/models/diff_stage_topography_model.dart';

// diffStageTopoList[bandIndex][stageIndex]
// diffStageConnList[bandIndex][stageIndex]
// bands:  0=delta, 1=theta, 2=alpha, 3=sigma, 4=beta, 5=gamma
// stages: 0=WAKE,  1=N1,    2=N2,    3=N3,    4=REM

class DiffStageWidget extends StatefulWidget {
  final List<List<DiffStageTopographyModel>> diffStageTopoList;
  final List<List<DiffStageConnectivityModel>> diffStageConnList;

  const DiffStageWidget({
    super.key,
    required this.diffStageTopoList,
    required this.diffStageConnList,
  });

  @override
  State<DiffStageWidget> createState() => _DiffStageWidgetState();
}

class _DiffStageWidgetState extends State<DiffStageWidget> {
  static const _bands  = ['Delta', 'Theta', 'Alpha', 'Sigma', 'Beta', 'Gamma'];
  static const _stages = ['WAKE', 'N1', 'N2', 'N3', 'REM'];

  int _bandIndex  = 0;
  int _stageIndex = 0;

  Widget _tabButton(String label, int current, int target, void Function(int) onTap) {
    return MouseRegion(
      cursor: MaterialStateMouseCursor.clickable,
      child: GestureDetector(
        onTap: () => onTap(target),
        child: Container(
          decoration: BoxDecoration(
            color: current == target ? Colors.grey.withOpacity(0.4) : Colors.white,
            borderRadius: const BorderRadius.all(Radius.circular(4)),
            border: Border.all(color: Colors.black),
          ),
          width: 90,
          height: 30,
          child: Center(child: Text(label)),
        ),
      ),
    );
  }

  Widget _imageColumn(BuildContext context, String? path, String label) {
    if (path == null) return const SizedBox.shrink();
    final url = '$BASE_URL$path';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => _showDialog(context, url),
            child: Image.network(url, width: 150, filterQuality: FilterQuality.high),
          ),
        ),
        Text(label),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final topo = widget.diffStageTopoList.isNotEmpty
        ? widget.diffStageTopoList[_bandIndex][_stageIndex]
        : null;
    final conn = widget.diffStageConnList.isNotEmpty
        ? widget.diffStageConnList[_bandIndex][_stageIndex]
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Band tabs
        Row(
          children: List.generate(_bands.length, (i) =>
            _tabButton(_bands[i], _bandIndex, i, (v) => setState(() => _bandIndex = v)),
          ),
        ),
        const SizedBox(height: 4),
        // Stage tabs
        Row(
          children: List.generate(_stages.length, (i) =>
            _tabButton(_stages[i], _stageIndex, i, (v) => setState(() => _stageIndex = v)),
          ),
        ),
        const SizedBox(height: 8),
        // Images
        Container(
          decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 1)),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              if (topo != null) ...[
                const Text('Topography', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _imageColumn(context, topo.diff1, 'Stim1-Base'),
                    _imageColumn(context, topo.diff2, 'Rec1-Stim1'),
                    _imageColumn(context, topo.diff3, 'Stim2-Rec1'),
                    _imageColumn(context, topo.diff4, 'Rec2-Stim2'),
                  ],
                ),
              ],
              if (conn != null) ...[
                const SizedBox(height: 16),
                const Text('Connectivity', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _imageColumn(context, conn.diff1, 'Stim1-Base'),
                    _imageColumn(context, conn.diff2, 'Rec1-Stim1'),
                    _imageColumn(context, conn.diff3, 'Stim2-Rec1'),
                    _imageColumn(context, conn.diff4, 'Rec2-Stim2'),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _showDialog(BuildContext context, String image) {
    showDialog(
      context: context,
      builder: (context) => Container(
        color: Colors.black,
        child: Column(
          children: [
            Row(children: [
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(20),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.close, color: Colors.white, size: 30),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 20),
            SizedBox(width: 800, height: 800, child: Center(child: Image.network(image))),
          ],
        ),
      ),
    );
  }
}
