import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/solicitud_documento_service.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/widgets/oficial_scaffold.dart';
import '../../viewmodel/auth_oficial_viewmodel.dart';
import 'captura_documentos_screen.dart';

/// Lista solicitudes pendientes de documentos para abrir captura.
class SeleccionSolicitudDocumentosScreen extends StatefulWidget {
  final bool embedded;

  const SeleccionSolicitudDocumentosScreen({super.key, this.embedded = false});

  @override
  State<SeleccionSolicitudDocumentosScreen> createState() =>
      _SeleccionSolicitudDocumentosScreenState();
}

class _SeleccionSolicitudDocumentosScreenState
    extends State<SeleccionSolicitudDocumentosScreen> {
  final _service = SolicitudDocumentoService();
  List<Map<String, dynamic>> _lista = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final asesor = context.read<AuthOficialViewModel>().oficial?.asesorid;
    if (asesor != null) {
      _lista = await _service.listarSolicitudesPendientesDocs(asesor);
    }
    setState(() => _cargando = false);
  }

  @override
  Widget build(BuildContext context) {
    return OficialScaffold(
      embedded: widget.embedded,
      title: 'Documentos de solicitud',
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.amarillo),
            )
          : _lista.isEmpty
              ? const Center(
                  child: Text(
                    'No hay solicitudes pendientes de documentos',
                    style: TextStyle(color: Colors.white54),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargar,
                  color: AppTheme.amarillo,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _lista.length,
                    itemBuilder: (context, i) {
                      final s = _lista[i];
                      final nombre =
                          '${s['nombres'] ?? ''} ${s['apellidos'] ?? ''}'.trim();
                      final monto = s['monto'];
                      return Card(
                        color: AppTheme.superficie,
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          title: Text(
                            nombre.isEmpty ? 'Solicitud' : nombre,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            'S/ ${monto?.toString() ?? '0'} · ${s['estado'] ?? ''}',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right,
                              color: Colors.white38),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CapturaDocumentosScreen(
                                  args: CapturaDocumentosArgs(
                                    solicitudId: s['id'].toString(),
                                    tituloSolicitud: nombre,
                                  ),
                                ),
                              ),
                            ).then((_) => _cargar());
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
