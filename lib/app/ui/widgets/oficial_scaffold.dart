import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Envuelve el contenido en [Scaffold] solo cuando no está embebido en el shell.
class OficialScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final bool embedded;

  const OficialScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context) {
    if (embedded) {
      return ColoredBox(
        color: AppTheme.fondoOscuro,
        child: SizedBox.expand(child: body),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.fondoOscuro,
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            color: AppTheme.amarillo,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: actions,
      ),
      body: body,
    );
  }
}
