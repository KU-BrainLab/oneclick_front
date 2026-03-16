import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:omnifit_front/model/user_model.dart';
import 'package:omnifit_front/page/login_page.dart';
import 'package:omnifit_front/page/page_1.dart';
import 'package:omnifit_front/page/page_2.dart';
import 'package:omnifit_front/page/survey_page.dart';
import 'package:omnifit_front/page/sleep_result.dart';
import 'package:omnifit_front/page/users_page.dart';
import 'package:omnifit_front/page/report_page1.dart';
import 'package:omnifit_front/page/report_page2.dart';
import 'package:omnifit_front/page/report_page3.dart';
import 'package:omnifit_front/page/report_page4.dart';
import 'package:omnifit_front/page/users_page_report.dart';
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
      pageBuilder: (context, state) => const NoTransitionPage(child: LoginPage()),
    ),
    GoRoute(
      path: UsersPage.route,
      pageBuilder: (context, state) => const NoTransitionPage(child: UsersPage()),
    ),
    GoRoute(
      path: Page1.route,
      pageBuilder: (context, state) {
        final extra = state.extra;
        if (extra == null || extra is! Map<String, dynamic> || extra["user"] == null) {
          return const NoTransitionPage(child: UsersPage());
        }
        return NoTransitionPage(child: Page1(user: extra["user"] as UserModel, trigger: extra["trigger"] as List<double>?));
      },
    ),
    GoRoute(
      path: Page2.route,
      pageBuilder: (context, state) {
        final extra = state.extra;
        if (extra == null || extra is! Map<String, dynamic> || extra["user"] == null) {
          return const NoTransitionPage(child: UsersPage());
        }
        return NoTransitionPage(child: Page2(user: extra["user"] as UserModel));
      },
    ),
    GoRoute(
      path: SurveyPage.route,
      pageBuilder: (context, state) {
        final extra = state.extra;
        if (extra == null || extra is! Map<String, dynamic> || extra["user"] == null) {
          return const NoTransitionPage(child: UsersPage());
        }
        return NoTransitionPage(child: SurveyPage(user: extra["user"] as UserModel));
      },
    ),
      GoRoute(
      path: SleepResult.route,
      pageBuilder: (context, state) {
        final extra = state.extra;
        if (extra == null || extra is! Map<String, dynamic> || extra["user"] == null) {
          return const NoTransitionPage(child: UsersPage());
        }
        return NoTransitionPage(child: SleepResult(user: extra["user"] as UserModel));
      },
    ),
      GoRoute(
      path: ReportPage1.route,
      pageBuilder: (context, state) {
        final extra = state.extra;
        if (extra == null || extra is! Map<String, dynamic> || extra["user"] == null) {
          return const NoTransitionPage(child: UsersPage());
        }
        return NoTransitionPage(child: ReportPage1(user: extra["user"] as UserModel, trigger: extra["trigger"] as List<double>?));
      },
    ),
      GoRoute(
      path: ReportPage2.route,
      pageBuilder: (context, state) {
        final extra = state.extra;
        if (extra == null || extra is! Map<String, dynamic> || extra["user"] == null) {
          return const NoTransitionPage(child: UsersPage());
        }
        return NoTransitionPage(child: ReportPage2(user: extra["user"] as UserModel));
      },
    ),
      GoRoute(
      path: ReportPage3.route,
      pageBuilder: (context, state) {
        final extra = state.extra;
        if (extra == null || extra is! Map<String, dynamic> || extra["user"] == null) {
          return const NoTransitionPage(child: UsersPage());
        }
        return NoTransitionPage(child: ReportPage3(user: extra["user"] as UserModel));
      },
    ),
      GoRoute(
      path: ReportPage4.route,
      pageBuilder: (context, state) {
        final extra = state.extra;
        if (extra == null || extra is! Map<String, dynamic> || extra["user"] == null) {
          return const NoTransitionPage(child: UsersPage());
        }
        return NoTransitionPage(child: ReportPage4(user: extra["user"] as UserModel));
      },
    ),

    GoRoute(
      path: UsersPageReport.route,
      pageBuilder: (context, state) => const NoTransitionPage(child: UsersPageReport()),
    ),
  ],
);