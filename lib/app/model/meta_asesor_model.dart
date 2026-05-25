class MetaAsesorModel {
  final String metaid;
  final String asesorid;
  final int anio;
  final int mes;
  final int metasvisitas;
  final int metascreditos;
  final double metasmonot;
  final int visitaslogradas;
  final int creditoslogrados;
  final double montologistrado;

  MetaAsesorModel({
    required this.metaid,
    required this.asesorid,
    required this.anio,
    required this.mes,
    required this.metasvisitas,
    required this.metascreditos,
    required this.metasmonot,
    required this.visitaslogradas,
    required this.creditoslogrados,
    required this.montologistrado,
  });

  factory MetaAsesorModel.fromJson(Map<String, dynamic> json) {
    return MetaAsesorModel(
      metaid: json['metaid'] ?? '',
      asesorid: json['asesorid'] ?? '',
      anio: json['anio'] ?? 0,
      mes: json['mes'] ?? 0,
      metasvisitas: json['metasvisitas'] ?? 0,
      metascreditos: json['metascreditos'] ?? 0,
      metasmonot: (json['metasmonto'] ?? 0).toDouble(),
      visitaslogradas: json['visitaslogradas'] ?? 0,
      creditoslogrados: json['creditoslogrados'] ?? 0,
      montologistrado: (json['montologistrado'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'metaid': metaid,
      'asesorid': asesorid,
      'anio': anio,
      'mes': mes,
      'metasvisitas': metasvisitas,
      'metascreditos': metascreditos,
      'metasmonto': metasmonot,
      'visitaslogradas': visitaslogradas,
      'creditoslogrados': creditoslogrados,
      'montologistrado': montologistrado,
    };
  }
}
