import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waterpark/main.dart';

void main() {
  testWidgets('waterpark dashboard renders overview content', (tester) async {
    await tester.pumpWidget(const WaterparkApp());
    await tester.pumpAndSettle();

    expect(find.text('Dashboard Overview'), findsOneWidget);
    expect(find.text('Quick Actions'), findsOneWidget);
    expect(find.byIcon(Icons.wifi_rounded), findsOneWidget);
  });
}
