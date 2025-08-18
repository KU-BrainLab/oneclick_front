class HypnogramModel {

  List<HypnogramData> dataList;

  HypnogramModel({
    required this.dataList,
  });

  factory HypnogramModel.fromJson(List<dynamic> jsonList) {

    List<HypnogramData> list = [];
    for(int i = 0; i < jsonList.length; i++) {
      list.add(HypnogramData(i, jsonList[i] as int));
    }

    return HypnogramModel(
      dataList: list
    );
  }

}

class HypnogramData {
  const HypnogramData(this.x, this.y);
  final int x;
  final int y;
}