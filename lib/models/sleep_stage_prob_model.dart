class SleepStageProbModel {

  List<ChartData> list;
  double maximum;

  SleepStageProbModel({
    required this.list,
    required this.maximum,
  });

  factory SleepStageProbModel.fromJson(List<dynamic> jsonList) {

    double maximum = 0;
    List<ChartData> list = [];

    int index = 0;
    jsonList.forEach((element) {
      List<dynamic> ele = element as List<dynamic>;

      double w = ele[0];
      double n1 = ele[1];
      double n2 = ele[2];
      double n3 = ele[3];
      double rem = ele[4];

      ele.forEach((element) {
        double el = element as double;
        if(el > maximum) {
          maximum = el;
        }
      });

      list.add(ChartData(index, w, rem, n1, n2, n3));
      index += 1;
    });

    return SleepStageProbModel(list: list, maximum: maximum);
  }
}

class ChartData {
  ChartData(this.x, this.w, this.rem, this.n1, this.n2, this.n3);
  final num x;
  final num w;
  final num rem;
  final num n1;
  final num n2;
  final num n3;
}