class ColorAreaChartModel {

  List<ChartData> chartList;
  double intervalX;
  double intervalY;
  double minX;
  double minY;
  double maxX;
  double maxY;

  ColorAreaChartModel({
    required this.chartList,
    required this.intervalX,
    required this.intervalY,
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY
  });

  factory ColorAreaChartModel.fromJson(Map<String, dynamic> json) {

    List<dynamic> list1 = json['std'];
    List<dynamic> list2 = json['mean'];

    List<ChartData> chartList = [];
    double minX = 9999;
    double minY = 0;
    double maxX = 0;
    double maxY = 0;

    for(int i = 0; i < list1.length; i++) {

      double x = list1[i] as double;
      double y = -(list2[i] as double);

      chartList.add(ChartData(x, y));

      // if(y < minY) {
      //   minY = y;
      // }
      if(y > maxY) {
        maxY = y;
      }
      if(x < minX) {
        minX = x;
      }
      if(x > maxX) {
        maxX = x;
      }
    }

    double intervalX = maxX / 5;
    double intervalY = maxY / 5 ;

    maxY += (intervalY*2);

    return ColorAreaChartModel(
      chartList: chartList,
      intervalX: intervalX,
      intervalY: intervalY,
      minX: minX,
      maxX: maxX,
      minY: minY,
      maxY: maxY,
    );
  }

  @override
  String toString() {
    return "ColorAreaChartModel : { minX : $minX, maxX : $maxX, minY : $minY, maxY : $maxY, intervalX : $intervalX, intervalY : $intervalY, dataList : ${chartList.length} }";
  }
}


class ChartData {
  const ChartData(this.x, this.y);
  final double x;
  final double y;
}
