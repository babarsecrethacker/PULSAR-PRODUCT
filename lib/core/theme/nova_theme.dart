import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Design tokens for Pulsar Chat.
///
/// Everything visual comes from here rather than inline colour
/// literals. A theme is a [NovaThemeSpec]: a flat set of semantic
/// colours, which the widget layer reads through the Flutter [Theme] so
/// switching a theme restyles the whole app at once.
class NovaColors {
  const NovaColors._();

  // ---------------------------------------------------------------------
  // Surfaces - the default (purple) dark ramp.
  // ---------------------------------------------------------------------
  static const Color canvas = Color(0xFF0B0D11);
  static const Color surface = Color(0xFF12151B);
  static const Color surfaceRaised = Color(0xFF171B22);
  static const Color surfaceOverlay = Color(0xFF1C212A);
  static const Color surfaceInput = Color(0xFF0F1217);

  static const Color border = Color(0xFF232935);
  static const Color borderStrong = Color(0xFF2E3542);
  static const Color divider = Color(0xFF1D222B);

  // ---------------------------------------------------------------------
  // Text
  // ---------------------------------------------------------------------
  static const Color textPrimary = Color(0xFFF3F5F9);
  static const Color textSecondary = Color(0xFFA9B2C0);
  static const Color textTertiary = Color(0xFF7A8494);
  static const Color textDisabled = Color(0xFF59616E);

  // ---------------------------------------------------------------------
  // Accent
  // ---------------------------------------------------------------------
  static const Color accent = Color(0xFF6C63FF);
  static const Color accentHover = Color(0xFF7B74FF);
  static const Color accentPressed = Color(0xFF5B52F0);
  static const Color accentMuted = Color(0xFF2B2456);
  static const Color onAccent = Colors.white;

  // ---------------------------------------------------------------------
  // Semantic
  // ---------------------------------------------------------------------
  static const Color success = Color(0xFF2FA36B);
  static const Color warning = Color(0xFFD9922B);
  static const Color danger = Color(0xFFD64F4F);
  static const Color online = Color(0xFF35C48B);

  // ---------------------------------------------------------------------
  // Chat
  // ---------------------------------------------------------------------
  static const Color bubbleOwn = Color(0xFF3A31A8);
  static const Color bubbleOwnText = Color(0xFFF0EEFF);
  static const Color bubbleOther = Color(0xFF1A1F27);
  static const Color bubbleOtherText = Color(0xFFE4E8EF);
}

/// Spacing scale.
class NovaSpacing {
  const NovaSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

/// Corner radius scale.
class NovaRadius {
  const NovaRadius._();

  static const double sm = 6;
  static const double md = 10;
  static const double lg = 14;
  static const double xl = 18;
  static const double pill = 999;
}

/// Selectable accent colours for the appearance settings.
class NovaAccents {
  const NovaAccents._();

  static const List<Color> colors = <Color>[
    Color(0xFF6C63FF), // Violet (default)
    Color(0xFF4C6EF5), // Indigo
    Color(0xFF2F7FE0), // Blue
    Color(0xFF1E9E8F), // Teal
    Color(0xFF25D366), // WhatsApp green
    Color(0xFFD08A26), // Amber
    Color(0xFFD0544E), // Red
  ];

  static const List<String> labels = <String>[
    'Violet',
    'Indigo',
    'Blue',
    'Teal',
    'Green',
    'Amber',
    'Red',
  ];

  static Color at(int index) {
    if (index < 0 || index >= colors.length) return colors.first;
    return colors[index];
  }

  static String labelAt(int index) {
    if (index < 0 || index >= labels.length) return labels.first;
    return labels[index];
  }
}

/// The selectable app themes.
enum NovaThemeFamily {
  /// The original violet-on-near-black look.
  purple('Midnight Violet'),

  /// True black surfaces, for OLED displays.
  black('Pure Black'),

  /// Light with WhatsApp-style green actions and chat background.
  whatsappLight('WhatsApp Light'),

  /// Light with a calm blue accent.
  blueLight('Blue Light');

  const NovaThemeFamily(this.label);

  final String label;

  static NovaThemeFamily fromIndex(int index) {
    if (index < 0 || index >= values.length) return values.first;
    return values[index];
  }
}

/// A complete set of semantic colours for one theme.
class NovaThemeSpec {
  final NovaThemeFamily family;

  final Color canvas;
  final Color surface;
  final Color surfaceRaised;
  final Color surfaceOverlay;
  final Color surfaceInput;

  final Color border;
  final Color borderStrong;
  final Color divider;

  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textDisabled;

