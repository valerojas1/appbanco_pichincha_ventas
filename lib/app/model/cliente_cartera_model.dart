class ClienteCarteraModel {
  final String nombre;
  final String dni;
  final String tipoGestion; // 'renovacion' | 'nuevo' | 'cobranza'
  final String estado;      // 'pendiente' | 'visitado'
  final String direccion;

  ClienteCarteraModel({
    required this.nombre,
    required this.dni,
    required this.tipoGestion,
    required this.estado,
    required this.direccion,
  });
}