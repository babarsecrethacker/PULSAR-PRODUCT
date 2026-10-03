import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ============================================================
///  PULSAR // CYBER DESIGN SYSTEM
///  Tokens only. Every screen reads from here so the visual
///  language stays consistent as the app grows.
/// ============================================================

/// Core palette. Obsidian grounds the UI; cyan and violet are the
/// signal colours, magenta marks alerts and violet marks the local
/// mesh so the two engines never look alike.
class CyberPalette {
  const CyberPalette._();

  // --- Surfaces: near-black with a blue undertone, not pure grey.
  static const Color voidBlack = Color(0xFF05070B);
  static const Color obsidian = Color(0xFF0A0E16);
  static const Color obsidianHigh = Color(0xFF111726);
  static const Color obsidianTop = Color(0xFF18202F);
  static const Color glass = Color(0x14FFFFFF);
  static const Color glassStrong = Color(0x24FFFFFF);
  static const Color hairline = Color(0x1FFFFFFF);
  static const Color hairlineBright = Color(0x40FFFFFF);

  // --- Signal colours.
  static const Color cyan = Color(0xFF22E4F5);
  static const Color cyanDeep = Color(0xFF0A7C8C);
  static const Color violet = Color(0xFF8B5CF6);
  static const Color violetDeep = Color(0xFF5B21B6);
  static const Color magenta = Color(0xFFF046B6);
  static const Color amber = Color(0xFFF5B942);
  static const Color danger = Color(0xFFFF4D6A);
  static const Color success = Color(0xFF31E0A1);
  static const Color online = Color(0xFF31E0A1);

  // --- Type.
  static const Color textPrimary = Color(0xFFEDF4FF);
  static const Color textSecondary = Color(0xFF9AA9C4);
  static const Color textTertiary = Color(0xFF63708A);
  static const Color textDisabled = Color(0xFF414D63);

  /// Engine accents. LAN is violet, Cloud is cyan, so a glance at
  /// the ambient glow tells you which network you are on.
  static const Color lanAccent = violet;
  static const Color cloudAccent = cyan;
}

/// Corner radii.
class CyberRadius {
  const CyberRadius._();

  static const double sm = 8;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 24;
  static const double pill = 999;

  static BorderRadius r(double v) => BorderRadius.circular(v);
  static BorderRadius get card => r(lg);
  static BorderRadius get panel => r(xl);
  static BorderRadius get pillAll => r(pill);
}

/// Spacing scale.
class CyberSpace {
  const CyberSpace._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

/// Motion. Every duration here is deliberate: entry is quick, ambient
/// loops are slow enough not to distract, and the mode cross-fade is
/// long enough to register as a state change.
class CyberMotion {
  const CyberMotion._();

  static const Duration instant = Duration(milliseconds: 90);
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration normal = Duration(milliseconds: 320);
  static const Duration slow = Duration(milliseconds: 560);
  static const Duration modeShift = Duration(milliseconds: 720);

  /// Ambient loops.
  static const Duration pulse = Duration(milliseconds: 2200);
  static const Duration sweep = Duration(milliseconds: 3200);
  static const Duration shimmer = Duration(milliseconds: 1800);

  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
  static const Curve ambient = Curves.easeInOutSine;
  static const Curve crossfade = Curves.easeInOutCubic;
}

/// Glow. Kept as functions so intensity can scale with importance
/// rather than being copy-pasted.
class CyberGlow {
  const CyberGlow._();

  /// Soft ambient bloom behind a focal element.
  static List<BoxShadow> ambient(Color color, {double strength = 0.35}) {
    return <BoxShadow>[
      BoxShadow(
        color: color.withValues(alpha: strength * 0.55),
        blurRadius: 28,
        spreadRadius: -4,
      ),
      BoxShadow(
        color: color.withValues(alpha: strength * 0.22),
        blurRadius: 64,
        spreadRadius: 2,
      ),
    ];
  }

  /// Tight highlight for controls and active states.
  static List<BoxShadow> focus(Color color) {
    return <BoxShadow>[
      BoxShadow(
        color: color.withValues(alpha: 0.45),
        blurRadius: 14,
        spreadRadius: 0,
      ),
    ];
  }

  /// Inner top sheen that sells the frosted-glass edge.
  static const List<BoxShadow> glassSheen = <BoxShadow>[
    BoxShadow(
      color: Color(0x1AFFFFFF),
      blurRadius: 0,
      spreadRadius: 1,
      offset: Offset(0, -0.5),
    ),
  ];
}

/// Gradients used for ambient backdrops.
class CyberGradient {
  const CyberGradient._();

