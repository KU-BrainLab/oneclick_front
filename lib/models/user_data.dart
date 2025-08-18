import 'package:hive/hive.dart';

part 'user_data.g.dart';

@HiveType(typeId: 0)
class UserData {
  @HiveField(0)
  final String? id;
  @HiveField(1)
  final String? email;

  const UserData({
    this.id,
    this.email,
  });
}
