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
    final TextSelectionToolbarAnchors anchors = state.contextMenuAnchors;
    final String layouts = find
        .byType(CustomSingleChildLayout)
        .evaluate()
        .map(
          (Element e) =>
              '${(e.renderObject! as RenderBox).localToGlobal(Offset.zero)}'
              '/${(e.renderObject! as RenderBox).size}',
        )
        .join(' | ');
    fail(
      'primary=${anchors.primaryAnchor} secondary=${anchors.secondaryAnchor} '
      'paste=${tester.getRect(find.text('Paste'))} '
      'field=${tester.getRect(find.byType(EditableText))} '
      'overlays=${tester.getSize(find.byType(Overlay).first)} '
      'layouts=[$layouts] media=${MediaQuery.of(tester.element(find.byType(EditableText))).size}',
    );
  });
}
