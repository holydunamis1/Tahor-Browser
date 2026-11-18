import 'package:flutter_test/flutter_test.dart';
import 'package:tahorbrowser/core/models/session_snapshot.dart';
import 'package:tahorbrowser/core/models/tab_model.dart';

void main() {
  final DateTime saved = DateTime.utc(2026, 11, 18, 9, 30);
  const TabModel a = TabModel(id: 'a', url: 'https://a.example', scrollY: 120);
  const TabModel b = TabModel(
    id: 'b',
    url: 'https://b.example',
    title: 'B',
    viewMode: TabViewMode.desktop,
    stateKey: 'b-state',
  );
  const TabModel secret = TabModel(
    id: 'p',
    url: 'https://p.example',
    isIncognito: true,
  );

  test('a snapshot survives toJson and tryFromJson unchanged', () {
    final SessionSnapshot snapshot = SessionSnapshot.capture(
      tabs: <TabModel>[a, b],
      activeTabId: 'b',
      savedAt: saved,
    );
    final SessionSnapshot? back = SessionSnapshot.tryFromJson(
      snapshot.toJson(),
    );
    expect(back, snapshot);
    expect(back!.activeIndex, 1);
    expect(back.activeTab, b);
    expect(back.savedAt, saved);
  });

  test('private tabs are never captured', () {
    final SessionSnapshot snapshot = SessionSnapshot.capture(
      tabs: <TabModel>[a, secret, b],
      activeTabId: 'b',
      savedAt: saved,
    );
    expect(snapshot.tabs, <TabModel>[a, b]);
    expect(snapshot.activeIndex, 1);
  });

  test('when the active tab was private the first tab becomes active', () {
    final SessionSnapshot snapshot = SessionSnapshot.capture(
      tabs: <TabModel>[a, secret, b],
      activeTabId: 'p',
      savedAt: saved,
    );
    expect(snapshot.activeTab, a);
  });

  test('no tabs gives an empty snapshot with no active tab', () {
    final SessionSnapshot snapshot = SessionSnapshot.capture(
      tabs: const <TabModel>[],
      activeTabId: null,
      savedAt: saved,
    );
    expect(snapshot.isEmpty, isTrue);
    expect(snapshot.activeTab, isNull);
    expect(SessionSnapshot.tryFromJson(snapshot.toJson()), snapshot);
  });

  group('reading damaged or foreign data', () {
    test('null, no version and a newer version are not readable', () {
      expect(SessionSnapshot.tryFromJson(null), isNull);
      expect(
        SessionSnapshot.tryFromJson(<String, Object?>{'tabs': <Object?>[]}),
        isNull,
      );
      expect(
        SessionSnapshot.tryFromJson(<String, Object?>{
          'v': SessionSnapshot.schemaVersion + 1,
          'tabs': <Object?>[],
        }),
        isNull,
      );
    });

    test('tabs that cannot be read are skipped and the rest are kept', () {
      final SessionSnapshot? back = SessionSnapshot.tryFromJson(
        <String, Object?>{
          'v': 1,
          'active': 1,
          'savedAt': saved.millisecondsSinceEpoch,
          'tabs': <Object?>[
            a.toJson(),
            'not a tab',
            <String, Object?>{'url': 'no id'},
            b.toJson(),
          ],
        },
      );
      expect(back!.tabs, <TabModel>[a, b]);
      expect(back.activeIndex, 1);
    });

    test('a private tab found in a file is dropped', () {
      final SessionSnapshot? back = SessionSnapshot.tryFromJson(
        <String, Object?>{
          'v': 1,
          'tabs': <Object?>[a.toJson(), secret.toJson()],
        },
      );
      expect(back!.tabs, <TabModel>[a]);
    });

    test('a repeated tab id keeps only the first', () {
      final SessionSnapshot? back = SessionSnapshot.tryFromJson(
        <String, Object?>{
          'v': 1,
          'tabs': <Object?>[a.toJson(), a.copyWith(url: 'https://x').toJson()],
        },
      );
      expect(back!.tabs, <TabModel>[a]);
    });

    test('an out-of-range active index falls back to the first tab', () {
      for (final Object? bad in <Object?>[9, -1, 'x', null]) {
        final SessionSnapshot? back = SessionSnapshot.tryFromJson(
          <String, Object?>{
            'v': 1,
            'active': bad,
            'tabs': <Object?>[a.toJson(), b.toJson()],
          },
        );
        expect(back!.activeIndex, 0, reason: '$bad');
      }
    });

    test('a missing or wrong saved time becomes the epoch', () {
      final SessionSnapshot? back = SessionSnapshot.tryFromJson(
        <String, Object?>{
          'v': 1,
          'savedAt': 'yesterday',
          'tabs': <Object?>[a.toJson()],
        },
      );
      expect(back!.savedAt.millisecondsSinceEpoch, 0);
    });

    test('tabs that are not a list make the snapshot unreadable', () {
      expect(
        SessionSnapshot.tryFromJson(<String, Object?>{'v': 1, 'tabs': 'x'}),
        isNull,
      );
    });
  });
}
