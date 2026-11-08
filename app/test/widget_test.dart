import 'package:flutter_test/flutter_test.dart';
import 'package:yunta/main.dart';

void main() {
  testWidgets('sin claves muestra cómo conectar', (tester) async {
    await tester.pumpWidget(const SetupApp());
    expect(find.textContaining('Falta conectar'), findsOneWidget);
  });
}
