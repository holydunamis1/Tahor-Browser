import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahorbrowser/widgets/core/premium_text_field.dart';

import 'support/test_host.dart';

void main() {
  testWidgets('DIAG long press', (WidgetTester tester) async {
    final TextEditingController c = TextEditingController();
    String? clip = 'x';
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall call) async {
        if (call.method == 'Clipboard.getData') {
          return <String, Object?>{'text': clip};
        }
        if (call.method == 'Clipboard.hasStrings') {
          return <String, Object?>{'value': true};
        }
        return null;
      },
    );
    await tester.pumpWidget(
      testHost(
        Center(
          child: SizedBox(
            width: 300,
            child: PremiumTextField(controller: c, hintText: 'Search'),
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(EditableText), 'hello world');
    await tester.pump();
    final String before = '${c.selection}';
    await tester.longPress(find.byType(EditableText));
    await tester.pumpAndSettle();
    final EditableTextState state = tester.state<EditableTextState>(
      find.byType(EditableText),
    );
    List<String> texts() => tester
        .widgetList<Text>(find.byType(Text, skipOffstage: false))
        .map((Text t) => t.data ?? '?')
        .toList();
    final String afterLong =
        'sel=${c.selection} texts=${texts()} '
        'toolbarVisible=${state.selectionOverlay?.toolbarIsVisible} '
        'handles=${state.selectionOverlay?.handlesVisible} '
        'overlayNull=${state.selectionOverlay == null}';
    final bool shown = state.showToolbar();
    await tester.pumpAndSettle();
    final String afterShow =
        'shown=$shown texts=${texts()} '
        'toolbarVisible=${state.selectionOverlay?.toolbarIsVisible}';
    fail('LONG[$afterLong] SHOW[$afterShow] before=$before');
  });
}
