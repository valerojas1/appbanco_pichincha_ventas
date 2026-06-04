import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../model/documento_slot_model.dart';
import '../../model/tipo_documento_config.dart';
import '../../ui/theme/app_theme.dart';
import '../../viewmodel/captura_documentos_viewmodel.dart';
import 'visor_documento_screen.dart';
import 'transmision_electronica_screen.dart';

class CapturaDocumentosArgs {
  final String solicitudId;
  final String tituloSolicitud;

  const CapturaDocumentosArgs({
    required this.solicitudId,
    required this.tituloSolicitud,
  });
}

class CapturaDocumentosScreen extends StatefulWidget {
  final CapturaDocumentosArgs args;
  final bool embedded;

  const CapturaDocumentosScreen({
    super.key,
    required this.args,
    this.embedded = false,
  });

  @override
  State<CapturaDocumentosScreen> createState() =>
      _CapturaDocumentosScreenState();
}

class _CapturaDocumentosScreenState extends State<CapturaDocumentosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CapturaDocumentosViewModel>().iniciar(
            solicitudId: widget.args.solicitudId,
            tituloSolicitud: widget.args.tituloSolicitud,
          );
    });
  }

  Future<void> _mostrarOpcionesCaptura(String tipoId) async {
    final fuente = await showModalBottomSheet<ImageSourceChoice>(
      context: context,
      backgroundColor: AppTheme.navyOscuro,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => const _SheetFuenteCaptura(),
    );
    if (fuente == null || !mounted) return;

    final vm = context.read<CapturaDocumentosViewModel>();
    final err = fuente == ImageSourceChoice.camara
        ? await vm.capturarDesdeCamara(tipoId)
        : await vm.capturarDesdeGaleria(tipoId);

    if (!mounted) return;
    if (err != null) {
      final esNitidez = err.contains('poco nítida') || err.contains('puntaje');
      if (esNitidez) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.superficie,
            title: const Text(
              'Foto poco nítida',
              style: TextStyle(color: Colors.orangeAccent),
            ),
            content: Text(
              err,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('ENTENDIDO'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err),
            backgroundColor: Colors.orangeAccent,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _confirmarEliminar(DocumentoSlotModel slot) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.superficie,
        title: const Text('Eliminar documento',
            style: TextStyle(color: AppTheme.amarillo)),
        content: Text(
          '¿Eliminar ${slot.config.titulo}? Se borrará de Storage.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final err =
        await context.read<CapturaDocumentosViewModel>().eliminarDocumento(
              slot.config.id,
            );
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CapturaDocumentosViewModel>();

    return Scaffold(
      backgroundColor: AppTheme.fondoOscuro,
      appBar: AppBar(
        title: const Text(
          'Captura de documentos',
          style: TextStyle(
            color: AppTheme.amarillo,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
      body: Stack(
        children: [
          vm.cargando
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.amarillo),
                )
              : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vm.tituloSolicitud,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Obligatorios listos: ${vm.obligatoriosListos}/${vm.totalObligatorios}',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Se valida nitidez automática y se comprime a ≤800 KB',
                        style: TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: TipoDocumentoConfig.catalogo.map((t) {
                      final slot = vm.slots[t.id] ??
                          DocumentoSlotModel(config: t);
                      return _TarjetaDocumento(
                        slot: slot,
                        onCapturar: () => _mostrarOpcionesCaptura(t.id),
                        onRetomar: () => _mostrarOpcionesCaptura(t.id),
                        onVer: slot.urlPublica != null
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => VisorDocumentoScreen(
                                      titulo: t.titulo,
                                      imageUrl: slot.urlPublica!,
                                    ),
                                  ),
                                );
                              }
                            : null,
                        onEliminar: slot.estaListo
                            ? () => _confirmarEliminar(slot)
                            : null,
                      );
                    }).toList(),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        if (vm.error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              vm.error!,
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: vm.puedeEnviarSolicitud && !vm.enviando
                                ? () async {
                                    final ok =
                                        await vm.prepararTransmisionElectronica();
                                    if (!context.mounted) return;
                                    if (ok) {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              TransmisionElectronicaScreen(
                                            args: TransmisionElectronicaArgs(
                                              solicitudId: widget.args.solicitudId,
                                              tituloSolicitud:
                                                  widget.args.tituloSolicitud,
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                : null,
                            child: vm.enviando
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppTheme.navy,
                                    ),
                                  )
                                : const Text('TRANSMITIR ELECTRÓNICAMENTE'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          if (vm.procesandoImagen) const _OverlayProcesandoImagen(),
        ],
      ),
    );
  }
}

class _OverlayProcesandoImagen extends StatelessWidget {
  const _OverlayProcesandoImagen();

  @override
  Widget build(BuildContext context) {
    final etapa = context.watch<CapturaDocumentosViewModel>().etapaProceso;

    return AbsorbPointer(
      child: Container(
        color: const Color(0xCC000000),
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppTheme.amarillo),
              const SizedBox(height: 20),
              const Text(
                'Procesando documento',
                style: TextStyle(
                  color: AppTheme.amarillo,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                etapa.isEmpty ? 'Por favor espere...' : etapa,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 16),
              const Text(
                'No cierre la aplicación',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum ImageSourceChoice { camara, galeria }

class _SheetFuenteCaptura extends StatelessWidget {
  const _SheetFuenteCaptura();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt, color: AppTheme.amarillo),
            title: const Text('Tomar foto',
                style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.pop(context, ImageSourceChoice.camara),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library, color: AppTheme.amarillo),
            title: const Text('Galería',
                style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.pop(context, ImageSourceChoice.galeria),
          ),
        ],
      ),
    );
  }
}

class _TarjetaDocumento extends StatelessWidget {
  final DocumentoSlotModel slot;
  final VoidCallback onCapturar;
  final VoidCallback onRetomar;
  final VoidCallback? onVer;
  final VoidCallback? onEliminar;

  const _TarjetaDocumento({
    required this.slot,
    required this.onCapturar,
    required this.onRetomar,
    required this.onVer,
    required this.onEliminar,
  });

  Color _colorEstado() {
    switch (slot.estadoChecklist) {
      case EstadoDocumentoChecklist.listo:
        return AppTheme.verdePendiente;
      case EstadoDocumentoChecklist.obligatorioPendiente:
        return Colors.redAccent;
      case EstadoDocumentoChecklist.pendiente:
        return Colors.white38;
    }
  }

  String _etiquetaEstado() {
    switch (slot.estadoChecklist) {
      case EstadoDocumentoChecklist.listo:
        return 'LISTO';
      case EstadoDocumentoChecklist.obligatorioPendiente:
        return 'OBLIGATORIO';
      case EstadoDocumentoChecklist.pendiente:
        return 'PENDIENTE';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorEstado();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.superficie,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  slot.config.titulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: color),
                ),
                child: Text(
                  _etiquetaEstado(),
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (slot.subiendo)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: LinearProgressIndicator(color: AppTheme.amarillo),
            ),
          if (slot.estaListo) ...[
            const SizedBox(height: 6),
            Text(
              'Nitidez: ${slot.puntajeNitidez?.toStringAsFixed(0) ?? '—'} · '
              '${slot.tamanoKb ?? 0} KB',
              style: const TextStyle(color: Colors.white38, fontSize: 10),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              if (!slot.estaListo)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: slot.subiendo ? null : onCapturar,
                    icon: const Icon(Icons.add_a_photo, size: 16),
                    label: const Text('Capturar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.amarillo,
                      side: const BorderSide(color: AppTheme.amarillo),
                    ),
                  ),
                )
              else ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: slot.subiendo ? null : onRetomar,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.amarillo,
                      side: const BorderSide(color: AppTheme.amarillo),
                    ),
                    child: const Text('RETOMAR'),
                  ),
                ),
                const SizedBox(width: 8),
                if (onVer != null)
                  IconButton(
                    onPressed: onVer,
                    icon: const Icon(Icons.zoom_in, color: AppTheme.azulVisitado),
                    tooltip: 'Ver pantalla completa',
                  ),
                if (onEliminar != null)
                  IconButton(
                    onPressed: onEliminar,
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.redAccent),
                    tooltip: 'Eliminar',
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
