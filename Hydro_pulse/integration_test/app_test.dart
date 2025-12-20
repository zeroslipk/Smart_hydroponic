import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:aquagrow_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('end-to-end test', () {
    testWidgets('tap on quick action button, verify no crash',
        (tester) async {
      app.main();
      
      // Wait for the Splash Screen delay (4 seconds in code)
      // We wait 8 seconds to be safe and allow animations on slower devices
      await Future.delayed(const Duration(seconds: 8));
      await tester.pump(); // Use pump() instead of pumpAndSettle() due to infinite Splash animation

      // Check if we are stuck on Auth Screen
      final loginFinder = find.text('Join HydroPulse');
      final welcomeFinder = find.text('Welcome Back');
      
      if (loginFinder.evaluate().isNotEmpty || welcomeFinder.evaluate().isNotEmpty) {
        // We are on the login screen.
        // Since we can't automate login without credentials, we fail gracefully.
        debugPrint('----------------------------------------------------');
        debugPrint('TEST INFO: App is on Login Screen.');
        debugPrint('Please log in on the device manually, then run test again.');
        debugPrint('----------------------------------------------------');
        // We can either fail or return. Fail makes it clear.
        fail('Device is not logged in. Please log in on the device and retry.');
      }

      // If we are here, we should be on Dashboard
      final pumpFinder = find.text('Pump');
      
      // Wait for Dashboard to settle and Pump button to appear
      bool dashLoaded = false;
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 500));
        if (find.text('HydroPulse System').evaluate().isNotEmpty) {
          dashLoaded = true;
          break;
        }
      }
      
      if (!dashLoaded) {
        fail('Dashboard did not load in time (Stuck on Splash?)');
      }

      // Verify Dashboard is loaded (check for Unique Subtitle)
      expect(find.text('HydroPulse System'), findsOneWidget);
      debugPrint('TEST STATUS: Dashboard Loaded');

      // Ensure the button is visible (scroll if needed)
      // We loop briefly to ensure it's in the tree before ensuring visibility
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      
      await tester.ensureVisible(pumpFinder);
      await tester.pump(); // Cannot use pumpAndSettle due to infinite animations
      debugPrint('TEST STATUS: Pump Switch Found and Visible');

      // Tap the Pump button
      debugPrint('TEST STATUS: Tapping Pump Switch...');
      await tester.tap(pumpFinder);
      await tester.pump(); // Pump a frame to process the tap
      
      // Wait a bit for any feedback animation (but don't settle infinite ones)
      await Future.delayed(const Duration(milliseconds: 500)); 
      debugPrint('TEST STATUS: Tap Complete');

      // Verify we are still running
      expect(find.text('HydroPulse'), findsOneWidget);
      debugPrint('TEST STATUS: Test Finished Successfully!');
    });
  });
}
