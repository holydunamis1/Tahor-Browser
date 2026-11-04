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
    final String types = state.contextMenuButtonItems
        .map((ContextMenuButtonItem i) => i.type.name)
        .join(',');
    final ContextMenuButtonItem paste = state.contextMenuButtonItems.firstWhere(
      (ContextMenuButtonItem i) => i.type == ContextMenuButtonType.paste,
    );
    paste.onPressed!();
    await tester.pumpAndSettle();
    final String viaItem = c.text;
    await state.pasteText(SelectionChangedCause.toolbar);
    await tester.pumpAndSettle();
    final String viaMethod = c.text;
    await tester.runAsync(() async {
      await state.pasteText(SelectionChangedCause.toolbar);
    });
    await tester.pump();
    fail(
      'types=$types viaItem="$viaItem" viaMethod="$viaMethod" '
      'afterRunAsync="${c.text}" readOnly=${state.widget.readOnly} '
      'sel=${c.selection} pasteEnabled=${state.pasteEnabled}',
    );
  });
}
