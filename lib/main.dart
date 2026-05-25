import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/core/supabase_config.dart';
import 'app/navigation/app_router.dart';
import 'app/ui/theme/app_theme.dart';
import 'app/viewmodel/auth_oficial_viewmodel.dart';
import 'app/viewmodel/cartera_viewmodel.dart';
import 'app/viewmodel/dashboard_viewmodel.dart';
import 'app/viewmodel/ruta_viewmodel.dart';
import 'app/viewmodel/ficha_viewmodel.dart';
import 'app/viewmodel/scoring_viewmodel.dart';
import 'app/viewmodel/metas_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );
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
        ChangeNotifierProvider(create: (_) => DashboardViewModel()),
        ChangeNotifierProvider(create: (_) => RutaViewModel()),
        ChangeNotifierProvider(create: (_) => FichaViewModel()),
        ChangeNotifierProvider(create: (_) => ScoringViewModel()),
        ChangeNotifierProvider(create: (_) => MetasViewModel()),
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
