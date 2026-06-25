import 'package:flutter/material.dart';
import '../../../../ui/theme/app_theme.dart';

class AdminContentHeader extends StatelessWidget {
  final String titulo;
  final String? subtitulo;
  final List<Widget>? acciones;

  const AdminContentHeader({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.acciones,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitulo != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitulo!,
                    style: const TextStyle(
                      color: AppTheme.grisMedio,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (acciones != null) ...acciones!,
        ],
      ),
    );
  }
}
