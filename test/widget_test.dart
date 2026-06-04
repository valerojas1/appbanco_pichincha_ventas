import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:appbanco_pichincha_ventas/app/core/supabase_config.dart';
import 'package:appbanco_pichincha_ventas/app/viewmodel/auth_oficial_viewmodel.dart';
import 'package:appbanco_pichincha_ventas/main.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
  });

  testWidgets('App builds without error', (WidgetTester tester) async {
    final authViewModel = AuthOficialViewModel();
    await authViewModel.initialize();

    await tester.pumpWidget(AppPichinchaVentas(authViewModel: authViewModel));
    await tester.pump();
  });
}
