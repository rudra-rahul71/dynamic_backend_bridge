import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dynamic_backend_bridge/dynamic_backend_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppBannerWidget tests', () {
    testWidgets('renders success banner correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppBannerWidget(
              type: AppBannerType.success,
              title: 'Success Title',
              body: 'Success Body',
              actionLabel: 'Undo',
              onActionTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Success Title'), findsOneWidget);
      expect(find.text('Success Body'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('renders error banner correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppBannerWidget(
              type: AppBannerType.error,
              title: 'Error Title',
              body: 'Something went wrong',
            ),
          ),
        ),
      );

      expect(find.text('Error Title'), findsOneWidget);
      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.byIcon(Icons.error_rounded), findsOneWidget);
    });

    testWidgets('renders info banner correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppBannerWidget(
              type: AppBannerType.info,
              title: 'Info Title',
              body: 'Info detail message',
            ),
          ),
        ),
      );

      expect(find.text('Info Title'), findsOneWidget);
      expect(find.text('Info detail message'), findsOneWidget);
      expect(find.byIcon(Icons.info_rounded), findsOneWidget);
    });
  });

  group('AppBannerService overlay tests', () {
    testWidgets('shows and hides banner using AppBannerService', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    AppBannerService.showSuccess(
                      context,
                      'Test banner body',
                      title: 'Test Banner Title',
                    );
                  },
                  child: const Text('Show Banner'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Banner'));
      await tester.pumpAndSettle();

      expect(find.text('Test Banner Title'), findsOneWidget);
      expect(find.text('Test banner body'), findsOneWidget);

      AppBannerService.hideCurrentBanner();
      await tester.pumpAndSettle();

      expect(find.text('Test Banner Title'), findsNothing);
    });
  });
}
