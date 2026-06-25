import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/auth_constants.dart';
import '../model/oficial_model.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  Session? get currentSession => _client.auth.currentSession;

  Future<OficialModel?> loginWithCodigoEmpleado(
    String codigoEmpleado,
    String password,
  ) async {
    final codigo = codigoEmpleado.trim();
    if (codigo.isEmpty) return null;

    final email = AuthConstants.emailFromCodigoEmpleado(codigo);

    final authResponse = await _client.auth
        .signInWithPassword(
          email: email,
          password: password,
        )
        .timeout(const Duration(seconds: 20));

    final authUser = authResponse.user;
    if (authUser == null) return null;

    return _fetchPerfilPorAuthUser(authUser.id);
  }

  Future<OficialModel?> restoreFromCurrentSession() async {
    final session = _client.auth.currentSession;
    if (session == null) return null;
    return _fetchPerfilPorAuthUser(session.user.id);
  }

  Future<OficialModel?> _fetchPerfilPorAuthUser(String authUserId) async {
    final row = await _client
        .from('vwperfilasesor')
        .select()
        .eq('auth_user_id', authUserId)
        .maybeSingle()
        .timeout(const Duration(seconds: 15));

    if (row == null) return null;
    return OficialModel.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
