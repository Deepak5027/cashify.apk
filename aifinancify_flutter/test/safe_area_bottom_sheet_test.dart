import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aifinancify_flutter/widgets/app_bottom_sheet.dart';

void main() {
  testWidgets('AppModalSheetLayout renders title, content and pinned bottom action', (WidgetTester tester) async {
    bool saved = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () {
                  showAppModalBottomSheet(
                    context: context,
                    builder: (ctx) => AppModalSheetLayout(
                      title: 'Add New Transaction',
                      bottomAction: ElevatedButton(
                        key: const Key('save_button'),
                        onPressed: () {
                          saved = true;
                          Navigator.pop(ctx);
                        },
                        child: const Text('Save Transaction'),
                      ),
                      child: Column(
                        children: const [
                          Text('Amount Field'),
                          SizedBox(height: 100),
                          Text('Category Field'),
                        ],
                      ),
                    ),
                  );
                },
                child: const Text('Open Modal'),
              ),
            ),
          ),
        ),
      ),
    );

    // Tap to open modal bottom sheet
    await tester.tap(find.text('Open Modal'));
    await tester.pumpAndSettle();

    // Verify Title, Content, and Save Transaction button are rendered
    expect(find.text('Add New Transaction'), findsOneWidget);
    expect(find.text('Amount Field'), findsOneWidget);
    expect(find.text('Category Field'), findsOneWidget);
    expect(find.text('Save Transaction'), findsOneWidget);

    // Verify the Save button is fully tappable and works
    await tester.tap(find.byKey(const Key('save_button')));
    await tester.pumpAndSettle();

    expect(saved, isTrue);
    expect(find.text('Add New Transaction'), findsNothing);
  });

  testWidgets('AppModalSheetLayout respects bottom safe area on devices with system navigation', (WidgetTester tester) async {
    // Simulate a device with 48dp bottom navigation bar (e.g. 3-button navigation on Android)
    tester.view.padding = const FakeViewPadding(bottom: 48, top: 24, left: 0, right: 0);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppModalSheetLayout(
            title: 'Add New Transaction',
            bottomAction: const SizedBox(
              height: 50,
              child: Text('Save Transaction Button'),
            ),
            child: const Text('Form content'),
          ),
        ),
      ),
    );

    // Find the Save Transaction Button location
    final buttonFinder = find.text('Save Transaction Button');
    expect(buttonFinder, findsOneWidget);

    final buttonBottom = tester.getBottomLeft(buttonFinder).dy;
    final screenHeight = tester.view.physicalSize.height / tester.view.devicePixelRatio;

    // The bottom edge of the button must be at least 48dp above the screen bottom (safe area padding)
    expect(buttonBottom <= screenHeight - 48, isTrue,
        reason: 'Button must sit above the Android 48dp system navigation bar');

    // Reset view padding
    addTearDown(() => tester.view.resetPadding());
  });
}
