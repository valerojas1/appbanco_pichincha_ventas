import 'package:flutter/material.dart';

class AppTheme {
  // Mismo branding Pichincha — versión oscura para oficiales
  static const Color amarillo = Color(0xFFFFD100);
  static const Color navy = Color(0xFF1A2B5E);
  static const Color navyOscuro = Color(0xFF0F1A3D);
  static const Color fondoOscuro = Color(0xFF0D1B3E);
  static const Color superficie = Color(0xFF162447);
  static const Color blanco = Color(0xFFFFFFFF);
  static const Color grisMedio = Color(0xFF9E9E9E);
  static const Color verdePendiente = Color(0xFF43A047);
  static const Color azulVisitado = Color(0xFF1E88E5);
  static const Color naranjaNuevo = Color(0xFFFB8C00);

  static ThemeData get temaVentas => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: navy,
          brightness: Brightness.dark,
          primary: amarillo,
          secondary: navy,
          surface: superficie,
          error: Colors.redAccent,
        ),
        scaffoldBackgroundColor: fondoOscuro,
        appBarTheme: const AppBarTheme(
          backgroundColor: navyOscuro,
          foregroundColor: amarillo,
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: amarillo,
            foregroundColor: navy,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: superficie,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: amarillo.withOpacity(0.4)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: amarillo.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: amarillo, width: 2),
          ),
          labelStyle: const TextStyle(color: Colors.white70),
          prefixIconColor: amarillo,
        ),
      );
}