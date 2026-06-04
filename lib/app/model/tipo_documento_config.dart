/// Configuración de tipos de documento para captura.
class TipoDocumentoConfig {
  final String id;
  final String titulo;
  final bool obligatorio;

  const TipoDocumentoConfig({
    required this.id,
    required this.titulo,
    required this.obligatorio,
  });

  static const List<TipoDocumentoConfig> catalogo = [
    TipoDocumentoConfig(
      id: 'dni_anverso',
      titulo: 'DNI — Anverso',
      obligatorio: true,
    ),
    TipoDocumentoConfig(
      id: 'dni_reverso',
      titulo: 'DNI — Reverso',
      obligatorio: true,
    ),
    TipoDocumentoConfig(
      id: 'foto_negocio',
      titulo: 'Foto del negocio',
      obligatorio: true,
    ),
    TipoDocumentoConfig(
      id: 'foto_asesor_cliente',
      titulo: 'Foto asesor con cliente',
      obligatorio: true,
    ),
    TipoDocumentoConfig(
      id: 'ruc',
      titulo: 'RUC (opcional)',
      obligatorio: false,
    ),
    TipoDocumentoConfig(
      id: 'recibo_servicios',
      titulo: 'Recibo de servicios (opcional)',
      obligatorio: false,
    ),
    TipoDocumentoConfig(
      id: 'contrato_arriendo',
      titulo: 'Contrato de arriendo (opcional)',
      obligatorio: false,
    ),
  ];

  static TipoDocumentoConfig? porId(String id) {
    for (final t in catalogo) {
      if (t.id == id) return t;
    }
    return null;
  }
}

/// Estado visual del checklist.
enum EstadoDocumentoChecklist {
  listo,
  pendiente,
  obligatorioPendiente,
}
