import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaisa_application/features/resident/events/event_details_modal.dart';
import 'package:kaisa_application/features/resident/events/kaisa_events_repository.dart';

void main() {
  test('extra registration requirements are explicit and single line', () {
    expect(eventRegistrationRequirement('Bring water and a valid ID.'), isNull);
    expect(
      eventRegistrationRequirement(
        'Registration requirements: \nGoals: Help out',
      ),
      isNull,
    );
    expect(
      eventRegistrationRequirement(
        'Goals: Help out\nRegistration requirements: Present a valid ID.\nImportant instructions: Arrive early.',
      ),
      'Present a valid ID.',
    );
  });

  testWidgets('shows the briefing, top feedback, report form and close button', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 1280);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    var organizerOpened = false;
    final event = KaisaEvent(
      id: 'd32111fd-8580-48bc-9ab6-c7f4afb96301',
      title: '[TEST] Cavite volunteer day',
      organization: 'Community volunteers',
      category: 'Environment',
      description: 'Join a shoreline cleanup.',
      location: 'Samonte Park',
      startsAt: DateTime.utc(2026, 12, 3, 1),
      endsAt: DateTime.utc(2026, 12, 3, 3),
      capacity: 40,
      registeredCount: 3,
      registrationStatus: null,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => Dialog(
                  child: SizedBox(
                    width: 1000,
                    height: 1100,
                    child: EventDetailsModal(
                      title: event.title,
                      coverAsset: null,
                      event: event,
                      openOrganizer: () => organizerOpened = true,
                      info: const {
                        'instructions':
                            'Assembly venue: North gate\n'
                            'Goals: Clear the shoreline\n'
                            'Intended participants: Local volunteers\n'
                            'Required attire or items to bring: Gloves and boots\n'
                            'Important instructions: Arrive early\n'
                            'Registration requirements: Bring a valid ID\n'
                            'Attendance requirements: Check in at arrival\n'
                            'Sample ratings: 5, 4',
                      },
                      feedback: const [],
                      loading: false,
                      error: null,
                      retry: () {},
                      registrationLabel: 'Register',
                      register: null,
                    ),
                  ),
                ),
              ),
              child: const Text('Open event'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open event'));
    await tester.pumpAndSettle();

    final feedback = find.text('Event ratings & verified participant feedback');
    final description = find.text('Event description & Bayanihan objectives');
    expect(
      tester.getTopLeft(feedback).dy,
      lessThan(tester.getTopLeft(description).dy),
    );
    expect(find.text('No verified feedback yet.'), findsOneWidget);
    expect(find.text('4.5 / 5 · 2 sample ratings'), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsNWidgets(4));
    expect(find.byIcon(Icons.star_half_rounded), findsOneWidget);
    await tester.tap(find.text(event.organization));
    expect(organizerOpened, isTrue);
    expect(find.text('North gate'), findsOneWidget);
    expect(find.text('Clear the shoreline'), findsOneWidget);
    expect(find.text('Local volunteers'), findsOneWidget);
    expect(find.text('Gloves and boots'), findsOneWidget);
    expect(find.text('Arrive early'), findsOneWidget);
    expect(
      find.text('Registration requirements\nBring a valid ID'),
      findsOneWidget,
    );
    expect(
      find.text('Attendance requirements\nCheck in at arrival'),
      findsOneWidget,
    );

    await tester.tap(find.text('Submit private report'));
    await tester.pumpAndSettle();
    expect(find.text('Report category'), findsOneWidget);
    expect(find.text('Explanation'), findsOneWidget);
    await tester.tap(find.text('File private report'));
    await tester.pumpAndSettle();
    expect(
      find.text('Choose a category and enter at least 10 characters.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Close event details'));
    await tester.pumpAndSettle();
    expect(find.byType(EventDetailsModal), findsNothing);
  });
}
