import 'package:flutter/material.dart';

/// Semáforo de mora: 1–30 amarillo, 31–60 naranja, >60 rojo.
enum NivelMoraSemaforo {
  amarillo,
  naranja,
  rojo,
}

class CarteraMoraSemaforo {
  static NivelMoraSemaforo nivel(int diasMora) {
    if (diasMora <= 30) return NivelMoraSemaforo.amarillo;
    if (diasMora <= 60) return NivelMoraSemaforo.naranja;
    return NivelMoraSemaforo.rojo;
  }

  static Color color(int diasMora) {
    switch (nivel(diasMora)) {
      case NivelMoraSemaforo.amarillo:
        return const Color(0xFFFFD100);
      case NivelMoraSemaforo.naranja:
        return const Color(0xFFFF9800);
      case NivelMoraSemaforo.rojo:
        return const Color(0xFFE53935);
    }
  }

  static String etiqueta(int diasMora) {
    final n = nivel(diasMora);
    final rango = switch (n) {
      NivelMoraSemaforo.amarillo => '1–30 días',
      NivelMoraSemaforo.naranja => '31–60 días',
      NivelMoraSemaforo.rojo => 'Más de 60 días',
    };
    return '$diasMora días ($rango)';
  }
}
