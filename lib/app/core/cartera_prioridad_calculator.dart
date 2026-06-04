import '../model/cartera_diaria_model.dart';

class CarteraPrioridadCalculator {
  static int calcular(CarteraDiariaModel item) {
    var score = 0;

    if (item.moraactiva || item.tipogestion == 'RECUPERACION MORA') {
      score += 40;
      final extra = item.diasenmora.clamp(0, 30);
      score += extra;
    }

    if (item.tipogestion == 'RENOVACION' && item.monto > 5000) {
      score += 35;
    } else if (item.tipogestion == 'AMPLIACION') {
      score += 25;
    } else if (item.tipogestion == 'SEGUIMIENTO') {
      score += 10;
    } else if (item.tipogestion == 'NUEVA SOLICITUD') {
      score += 5;
    }

    return score;
  }

  static List<CarteraDiariaModel> conScore(List<CarteraDiariaModel> items) {
    return items
        .map((i) => i.copyWith(scorePrioridad: calcular(i)))
        .toList();
  }
}
