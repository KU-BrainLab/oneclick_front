import 'package:flutter/material.dart';
import 'package:omnifit_front/constants/constants.dart';
import 'package:omnifit_front/models/diff_stage_connectivity_model.dart';
import 'package:omnifit_front/models/diff_stage_topography_model.dart';

// diffStageTopoList[bandIndex][stageIndex]
// diffStageConnList[bandIndex][stageIndex]
// phases: 0=Stim1-Base, 1=Rec1-Stim1, 2=Stim2-Rec1, 3=Rec2-Stim2
// stages: 0=WAKE, 1=N1, 2=N2, 3=N3, 4=REM
// bands:  0=delta, 1=theta, 2=alpha, 3=sigma, 4=beta, 5=gamma

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
  static const _phases = ['Stim1-Base', 'Rec1-Stim1', 'Stim2-Rec1', 'Rec2-Stim2'];
  static const _stages = ['WAKE', 'N1', 'N2', 'N3', 'REM'];
  static const _bands  = ['Delta', 'Theta', 'Alpha', 'Sigma', 'Beta', 'Gamma'];

  int _phaseIndex = 0;
  int _stageIndex = 0;

  String? _getPhaseField(DiffStageTopographyModel m) {
    switch (_phaseIndex) {
      case 0: return m.diff1;
      case 1: return m.diff2;
      case 2: return m.diff3;
      case 3: return m.diff4;
      default: return null;
    }
  }

  String? _getPhaseFieldConn(DiffStageConnectivityModel m) {
    switch (_phaseIndex) {
      case 0: return m.diff1;
      case 1: return m.diff2;
      case 2: return m.diff3;
      case 3: return m.diff4;
      default: return null;
    }
  }

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
          width: 100,
          height: 30,
          child: Center(child: Text(label, style: const TextStyle(fontSize: 12))),
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
            child: Image.network(
              url,
              width: 130,
              filterQuality: FilterQuality.high,
              errorBuilder: (context, error, stackTrace) =>
                const SizedBox(width: 130, height: 130, child: Center(child: Text("No data"))),
            ),
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasTopo = widget.diffStageTopoList.isNotEmpty;
    final hasConn = widget.diffStageConnList.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Phase tabs
        Wrap(
          children: List.generate(_phases.length, (i) =>
            _tabButton(_phases[i], _phaseIndex, i, (v) => setState(() => _phaseIndex = v)),
          ),
        ),
        const SizedBox(height: 4),
        // Stage tabs
        Wrap(
          children: List.generate(_stages.length, (i) =>
            _tabButton(_stages[i], _stageIndex, i, (v) => setState(() => _stageIndex = v)),
          ),
        ),
        const SizedBox(height: 8),
        // Images — 6 bands
        Container(
          decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 1)),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              if (hasTopo) ...[
                const Text('Topography', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(_bands.length, (bi) =>
                    _imageColumn(
                      context,
                      _getPhaseField(widget.diffStageTopoList[bi][_stageIndex]),
                      _bands[bi],
                    ),
                  ),
                ),
              ],
              if (hasConn) ...[
                const SizedBox(height: 16),
                const Text('Connectivity', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(_bands.length, (bi) =>
                    _imageColumn(
                      context,
                      _getPhaseFieldConn(widget.diffStageConnList[bi][_stageIndex]),
                      _bands[bi],
                    ),
                  ),
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
