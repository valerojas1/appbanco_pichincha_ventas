class AuthConstants {
  static const String empleadoEmailDomain = '@empleados.pichincha.pe';

  static const int maxLoginAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 30);
  static const Duration sessionInactivityLimit = Duration(hours: 8);

  static String emailFromCodigoEmpleado(String codigo) {
    return '${codigo.trim()}$empleadoEmailDomain';
  }
}
