import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsar_chat/core/theme/nova_theme.dart';

/// Every selectable family has to produce a usable, self-consistent
/// theme. A missing colour or a contrast mistake would only show up as
/// an unreadable screen at runtime, so the definitions are checked here.
void main() {
  group('NovaThemeFamily', () {
    test('has the four requested families', () {
      expect(
        NovaThemeFamily.values,
        contains(NovaThemeFamily.purple),
      );
      expect(NovaThemeFamily.values, contains(NovaThemeFamily.black));
      expect(
        NovaThemeFamily.values,
        contains(NovaThemeFamily.whatsappLight),
      );
      expect(
        NovaThemeFamily.values,
        contains(NovaThemeFamily.blueLight),
      );
    });

    test('fromIndex is safe at the boundaries', () {
      expect(NovaThemeFamily.fromIndex(-1), NovaThemeFamily.values.first);
      expect(NovaThemeFamily.fromIndex(99), NovaThemeFamily.values.first);
      expect(NovaThemeFamily.fromIndex(0), NovaThemeFamily.values.first);
    });

    test('two light and two dark families', () {
      int dark = 0;
      int light = 0;

      for (final NovaThemeFamily f in NovaThemeFamily.values) {
        if (NovaTheme.specOf(f).isLight) {
          light++;
        } else {
          dark++;
        }
      }

      expect(dark, 2);
      expect(light, 2);
    });
  });

  group('specs', () {
    test('every family resolves to its own spec', () {
      for (final NovaThemeFamily f in NovaThemeFamily.values) {
        expect(
          NovaTheme.specOf(f).family,
          f,
          reason: 'spec for $f is wrong',
        );
      }
    });

    test('the black theme is genuinely black', () {
      final NovaThemeSpec spec = NovaTheme.specOf(NovaThemeFamily.black);

      expect(spec.canvas, const Color(0xFF000000));
      expect(spec.surface, const Color(0xFF050505));
      expect(spec.chatBackground, const Color(0xFF000000));
      expect(spec.isLight, isFalse);
    });

    test('the WhatsApp theme has green actions and its bubble colours', () {
      final NovaThemeSpec spec =
          NovaTheme.specOf(NovaThemeFamily.whatsappLight);

      // A recognisable WhatsApp green, deep enough that a white button
      // label is actually readable: the green channel dominates.
      expect(spec.accent.g, greaterThan(spec.accent.r));
      expect(spec.accent.g, greaterThan(spec.accent.b));
      expect(spec.isLight, isTrue);

      // Outgoing pale green, incoming white, on the beige wallpaper.
      expect(spec.bubbleOwn, const Color(0xFFD9FDD3));
      expect(spec.bubbleOther, const Color(0xFFFFFFFF));
      expect(spec.chatBackground, const Color(0xFFECE5DD));
    });

    test('the blue light theme is light and blue', () {
      final NovaThemeSpec spec =
          NovaTheme.specOf(NovaThemeFamily.blueLight);

      expect(spec.isLight, isTrue);
      expect(spec.accent, const Color(0xFF1E6FD9));
    });

    test('primary text is legible on every canvas', () {
      for (final NovaThemeFamily f in NovaThemeFamily.values) {
        final NovaThemeSpec spec = NovaTheme.specOf(f);

        expect(
          _contrast(spec.textPrimary, spec.canvas),
          greaterThan(4.5),
          reason: '$f has poor primary text contrast',
        );
      }
    });

    test('button labels are legible on their own accent', () {
      for (final NovaThemeFamily f in NovaThemeFamily.values) {
        final NovaThemeSpec spec = NovaTheme.specOf(f);

        expect(
          _contrast(spec.accent, spec.onAccent),
          greaterThan(3.0),
          reason: '$f button text is hard to read',
        );
      }
    });

    test('bubble text is legible in both directions', () {
      for (final NovaThemeFamily f in NovaThemeFamily.values) {
        final NovaThemeSpec spec = NovaTheme.specOf(f);

        expect(
          _contrast(spec.bubbleOwn, spec.bubbleOwnText),
          greaterThan(4.0),
          reason: '$f own bubble text',
        );
        expect(
          _contrast(spec.bubbleOther, spec.bubbleOtherText),
          greaterThan(4.0),
          reason: '$f other bubble text',
        );
      }
    });
  });

  group('ThemeData', () {
    test('builds for every family', () {
      for (final NovaThemeFamily f in NovaThemeFamily.values) {
        final ThemeData t = NovaTheme.build(family: f);

        expect(t.brightness, isNotNull, reason: '$f');
        expect(t.textTheme.bodyMedium, isNotNull);
        expect(t.extensions, isNotEmpty);
      }
    });

    test('carries the chat extension everywhere', () {
      for (final NovaThemeFamily f in NovaThemeFamily.values) {
        final NovaChatColors? chat = NovaTheme.build(
          family: f,
        ).extension<NovaChatColors>();

        expect(chat, isNotNull, reason: '$f has no chat colours');
      }
    });

    test('a family keeps its own accent when none is overridden', () {
      final Color specAccent =
          NovaTheme.specOf(NovaThemeFamily.black).accent;

      expect(
        NovaTheme.build(family: NovaThemeFamily.black)
            .colorScheme
            .primary,
        specAccent,
        reason: 'the black theme must not be recoloured by the '
            'violet accent setting',
      );
    });

    test('an explicit accent overrides', () {
      expect(
        NovaTheme.build(
          family: NovaThemeFamily.black,
          accent: const Color(0xFFFF0000),
        ).colorScheme
            .primary,
        const Color(0xFFFF0000),
      );
    });

    test('brightness matches the family', () {
      expect(
        NovaTheme.build(family: NovaThemeFamily.whatsappLight)
            .brightness,
        Brightness.light,
      );
      expect(
        NovaTheme.build(family: NovaThemeFamily.blueLight)
            .brightness,
        Brightness.light,
      );
      expect(
        NovaTheme.build(family: NovaThemeFamily.purple)
            .brightness,
        Brightness.dark,
      );
      expect(
        NovaTheme.build(family: NovaThemeFamily.black).brightness,
        Brightness.dark,
      );
    });
  });

  group('NovaChatColors', () {
    const NovaChatColors a = NovaChatColors(
      chatBackground: Color(0xFF000000),
      bubbleOwn: Color(0xFF000000),
      bubbleOwnText: Color(0xFFFFFFFF),
      bubbleOther: Color(0xFF000000),
      bubbleOtherText: Color(0xFFFFFFFF),
      online: Color(0xFF00FF00),
      warning: Color(0xFFFF00FF),
    );

    const NovaChatColors b = NovaChatColors(
      chatBackground: Color(0xFFFFFFFF),
      bubbleOwn: Color(0xFFFFFFFF),
      bubbleOwnText: Color(0xFF000000),
      bubbleOther: Color(0xFFFFFFFF),
      bubbleOtherText: Color(0xFF000000),
      online: Color(0xFF0000FF),
      warning: Color(0xFF00FFFF),
    );

    test('lerp blends between two families', () {
      final NovaChatColors mid = a.lerp(b, 0.5);

      expect(mid.chatBackground, isNot(a.chatBackground));
      expect(mid.bubbleOwn, isNot(a.bubbleOwn));
    });

    test('lerp with a non-matching type returns this', () {
      expect(a.lerp(null, 0.5), a);
    });

    testWidgets('falls back safely when the extension is absent', (
      WidgetTester tester,
    ) async {
      late NovaChatColors resolved;

      await tester.pumpWidget(
        MaterialApp(
          // Deliberately no NovaChatColors extension.
          theme: ThemeData.dark(),
          home: Builder(
            builder: (BuildContext context) {
              resolved = NovaChatColors.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolved.bubbleOwn, isNotNull);
    });

    testWidgets('resolves the extension from a real theme', (
      WidgetTester tester,
    ) async {
      late NovaChatColors resolved;

      await tester.pumpWidget(
        MaterialApp(
          theme: NovaTheme.build(
            family: NovaThemeFamily.whatsappLight,
          ),
          home: Builder(
            builder: (BuildContext context) {
              resolved = NovaChatColors.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(
        resolved.bubbleOwn,
        NovaTheme.specOf(NovaThemeFamily.whatsappLight).bubbleOwn,
      );
    });
  });
}

/// WCAG relative-luminance contrast ratio between two opaque colours.
double _contrast(Color a, Color b) {
  final double la = _luminance(a);
  final double lb = _luminance(b);

  final double lighter = math.max(la, lb);
  final double darker = math.min(la, lb);

  return (lighter + 0.05) / (darker + 0.05);
}

double _luminance(Color c) {
  double channel(double v) => v <= 0.03928
      ? v / 12.92
      : math.pow((v + 0.055) / 1.055, 2.4).toDouble();

  return 0.2126 * channel(c.r) +
      0.7152 * channel(c.g) +
      0.0722 * channel(c.b);
}
