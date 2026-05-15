import 'package:flutter/material.dart';
import '../view/auth/login_oficial_screen.dart';
import '../view/home/cartera_diaria_screen.dart';

class AppRouter {
  static const String login = '/login';
  static const String cartera = '/cartera';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginOficialScreen(),
        );
      case cartera:
        return MaterialPageRoute(
          builder: (_) => const CarteraDiariaScreen(),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const LoginOficialScreen(),
        );
    }
  }
}