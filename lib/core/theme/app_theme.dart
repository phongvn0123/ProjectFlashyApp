import 'package:flutter/material.dart';

/// ============================================================================
///  APP THEME — cầu nối DESIGN-apple.md → Flutter ThemeData
/// ----------------------------------------------------------------------------
///  Quy tắc vàng: KHÔNG viết hex/khoảng cách thẳng trong UI.
///  Luôn dùng [AppColors] / [Sp] / [R] / [AppText] để giữ một ngôn ngữ thị giác.
/// ============================================================================

/// ===== MÀU (DESIGN-apple.md) =====
class AppColors {
  AppColors._();

  static const primary = Color(0xFF0066CC); // Action Blue — màu nhấn DUY NHẤT
  static const primaryFocus = Color(0xFF0071E3); // viền focus
  static const primaryOnDark = Color(0xFF2997FF); // link trên nền tối

  static const ink = Color(0xFF1D1D1F); // chữ chính
  static const inkMuted80 = Color(0xFF333333);
  static const inkMuted48 = Color(0xFF7A7A7A); // disabled / fine print
  static const bodyMuted = Color(0xFFCCCCCC); // chữ phụ trên nền tối

  static const canvas = Color(0xFFFFFFFF); // nền sáng chủ đạo
  static const parchment = Color(0xFFF5F5F7); // nền off-white tạo nhịp
  static const pearl = Color(0xFFFAFAFC);
  static const hairline = Color(0xFFE0E0E0); // viền 1px
  static const dividerSoft = Color(0xFFF0F0F0);

  static const tile1 = Color(0xFF272729); // dark tile chính
  static const tile3 = Color(0xFF252527); // nền màn Study

  static const danger = Color(0xFFD93025); // hành động phá huỷ (Xoá/Reset)
  static const success = Color(0xFF2E7D32);
}

/// ===== KHOẢNG CÁCH (base 8) =====
class Sp {
  Sp._();
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 17.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
  static const section = 80.0;
}

/// ===== BO GÓC =====
class R {
  R._();
  static const sm = 8.0; // nút utility
  static const md = 11.0;
  static const lg = 18.0; // card tiện ích
  static const pill = 9999.0; // nút/chip/input pill
}

/// ===== BÓNG sản phẩm — CHỈ dùng cho thẻ đang học (màn Study). Cấm dùng cho nút/card. =====
const kProductShadow = <BoxShadow>[
  BoxShadow(color: Color(0x38000000), offset: Offset(3, 5), blurRadius: 30),
];

/// ===== KIỂU CHỮ — alias gọi nhanh từ Theme.of(context).textTheme =====
/// Quy ước map sang Material TextTheme:
///  hero      → displayLarge   (56/600, tight)
///  displayLg → displayMedium  (40/600)
///  displayMd → headlineMedium (28/600)
///  tagline   → titleLarge     (21/600)
///  bodyStrong→ titleMedium    (17/600)
///  body      → bodyLarge      (17/400)
///  caption   → bodyMedium     (14/400)
class AppText {
  AppText._();
  static TextStyle? hero(BuildContext c) => Theme.of(c).textTheme.displayLarge;
  static TextStyle? displayLg(BuildContext c) => Theme.of(c).textTheme.displayMedium;
  static TextStyle? displayMd(BuildContext c) => Theme.of(c).textTheme.headlineMedium;
  static TextStyle? tagline(BuildContext c) => Theme.of(c).textTheme.titleLarge;
  static TextStyle? bodyStrong(BuildContext c) => Theme.of(c).textTheme.titleMedium;
  static TextStyle? body(BuildContext c) => Theme.of(c).textTheme.bodyLarge;
  static TextStyle? caption(BuildContext c) => Theme.of(c).textTheme.bodyMedium;
}

/// ===== THEME =====
class AppTheme {
  AppTheme._();

  // SF Pro là độc quyền Apple → để null = dùng font hệ thống (an toàn, không cần asset).
  // Muốn giống thật hơn: thêm Inter vào pubspec rồi đặt _fontFamily = 'Inter'.
  static const String? _fontFamily = null;

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);

    final textTheme = base.textTheme
        .apply(
          bodyColor: AppColors.ink,
          displayColor: AppColors.ink,
          fontFamily: _fontFamily,
        )
        .copyWith(
          displayLarge: const TextStyle(
              fontSize: 56, fontWeight: FontWeight.w600, letterSpacing: -0.28, height: 1.07),
          displayMedium: const TextStyle(
              fontSize: 40, fontWeight: FontWeight.w600, letterSpacing: -0.4, height: 1.10),
          headlineMedium: const TextStyle(
              fontSize: 28, fontWeight: FontWeight.w600, letterSpacing: -0.3, height: 1.18),
          headlineSmall: const TextStyle(
              fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: -0.26, height: 1.27),
          titleLarge: const TextStyle(
              fontSize: 21, fontWeight: FontWeight.w600, letterSpacing: 0.23),
          titleMedium: const TextStyle(
              fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: -0.37, height: 1.4),
          bodyLarge: const TextStyle(
              fontSize: 17, fontWeight: FontWeight.w400, letterSpacing: -0.37, height: 1.47),
          bodyMedium: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: -0.22, height: 1.43),
          labelLarge: const TextStyle(
              fontSize: 17, fontWeight: FontWeight.w400, letterSpacing: -0.37),
        );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.canvas,
      textTheme: textTheme,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        surface: AppColors.canvas,
        onSurface: AppColors.ink,
        error: AppColors.danger,
      ),

      // AppBar phẳng, không bóng (Apple chỉ bóng ảnh sản phẩm).
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.canvas,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
            fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.ink, letterSpacing: -0.37),
      ),

      // Nút pill Action Blue (mẫu mặc định; AppButton bọc thêm micro-interaction).
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.hairline,
          disabledForegroundColor: AppColors.inkMuted48,
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.pill)),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),

      // Nút ghost (pill viền) cho hành động phụ.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          side: const BorderSide(color: AppColors.hairline),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.pill)),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w400),
        ),
      ),

      // Input pill viền hairline → focus đổi sang viền primary 2px.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.canvas,
        hintStyle: const TextStyle(color: AppColors.inkMuted48, fontSize: 17),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(R.pill),
          borderSide: const BorderSide(color: AppColors.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(R.pill),
          borderSide: const BorderSide(color: AppColors.primaryFocus, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(R.pill),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(R.pill),
          borderSide: const BorderSide(color: AppColors.danger, width: 2),
        ),
      ),

      // Card tiện ích: trắng, viền hairline, KHÔNG bóng, bo R.lg.
      cardTheme: CardThemeData(
        color: AppColors.canvas,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(R.lg),
          side: const BorderSide(color: AppColors.hairline),
        ),
      ),

      // Bottom navigation theo SCREENS §3.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        height: 64,
        indicatorColor: AppColors.primary.withValues(alpha: 0.10),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? AppColors.primary : AppColors.inkMuted48,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
              color: selected ? AppColors.primary : AppColors.inkMuted48);
        }),
      ),

      // Switch màu primary (SCREENS §6B shuffle).
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? AppColors.primary : AppColors.hairline),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),

      // Dialog bo góc, KHÔNG bóng.
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.lg)),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.md)),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.hairline,
        thickness: 1,
        space: 1,
      ),

      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.canvas,
        selectedColor: AppColors.primary.withValues(alpha: 0.10),
        side: const BorderSide(color: AppColors.hairline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.pill)),
        labelStyle: const TextStyle(fontSize: 15, color: AppColors.ink),
      ),

      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: AppColors.primary),
    );
  }
}
