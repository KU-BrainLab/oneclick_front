import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:omnifit_front/model/user_model.dart';
import 'package:omnifit_front/page/login_page.dart';
import 'package:omnifit_front/page/page_1.dart';
import 'package:omnifit_front/page/page_2.dart';
import 'package:omnifit_front/page/survey_page.dart';
import 'package:omnifit_front/page/sleep_result.dart';
import 'package:omnifit_front/page/users_page.dart';
import 'package:omnifit_front/service/app_service.dart';

part 'redirection.dart';

enum AppRoute { result, login, users }

final router = GoRouter(
  redirect: _redirect,
  debugLogDiagnostics: true,
  refreshListenable: AppService.instance,
  navigatorKey: AppService.instance.navigatorKey,
  initialLocation: "/users",
  routes: <GoRoute>[
    GoRoute(
      path: LoginPage.route,
      pageBuilder: (context, state) => const MaterialPage(child: LoginPage()),
    ),
    GoRoute(
      path: UsersPage.route,
      pageBuilder: (context, state) => const MaterialPage(child: UsersPage()),
    ),
    GoRoute(
      path: Page1.route,
      pageBuilder: (context, state) => MaterialPage(child: Page1(user: (state.extra as Map<String, dynamic>)["user"] as UserModel)),
    ),
    GoRoute(
      path: Page2.route,
      pageBuilder: (context, state) => MaterialPage(child: Page2(user: (state.extra as Map<String, dynamic>)["user"] as UserModel)),
    ),
    GoRoute(
      path: SurveyPage.route,
      pageBuilder: (context, state) => MaterialPage(child: SurveyPage(user: (state.extra as Map<String, dynamic>)["user"] as UserModel)),
    ),
      GoRoute(
      path: SleepResult.route,
      pageBuilder: (context, state) => MaterialPage(child: SleepResult(user: (state.extra as Map<String, dynamic>)["user"] as UserModel)),
    ),
  ],
);