  final Color accent;
  final Color accentHover;
  final Color onAccent;

  final Color success;
  final Color warning;
  final Color danger;
  final Color online;

  /// Chat surface behind the message list.
  final Color chatBackground;

  final Color bubbleOwn;
  final Color bubbleOwnText;
  final Color bubbleOther;
  final Color bubbleOtherText;

  final bool isLight;

  const NovaThemeSpec({
    required this.family,
    required this.canvas,
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceOverlay,
    required this.surfaceInput,
    required this.border,
    required this.borderStrong,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textDisabled,
    required this.accent,
    required this.accentHover,
    required this.onAccent,
    required this.success,
    required this.warning,
    required this.danger,
    required this.online,
    required this.chatBackground,
    required this.bubbleOwn,
    required this.bubbleOwnText,
    required this.bubbleOther,
    required this.bubbleOtherText,
    required this.isLight,
  });
}

/// Chat-specific colours, exposed as a [ThemeExtension] so widgets can
/// read them from the ambient theme instead of hard-coding.
@immutable
class NovaChatColors extends ThemeExtension<NovaChatColors> {
  final Color chatBackground;
  final Color bubbleOwn;
  final Color bubbleOwnText;
  final Color bubbleOther;
  final Color bubbleOtherText;
  final Color online;
  final Color warning;

  const NovaChatColors({
    required this.chatBackground,
    required this.bubbleOwn,
    required this.bubbleOwnText,
    required this.bubbleOther,
    required this.bubbleOtherText,
    required this.online,
    required this.warning,
  });

  @override
  NovaChatColors copyWith({
    Color? chatBackground,
    Color? bubbleOwn,
    Color? bubbleOwnText,
    Color? bubbleOther,
    Color? bubbleOtherText,
    Color? online,
    Color? warning,
  }) {
    return NovaChatColors(
      chatBackground: chatBackground ?? this.chatBackground,
      bubbleOwn: bubbleOwn ?? this.bubbleOwn,
      bubbleOwnText: bubbleOwnText ?? this.bubbleOwnText,
      bubbleOther: bubbleOther ?? this.bubbleOther,
      bubbleOtherText: bubbleOtherText ?? this.bubbleOtherText,
      online: online ?? this.online,
      warning: warning ?? this.warning,
    );
  }

  @override
  NovaChatColors lerp(ThemeExtension<NovaChatColors>? other, double t) {
    if (other is! NovaChatColors) return this;

    return NovaChatColors(
      chatBackground:
          Color.lerp(chatBackground, other.chatBackground, t)!,
      bubbleOwn: Color.lerp(bubbleOwn, other.bubbleOwn, t)!,
      bubbleOwnText:
          Color.lerp(bubbleOwnText, other.bubbleOwnText, t)!,
      bubbleOther:
          Color.lerp(bubbleOther, other.bubbleOther, t)!,
      bubbleOtherText:
          Color.lerp(bubbleOtherText, other.bubbleOtherText, t)!,
      online: Color.lerp(online, other.online, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
    );
  }

  /// Convenience accessor: falls back to sane values if the extension is
  /// missing, so a widget can never crash on a missing theme.
  static NovaChatColors of(BuildContext context) {
    return Theme.of(context).extension<NovaChatColors>() ??
        const NovaChatColors(
          chatBackground: Color(0xFF0F1217),
          bubbleOwn: Color(0xFF3A31A8),
          bubbleOwnText: Color(0xFFF0EEFF),
          bubbleOther: Color(0xFF1A1F27),
          bubbleOtherText: Color(0xFFE4E8EF),
          online: Color(0xFF35C48B),
          warning: Color(0xFFD9922B),
        );
  }
}

class NovaTheme {
  const NovaTheme._();

  /// Windows resolves this from the OS font manager, so no font asset
  /// has to be bundled. Segoe UI is the platform UI face and reads as a
  /// native professional application.
  static const String fontFamily = 'Segoe UI';
  static const List<String> fontFallback = <String>[
    'Segoe UI Variable Text',
    'Inter',
    'Roboto',
    'Helvetica Neue',
    'Arial',
  ];

  static const SystemUiOverlayStyle overlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: NovaColors.canvas,
    systemNavigationBarIconBrightness: Brightness.light,
  );

  /// Uppercase micro-label used for section headers.
  static const TextStyle sectionLabel = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.9,
    color: NovaColors.textTertiary,
  );

  // ---------------------------------------------------------------------
  // Theme definitions
  // ---------------------------------------------------------------------

