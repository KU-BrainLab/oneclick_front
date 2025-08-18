import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:hive/hive.dart';
import 'package:omnifit_front/models/user_data.dart';
import 'package:omnifit_front/router/router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'service/app_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(UserDataAdapter());
  await Hive.openBox('App Service Box');
  runApp(const OmniFitApp());
}

class OmniFitApp extends StatefulWidget {
  const OmniFitApp({super.key});

  @override
  State<OmniFitApp> createState() => _OmniFitAppState();
}

class _OmniFitAppState extends State<OmniFitApp> {
  @override
  void initState() {
    super.initState();
    usePathUrlStrategy();
    AppService.instance.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Web Authentication',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'DotumBold'
      ),
      routerDelegate: router.routerDelegate,
      routeInformationParser: router.routeInformationParser,
      routeInformationProvider: router.routeInformationProvider,
    );
  }
}
