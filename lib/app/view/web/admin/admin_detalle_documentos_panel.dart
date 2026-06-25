import 'package:flutter/material.dart';
import '../../../model/documento_slot_model.dart';
import '../../../model/tipo_documento_config.dart';
import '../../../ui/theme/app_theme.dart';

class AdminDetalleDocumentosPanel extends StatelessWidget {
  final String solicitudId;
  final Map<String, DocumentoSlotModel> slots;
  final bool cargando;
  final VoidCallback? onVolver;
  final VoidCallback? onEvaluar;
  final void Function(String titulo, String url) onVerDocumento;

  const AdminDetalleDocumentosPanel({
    super.key,
    required this.solicitudId,
    required this.slots,
    required this.cargando,
    this.onVolver,
    this.onEvaluar,
    required this.onVerDocumento,
  });

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.amarillo),
      );
    }

    final catalogo = TipoDocumentoConfig.catalogo;
    final subidos = catalogo.where((t) => slots[t.id]?.estaListo ?? false).length;
    final obligatorios = catalogo.where((t) => t.obligatorio).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              if (onVolver != null)
                IconButton(
                  onPressed: onVolver,
                  icon: const Icon(Icons.arrow_back, color: AppTheme.amarillo),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Documentación del cliente',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$subidos de $obligatorios obligatorios · ID: $solicitudId',
                      style: const TextStyle(
                        color: AppTheme.grisMedio,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (onEvaluar != null)
                ElevatedButton.icon(
                  onPressed: onEvaluar,
                  icon: const Icon(Icons.fact_check_outlined, size: 18),
                  label: const Text('Evaluar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.amarillo,
                    foregroundColor: AppTheme.navyOscuro,
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 3 : 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.85,
            ),
            itemCount: catalogo.length,
            itemBuilder: (_, i) {
              final tipo = catalogo[i];
              final slot = slots[tipo.id];
              final listo = slot?.estaListo ?? false;

              return _DocumentoCard(
                titulo: tipo.titulo,
                obligatorio: tipo.obligatorio,
                listo: listo,
                url: slot?.urlPublica,
                puntaje: slot?.puntajeNitidez,
                onTap: listo && slot?.urlPublica != null
                    ? () => onVerDocumento(tipo.titulo, slot!.urlPublica!)
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DocumentoCard extends StatelessWidget {
  final String titulo;
  final bool obligatorio;
  final bool listo;
  final String? url;
  final double? puntaje;
  final VoidCallback? onTap;

  const _DocumentoCard({
    required this.titulo,
    required this.obligatorio,
    required this.listo,
    this.url,
    this.puntaje,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.superficie,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: listo
                  ? AppTheme.verdePendiente.withValues(alpha: 0.4)
                  : (obligatorio
                      ? AppTheme.naranjaNuevo.withValues(alpha: 0.3)
                      : Colors.white12),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(11)),
                  child: listo && url != null
                      ? Image.network(
                          url!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(listo),
                          loadingBuilder: (_, child, progress) {
                            if (progress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.amarillo,
                                strokeWidth: 2,
                              ),
                            );
                          },
                        )
                      : _placeholder(listo),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          listo ? Icons.check_circle : Icons.cancel_outlined,
                          size: 14,
                          color: listo
                              ? AppTheme.verdePendiente
                              : Colors.white38,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          listo
                              ? 'Adjuntado${puntaje != null ? ' · ${puntaje!.toStringAsFixed(0)}%' : ''}'
                              : (obligatorio ? 'Pendiente' : 'Opcional'),
                          style: TextStyle(
                            color: listo
                                ? AppTheme.verdePendiente
                                : Colors.white54,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder(bool listo) {
    return Container(
      color: AppTheme.navyOscuro,
      child: Center(
        child: Icon(
          listo ? Icons.image_outlined : Icons.upload_file_outlined,
          color: Colors.white24,
          size: 36,
        ),
      ),
    );
  }
}
