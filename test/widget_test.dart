import 'package:flutter_test/flutter_test.dart';
import 'package:appbanco_pichincha_ventas/main.dart';

void main() {
  testWidgets('App builds without error', (WidgetTester tester) async {
    await tester.pumpWidget(const AppPichinchaVentas());
  });
}