  /// Base page wash. Cyan top-left, violet bottom-right, on obsidian.
  static const LinearGradient canvas = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      Color(0xFF0B1220),
      CyberPalette.voidBlack,
      Color(0xFF0C0A18),
    ],
    stops: <double>[0, 0.55, 1],
  );

  /// Accent wash for the LAN engine.
  static const LinearGradient lanAmbient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      Color(0xFF1A1030),
      CyberPalette.voidBlack,
      Color(0xFF0A0716),
    ],
  );

  /// Accent wash for the Cloud engine.
  static const LinearGradient cloudAmbient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      Color(0xFF04212B),
      CyberPalette.voidBlack,
      Color(0xFF050A18),
    ],
  );

  /// Border sheen for glass panels.
  static const LinearGradient glassBorder = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      Color(0x59FFFFFF),
      Color(0x0DFFFFFF),
      Color(0x26FFFFFF),
    ],
    stops: <double>[0, 0.5, 1],
  );

  /// Outgoing message fill.
  static const LinearGradient bubbleOut = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      Color(0xFF6D28D9),
      Color(0xFF0E7490),
    ],
  );

  /// Primary action fill.
  static const LinearGradient accentFill = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[CyberPalette.cyan, Color(0xFF0EA5E9)],
  );
}

/// Typography. Orbitron-like display face for headings is not bundled,
/// so display type uses the platform UI face with wide tracking and
/// heavy weight, which reads as technical without another asset.
class CyberType {
  const CyberType._();

  /// Section and screen titles: wide-tracked, uppercase at the call site.
  static const TextStyle display = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    height: 1.15,
  );

  static const TextStyle title = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 15.5,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle bodyMuted = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  /// Small technical labels, e.g. latency, status readouts.
  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.6,
  );

  /// Uppercase micro-label for section headers.
  static const TextStyle overline = TextStyle(
    fontSize: 10.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.4,
  );

  /// Numeric readouts. Monospace keeps values from jittering.
  static const TextStyle mono = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
    fontFamily: 'Consolas',
    fontFamilyFallback: <String>[
      'Menlo',
      'DejaVu Sans Mono',
      'monospace',
    ],
    letterSpacing: 0.2,
  );
}

/// Engine identity, used to pick the ambient accent.
enum PulseEngine {
  lan('LAN MESH', CyberPalette.lanAccent),
  cloud('CLOUD GRID', CyberPalette.cloudAccent);

  const PulseEngine(this.label, this.accent);

  final String label;
  final Color accent;
}

/// ============================================================
///  THEME
/// ============================================================

/// Chat surface colours, exposed as a [ThemeExtension] so message
/// bubbles follow whichever theme is active instead of being hard-coded.
@immutable
class CyberChatColors extends ThemeExtension<CyberChatColors> {
  final Color outgoing;
  final Color outgoingText;
  final Color incoming;
  final Color incomingText;
  final Color canvas;
  final Color accent;

  const CyberChatColors({
    required this.outgoing,
    required this.outgoingText,
    required this.incoming,
    required this.incomingText,
    required this.canvas,
    required this.accent,
  });

  /// Falls back to the cyber palette so a widget can never crash on a
  /// missing extension.
  static CyberChatColors of(BuildContext context) {
    return Theme.of(context).extension<CyberChatColors>() ??
        const CyberChatColors(
          outgoing: Color(0xFF3B2A7A),
          outgoingText: Color(0xFFEDF4FF),
          incoming: Color(0xFF111726),
          incomingText: Color(0xFFEDF4FF),
          canvas: Color(0xFF05070B),
          accent: CyberPalette.cyan,
        );
  }

  @override
  CyberChatColors copyWith({
    Color? outgoing,
    Color? outgoingText,
    Color? incoming,
    Color? incomingText,
    Color? canvas,
    Color? accent,
  }) {
    return CyberChatColors(
      outgoing: outgoing ?? this.outgoing,
      outgoingText: outgoingText ?? this.outgoingText,
      incoming: incoming ?? this.incoming,
      incomingText: incomingText ?? this.incomingText,
      canvas: canvas ?? this.canvas,
      accent: accent ?? this.accent,
    );
  }

