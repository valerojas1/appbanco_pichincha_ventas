import '../model/oficial_model.dart';

/// Identificadores posibles del asesor en tablas operativas.
/// En demo, `carteravencida` puede usar el código 100001 mientras
/// `vwperfilasesor` devuelve otro `asesorid` (UUID, userid, etc.).
class AsesorIdUtil {
  static List<String> idsConsulta(OficialModel oficial) {
    final ids = <String>{};
    for (final v in [
      oficial.asesorid,
      oficial.codigoempleado,
      oficial.codigoasesor,
      oficial.userid,
    ]) {
      final t = v.trim();
      if (t.isNotEmpty) ids.add(t);
    }
    return ids.toList();
  }

  static String idPrincipal(OficialModel oficial) {
    final ids = idsConsulta(oficial);
    return ids.isNotEmpty ? ids.first : '';
  }
}
