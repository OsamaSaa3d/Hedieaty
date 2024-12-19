import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lab3/main.dart'; // Import the app entry point directly
import 'package:firebase_core/firebase_core.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('End-to-End Test: Login, Search, and Navigate to Events',
      (WidgetTester tester) async {
    // Ensure Firebase is initialized before the test starts
    await Firebase.initializeApp();

    // Launch the app
    await tester.pumpWidget(HedieatyApp());

    // Wait for any animations or setup to complete
    await tester.pumpAndSettle();

    // Step 1: Log in
    final emailField = find.byKey(const Key('email_field'));
    final passwordField = find.byKey(const Key('password_field'));
    final loginButton = find.byKey(const Key('login_button'));

    // Ensure the login fields are present
    expect(emailField, findsOneWidget);
    expect(passwordField, findsOneWidget);
    expect(loginButton, findsOneWidget);

    // Enter the credentials
    await tester.enterText(emailField, 'lol@gmail.com');
    await tester.pump(Duration(seconds: 1)); // Wait for the field to update
    await tester.enterText(passwordField, '#Osama1234');
    await tester.pump(Duration(seconds: 1)); // Wait for the field to update

    // Tap the login button
    await tester.tap(loginButton);
    await tester.pump(Duration(seconds: 5));
    await tester.pumpAndSettle();

    // Step 2: Search for "Osama"
    final searchField = find.byType(TextField);
    await tester.enterText(searchField, 'Osama');
    await tester.pump(Duration(seconds: 1));
    await tester.pumpAndSettle(); // Wait for the search results to update

    final listTileWithOsama = find.byKey(const Key('friend_tile'));
    expect(listTileWithOsama, findsOneWidget);

    // Step 4: Tap on the card to navigate to the events page
    await tester.tap(listTileWithOsama);
    await tester.pumpAndSettle(); // Wait for the page to navigate
    await tester.pump(Duration(seconds: 5));

    // Step 1: Tap the PopupMenuButton
    final popupMenuButton = find.byKey(const Key('popup_menu'));
    expect(popupMenuButton, findsOneWidget);

    // Select "Sort by Name"
    await tester.tap(popupMenuButton);
    await tester.pumpAndSettle(); // Wait for the menu to appear
    await tester.pump(Duration(seconds: 2));
    final sortByName = find.byKey(const Key('sort_name'));
    expect(sortByName, findsOneWidget);

    await tester.tap(sortByName);
    await tester.pumpAndSettle(); // Wait for the selection to take effect
    await tester.pump(Duration(seconds: 2));
    // Select "Sort by Category"
    await tester.tap(popupMenuButton);
    await tester.pumpAndSettle();

    final sortByCategory = find.byKey(const Key('sort_category'));
    expect(sortByCategory, findsOneWidget);

    await tester.tap(sortByCategory);
    await tester.pumpAndSettle();
    await tester.pump(Duration(seconds: 2));
    // Select "Sort by Status"
    await tester.tap(popupMenuButton);
    await tester.pumpAndSettle();

    final sortByStatus = find.byKey(const Key('sort_status'));
    expect(sortByStatus, findsOneWidget);

    await tester.tap(sortByStatus);
    await tester.pumpAndSettle();
    await tester.pump(Duration(seconds: 2));

    // Verify complete sequence
    print('Test completed: Sort by Name → Category → Status');

    final events_searchField = find.byType(TextField);
    await tester.enterText(events_searchField, 'bd party');
    await tester.pump(Duration(seconds: 1));
    await tester.pumpAndSettle();

    final event_tile = find.byKey(const Key('event_tile'));
    expect(event_tile, findsOneWidget);

    await tester.tap(event_tile);
    await tester.pumpAndSettle();
    await tester.pump(Duration(seconds: 5));

    final giftspopupMenuButton = find.byKey(const Key('gifts_popup_menu'));
    expect(giftspopupMenuButton, findsOneWidget);

    await tester.tap(giftspopupMenuButton);
    await tester.pumpAndSettle();

    final giftsSortByName = find.byKey(const Key('sort_gifts_name'));
    expect(giftsSortByName, findsOneWidget);

    await tester.tap(giftsSortByName);
    await tester.pumpAndSettle();

    await tester.tap(giftspopupMenuButton);
    await tester.pumpAndSettle();

    final giftsSortByCategory = find.byKey(const Key('sort_gifts_category'));
    expect(giftsSortByCategory, findsOneWidget);

    await tester.tap(giftsSortByCategory);
    await tester.pumpAndSettle();

    await tester.tap(giftspopupMenuButton);
    await tester.pumpAndSettle();

    final giftsSortByStatus = find.byKey(const Key('sort_gifts_status'));
    expect(giftsSortByStatus, findsOneWidget);

    await tester.tap(giftsSortByStatus);
    await tester.pumpAndSettle();

    print('Test completed: Sort by Name → Category → Status');

    final gifts_searchField = find.byType(TextField);
    await tester.enterText(gifts_searchField, 'green');
    await tester.pump(Duration(seconds: 1));
    await tester.pumpAndSettle();

    final gift_tile = find.byKey(const Key('gift_tile'));
    expect(gift_tile, findsOneWidget);

    await tester.tap(gift_tile);
    await tester.pumpAndSettle();
    await tester.pump(Duration(seconds: 5));

    final close_gift_button = find.byKey(const Key('close_button'));
    expect(close_gift_button, findsOneWidget);

    await tester.tap(close_gift_button);
    await tester.pumpAndSettle();

    print('Test completed: Search for "green"');

    await tester.enterText(gifts_searchField, '');
    await tester.pump(Duration(seconds: 3));
    await tester.pumpAndSettle();

    final pledge_gifts_button =
        find.byKey(const Key('gift_pledge_switch')).first;
    expect(pledge_gifts_button, findsOneWidget);

    await tester.tap(pledge_gifts_button);
    await tester.pumpAndSettle();

    await tester.pump(Duration(seconds: 4));

    await tester.tap(pledge_gifts_button);
    await tester.pumpAndSettle();

    print('Test completed: Pledge Gifts');

    // back to events page
    final giftsBackButton = find.byTooltip('Back');
    expect(giftsBackButton, findsOneWidget);

    await tester.tap(giftsBackButton);
    await tester.pumpAndSettle();

    // back to home page
    final eventBackButton = find.byTooltip('Back');
    expect(eventBackButton, findsOneWidget);

    await tester.tap(eventBackButton);
    await tester.pumpAndSettle();

    final homeSearchField = find.byType(TextField);
    await tester.enterText(homeSearchField, '');
    await tester.pump(Duration(seconds: 1));
    await tester.pumpAndSettle();

    final buttonNavBarEvents = find.byKey(const Key('bottom_nav_bar_events'));
    expect(buttonNavBarEvents, findsOneWidget);

    await tester.tap(buttonNavBarEvents);
    await tester.pumpAndSettle();
    await tester.pump(Duration(seconds: 3));

    final addEventButton = find.byKey(const Key('add_event_button'));
    expect(addEventButton, findsOneWidget);

    await tester.tap(addEventButton);
    await tester.pumpAndSettle();

    final event_name_field = find.byKey(const Key('event_name_field'));
    expect(event_name_field, findsOneWidget);

    await tester.enterText(event_name_field, 'bd party');
    await tester.pump(Duration(seconds: 1));
    await tester.pumpAndSettle();

    final event_description_field =
        find.byKey(const Key('event_description_field'));
    expect(event_description_field, findsOneWidget);

    await tester.enterText(event_description_field, 'my party');
    await tester.pump(Duration(seconds: 1));
    await tester.pumpAndSettle();

    final event_location_field = find.byKey(const Key('event_location_field'));
    expect(event_location_field, findsOneWidget);

    await tester.enterText(event_location_field, 'cairo');
    await tester.pump(Duration(seconds: 1));

    final event_date_field = find.byKey(const Key('event_date_field'));
    expect(event_date_field, findsOneWidget);

    await tester.tap(event_date_field);
    await tester.pumpAndSettle();

    final event_date_picker_ok = find.text('OK');
    expect(event_date_picker_ok, findsOneWidget);

    await tester.tap(event_date_picker_ok);
    await tester.pumpAndSettle();

    final create_event_button = find.byKey(const Key('create_event_button'));
    expect(create_event_button, findsOneWidget);

    await tester.tap(create_event_button);
    await tester.pumpAndSettle();

    print('Test completed: Create Event');

    final my_event_tile = find.byKey(const Key('event_tile')).first;
    expect(my_event_tile, findsOneWidget);

    await tester.tap(my_event_tile);
    await tester.pumpAndSettle();

    final add_gift_button = find.byKey(const Key('add_gift_button'));
    expect(add_gift_button, findsOneWidget);

    await tester.tap(add_gift_button);
    await tester.pumpAndSettle();

    final gift_name_field = find.byKey(const Key('gift_name_field'));
    expect(gift_name_field, findsOneWidget);

    await tester.enterText(gift_name_field, 'Laptop');
    await tester.pump(Duration(seconds: 1));

    final gift_description_field =
        find.byKey(const Key('gift_description_field'));
    expect(gift_description_field, findsOneWidget);

    await tester.enterText(gift_description_field, 'I want a new laptop');
    await tester.pump(Duration(seconds: 1));

    final gift_category_field = find.byKey(const Key('gift_category_field'));
    expect(gift_category_field, findsOneWidget);

    await tester.enterText(gift_category_field, 'Technology');
    await tester.pump(Duration(seconds: 1));

    final gift_price_field = find.byKey(const Key('gift_price_field'));
    expect(gift_price_field, findsOneWidget);

    await tester.enterText(gift_price_field, '100');
    await tester.pump(Duration(seconds: 1));

    final gift_create_button = find.byKey(const Key('gift_create_button'));
    expect(gift_create_button, findsOneWidget);

    await tester.tap(gift_create_button);
    await tester.pumpAndSettle();

    print('Test completed: Create Gift');

    final my_gift_tile = find.byKey(const Key('gift_tile')).first;
    expect(my_gift_tile, findsOneWidget);

    await tester.tap(my_gift_tile);
    await tester.pumpAndSettle();

    final next_close_gift_button = find.byKey(const Key('close_button'));
    expect(next_close_gift_button, findsOneWidget);

    await tester.tap(next_close_gift_button);
    await tester.pumpAndSettle();

    final edit_gift_button = find.byKey(const Key('edit_gift_button'));
    expect(edit_gift_button, findsOneWidget);

    await tester.tap(edit_gift_button);
    await tester.pumpAndSettle();

    final gift_name_field_edit = find.byKey(const Key('gift_name_field'));
    expect(gift_name_field_edit, findsOneWidget);

    await tester.enterText(gift_name_field_edit, 'Car');
    await tester.pump(Duration(seconds: 4));

    final next_gift_create_button = find.byKey(const Key('gift_create_button'));
    expect(next_gift_create_button, findsOneWidget);

    await tester.tap(next_gift_create_button);
    await tester.pumpAndSettle();

    print('Test completed: Edit Gift');
    await tester.pump(Duration(seconds: 4));
    final delete_gift_button = find.byKey(const Key('delete_gift_button'));
    expect(delete_gift_button, findsOneWidget);

    await tester.tap(delete_gift_button);
    await tester.pumpAndSettle();
    await tester.pump(Duration(seconds: 4));

    print('Test completed: Delete Gift');

    final next_giftsBackButton = find.byTooltip('Back');
    expect(next_giftsBackButton, findsOneWidget);

    await tester.tap(next_giftsBackButton);
    await tester.pumpAndSettle();

    final deleteEventButton =
        find.byKey(const Key('delete_event_button')).first;
    expect(deleteEventButton, findsOneWidget);

    await tester.tap(deleteEventButton);
    await tester.pumpAndSettle();
    await tester.pump(Duration(seconds: 2));
    print('Test completed: Delete Event');

    final to_homepage_button = find.byTooltip('Back');
    expect(to_homepage_button, findsOneWidget);

    await tester.tap(to_homepage_button);
    await tester.pumpAndSettle();
    await tester.pump(Duration(seconds: 2));
    final to_profile_button = find.byKey(const Key('profile_button'));
    expect(to_profile_button, findsOneWidget);

    await tester.tap(to_profile_button);
    await tester.pumpAndSettle();

    final myPledgedGfitsButton =
        find.byKey(const Key('my_pledged_gifts_button'));
    expect(myPledgedGfitsButton, findsOneWidget);

    await tester.tap(myPledgedGfitsButton);
    await tester.pumpAndSettle();
    await tester.pump(Duration(seconds: 4));
    print('Test completed: My Pledged Gifts');

    final to_profilee_button = find.byTooltip('Back');
    expect(to_profilee_button, findsOneWidget);

    await tester.tap(to_profilee_button);
    await tester.pumpAndSettle();

    final myGotPledgedGfitsButton =
        find.byKey(const Key('my_event_that_got_pledged_button'));
    expect(myGotPledgedGfitsButton, findsOneWidget);

    await tester.tap(myGotPledgedGfitsButton);
    await tester.pumpAndSettle();
    await tester.pump(Duration(seconds: 4));
    print('Test completed: My Got Pledged Gifts');

    // to profile
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    // to homepage
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.pump(Duration(seconds: 2));
    final logoutButton = find.byKey(const Key('logout_button'));
    expect(logoutButton, findsOneWidget);

    await tester.tap(logoutButton);
    await tester.pumpAndSettle();
    await tester.pump(Duration(seconds: 4));
    print('Test completed: Logout');
  });
}
