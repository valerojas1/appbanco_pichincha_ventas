import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import '../../ui/theme/app_theme.dart';

class VisorDocumentoScreen extends StatelessWidget {
  final String titulo;
  final String imageUrl;

  const VisorDocumentoScreen({
    super.key,
    required this.titulo,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: AppTheme.amarillo,
        title: Text(
          titulo,
          style: const TextStyle(fontSize: 14),
        ),
      ),
      body: PhotoView(
        imageProvider: NetworkImage(imageUrl),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 4,
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        loadingBuilder: (context, event) => const Center(
          child: CircularProgressIndicator(color: AppTheme.amarillo),
        ),
        errorBuilder: (_, __, ___) => const Center(
          child: Text(
            'No se pudo cargar la imagen',
            style: TextStyle(color: Colors.white54),
          ),
        ),
      ),
    );
  }
}
