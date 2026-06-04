import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../navigation/app_router.dart';
import '../../viewmodel/auth_oficial_viewmodel.dart';
import '../../viewmodel/clientes_credito_viewmodel.dart';
import '../../ui/theme/app_theme.dart';
import 'clientes_pichincha_tab.dart';
import 'prospectos_credito_tab.dart';

class HomeOficialScreen extends StatefulWidget {
  const HomeOficialScreen({super.key});

  @override
  State<HomeOficialScreen> createState() => _HomeOficialScreenState();
}

class _HomeOficialScreenState extends State<HomeOficialScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClientesCreditoViewModel>().cargarTodo();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final oficial = context.watch<AuthOficialViewModel>().oficial;

    return Scaffold(
      backgroundColor: AppTheme.fondoOscuro,
      appBar: AppBar(
        title: Column(
          children: [
            const Text(
              'Portal Oficial de Crédito',
              style: TextStyle(
                color: AppTheme.amarillo,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (oficial != null)
              Text(
                '${oficial.nombre} ${oficial.apellido}',
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.dashboard_outlined, color: AppTheme.amarillo),
            tooltip: 'Dashboard',
            onPressed: () =>
                Navigator.pushNamed(context, AppRouter.dashboard),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.amarillo),
            tooltip: 'Cerrar sesión',
            onPressed: () {
              context.read<AuthOficialViewModel>().logout();
              Navigator.pushReplacementNamed(context, AppRouter.login);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.amarillo,
          labelColor: AppTheme.amarillo,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(
              icon: Icon(Icons.account_balance, size: 20),
              text: 'Clientes Pichincha',
            ),
            Tab(
              icon: Icon(Icons.person_search, size: 20),
              text: 'Prospectos Crédito',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ClientesPichinchaTab(),
          ProspectosCreditoTab(),
        ],
      ),
    );
  }
}
