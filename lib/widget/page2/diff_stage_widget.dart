import 'package:flutter/material.dart';
import 'package:omnifit_front/models/phase_defs.dart';
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
  final int phaseCount;

  const DiffStageWidget({
    super.key,
    required this.diffStageTopoList,
    required this.diffStageConnList,
    this.phaseCount = 5,
  });

  @override
  State<DiffStageWidget> createState() => _DiffStageWidgetState();
}

class _DiffStageWidgetState extends State<DiffStageWidget> {
  static const _allPhases = ['Stim1-Base', 'Rec1-Stim1', 'Stim2-Rec1', 'Rec2-Stim2'];
  static const _stages = ['WAKE', 'N1', 'N2', 'N3', 'REM'];
  static const _bands  = ['Delta', 'Theta', 'Alpha', 'Sigma', 'Beta', 'Gamma'];

  late final List<String> _phases;
  int _phaseIndex = 0;
  int _stageIndex = 0;

  @override
  void initState() {
    super.initState();
    // diff 슬롯(diff1~5)은 위치 기반이라 모드마다 뜻이 다르다 — 라벨은
    // 반드시 phase_defs.dart 에서 가져온다. (1-phase 는 diff 가 없지만
    // 기존 동작대로 앞 두 칸을 보여준다: 데이터가 없으면 "No data".)
    final diffs = diffSeqFor(widget.phaseCount);
    _phases = diffs.isNotEmpty
        ? [for (final d in diffs) d.short]
        : _allPhases.sublist(0, 2);
  }

  String? _getPhaseField(DiffStageTopographyModel m) => m.byIndex(_phaseIndex);

  String? _getPhaseFieldConn(DiffStageConnectivityModel m) =>
      m.byIndex(_phaseIndex);

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
