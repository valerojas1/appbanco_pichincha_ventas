import 'package:flutter/material.dart';
import '../view/auth/login_oficial_screen.dart';
import '../view/home/cartera_diaria_screen.dart';
import '../view/home/dashboard_view.dart';
import '../view/home/ruta_view.dart';
import '../view/home/ficha_view.dart';
import '../view/home/scoring_view.dart';
import '../view/home/metas_view.dart';

class AppRouter {
  static const String login = '/login';
  static const String cartera = '/cartera';
  static const String dashboard = '/dashboard';
  static const String ruta = '/ruta';
  static const String ficha = '/ficha';
  static const String scoring = '/scoring';
  static const String metas = '/metas';

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
      case dashboard:
        return MaterialPageRoute(
          builder: (_) => const DashboardView(),
        );
      case ruta:
        return MaterialPageRoute(
          builder: (_) => const RutaView(),
        );
      case ficha:
        return MaterialPageRoute(
          builder: (_) => const FichaView(),
        );
      case scoring:
        return MaterialPageRoute(
          builder: (_) => const ScoringView(),
        );
      case metas:
        return MaterialPageRoute(
          builder: (_) => const MetasView(),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const LoginOficialScreen(),
        );
    }
  }
}
