import 'package:flutter/material.dart';
import '../../home/cartera_vencida_screen.dart';
import 'widgets/admin_content_header.dart';

class AdminCobranzaScreen extends StatelessWidget {
  const AdminCobranzaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminContentHeader(
          titulo: 'Cobranza',
          subtitulo: 'Gestión de mora y acciones de cobranza del día',
        ),
        Expanded(child: CarteraVencidaScreen(embedded: true)),
      ],
    );
  }
}
