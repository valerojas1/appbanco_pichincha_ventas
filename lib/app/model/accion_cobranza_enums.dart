enum TipoAccionCobranza {
  visita('visita', 'Visita'),
  llamada('llamada', 'Llamada'),
  mensaje('mensaje', 'Mensaje');

  final String db;
  final String etiqueta;
  const TipoAccionCobranza(this.db, this.etiqueta);
}

enum ResultadoAccionCobranza {
  compromisoPago('compromiso_pago', 'Compromiso de pago'),
  pagoParcial('pago_parcial', 'Pago parcial'),
  sinContacto('sin_contacto', 'Sin contacto'),
  seNiega('se_niega', 'Se niega');

  final String db;
  final String etiqueta;
  const ResultadoAccionCobranza(this.db, this.etiqueta);

  bool get requiereCompromiso => this == ResultadoAccionCobranza.compromisoPago;
  bool get requiereMontoPago => this == ResultadoAccionCobranza.pagoParcial;
}