  static const NovaThemeSpec _purple = NovaThemeSpec(
    family: NovaThemeFamily.purple,
    canvas: NovaColors.canvas,
    surface: NovaColors.surface,
    surfaceRaised: NovaColors.surfaceRaised,
    surfaceOverlay: NovaColors.surfaceOverlay,
    surfaceInput: NovaColors.surfaceInput,
    border: NovaColors.border,
    borderStrong: NovaColors.borderStrong,
    divider: NovaColors.divider,
    textPrimary: NovaColors.textPrimary,
    textSecondary: NovaColors.textSecondary,
    textTertiary: NovaColors.textTertiary,
    textDisabled: NovaColors.textDisabled,
    accent: NovaColors.accent,
    accentHover: NovaColors.accentHover,
    onAccent: NovaColors.onAccent,
    success: NovaColors.success,
    warning: NovaColors.warning,
    danger: NovaColors.danger,
    online: NovaColors.online,
    chatBackground: Color(0xFF0F1217),
    bubbleOwn: NovaColors.bubbleOwn,
    bubbleOwnText: NovaColors.bubbleOwnText,
    bubbleOther: NovaColors.bubbleOther,
    bubbleOtherText: NovaColors.bubbleOtherText,
    isLight: false,
  );

  /// True black for OLED, with a violet accent kept from the default.
  static const NovaThemeSpec _black = NovaThemeSpec(
    family: NovaThemeFamily.black,
    canvas: Color(0xFF000000),
    surface: Color(0xFF050505),
    surfaceRaised: Color(0xFF0B0B0C),
    surfaceOverlay: Color(0xFF141416),
    surfaceInput: Color(0xFF000000),
    border: Color(0xFF1C1C1F),
    borderStrong: Color(0xFF2A2A2E),
    divider: Color(0xFF131316),
    textPrimary: Color(0xFFF7F7F8),
    textSecondary: Color(0xFFB4B4BA),
    textTertiary: Color(0xFF85858C),
    textDisabled: Color(0xFF5C5C63),
    accent: Color(0xFF8B7BFF),
    accentHover: Color(0xFF9C8EFF),
    onAccent: Color(0xFF0B0B0C),
    success: Color(0xFF32B76E),
    warning: Color(0xFFE0A23C),
    danger: Color(0xFFE05252),
    online: Color(0xFF3ED48F),
    chatBackground: Color(0xFF000000),
    bubbleOwn: Color(0xFF4B3FD6),
    bubbleOwnText: Color(0xFFF2F0FF),
    bubbleOther: Color(0xFF131316),
    bubbleOtherText: Color(0xFFE6E6EA),
    isLight: false,
  );

