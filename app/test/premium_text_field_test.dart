import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahorbrowser/core/constants/design_tokens.dart';
import 'package:tahorbrowser/widgets/core/app_text_selection.dart';
import 'package:tahorbrowser/widgets/core/premium_text_field.dart';

import 'support/test_host.dart';

void main() {
  late TextEditingController controller;
  String? clipboard;

  setUp(() {
    controller = TextEditingController();
    clipboard = null;
  });

  tearDown(() => controller.dispose());

  void mockClipboard(WidgetTester tester) {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall call) async {
        switch (call.method) {
          case 'Clipboard.getData':
            return clipboard == null
                ? null
                : <String, Object?>{'text': clipboard};
          case 'Clipboard.hasStrings':
            return <String, Object?>{
              'value': clipboard != null && clipboard!.isNotEmpty,
            };
          case 'Clipboard.setData':
            clipboard =
                (call.arguments as Map<Object?, Object?>)['text'] as String?;
            return null;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
  }

  Widget field({
    String? hint = 'Search',
    Widget? leading,
    ValueChanged<String>? onSubmitted,
    ValueChanged<String>? onChanged,
    EditableTextContextMenuBuilder? menu,
    bool obscure = false,
    bool selectAllOnFocus = false,
    TextDirection direction = TextDirection.ltr,
  }) {
    return testHost(
      Center(
        child: SizedBox(
          width: 300,
          child: PremiumTextField(
            controller: controller,
            hintText: hint,
            leading: leading,
            onSubmitted: onSubmitted,
            onChanged: onChanged,
            contextMenuBuilder: menu,
            obscureText: obscure,
            selectAllOnFocus: selectAllOnFocus,
          ),
        ),
      ),
      direction: direction,
    );
  }

  BoxDecoration decoration(WidgetTester tester) {
    final DecoratedBox box = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(PremiumTextField),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    return box.decoration as BoxDecoration;
  }

  testWidgets('is at least 48 high and shows the hint while empty', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(field());
    expect(
      tester.getSize(find.byType(PremiumTextField)).height,
      greaterThanOrEqualTo(48),
    );
    expect(find.text('Search'), findsOneWidget);
    await tester.enterText(find.byType(EditableText), 'hi');
    await tester.pump();
    expect(find.text('Search'), findsNothing);
  });

  testWidgets('the border turns to the focus colour on focus', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(field());
    expect(
      (decoration(tester).border! as Border).top.color,
      AppPalette.light.borderSubtle,
    );
    await tester.tap(find.byType(EditableText));
    await tester.pump();
    expect(
      (decoration(tester).border! as Border).top.color,
      AppPalette.light.borderFocus,
    );
  });

  testWidgets('typing calls onChanged and updates the controller', (
    WidgetTester tester,
  ) async {
    final List<String> changes = <String>[];
    await tester.pumpWidget(field(onChanged: changes.add));
    await tester.enterText(find.byType(EditableText), 'hello');
    expect(controller.text, 'hello');
    expect(changes.last, 'hello');
  });

  testWidgets('the keyboard action submits the text', (
    WidgetTester tester,
  ) async {
    final List<String> submitted = <String>[];
    await tester.pumpWidget(field(onSubmitted: submitted.add));
    await tester.enterText(find.byType(EditableText), 'example.com');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    expect(submitted, <String>['example.com']);
  });

  testWidgets('the clear button empties the field and reports it', (
    WidgetTester tester,
  ) async {
    final List<String> changes = <String>[];
    await tester.pumpWidget(field(onChanged: changes.add));
    expect(find.bySemanticsLabel('Clear'), findsNothing);
    await tester.enterText(find.byType(EditableText), 'abc');
    await tester.pump();
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pump();
    expect(find.bySemanticsLabel('Clear'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Clear'));
    await tester.pump();
    expect(controller.text, isEmpty);
    expect(changes.last, '');
    handle.dispose();
  });

  testWidgets('the whole text can be selected on focus', (
    WidgetTester tester,
  ) async {
    controller.text = 'example.com/path';
    await tester.pumpWidget(field(selectAllOnFocus: true));
    await tester.tap(find.byType(EditableText));
    await tester.pump();
    expect(
      controller.selection,
      const TextSelection(baseOffset: 0, extentOffset: 16),
    );
  });

  testWidgets('a long press shows the selection menu with localized labels', (
    WidgetTester tester,
  ) async {
    mockClipboard(tester);
    await tester.pumpWidget(field());
    await tester.enterText(find.byType(EditableText), 'hello world');
    await tester.pump();
    await tester.longPress(find.byType(EditableText));
    await tester.pumpAndSettle();
    expect(find.text('Copy'), findsOneWidget);
    expect(find.text('Cut'), findsOneWidget);
    expect(find.text('Select all'), findsOneWidget);
  });

  testWidgets('the menu sits above the field and inside the screen', (
    WidgetTester tester,
  ) async {
    mockClipboard(tester);
    clipboard = 'x';
    await tester.pumpWidget(field());
    await tester.longPress(find.byType(EditableText));
    await tester.pumpAndSettle();
    final Rect paste = tester.getRect(find.text('Paste'));
    final Rect fieldRect = tester.getRect(find.byType(EditableText));
    expect(paste.bottom, lessThanOrEqualTo(fieldRect.top));
    expect(paste.top, greaterThanOrEqualTo(0));
    expect(paste.left, greaterThanOrEqualTo(0));
  });

  testWidgets('the menu moves below a field at the top of the screen', (
    WidgetTester tester,
  ) async {
    mockClipboard(tester);
    clipboard = 'x';
    await tester.pumpWidget(
      testHost(
        Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 300,
            child: PremiumTextField(controller: controller),
          ),
        ),
      ),
    );
    await tester.longPress(find.byType(EditableText));
    await tester.pumpAndSettle();
    final Rect paste = tester.getRect(find.text('Paste'));
    final Rect fieldRect = tester.getRect(find.byType(EditableText));
    expect(paste.top, greaterThanOrEqualTo(fieldRect.bottom));
    expect(paste.bottom, lessThanOrEqualTo(600));
  });

  testWidgets('Paste inserts the clipboard text', (WidgetTester tester) async {
    mockClipboard(tester);
    clipboard = 'pasted text';
    await tester.pumpWidget(field());
    await tester.longPress(find.byType(EditableText));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Paste'));
    await tester.pumpAndSettle();
    expect(controller.text, 'pasted text');
  });

  testWidgets('Paste and go hands the clipboard text to the callback', (
    WidgetTester tester,
  ) async {
    mockClipboard(tester);
    clipboard = 'example.com';
    final List<String> went = <String>[];
    await tester.pumpWidget(
      field(
        menu: (BuildContext context, EditableTextState state) =>
            appContextMenuBuilder(context, state, onPasteAndGo: went.add),
      ),
    );
    await tester.longPress(find.byType(EditableText));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Paste and go'));
    await tester.pumpAndSettle();
    expect(went, <String>['example.com']);
    expect(controller.text, isEmpty);
  });

  testWidgets('a password field offers no selection menu', (
    WidgetTester tester,
  ) async {
    mockClipboard(tester);
    await tester.pumpWidget(field(obscure: true));
    await tester.enterText(find.byType(EditableText), 'secret');
    await tester.longPress(find.byType(EditableText));
    await tester.pumpAndSettle();
    expect(find.text('Copy'), findsNothing);
  });

  testWidgets('the leading widget sits at the start in both directions', (
    WidgetTester tester,
  ) async {
    const Key leadingKey = Key('leading');
    const Widget leading = SizedBox(key: leadingKey, width: 20, height: 20);
    await tester.pumpWidget(field(leading: leading));
    expect(
      tester.getCenter(find.byKey(leadingKey)).dx,
      lessThan(tester.getCenter(find.byType(EditableText)).dx),
    );
    await tester.pumpWidget(
      field(leading: leading, direction: TextDirection.rtl),
    );
    expect(
      tester.getCenter(find.byKey(leadingKey)).dx,
      greaterThan(tester.getCenter(find.byType(EditableText)).dx),
    );
  });

  testWidgets('the label reaches screen readers', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(field());
    expect(find.bySemanticsLabel('Search'), findsWidgets);
    handle.dispose();
  });

  testWidgets('the selection handles are 40 wide and follow the line height', (
    WidgetTester tester,
  ) async {
    final AppTextSelectionControls controls = AppTextSelectionControls();
    expect(controls.getHandleSize(20), const Size(40, 32));
    expect(controls.getHandleAnchor(TextSelectionHandleType.left, 20).dx, 20);
    expect(controls.getHandleAnchor(TextSelectionHandleType.right, 20).dy, 20);
    expect(controls.getHandleAnchor(TextSelectionHandleType.left, 20).dy, 32);
  });
}
