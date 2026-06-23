import 'package:flutter_test/flutter_test.dart';
import 'package:waterpark/main.dart';

void main() {
  testWidgets('waterpark dashboard renders overview content', (tester) async {
    await tester.pumpWidget(const WaterparkApp());
    await tester.pumpAndSettle();

    expect(find.text('Welcome back,'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);
    expect(find.text('Dashboard Overview'), findsOneWidget);
    expect(find.text('Quick Actions'), findsOneWidget);
  });
}