  /// WhatsApp-like: green actions, the familiar chat wallpaper.
  static const NovaThemeSpec _whatsapp = NovaThemeSpec(
    family: NovaThemeFamily.whatsappLight,
    canvas: Color(0xFFECE5DD),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFFFFFFF),
    surfaceOverlay: Color(0xFFF0F2F5),
    surfaceInput: Color(0xFFFFFFFF),
    border: Color(0xFFE3E0DA),
    borderStrong: Color(0xFFD1CDC6),
    divider: Color(0xFFE9E6E0),
    textPrimary: Color(0xFF111B21),
    textSecondary: Color(0xFF667781),
    textTertiary: Color(0xFF8696A0),
    textDisabled: Color(0xFFB0B7BC),
    // WhatsApp's brand green (#25D366) is only 1.98:1 against white,
    // which is genuinely hard to read for a button label. This is a
    // slightly deeper green that still reads as WhatsApp but clears
    // the contrast bar.
    accent: Color(0xFF12A150),
    accentHover: Color(0xFF0F8C43),
    onAccent: Color(0xFFFFFFFF),
    success: Color(0xFF12A150),
    warning: Color(0xFFD89B2C),
    danger: Color(0xFFDC3545),
    online: Color(0xFF12A150),
    chatBackground: Color(0xFFECE5DD),
    bubbleOwn: Color(0xFFD9FDD3),
    bubbleOwnText: Color(0xFF111B21),
    bubbleOther: Color(0xFFFFFFFF),
    bubbleOtherText: Color(0xFF111B21),
    isLight: true,
  );

  /// Calm light theme with a blue accent.
  static const NovaThemeSpec _blueLight = NovaThemeSpec(
    family: NovaThemeFamily.blueLight,
    canvas: Color(0xFFF2F5FA),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFFFFFFF),
    surfaceOverlay: Color(0xFFEDF2F9),
    surfaceInput: Color(0xFFFFFFFF),
    border: Color(0xFFDCE4EF),
    borderStrong: Color(0xFFC2D0E2),
    divider: Color(0xFFE6ECF4),
    textPrimary: Color(0xFF10203A),
    textSecondary: Color(0xFF4A5C74),
    textTertiary: Color(0xFF71829A),
    textDisabled: Color(0xFF9AA8BC),
    accent: Color(0xFF1E6FD9),
    accentHover: Color(0xFF2B7FE8),
    onAccent: Color(0xFFFFFFFF),
    success: Color(0xFF1E9E6A),
    warning: Color(0xFFD08A26),
    danger: Color(0xFFD6455D),
    online: Color(0xFF1E9E6A),
    chatBackground: Color(0xFFF2F5FA),
    bubbleOwn: Color(0xFF1E6FD9),
    bubbleOwnText: Color(0xFFFFFFFF),
    bubbleOther: Color(0xFFFFFFFF),
    bubbleOtherText: Color(0xFF10203A),
    isLight: true,
  );

  static const Map<NovaThemeFamily, NovaThemeSpec> _specs =
      <NovaThemeFamily, NovaThemeSpec>{
    NovaThemeFamily.purple: _purple,
    NovaThemeFamily.black: _black,
    NovaThemeFamily.whatsappLight: _whatsapp,
    NovaThemeFamily.blueLight: _blueLight,
  };

  static NovaThemeSpec specOf(NovaThemeFamily family) =>
      _specs[family] ?? _purple;

  /// Builds the [ThemeData] for a family.
  ///
  /// [accent] overrides the family's accent colour, so the accent picker
  /// keeps working in every theme; pass null to use the family's own.
  static ThemeData build({
    NovaThemeFamily family = NovaThemeFamily.purple,
    Color? accent,
  }) {
    final NovaThemeSpec s = specOf(family);
    final Color brand = accent ?? s.accent;
    final Color brandMuted = _mute(brand, s.isLight);

    return _build(
      s: s,
      brand: brand,
      brandMuted: brandMuted,
    );
  }

  /// Convenience for the default family.
  static ThemeData dark({Color? accent}) => build(accent: accent);

  /// Darkens a brand colour for selected/pressed states. Light themes
  /// need a tint rather than a shade.
  static Color _mute(Color color, bool isLight) {
    final HSLColor hsl = HSLColor.fromColor(color);

    if (isLight) {
      return hsl
          .withLightness((hsl.lightness + 0.42).clamp(0.0, 1.0))
          .withSaturation((hsl.saturation * 0.75).clamp(0.0, 1.0))
          .toColor();
    }

    return hsl
        .withLightness((hsl.lightness * 0.42).clamp(0.0, 1.0))
        .withSaturation((hsl.saturation * 0.55).clamp(0.0, 1.0))
        .toColor();
  }

  static ThemeData _build({
    required NovaThemeSpec s,
    required Color brand,
    required Color brandMuted,
  }) {
    final Brightness brightness =
        s.isLight ? Brightness.light : Brightness.dark;

    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: brand,
      brightness: brightness,
    ).copyWith(
      primary: brand,
      onPrimary: s.onAccent,
      primaryContainer: brandMuted,
      onPrimaryContainer: s.textPrimary,
      surface: s.surface,
      onSurface: s.textPrimary,
      error: s.danger,
      outline: s.border,
      outlineVariant: s.divider,
    );

    final TextTheme text = _textTheme(s);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: fontFamily,
      fontFamilyFallback: fontFallback,
      scaffoldBackgroundColor: s.canvas,
      canvasColor: s.canvas,
      splashFactory: InkSparkle.splashFactory,
      textTheme: text,
      primaryTextTheme: text,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,

      extensions: <ThemeExtension<dynamic>>[
        NovaChatColors(
          chatBackground: s.chatBackground,
          bubbleOwn: s.bubbleOwn,
          bubbleOwnText: s.bubbleOwnText,
          bubbleOther: s.bubbleOther,
          bubbleOtherText: s.bubbleOtherText,
          online: s.online,
          warning: s.warning,
        ),
      ],

      dialogTheme: DialogThemeData(
        backgroundColor: s.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NovaRadius.lg),
          side: BorderSide(color: s.border),
        ),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: s.textSecondary,
          height: 1.55,
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: brand,
          foregroundColor: s.onAccent,
          disabledBackgroundColor: s.surfaceOverlay,
          disabledForegroundColor: s.textDisabled,
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(horizontal: NovaSpacing.xl),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NovaRadius.md),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: s.surfaceOverlay,
          foregroundColor: s.textPrimary,
          elevation: 0,
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(horizontal: NovaSpacing.xl),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NovaRadius.md),
            side: BorderSide(color: s.border),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: s.textPrimary,
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(horizontal: NovaSpacing.xl),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          side: BorderSide(color: s.borderStrong),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NovaRadius.md),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: s.textSecondary,
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(horizontal: NovaSpacing.lg),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NovaRadius.md),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: s.textSecondary,
          hoverColor: s.surfaceOverlay,
          highlightColor: s.surfaceOverlay,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: s.surfaceInput,
        hintStyle: text.bodyMedium?.copyWith(color: s.textDisabled),
        labelStyle: text.labelMedium,
        floatingLabelStyle: text.labelMedium?.copyWith(color: brand),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: NovaSpacing.lg,
          vertical: 14,
        ),
        border: _border(s.border),
        enabledBorder: _border(s.border),
        focusedBorder: _border(brand, width: 1.5),
        errorBorder: _border(s.danger),
        focusedErrorBorder: _border(s.danger, width: 1.5),
      ),

      cardTheme: CardThemeData(
        color: s.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NovaRadius.lg),
          side: BorderSide(color: s.border),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: s.divider,
        thickness: 1,
        space: 1,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: s.surface,
        surfaceTintColor: Colors.transparent,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: s.surfaceOverlay,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NovaRadius.md),
          side: BorderSide(color: s.border),
        ),
        textStyle: text.bodyMedium?.copyWith(color: s.textPrimary),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: s.surfaceOverlay,
          borderRadius: BorderRadius.circular(NovaRadius.sm),
          border: Border.all(color: s.border),
        ),
        textStyle: text.bodySmall?.copyWith(color: s.textPrimary),
      ),

      listTileTheme: ListTileThemeData(
        iconColor: s.textSecondary,
        textColor: s.textPrimary,
        titleTextStyle: text.titleMedium,
        subtitleTextStyle: text.bodySmall,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NovaRadius.md),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: s.surface,
        indicatorColor: brandMuted,
        selectedIconTheme: IconThemeData(color: brand, size: 22),
        unselectedIconTheme: IconThemeData(
          color: s.textTertiary,
          size: 22,
        ),
        selectedLabelTextStyle: text.labelSmall?.copyWith(
          color: brand,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: text.labelSmall,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return s.onAccent;
          }
          return s.textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return brand;
          return s.surfaceOverlay;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.transparent;
          }
          return s.borderStrong;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return brand;
          return Colors.transparent;
        }),
        checkColor: WidgetStatePropertyAll<Color>(s.onAccent),
        side: BorderSide(color: s.borderStrong, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NovaRadius.sm),
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return brand;
          return s.borderStrong;
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: brand,
        inactiveTrackColor: s.surfaceOverlay,
        thumbColor: s.isLight ? brand : Colors.white,
        overlayColor: brand.withValues(alpha: 0.20),
        trackHeight: 4,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: brand,
        linearTrackColor: s.surfaceOverlay,
        circularTrackColor: s.surfaceOverlay,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: s.isLight ? const Color(0xFF2B2B2B) : s.surfaceOverlay,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: s.isLight ? Colors.white : s.textPrimary,
        ),
        actionTextColor: brand,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NovaRadius.md),
          side: BorderSide(color: s.border),
        ),
      ),
      bannerTheme: MaterialBannerThemeData(
        backgroundColor: s.surfaceOverlay,
        surfaceTintColor: Colors.transparent,
      ),

      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll<Color>(s.borderStrong),
        radius: const Radius.circular(NovaRadius.pill),
        thickness: const WidgetStatePropertyAll<double>(8),
      ),
    );
  }

  static OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(NovaRadius.md),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  /// Explicit weights. Relying on the default Material weight ramp
  /// produced the thin text the update dialog used to show.
  static TextTheme _textTheme(NovaThemeSpec s) {
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        height: 1.15,
        color: s.textPrimary,
      ),
      displayMedium: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        height: 1.18,
        color: s.textPrimary,
      ),
      headlineMedium: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        height: 1.22,
        color: s.textPrimary,
      ),
      headlineSmall: TextStyle(
        fontSize: 21,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.28,
        color: s.textPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        color: s.textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: s.textPrimary,
      ),
      titleSmall: TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        color: s.textPrimary,
      ),
      bodyLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: s.textPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: s.textSecondary,
      ),
      bodySmall: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: s.textTertiary,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: s.textPrimary,
      ),
      labelMedium: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w500,
        color: s.textSecondary,
      ),
      labelSmall: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
        color: s.textTertiary,
      ),
    );
  }
}
