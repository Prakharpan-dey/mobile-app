import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mobile_app/locator.dart';
import 'package:mobile_app/models/assignments.dart';
import 'package:mobile_app/ui/views/groups/assignment_details_view.dart';
import '../../utils_tests/image_test_utils.dart';
import 'package:mobile_app/utils/router.dart';
import 'package:mobile_app/viewmodels/groups/assignment_details_viewmodel.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../setup/test_data/mock_assignments.dart';
import '../../setup/test_helpers.mocks.dart';

void main() {
  group('AssignmentDetailsViewTest -', () {
    late MockNavigatorObserver mockObserver;

    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      await setupLocator();
      locator.allowReassignment = true;
    });

    setUp(() => mockObserver = MockNavigatorObserver());

    Future<void> _pumpAssignmentDetailsView(WidgetTester tester) async {
      var _assignment = Assignment.fromJson(mockAssignment);

      // Mock AssignmentDetails ViewModel
      var _assignmentsDetailsViewModel = MockAssignmentDetailsViewModel();
      locator.registerSingleton<AssignmentDetailsViewModel>(
        _assignmentsDetailsViewModel,
      );

      when(
        _assignmentsDetailsViewModel.FETCH_ASSIGNMENT_DETAILS,
      ).thenAnswer((_) => 'fetch_assignment');
      when(
        _assignmentsDetailsViewModel.fetchAssignmentDetails(any),
      ).thenReturn(null);
      when(_assignmentsDetailsViewModel.isSuccess(any)).thenReturn(true);
      when(
        _assignmentsDetailsViewModel.assignment,
      ).thenAnswer((_) => _assignment);
      when(
        _assignmentsDetailsViewModel.projects,
      ).thenAnswer((_) => _assignment.projects!);
      when(
        _assignmentsDetailsViewModel.focussedProject,
      ).thenAnswer((_) => _assignment.projects?.first);
      when(
        _assignmentsDetailsViewModel.grades,
      ).thenAnswer((_) => _assignment.grades!);

      await tester.pumpWidget(
        GetMaterialApp(
          onGenerateRoute: CVRouter.generateRoute,
          navigatorObservers: [mockObserver],
          home: AssignmentDetailsView(assignment: _assignment),
        ),
      );

      /// The tester.pumpWidget() call above just built our app widget
      /// and triggered the pushObserver method on the mockObserver once.
      verify(mockObserver.didPush(any, any));
    }

    testWidgets('finds Generic UpdateAssignmentView widgets', (
      WidgetTester tester,
    ) async {
      await provideMockedNetworkImages(() async {
        await _pumpAssignmentDetailsView(tester);
        await tester.pumpAndSettle();

        // Scroll
        final gesture = await tester.startGesture(const Offset(0, 300));
        await gesture.moveBy(const Offset(0, 900));
        await tester.pump();

        // Finds Author Name and Assignment name who submitted
        expect(find.text('Test'), findsNWidgets(2));

        // Finds Assignment Edit Button, Submit Grade and Delete Grade Button
        expect(find.byType(ElevatedButton), findsNWidgets(3));

        // Finds Name, Deadline, Restricted Elements
        expect(
          find.byWidgetPredicate((widget) {
            return widget is RichText &&
                (widget.text.toPlainText() == 'Name : Test' ||
                    widget.text.toPlainText().contains('Deadline : ') ||
                    widget.text.toPlainText() == 'Restricted Elements : N.A');
          }),
          findsNWidgets(3),
        );

        // Finds HTML description
        expect(find.byType(Html), findsOneWidget);
      });
    });
  });
}
