import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';
import 'package:frontend/ui/hud/resource_dashboard.dart';

void main() {
  testWidgets('StrategyApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: StrategyApp(),
      ),
    );

    // Initial pump
    await tester.pump();

    // Verify top Resource Dashboard is present
    expect(find.byType(ResourceDashboard), findsOneWidget);
    expect(find.text('TURN'), findsOneWidget);
  });
}
