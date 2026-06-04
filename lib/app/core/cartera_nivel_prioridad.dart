import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum NivelPrioridad { alta, media, normal }

class CarteraNivelPrioridad {
  static NivelPrioridad desdeScore(int score) {
    if (score >= 45) return NivelPrioridad.alta;
    if (score >= 20) return NivelPrioridad.media;
    return NivelPrioridad.normal;
  }

  static String etiqueta(NivelPrioridad nivel) {
    switch (nivel) {
      case NivelPrioridad.alta:
        return 'ALTA';
      case NivelPrioridad.media:
        return 'MEDIA';
      case NivelPrioridad.normal:
        return 'NORMAL';
    }
  }

  static Color colorMarcador(NivelPrioridad nivel, {bool visitado = false}) {
    if (visitado) return Colors.grey;
    switch (nivel) {
      case NivelPrioridad.alta:
        return Colors.red;
      case NivelPrioridad.media:
        return Colors.amber;
      case NivelPrioridad.normal:
        return Colors.green;
    }
  }

  static double hueMarcador(NivelPrioridad nivel, {bool visitado = false}) {
    if (visitado) return BitmapDescriptor.hueAzure;
    switch (nivel) {
      case NivelPrioridad.alta:
        return BitmapDescriptor.hueRed;
      case NivelPrioridad.media:
        return BitmapDescriptor.hueYellow;
      case NivelPrioridad.normal:
        return BitmapDescriptor.hueGreen;
    }
  }
}
