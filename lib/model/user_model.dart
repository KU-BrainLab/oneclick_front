class UserModel {
  int id;
  String name;
  int? age;
  String? birth;
  int? sex;
  DateTime measurement_date;
  DateTime int_dt;
  DateTime upt_dt;
  int? hrv;
  int? eeg;


  get sexName => sex == null ? '' : sex == 0 ? "남자" : "여자";

  UserModel({
    required this.id,
    required this.name,
    required this.age,
    required this.birth,
    required this.sex,
    required this.measurement_date,
    required this.int_dt,
    required this.upt_dt,
    required this.hrv,
    required this.eeg
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      age: json['age'],
      birth: json['birth'],
      sex: json['sex'],
      measurement_date: DateTime.parse(json['measurement_date']),
      int_dt: DateTime.parse(json['int_dt']),
      upt_dt: DateTime.parse(json['upt_dt']),
      hrv: json['hrv'],
      eeg: json['eeg']
    );
  }
}
