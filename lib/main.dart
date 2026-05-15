import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app/navigation/app_router.dart';
import 'app/ui/theme/app_theme.dart';
import 'app/viewmodel/auth_oficial_viewmodel.dart';
import 'app/viewmodel/cartera_viewmodel.dart';

void main() {
  runApp(const AppPichinchaVentas());
}

class AppPichinchaVentas extends StatelessWidget {
  const AppPichinchaVentas({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthOficialViewModel()),
        ChangeNotifierProvider(create: (_) => CarteraViewModel()),
      ],
      child: MaterialApp(
        title: 'Pichincha — Portal Oficial',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.temaVentas,
        initialRoute: AppRouter.login,
        onGenerateRoute: AppRouter.generateRoute,
      ),
    );
  }
}