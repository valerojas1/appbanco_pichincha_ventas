class ScoringResultadoModel {
  final double score;
  final String segmento;
  final String decision;
  final double? montomaximo;
  final double? tasasugerida;

  ScoringResultadoModel({
    required this.score,
    required this.segmento,
    required this.decision,
    this.montomaximo,
    this.tasasugerida,
  });

  factory ScoringResultadoModel.fromJson(Map<String, dynamic> json) {
    return ScoringResultadoModel(
      score: (json['score'] ?? 0).toDouble(),
      segmento: json['segmento'] ?? '',
      decision: json['decision'] ?? '',
      montomaximo: (json['montomaximo'] as num?)?.toDouble(),
      tasasugerida: (json['tasasugerida'] as num?)?.toDouble(),
    );
  }
}
