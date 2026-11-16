import 'package:flutter_test/flutter_test.dart';
import 'package:si_paket/main.dart';

void main() {
  testWidgets('SI-PAKET role selection smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SiPaketApp());

    expect(find.text('SI-PAKET'), findsOneWidget);
    expect(find.text('Admin Pos'), findsOneWidget);
    expect(find.text('Kurir'), findsOneWidget);
    expect(find.text('User/Pelanggan'), findsOneWidget);
  });
}