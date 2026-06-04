import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Guarda el token FCM del asesor en `asesores_fcmtokens`.
class FcmTokenService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<bool> guardarToken({
    required String asesorid,
    required String token,
  }) async {
    if (asesorid.isEmpty) {
      if (kDebugMode) {
        debugPrint('FCM: asesorid vacío — no se guarda en Supabase');
      }
      return false;
    }
    if (token.isEmpty) return false;

    try {
      await _client.from('asesores_fcmtokens').upsert(
        {
          'asesorid': asesorid,
          'fcmtoken': token,
          'fcmtokenupdatedat': DateTime.now().toIso8601String(),
          'updatedat': DateTime.now().toIso8601String(),
        },
        onConflict: 'asesorid',
      );
      if (kDebugMode) {
        debugPrint('OK: FCM guardado en asesores_fcmtokens (asesorid=$asesorid)');
      }
      return true;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('ERROR guardando FCM en asesores_fcmtokens: $e');
        debugPrint('$st');
        debugPrint(
          '¿Creaste la tabla? Ejecuta: supabase/migrations/20260603_asesores_fcmtokens.sql',
        );
      }
      return false;
    }
  }

  Future<String?> leerToken(String asesorid) async {
    try {
      final row = await _client
          .from('asesores_fcmtokens')
          .select('fcmtoken')
          .eq('asesorid', asesorid)
          .maybeSingle();
      return row?['fcmtoken']?.toString();
    } catch (_) {
      return null;
    }
  }
}
