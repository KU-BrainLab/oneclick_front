part of 'router.dart';

String? _redirect(BuildContext context, GoRouterState state) {
  final isLoggedIn = AppService.instance.isLoggedIn;
  final isLoginRoute = state.matchedLocation == LoginPage.route;

  if (!isLoggedIn && !isLoginRoute) {
    return LoginPage.route;
  } else if (isLoggedIn && isLoginRoute) {
    return UsersPage.route;
  }
  return null;
}