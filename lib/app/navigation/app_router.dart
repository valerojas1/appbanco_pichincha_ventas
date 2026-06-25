import 'package:flutter/material.dart';
import '../view/auth/login_oficial_screen.dart';
import '../view/home/cartera_diaria_screen.dart';
import '../view/home/dashboard_view.dart';
import '../view/home/ruta_view.dart';
import '../view/home/ficha_view.dart';
import '../view/home/scoring_view.dart';
import '../view/home/metas_view.dart';
import '../view/home/shell_oficial_screen.dart';
import '../view/home/ficha_cliente_screen.dart';
import '../view/home/pre_evaluacion_screen.dart';
import '../view/home/cliente_desertor_screen.dart';
import '../view/home/solicitud_credito_wizard_screen.dart';
import '../view/home/bandeja_solicitudes_cliente_screen.dart';
import '../view/home/borradores_solicitud_screen.dart';
import '../view/home/seleccion_solicitud_documentos_screen.dart';
import '../view/home/captura_documentos_screen.dart';
import '../view/home/consulta_buro_screen.dart';
import '../view/home/cartera_vencida_screen.dart';
import '../view/home/monitor_asesores_screen.dart';
import '../view/home/reporte_productividad_screen.dart';
import '../view/home/solicitudes_tablero_screen.dart';
import '../view/home/solicitud_detalle_screen.dart';
import '../view/home/transmision_electronica_screen.dart';

class AppRouter {
  static const String login = '/login';
  static const String home = '/home';
  static const String cartera = '/cartera';
  static const String carteraVencida = '/cartera-vencida';
  static const String monitorAsesores = '/monitor-asesores';
  static const String reporteProductividad = '/reporte-productividad';
  static const String dashboard = '/dashboard';
  static const String ruta = '/ruta';
  static const String ficha = '/ficha';
  static const String scoring = '/scoring';
  static const String metas = '/metas';
  static const String fichaCliente = '/ficha-cliente';
  static const String prospeccion = '/prospeccion';
  static const String clienteDesertor = '/cliente-desertor';
  static const String solicitudCredito = '/solicitud-credito';
  static const String bandejaSolicitudesCliente = '/bandeja-solicitudes-cliente';
  static const String borradoresSolicitud = '/borradores-solicitud';
  static const String documentosSolicitud = '/documentos-solicitud';
  static const String capturaDocumentos = '/captura-documentos';
  static const String consultaBuro = '/consulta-buro';
  static const String estadoSolicitudes = '/estado-solicitudes';
  static const String solicitudDetalle = '/solicitud-detalle';
  static const String transmisionElectronica = '/transmision-electronica';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginOficialScreen(),
        );
      case home:
        return MaterialPageRoute(
          builder: (_) => const ShellOficialScreen(),
        );
      case cartera:
        return MaterialPageRoute(
          builder: (_) => const CarteraDiariaScreen(),
        );
      case carteraVencida:
        return MaterialPageRoute(
          builder: (_) => const CarteraVencidaScreen(),
        );
      case monitorAsesores:
        return MaterialPageRoute(
          builder: (_) => const MonitorAsesoresScreen(),
        );
      case reporteProductividad:
        return MaterialPageRoute(
          builder: (_) => const ReporteProductividadScreen(),
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
      case fichaCliente:
        final args = settings.arguments;
        if (args is FichaClienteArgs) {
          return MaterialPageRoute(
            builder: (_) => FichaClienteScreen(args: args),
          );
        }
        return MaterialPageRoute(
          builder: (_) => const FichaClienteScreen(
            args: FichaClienteArgs(documento: ''),
          ),
        );
      case estadoSolicitudes:
        return MaterialPageRoute(
          builder: (_) => const SolicitudesTableroScreen(),
        );
      case solicitudDetalle:
        final detArgs = settings.arguments;
        if (detArgs is String) {
          return MaterialPageRoute(
            builder: (_) => SolicitudDetalleScreen(solicitudId: detArgs),
          );
        }
        return MaterialPageRoute(
          builder: (_) => const SolicitudesTableroScreen(),
        );
      case transmisionElectronica:
        final txArgs = settings.arguments;
        if (txArgs is TransmisionElectronicaArgs) {
          return MaterialPageRoute(
            builder: (_) => TransmisionElectronicaScreen(args: txArgs),
          );
        }
        return MaterialPageRoute(
          builder: (_) => const SolicitudesTableroScreen(),
        );
      case consultaBuro:
        final args = settings.arguments;
        return MaterialPageRoute(
          builder: (_) => ConsultaBuroScreen(
            args: args is ConsultaBuroArgs ? args : null,
          ),
        );
      case prospeccion:
        return MaterialPageRoute(
          builder: (_) => const PreEvaluacionScreen(),
        );
      case clienteDesertor:
        return MaterialPageRoute(
          builder: (_) => const ClienteDesertorScreen(),
        );
      case solicitudCredito:
        return MaterialPageRoute(
          builder: (_) => const SolicitudCreditoWizardScreen(),
        );
      case borradoresSolicitud:
        return MaterialPageRoute(
          builder: (_) => const BorradoresSolicitudScreen(),
        );
      case bandejaSolicitudesCliente:
        return MaterialPageRoute(
          builder: (_) => const BandejaSolicitudesClienteScreen(embedded: true),
        );
      case documentosSolicitud:
        return MaterialPageRoute(
          builder: (_) => const SeleccionSolicitudDocumentosScreen(),
        );
      case capturaDocumentos:
        final args = settings.arguments;
        if (args is CapturaDocumentosArgs) {
          return MaterialPageRoute(
            builder: (_) => CapturaDocumentosScreen(args: args),
          );
        }
        return MaterialPageRoute(
          builder: (_) => const SeleccionSolicitudDocumentosScreen(),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const LoginOficialScreen(),
        );
    }
  }
}
