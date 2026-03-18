import 'package:flutter_test/flutter_test.dart';

import 'package:webapp/app.dart';

void main() {
  testWidgets('dashboard renders key workspaces', (WidgetTester tester) async {
    await tester.pumpWidget(const WebApp());
    await tester.pumpAndSettle();

    expect(find.text('Prediction Workspace'), findsWidgets);
    expect(find.text('Model Prediction Interface'), findsOneWidget);
    expect(find.text('Prediction'), findsWidgets);
    expect(find.text('Combine Model Results'), findsWidgets);
  });
}
