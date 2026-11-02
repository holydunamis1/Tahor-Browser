import 'package:flutter_test/flutter_test.dart';
import 'package:tahorbrowser/core/utils/debouncer.dart';

void main() {
  const Duration delay = Duration(milliseconds: 500);

  testWidgets('only the last call runs, after the delay', (
    WidgetTester tester,
  ) async {
    final Debouncer debouncer = Debouncer(delay);
    final List<int> ran = <int>[];
    debouncer.run(() => ran.add(1));
    await tester.pump(const Duration(milliseconds: 300));
    debouncer.run(() => ran.add(2));
    await tester.pump(const Duration(milliseconds: 300));
    expect(ran, isEmpty);
    expect(debouncer.isPending, isTrue);
    await tester.pump(const Duration(milliseconds: 250));
    expect(ran, <int>[2]);
    expect(debouncer.isPending, isFalse);
  });

  testWidgets('cancel drops the scheduled action', (WidgetTester tester) async {
    final Debouncer debouncer = Debouncer(delay);
    int runs = 0;
    debouncer.run(() => runs++);
    debouncer.cancel();
    await tester.pump(delay * 2);
    expect(runs, 0);
  });

  testWidgets('flush runs the action now, once', (WidgetTester tester) async {
    final Debouncer debouncer = Debouncer(delay);
    int runs = 0;
    debouncer.run(() => runs++);
    debouncer.flush();
    expect(runs, 1);
    await tester.pump(delay * 2);
    expect(runs, 1);
  });

  testWidgets('flush with nothing scheduled does nothing', (
    WidgetTester tester,
  ) async {
    final Debouncer debouncer = Debouncer(delay);
    expect(debouncer.flush, returnsNormally);
  });

  testWidgets('can be used again after firing', (WidgetTester tester) async {
    final Debouncer debouncer = Debouncer(delay);
    int runs = 0;
    debouncer.run(() => runs++);
    await tester.pump(delay);
    debouncer.run(() => runs++);
    await tester.pump(delay);
    expect(runs, 2);
  });
}