  @override
  CyberChatColors lerp(
    ThemeExtension<CyberChatColors>? other,
    double t,
  ) {
    if (other is! CyberChatColors) return this;

    return CyberChatColors(
      outgoing: Color.lerp(outgoing, other.outgoing, t)!,
      outgoingText:
          Color.lerp(outgoingText, other.outgoingText, t)!,
      incoming: Color.lerp(incoming, other.incoming, t)!,
      incomingText:
          Color.lerp(incomingText, other.incomingText, t)!,
      canvas: Color.lerp(canvas, other.canvas, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
    );
  }
}

class CyberTheme {
  const CyberTheme._();

  static const String fontFamily = 'Segoe UI';
  static const List<String> fontFallback = <String>[
    'Segoe UI Variable Text',
    'Inter',
    'Roboto',
    'Arial',
  ];

  static const SystemUiOverlayStyle overlay = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: CyberPalette.voidBlack,
    systemNavigationBarIconBrightness: Brightness.light,
  );

  static const TextTheme textTheme = TextTheme(
    displayLarge: CyberType.display,
    displayMedium: CyberType.display,
    headlineMedium: CyberType.display,
    headlineSmall: CyberType.title,
    titleLarge: CyberType.title,
    titleMedium: CyberType.subtitle,
    titleSmall: CyberType.subtitle,
    bodyLarge: CyberType.body,
    bodyMedium: CyberType.bodyMuted,
    bodySmall: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      height: 1.45,
      color: CyberPalette.textTertiary,
    ),
    labelLarge: CyberType.label,
    labelMedium: CyberType.label,
    labelSmall: CyberType.overline,
  );

  /// The dark cyber theme. Shared by desktop and phone; the phone
  /// variant only widens touch targets and scales type up.
  static ThemeData build({bool mobile = false}) {
    const ColorScheme scheme = ColorScheme.dark(
      primary: CyberPalette.cyan,
      onPrimary: Color(0xFF001318),
      secondary: CyberPalette.violet,
      onSecondary: Colors.white,
      surface: CyberPalette.obsidian,
      onSurface: CyberPalette.textPrimary,
      error: CyberPalette.danger,
      outline: CyberPalette.hairline,
      outlineVariant: Color(0x1AFFFFFF),
    );

    final TextTheme text = _textTheme(mobile);
    final Size target = mobile
        ? const Size(0, 48)
        : const Size(0, 40);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: CyberPalette.voidBlack,
      canvasColor: CyberPalette.voidBlack,
      fontFamily: fontFamily,
      fontFamilyFallback: fontFallback,
      textTheme: text,
      primaryTextTheme: text,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      dividerColor: CyberPalette.hairline,

      // Chat surfaces live here so widgets read bubble colours from the
      // theme rather than hard-coding them.
      extensions: const <ThemeExtension<dynamic>>[
        CyberChatColors(
          outgoing: Color(0xFF3B2A7A),
          outgoingText: Color(0xFFEDF4FF),
          incoming: Color(0xFF111726),
          incomingText: Color(0xFFEDF4FF),
          canvas: Color(0xFF05070B),
          accent: CyberPalette.cyan,
        ),
      ],

      dialogTheme: DialogThemeData(
        backgroundColor: CyberPalette.obsidianHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: CyberRadius.r(CyberRadius.lg),
        ),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium?.copyWith(height: 1.55),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: mobile ? 58 : 62,
        titleTextStyle: text.titleLarge,
        iconTheme: const IconThemeData(
          color: CyberPalette.textSecondary,
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: CyberPalette.cyan,
          foregroundColor: const Color(0xFF001318),
          disabledBackgroundColor: CyberPalette.obsidianTop,
          disabledForegroundColor: CyberPalette.textDisabled,
          minimumSize: mobile
              ? const Size(double.infinity, 52)
              : target,
          padding: EdgeInsets.symmetric(
            horizontal: mobile ? 24 : 20,
          ),
          textStyle: CyberType.label,
          shape: RoundedRectangleBorder(
            borderRadius: CyberRadius.r(CyberRadius.md),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: CyberPalette.obsidianTop,
          foregroundColor: CyberPalette.textPrimary,
          elevation: 0,
          minimumSize: target,
          textStyle: CyberType.label,
          shape: RoundedRectangleBorder(
            borderRadius: CyberRadius.r(CyberRadius.md),
            side: const BorderSide(
              color: CyberPalette.hairline,
            ),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: CyberPalette.textPrimary,
          minimumSize: target,
          textStyle: CyberType.label,
          side: const BorderSide(
            color: CyberPalette.hairlineBright,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: CyberRadius.r(CyberRadius.md),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: CyberPalette.cyan,
          minimumSize: target,
          textStyle: CyberType.label,
          shape: RoundedRectangleBorder(
            borderRadius: CyberRadius.r(CyberRadius.md),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: CyberPalette.textSecondary,
          minimumSize: mobile
              ? const Size(48, 48)
              : const Size(40, 40),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: CyberPalette.obsidian,
        hintStyle: text.bodyMedium?.copyWith(
          color: CyberPalette.textTertiary,
        ),
        labelStyle: text.bodyMedium?.copyWith(
          color: CyberPalette.textSecondary,
        ),
        floatingLabelStyle: text.bodyMedium?.copyWith(
          color: CyberPalette.cyan,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: mobile ? 18 : 16,
          vertical: mobile ? 16 : 14,
        ),
        border: _edge(CyberPalette.hairline),
        enabledBorder: _edge(CyberPalette.hairline),
        focusedBorder: _edge(CyberPalette.cyan, width: 1.6),
        errorBorder: _edge(CyberPalette.danger),
        focusedErrorBorder: _edge(CyberPalette.danger, width: 1.6),
      ),

      listTileTheme: ListTileThemeData(
        iconColor: CyberPalette.textSecondary,
        textColor: CyberPalette.textPrimary,
        titleTextStyle: text.titleMedium,
        subtitleTextStyle: text.bodySmall,
        minVerticalPadding: mobile ? 12 : 8,
        contentPadding: EdgeInsets.symmetric(
          horizontal: mobile ? 18 : 16,
          vertical: mobile ? 6 : 2,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: CyberRadius.r(CyberRadius.md),
        ),
      ),

      cardTheme: CardThemeData(
        color: CyberPalette.obsidianHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: CyberRadius.card,
          side: const BorderSide(color: CyberPalette.hairline),
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll<Color>(
          CyberPalette.textPrimary,
        ),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return CyberPalette.cyan;
          }
          return CyberPalette.obsidianTop;
        }),
        trackOutlineColor: const WidgetStatePropertyAll<Color>(
          CyberPalette.hairlineBright,
        ),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: CyberPalette.cyan,
        linearTrackColor: CyberPalette.obsidianTop,
        circularTrackColor: CyberPalette.obsidianTop,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: CyberPalette.obsidianTop,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: CyberPalette.textPrimary,
        ),
        actionTextColor: CyberPalette.cyan,
        elevation: 0,
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: CyberRadius.r(CyberRadius.md),
          side: const BorderSide(color: CyberPalette.hairline),
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: CyberPalette.obsidianHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(CyberRadius.lg),
          ),
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: CyberPalette.obsidian,
        indicatorColor: CyberPalette.cyan.withValues(alpha: 0.18),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        labelTextStyle: WidgetStatePropertyAll<TextStyle?>(
          CyberType.label,
        ),
      ),

      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll<Color>(
          CyberPalette.hairlineBright,
        ),
        radius: const Radius.circular(CyberRadius.pill),
        thickness: const WidgetStatePropertyAll<double>(6),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: CyberPalette.obsidianTop,
          borderRadius: CyberRadius.r(CyberRadius.sm),
          border: Border.all(color: CyberPalette.hairline),
        ),
        textStyle: const TextStyle(
          fontSize: 12,
          color: CyberPalette.textPrimary,
        ),
      ),
    );
  }

  static OutlineInputBorder _edge(
    Color color, {
    double width = 1,
  }) {
    return OutlineInputBorder(
      borderRadius: CyberRadius.r(CyberRadius.md),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  /// Phone variant: same identity, ergonomics adjusted for touch.
  static TextTheme _textTheme(bool mobile) {
    if (!mobile) return textTheme;

    return textTheme.copyWith(
      displayLarge: textTheme.displayLarge?.copyWith(fontSize: 24),
      displayMedium: textTheme.displayMedium?.copyWith(fontSize: 24),
      headlineMedium: textTheme.headlineMedium?.copyWith(fontSize: 24),
      headlineSmall: textTheme.headlineSmall?.copyWith(fontSize: 21),
      titleLarge: textTheme.titleLarge?.copyWith(fontSize: 18),
      titleMedium: textTheme.titleMedium?.copyWith(fontSize: 16),
      bodyLarge: textTheme.bodyLarge?.copyWith(fontSize: 16),
      bodyMedium: textTheme.bodyMedium?.copyWith(fontSize: 15),
      bodySmall: textTheme.bodySmall?.copyWith(fontSize: 13.5),
    );
  }
}
