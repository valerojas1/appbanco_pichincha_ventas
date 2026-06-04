import 'tipo_documento_config.dart';

class DocumentoSlotModel {
  final TipoDocumentoConfig config;
  String? registroId;
  String? storagePath;
  String? urlPublica;
  double? puntajeNitidez;
  int? tamanoKb;
  bool subiendo;

  DocumentoSlotModel({
    required this.config,
    this.registroId,
    this.storagePath,
    this.urlPublica,
    this.puntajeNitidez,
    this.tamanoKb,
    this.subiendo = false,
  });

  bool get estaListo => storagePath != null && storagePath!.isNotEmpty;

  EstadoDocumentoChecklist get estadoChecklist {
    if (estaListo) return EstadoDocumentoChecklist.listo;
    if (config.obligatorio) return EstadoDocumentoChecklist.obligatorioPendiente;
    return EstadoDocumentoChecklist.pendiente;
  }

  DocumentoSlotModel copyWith({
    String? registroId,
    String? storagePath,
    String? urlPublica,
    double? puntajeNitidez,
    int? tamanoKb,
    bool? subiendo,
    bool limpiar = false,
  }) {
    if (limpiar) {
      return DocumentoSlotModel(config: config);
    }
    return DocumentoSlotModel(
      config: config,
      registroId: registroId ?? this.registroId,
      storagePath: storagePath ?? this.storagePath,
      urlPublica: urlPublica ?? this.urlPublica,
      puntajeNitidez: puntajeNitidez ?? this.puntajeNitidez,
      tamanoKb: tamanoKb ?? this.tamanoKb,
      subiendo: subiendo ?? this.subiendo,
    );
  }
}
