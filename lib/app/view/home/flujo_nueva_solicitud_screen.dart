import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/asesor_id_util.dart';
import '../../core/buro_solicitud_gate.dart';
import '../../core/sbs_semaforo.dart';
import '../../model/cartera_diaria_model.dart';
import '../../model/preevaluacion_resultado_model.dart';
import '../../services/consulta_buro_service.dart';
import '../../ui/theme/app_theme.dart';
import '../../viewmodel/auth_oficial_viewmodel.dart';
import '../../viewmodel/cartera_viewmodel.dart';
import 'consulta_buro_screen.dart';
import 'ficha_cartera_screen.dart';
import 'ficha_cliente_screen.dart';
import 'pre_evaluacion_screen.dart';

/// Orquesta el flujo completo de una NUEVA SOLICITUD desde cartera del día.
class FlujoNuevaSolicitudScreen extends StatefulWidget {
  final CarteraDiariaModel cartera;

  const FlujoNuevaSolicitudScreen({super.key, required this.cartera});

  @override
  State<FlujoNuevaSolicitudScreen> createState() =>
      _FlujoNuevaSolicitudScreenState();
}

class _FlujoNuevaSolicitudScreenState extends State<FlujoNuevaSolicitudScreen> {
  final _buroService = ConsultaBuroService();
  bool _cargando = true;
  bool _enListaNegra = false;
  String? _sbsClasificacion;
  bool _buroValido = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refrescar());
  }

  Future<void> _refrescar() async {
    setState(() => _cargando = true);
    final doc = widget.cartera.documento.replaceAll(RegExp(r'\D'), '');
    _enListaNegra = await _buroService.documentoEnListaNegraActiva(doc);
    final consulta = await _buroService.ultimaConsultaValida(doc);
    _buroValido = consulta != null && !consulta.enListaNegra;
    _sbsClasificacion = consulta?.clasificacionSbs;

    final oficial = context.read<AuthOficialViewModel>().oficial;
    if (oficial != null) {
      await context
          .read<CarteraViewModel>()
          .cargarCartera(AsesorIdUtil.idsConsulta(oficial));
    }
    if (mounted) setState(() => _cargando = false);
  }

  ProspectoSolicitudPrefill get _prefill => ProspectoSolicitudPrefill(
        dni: widget.cartera.documento,
        nombres: widget.cartera.nombrecliente,
        tiponegocio: 'Comercio',
        ingresos: 2500,
        destino: 'capital_trabajo',
        monto: widget.cartera.monto.clamp(500, 50000),
      );

  bool get _visitado => widget.cartera.estadovisita == 'visitado';

  @override
  Widget build(BuildContext context) {
    final bloqueado = _enListaNegra;

    return Scaffold(
      backgroundColor: AppTheme.fondoOscuro,
      appBar: AppBar(
        title: const Text(
          'Nueva solicitud',
          style: TextStyle(
            color: AppTheme.amarillo,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.amarillo),
            )
          : RefreshIndicator(
              onRefresh: _refrescar,
              color: AppTheme.amarillo,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _EncabezadoCliente(cartera: widget.cartera),
                  if (bloqueado) ...[
                    const SizedBox(height: 16),
                    _BloqueoListaNegra(documento: widget.cartera.documento),
                  ],
                  const SizedBox(height: 16),
                  _PasoFlujo(
                    numero: 1,
                    titulo: 'Ficha del cliente',
                    descripcion: 'Consultar perfil y posición crediticia.',
                    completado: true,
                    bloqueado: bloqueado,
                    icono: Icons.person_outline,
                    onAccion: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FichaClienteScreen(
                            args: FichaClienteArgs.fromCartera(widget.cartera),
                          ),
                        ),
                      );
                      await _refrescar();
                    },
                    etiquetaBoton: 'ABRIR FICHA',
                  ),
                  _PasoFlujo(
                    numero: 2,
                    titulo: 'Registrar visita',
                    descripcion: 'Marcar resultado como visitado en ficha de campo.',
                    completado: _visitado,
                    bloqueado: bloqueado,
                    icono: Icons.location_on_outlined,
                    onAccion: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              FichaCarteraScreen(cartera: widget.cartera),
                        ),
                      );
                      await _refrescar();
                    },
                    etiquetaBoton: 'FICHA DE CAMPO',
                  ),
                  _PasoFlujo(
                    numero: 3,
                    titulo: 'Pre-evaluación',
                    descripcion: 'Resultado APTO o REVISAR según capacidad de pago.',
                    completado: false,
                    bloqueado: bloqueado || !_visitado,
                    icono: Icons.fact_check_outlined,
                    onAccion: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PreEvaluacionScreen(prefill: _prefill),
                        ),
                      );
                    },
                    etiquetaBoton: 'PRE-EVALUAR',
                  ),
                  _PasoFlujo(
                    numero: 4,
                    titulo: 'Consulta buró + SBS',
                    descripcion: _buroValido
                        ? 'Clasificación SBS: $_sbsClasificacion'
                        : 'Consentimiento, firma y consulta de buró.',
                    completado: _buroValido,
                    bloqueado: bloqueado || !_visitado,
                    icono: Icons.verified_user_outlined,
                    trailing: _sbsClasificacion != null
                        ? _SbsBadge(clasificacion: _sbsClasificacion!)
                        : null,
                    onAccion: () async {
                      final ok = await BuroSolicitudGate.validarAntesDeSolicitud(
                        context,
                        dni: widget.cartera.documento,
                        nombres: widget.cartera.nombrecliente,
                      );
                      if (!context.mounted) return;
                      if (!ok) {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ConsultaBuroScreen(
                              args: ConsultaBuroArgs(
                                documento: widget.cartera.documento,
                                nombres: widget.cartera.nombrecliente,
                              ),
                            ),
                          ),
                        );
                      }
                      await _refrescar();
                    },
                    etiquetaBoton: _buroValido ? 'VER BURÓ' : 'CONSULTAR BURÓ',
                  ),
                  _PasoFlujo(
                    numero: 5,
                    titulo: 'Solicitud, documentos y envío',
                    descripcion:
                        'Wizard con firma, adjuntar documentos y transmitir al comité (recibido_comite).',
                    completado: false,
                    bloqueado: bloqueado || !_visitado || !_buroValido,
                    icono: Icons.send_outlined,
                    onAccion: () async {
                      final ok = await BuroSolicitudGate.validarAntesDeSolicitud(
                        context,
                        dni: widget.cartera.documento,
                        nombres: widget.cartera.nombrecliente,
                      );
                      if (!context.mounted || !ok) return;
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              PreEvaluacionScreen(prefill: _prefill),
                        ),
                      );
                      await _refrescar();
                    },
                    etiquetaBoton: 'INICIAR SOLICITUD',
                  ),
                  const SizedBox(height: 24),
                  if (bloqueado)
                    const Text(
                      'Caso 28: cliente en lista negra. El flujo está bloqueado.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.redAccent, fontSize: 12),
                    ),
                ],
              ),
            ),
    );
  }
}

