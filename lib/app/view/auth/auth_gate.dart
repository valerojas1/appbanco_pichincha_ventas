import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../model/perfil_oficial.dart';
import '../../viewmodel/auth_oficial_viewmodel.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/widgets/app_logo.dart';
import '../home/shell_oficial_screen.dart';
import '../web/admin/admin_web_shell.dart';
import 'login_oficial_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> with WidgetsBindingObserver {
  Timer? _inactivityTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _inactivityTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) return;
      context.read<AuthOficialViewModel>().checkInactivityExpiry();
    });
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<AuthOficialViewModel>().checkInactivityExpiry();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthOficialViewModel>();

    if (vm.state == AuthOficialState.initializing) {
      return const Scaffold(
        backgroundColor: AppTheme.fondoOscuro,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppLogo(size: 72),
              SizedBox(height: 24),
              CircularProgressIndicator(color: AppTheme.amarillo),
            ],
          ),
        ),
      );
    }

    if (vm.isAuthenticated) {
      final esAdminWeb =
          kIsWeb && vm.oficial?.perfil == PerfilOficial.administrador;
      return SessionActivityWrapper(
        child: esAdminWeb
            ? const AdminWebShell()
            : const ShellOficialScreen(),
      );
    }

    return const LoginOficialScreen();
  }
}

/// Registra actividad del usuario para el límite de 8 h de inactividad.
class SessionActivityWrapper extends StatelessWidget {
  final Widget child;

  const SessionActivityWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) {
        context.read<AuthOficialViewModel>().touchActivity();
      },
      child: child,
    );
  }
}
