import 'package:flutter_test/flutter_test.dart';
import 'package:smart_landmarks/main.dart';

void main() {
  testWidgets('App should render', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartLandmarksApp());
    expect(find.text('Smart Landmarks'), findsOneWidget);
  });
}
