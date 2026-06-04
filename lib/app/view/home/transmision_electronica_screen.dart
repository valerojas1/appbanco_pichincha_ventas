import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../model/transmision_paso.dart';
import '../../ui/theme/app_theme.dart';
import '../../viewmodel/transmision_electronica_viewmodel.dart';
import 'solicitud_detalle_screen.dart';
import 'solicitudes_tablero_screen.dart';

class TransmisionElectronicaArgs {
  final String solicitudId;
  final String tituloSolicitud;

  const TransmisionElectronicaArgs({
    required this.solicitudId,
    required this.tituloSolicitud,
  });
}

class TransmisionElectronicaScreen extends StatefulWidget {
  final TransmisionElectronicaArgs args;

  const TransmisionElectronicaScreen({super.key, required this.args});

  @override
  State<TransmisionElectronicaScreen> createState() =>
      _TransmisionElectronicaScreenState();
}

class _TransmisionElectronicaScreenState
    extends State<TransmisionElectronicaScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = context.read<TransmisionElectronicaViewModel>();
      await vm.iniciar(
        solicitudId: widget.args.solicitudId,
        tituloSolicitud: widget.args.tituloSolicitud,
      );
      if (mounted) await vm.ejecutarTransmisionCompleta();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TransmisionElectronicaViewModel>();

    return Scaffold(
      backgroundColor: AppTheme.fondoOscuro,
      appBar: AppBar(
        title: const Text(
          'Transmisión electrónica',
          style: TextStyle(
            color: AppTheme.amarillo,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              vm.titulo,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...TransmisionPaso.values.map((p) => _PasoItem(
                  paso: p,
                  activo: vm.pasoActual.indice == p.indice,
                  completado: vm.pasoActual.indice > p.indice ||
                      (vm.completado && p == TransmisionPaso.enviado),
                  enProgreso: vm.ejecutando && vm.pasoActual == p,
                )),
            if (vm.erroresValidacion.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.redAccent),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Corrija antes de transmitir:',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...vm.erroresValidacion.map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(color: Colors.white70)),
                            Expanded(
                              child: Text(
                                e,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (vm.error != null && vm.erroresValidacion.isEmpty) ...[
              const SizedBox(height: 12),
              Text(vm.error!, style: const TextStyle(color: Colors.redAccent)),
            ],
            if (vm.completado) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.verdePendiente.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.verdePendiente),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Transmisión exitosa',
                      style: TextStyle(
                        color: AppTheme.verdePendiente,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (vm.numeroExpediente != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Expediente: ${vm.numeroExpediente}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SolicitudDetalleScreen(
                        solicitudId: widget.args.solicitudId,
                      ),
                    ),
                  );
                },
                child: const Text('VER DETALLE'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SolicitudesTableroScreen(),
                    ),
                    (r) => r.isFirst,
                  );
                },
                child: const Text('IR AL TABLERO'),
              ),
            ],
            if (!vm.completado && !vm.ejecutando && vm.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: ElevatedButton(
                  onPressed: () => vm.ejecutarTransmisionCompleta(),
                  child: const Text('REINTENTAR'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PasoItem extends StatelessWidget {
  final TransmisionPaso paso;
  final bool activo;
  final bool completado;
  final bool enProgreso;

  const _PasoItem({
    required this.paso,
    required this.activo,
    required this.completado,
    required this.enProgreso,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    if (completado) {
      icon = Icons.check_circle;
      color = AppTheme.verdePendiente;
    } else if (enProgreso || activo) {
      icon = Icons.hourglass_top;
      color = AppTheme.amarillo;
    } else {
      icon = Icons.radio_button_unchecked;
      color = Colors.white38;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  paso.titulo,
                  style: TextStyle(
                    color: activo || completado || enProgreso
                        ? Colors.white
                        : Colors.white54,
                    fontWeight:
                        activo || enProgreso ? FontWeight.bold : null,
                  ),
                ),
                Text(
                  paso.descripcion,
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
          if (enProgreso)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.amarillo,
              ),
            ),
        ],
      ),
    );
  }
}
