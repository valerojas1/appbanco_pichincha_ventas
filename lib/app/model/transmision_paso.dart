/// Pasos de la transmisión electrónica atómica (Bloque 8).
enum TransmisionPaso {
  validando(0, 'Validando', 'Revisando formulario, firma, buró y documentos'),
  subiendoDocs(1, 'Subiendo docs', 'Verificando y sincronizando documentos en paralelo'),
  registrando(2, 'Registrando', 'Registrando solicitud en el sistema central'),
  asignandoExpediente(3, 'Asignando expediente', 'Generando número de expediente oficial'),
  enviado(4, 'Enviado', 'Transmisión completada correctamente');

  final int indice;
  final String titulo;
  final String descripcion;

  const TransmisionPaso(this.indice, this.titulo, this.descripcion);

  static TransmisionPaso? fromIndice(int i) {
    for (final p in TransmisionPaso.values) {
      if (p.indice == i) return p;
    }
    return null;
  }

  TransmisionPaso? get siguiente {
    final next = indice + 1;
    return fromIndice(next);
  }
}
