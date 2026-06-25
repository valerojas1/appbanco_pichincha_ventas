import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/core/app_navigator.dart';
import 'app/core/supabase_config.dart';
import 'app/navigation/app_router.dart';
import 'app/core/network_service.dart';
import 'app/services/cobranza_local_notifications_service.dart';
import 'package:workmanager/workmanager.dart';
import 'app/workers/sincronizacion_nocturna_callback.dart';
import 'app/ui/theme/app_theme.dart';
import 'app/view/auth/auth_gate.dart';
import 'app/viewmodel/auth_oficial_viewmodel.dart';
import 'app/viewmodel/cartera_viewmodel.dart';
import 'app/viewmodel/dashboard_viewmodel.dart';
import 'app/viewmodel/ruta_mapa_viewmodel.dart';
import 'app/viewmodel/ficha_viewmodel.dart';
import 'app/viewmodel/scoring_viewmodel.dart';
import 'app/viewmodel/metas_viewmodel.dart';
import 'app/viewmodel/clientes_credito_viewmodel.dart';
import 'app/viewmodel/ficha_cliente_viewmodel.dart';
import 'app/viewmodel/prospeccion_viewmodel.dart';
import 'app/viewmodel/solicitud_credito_viewmodel.dart';
import 'app/viewmodel/captura_documentos_viewmodel.dart';
import 'app/viewmodel/consulta_buro_viewmodel.dart';
import 'app/viewmodel/transmision_electronica_viewmodel.dart';
import 'app/viewmodel/solicitudes_tablero_viewmodel.dart';
import 'app/viewmodel/solicitud_detalle_viewmodel.dart';
import 'app/viewmodel/cartera_vencida_viewmodel.dart';
import 'app/viewmodel/offline_sync_viewmodel.dart';
import 'app/viewmodel/monitor_asesores_viewmodel.dart';
import 'app/viewmodel/reporte_productividad_viewmodel.dart';
import 'app/viewmodel/admin_web_inicio_viewmodel.dart';
import 'app/viewmodel/admin_revision_documentos_viewmodel.dart';
import 'app/viewmodel/admin_solicitudes_tablero_viewmodel.dart';
import 'app/viewmodel/admin_solicitud_evaluacion_viewmodel.dart';
import 'app/viewmodel/bandeja_solicitudes_cliente_viewmodel.dart';
import 'firebase_options.dart';

/// Handler de mensajes FCM con la app en segundo plano o cerrada.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  if (!kIsWeb) {
    try {
      await CobranzaLocalNotificationsService.instance.inicializar();
    } catch (e) {
      debugPrint('Notificaciones locales init error: $e');
    }
    try {
      await Workmanager().initialize(callbackDispatcher);
    } catch (e) {
      debugPrint('Workmanager init error: $e');
    }
  }
  try {
    await NetworkService.instance.inicializar();
  } catch (e) {
    debugPrint('NetworkService init error: $e');
  }

  final authViewModel = AuthOficialViewModel();
  runApp(AppPichinchaVentas(authViewModel: authViewModel));
  unawaited(authViewModel.initialize());
}

class AppPichinchaVentas extends StatelessWidget {
  final AuthOficialViewModel authViewModel;

  const AppPichinchaVentas({super.key, required this.authViewModel});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authViewModel),
        ChangeNotifierProvider(create: (_) => CarteraViewModel()),
        ChangeNotifierProvider(create: (_) => DashboardViewModel()),
        ChangeNotifierProvider(create: (_) => RutaMapaViewModel()),
        ChangeNotifierProvider(create: (_) => FichaViewModel()),
        ChangeNotifierProvider(create: (_) => ScoringViewModel()),
        ChangeNotifierProvider(create: (_) => MetasViewModel()),
        ChangeNotifierProvider(create: (_) => ClientesCreditoViewModel()),
        ChangeNotifierProvider(create: (_) => FichaClienteViewModel()),
        ChangeNotifierProvider(create: (_) => ProspeccionViewModel()),
        ChangeNotifierProvider(create: (_) => SolicitudCreditoViewModel()),
        ChangeNotifierProvider(create: (_) => CapturaDocumentosViewModel()),
        ChangeNotifierProvider(create: (_) => ConsultaBuroViewModel()),
        ChangeNotifierProvider(create: (_) => TransmisionElectronicaViewModel()),
        ChangeNotifierProvider(create: (_) => SolicitudesTableroViewModel()),
        ChangeNotifierProvider(create: (_) => SolicitudDetalleViewModel()),
        ChangeNotifierProvider(create: (_) => CarteraVencidaViewModel()),
        ChangeNotifierProvider(
          create: (_) => OfflineSyncViewModel()..inicializar(),
        ),
        ChangeNotifierProvider(create: (_) => MonitorAsesoresViewModel()),
        ChangeNotifierProvider(create: (_) => ReporteProductividadViewModel()),
        ChangeNotifierProvider(create: (_) => AdminWebInicioViewModel()),
        ChangeNotifierProvider(create: (_) => AdminRevisionDocumentosViewModel()),
        ChangeNotifierProvider(create: (_) => AdminSolicitudesTableroViewModel()),
        ChangeNotifierProvider(create: (_) => AdminSolicitudEvaluacionViewModel()),
        ChangeNotifierProvider(create: (_) => BandejaSolicitudesClienteViewModel()),
      ],
      child: MaterialApp(
        navigatorKey: appNavigatorKey,
        title: 'Pichincha — Portal Oficial',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.temaVentas,
        home: const AuthGate(),
        onGenerateRoute: AppRouter.generateRoute,
      ),
    );
  }
}