class _EncabezadoCliente extends StatelessWidget {
  final CarteraDiariaModel cartera;

  const _EncabezadoCliente({required this.cartera});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.superficie,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.naranjaNuevo.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.naranjaNuevo.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'NUEVA SOLICITUD',
                  style: TextStyle(
                    color: AppTheme.naranjaNuevo,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            cartera.nombrecliente,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'DNI ${cartera.documento} · S/ ${cartera.monto.toStringAsFixed(0)}',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _BloqueoListaNegra extends StatelessWidget {
  final String documento;

  const _BloqueoListaNegra({required this.documento});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent),
      ),
      child: Row(
        children: [
          const Icon(Icons.block, color: Colors.redAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Lista negra (caso 28) — DNI $documento. '
              'No se puede continuar con la solicitud.',
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _PasoFlujo extends StatelessWidget {
  final int numero;
  final String titulo;
  final String descripcion;
  final bool completado;
  final bool bloqueado;
  final IconData icono;
  final VoidCallback onAccion;
  final String etiquetaBoton;
  final Widget? trailing;

  const _PasoFlujo({
    required this.numero,
    required this.titulo,
    required this.descripcion,
    required this.completado,
    required this.bloqueado,
    required this.icono,
    required this.onAccion,
    required this.etiquetaBoton,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final color = completado
        ? AppTheme.verdePendiente
        : bloqueado
            ? Colors.white24
            : AppTheme.amarillo;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.superficie,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: color.withValues(alpha: 0.2),
                child: Text(
                  '$numero',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Icon(icono, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titulo,
                  style: TextStyle(
                    color: bloqueado ? Colors.white38 : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              if (completado)
                const Icon(Icons.check_circle, color: AppTheme.verdePendiente, size: 18),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 6),
          Text(
            descripcion,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
          if (!bloqueado) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onAccion,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.amarillo,
                  side: BorderSide(color: AppTheme.amarillo.withValues(alpha: 0.5)),
                ),
                child: Text(etiquetaBoton),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SbsBadge extends StatelessWidget {
  final String clasificacion;

  const _SbsBadge({required this.clasificacion});

  @override
  Widget build(BuildContext context) {
    final color = SbsSemaforo.color(clasificacion);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(
        clasificacion,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
