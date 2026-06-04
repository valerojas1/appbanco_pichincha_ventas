import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workmanager/workmanager.dart';
import '../core/supabase_config.dart';
import '../services/sincronizacion_nocturna_service.dart';

const String tareaSyncNocturna = 'sincronizacionNocturna22';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        anonKey: SupabaseConfig.supabaseAnonKey,
      );
      await SincronizacionNocturnaService.ejecutarDesdeBackground();
    } catch (_) {}
    return Future.value(true);
  });
}

/// Solo registra la tarea periódica (initialize se hace en main).
Future<void> registrarSincronizacionNocturna() async {
  final now = DateTime.now();
  var objetivo = DateTime(now.year, now.month, now.day, 22, 0);
  if (!objetivo.isAfter(now)) {
    objetivo = objetivo.add(const Duration(days: 1));
  }
  final delay = objetivo.difference(now);

  await Workmanager().registerPeriodicTask(
    tareaSyncNocturna,
    tareaSyncNocturna,
    frequency: const Duration(hours: 24),
    initialDelay: delay,
    constraints: Constraints(networkType: NetworkType.connected),
  );
}
