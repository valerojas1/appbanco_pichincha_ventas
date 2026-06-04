enum PerfilOficial {
  operador,
  superoperador,
  supervisor,
  administrador;

  static PerfilOficial fromString(String value) {
    return PerfilOficial.values.firstWhere(
      (p) => p.name == value,
      orElse: () => PerfilOficial.operador,
    );
  }

  String get etiqueta {
    switch (this) {
      case PerfilOficial.operador:
        return 'Operador';
      case PerfilOficial.superoperador:
        return 'Superoperador';
      case PerfilOficial.supervisor:
        return 'Supervisor';
      case PerfilOficial.administrador:
        return 'Administrador';
    }
  }
}
