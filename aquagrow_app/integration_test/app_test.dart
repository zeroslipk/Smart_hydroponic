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
      // We wait 6 seconds to be safe and allow animations
      await Future.delayed(const Duration(seconds: 6));
      await tester.pump(); // Use pump() instead of pumpAndSettle() due to infinite Splash animation

      // Check if we are stuck on Auth Screen
      final loginFinder = find.text('Join AquaGrow');
      final welcomeFinder = find.text('Welcome Back');
      
      if (loginFinder.evaluate().isNotEmpty || welcomeFinder.evaluate().isNotEmpty) {
        // We are on the login screen.
        // Since we can't automate login without credentials, we fail gracefully.
        print('----------------------------------------------------');
        print('TEST INFO: App is on Login Screen.');
        print('Please log in on the device manually, then run test again.');
        print('----------------------------------------------------');
        // We can either fail or return. Fail makes it clear.
        fail('Device is not logged in. Please log in on the device and retry.');
      }

      // If we are here, we should be on Dashboard
      final pumpFinder = find.text('Pump');
      
      // Verify Dashboard is loaded (check for AquaGrow title which is in AppBar)
      expect(find.text('AquaGrow'), findsOneWidget);
      print('TEST STATUS: Dashboard Loaded');

      // Find the Pump button
      // final pumpFinder = find.text('Pump'); // ALREADY DECLARED ABOVE
      
      // Ensure the button is visible (scroll if needed)
      await tester.ensureVisible(pumpFinder);
      await tester.pump(); // Cannot use pumpAndSettle due to infinite animations
      print('TEST STATUS: Pump Switch Found and Visible');

      // Tap the Pump button
      print('TEST STATUS: Tapping Pump Switch...');
      await tester.tap(pumpFinder);
      await tester.pump(); // Pump a frame to process the tap
      
      // Wait a bit for any feedback animation (but don't settle infinite ones)
      await Future.delayed(const Duration(milliseconds: 500)); 
      print('TEST STATUS: Tap Complete');

      // Verify we are still running
      expect(find.text('AquaGrow'), findsOneWidget);
      print('TEST STATUS: Test Finished Successfully!');
    });
  });
}
