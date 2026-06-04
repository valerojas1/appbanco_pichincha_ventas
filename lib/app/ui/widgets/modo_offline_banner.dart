import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodel/offline_sync_viewmodel.dart';
import '../theme/app_theme.dart';

class ModoOfflineBanner extends StatelessWidget {
  const ModoOfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OfflineSyncViewModel>();

    if (!vm.modoOffline && vm.pendientes == 0 && !vm.sincronizando) {
      return const SizedBox.shrink();
    }

    final texto = vm.sincronizando
        ? 'Sincronizando datos pendientes...'
        : vm.modoOffline
            ? 'Modo offline — mostrando datos guardados en el dispositivo'
            : vm.pendientes > 0
                ? '${vm.pendientes} pendiente(s) por enviar al servidor'
                : vm.mensajeSync ?? '';

    if (texto.isEmpty) return const SizedBox.shrink();

    return Material(
      color: vm.modoOffline ? Colors.orange.shade900 : AppTheme.navy,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(
                vm.modoOffline ? Icons.cloud_off : Icons.cloud_upload_outlined,
                color: AppTheme.amarillo,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  texto,
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
              if (vm.hayConexion && vm.pendientes > 0 && !vm.sincronizando)
                TextButton(
                  onPressed: () => vm.sincronizarPendientes(),
                  child: const Text(
                    'ENVIAR',
                    style: TextStyle(color: AppTheme.amarillo, fontSize: 11),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
