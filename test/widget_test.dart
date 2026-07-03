import 'package:flutter_test/flutter_test.dart';
import 'package:qr_app/main.dart';

void main() {
  testWidgets('QR App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const QRApp());
    expect(find.text('Generator QR'), findsNothing); // Loaded lazily
  });
}
