import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Resultado del procesamiento pesado de imagen (isolate).
class ResultadoProcesoImagen {
  final double nitidez;
  final bool nitida;
  final Uint8List bytesJpeg;

  ResultadoProcesoImagen({
    required this.nitidez,
    required this.nitida,
    required this.bytesJpeg,
  });
}

/// Utilidades de nitidez (varianza del Laplaciano) y compresión JPEG.
class DocumentoImagenUtil {
  static const int maxBytes = 800 * 1024;
  static const double nitidezMinima = 80.0;
  static const int _anchoMaxNitidez = 1200;

  /// Procesa en segundo plano para no bloquear la UI (evita ANR).
  static Future<ResultadoProcesoImagen> procesarEnSegundoPlano(
    Uint8List raw,
  ) {
    return compute(_procesarCapturaIsolate, raw);
  }

  static ResultadoProcesoImagen _procesarCapturaIsolate(Uint8List raw) {
    final decoded = img.decodeImage(raw);
    if (decoded == null) {
      return ResultadoProcesoImagen(
        nitidez: 0,
        nitida: false,
        bytesJpeg: raw,
      );
    }

    final muestra = decoded.width > _anchoMaxNitidez
        ? img.copyResize(decoded, width: _anchoMaxNitidez)
        : decoded;
    final nitidez = _varianzaLaplacianaEnGris(img.grayscale(muestra));
    final nitida = nitidez >= nitidezMinima;
    final comprimido = _comprimirHasta800KbSync(decoded);

    return ResultadoProcesoImagen(
      nitidez: nitidez,
      nitida: nitida,
      bytesJpeg: comprimido,
    );
  }

  static double varianzaLaplaciana(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return 0;
    final gray = img.grayscale(
      decoded.width > _anchoMaxNitidez
          ? img.copyResize(decoded, width: _anchoMaxNitidez)
          : decoded,
    );
    return _varianzaLaplacianaEnGris(gray);
  }

  static bool esNitida(Uint8List bytes) =>
      varianzaLaplaciana(bytes) >= nitidezMinima;

  static Future<Uint8List> comprimirHasta800Kb(Uint8List raw) async {
    return compute(_comprimirIsolate, raw);
  }

  static Uint8List _comprimirIsolate(Uint8List raw) =>
      _comprimirHasta800KbSync(
        img.decodeImage(raw) ?? img.Image(width: 1, height: 1),
      );

  static double _varianzaLaplacianaEnGris(img.Image gray) {
    final w = gray.width;
    final h = gray.height;
    if (w < 3 || h < 3) return 0;

    double sum = 0;
    double sumSq = 0;
    var count = 0;

    for (var y = 1; y < h - 1; y++) {
      for (var x = 1; x < w - 1; x++) {
        final c = gray.getPixel(x, y).r.toDouble();
        final lap = -4 * c +
            gray.getPixel(x - 1, y).r +
            gray.getPixel(x + 1, y).r +
            gray.getPixel(x, y - 1).r +
            gray.getPixel(x, y + 1).r;
        sum += lap;
        sumSq += lap * lap;
        count++;
      }
    }

    if (count == 0) return 0;
    final mean = sum / count;
    return (sumSq / count) - (mean * mean);
  }

  static Uint8List _comprimirHasta800KbSync(img.Image decoded) {
    var quality = 85;
    var ancho = decoded.width;

    while (quality >= 25) {
      var imagen = decoded;
      if (ancho < decoded.width) {
        imagen = img.copyResize(decoded, width: ancho);
      }
      final jpg = Uint8List.fromList(img.encodeJpg(imagen, quality: quality));
      if (jpg.length <= maxBytes) return jpg;

      quality -= 10;
      if (quality < 50 && ancho > 720) {
        ancho = (ancho * 0.85).round();
      }
    }

    final fallback = img.copyResize(decoded, width: 720);
    return Uint8List.fromList(img.encodeJpg(fallback, quality: 25));
  }
}
