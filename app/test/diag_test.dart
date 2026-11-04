import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahorbrowser/widgets/core/premium_text_field.dart';

import 'support/test_host.dart';

void main() {
  testWidgets('DIAG paste', (WidgetTester tester) async {
    final TextEditingController c = TextEditingController();
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall call) async {
        if (call.method == 'Clipboard.getData') {
          return <String, Object?>{'text': 'pasted text'};
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
    await tester.longPress(find.byType(EditableText));
    await tester.pumpAndSettle();
    final EditableTextState state = tester.state<EditableTextState>(
      find.byType(EditableText),
    );
    final String before =
        'toolbarTexts=${find.text('Paste').evaluate().length} '
        'sel=${c.selection} focus=${state.widget.focusNode.hasFocus}';
    final Offset target = tester.getCenter(find.text('Paste'));
    await tester.tapAt(target);
    final String t0 = c.text;
    await tester.pump();
    final String t1 = c.text;
    await tester.pump(const Duration(milliseconds: 100));
    final String t2 = c.text;
    await tester.pumpAndSettle();
    final String t3 = c.text;
    final String after =
        'toolbarTexts=${find.text('Paste').evaluate().length} '
        'focus=${state.widget.focusNode.hasFocus} sel=${c.selection}';
    fail(
      'BEFORE[$before] target=$target t0="$t0" t1="$t1" t2="$t2" t3="$t3" '
      'AFTER[$after]',
    );
  });
}
