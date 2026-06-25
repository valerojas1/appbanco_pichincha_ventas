import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class GeocercaZonaModel {
  final String id;
  final String nombre;
  final String? descripcion;
  final String colorHex;
  final List<LatLng> puntos;
  final bool activa;

  GeocercaZonaModel({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.colorHex,
    required this.puntos,
    required this.activa,
  });

  Color get color {
    final hex = colorHex.replaceAll('#', '');
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    }
    return const Color(0xFFFFD100);
  }

  factory GeocercaZonaModel.fromJson(Map<String, dynamic> json) {
    final poligono = json['poligono'];
    final puntos = <LatLng>[];
    if (poligono is List) {
      for (final p in poligono) {
        if (p is Map) {
          puntos.add(LatLng(
            _toDouble(p['lat']),
            _toDouble(p['lng']),
          ));
        }
      }
    }

    return GeocercaZonaModel(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'],
      colorHex: json['color'] ?? '#FFD100',
      puntos: puntos,
      activa: json['activa'] != false,
    );
  }

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }
}
