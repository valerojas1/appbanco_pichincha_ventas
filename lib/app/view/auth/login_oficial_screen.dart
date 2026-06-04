import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodel/auth_oficial_viewmodel.dart';
import '../../ui/theme/app_theme.dart';

class LoginOficialScreen extends StatefulWidget {
  const LoginOficialScreen({super.key});

  @override
  State<LoginOficialScreen> createState() => _LoginOficialScreenState();
}

class _LoginOficialScreenState extends State<LoginOficialScreen> {
  final _codigoController = TextEditingController();
  final _passController = TextEditingController();
  bool _verPassword = false;

  @override
  void dispose() {
    _codigoController.dispose();
    _passController.dispose();
    super.dispose();
  }

  String _formatCountdown(Duration? d) {
    if (d == null) return '00:00';
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.fondoOscuro,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Consumer<AuthOficialViewModel>(
            builder: (context, vm, _) {
              final bloqueado = vm.isLockedOut;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: AppTheme.amarillo,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          left: 18,
                          top: 18,
                          child: Container(
                            width: 16,
                            height: 44,
                            color: AppTheme.fondoOscuro,
                          ),
                        ),
                        Positioned(
                          left: 18,
                          bottom: 18,
                          child: Container(
                            width: 36,
                            height: 16,
                            color: AppTheme.fondoOscuro,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Banco Pichincha Perú',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.amarillo,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppTheme.amarillo.withValues(alpha: 0.5),
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Portal Oficial de Crédito',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.amarillo,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  if (bloqueado) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.redAccent.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.lock_clock,
                            color: Colors.redAccent,
                            size: 36,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Cuenta bloqueada temporalmente',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Demasiados intentos fallidos.\nReintenta en:',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _formatCountdown(vm.lockoutRemaining),
                            style: const TextStyle(
                              color: AppTheme.amarillo,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    TextField(
                      controller: _codigoController,
                      keyboardType: TextInputType.number,
                      maxLength: 10,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Código de empleado',
                        hintText: 'Ej: 100001',
                        counterText: '',
                        hintStyle: TextStyle(color: Colors.white38),
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passController,
                      obscureText: !_verPassword,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _verPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppTheme.amarillo,
                          ),
                          onPressed: () =>
                              setState(() => _verPassword = !_verPassword),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (vm.errorMessage.isNotEmpty &&
                        vm.state == AuthOficialState.error)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.redAccent.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.redAccent,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                vm.errorMessage,
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 32),
                    vm.state == AuthOficialState.loading
                        ? const CircularProgressIndicator(
                            color: AppTheme.amarillo,
                          )
                        : ElevatedButton(
                            onPressed: () => vm.login(
                              _codigoController.text.trim(),
                              _passController.text.trim(),
                            ),
                            child: const Text('ACCEDER AL PORTAL'),
                          ),
                  ],
                  const SizedBox(height: 24),
                  if (!bloqueado)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.amarillo.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Demo — Código: 100001 (operador) | Pass: asesor123\n'
                        '100002 superoperador · 100003 supervisor · 100004 admin',
                        style: TextStyle(fontSize: 11, color: Colors.white38),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
