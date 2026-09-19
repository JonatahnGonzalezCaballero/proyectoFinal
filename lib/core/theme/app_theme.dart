import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  static const violeta = Color(0xFF6161FF);
  static const tinta = Color(0xFF333333);
  static const pizarra = Color(0xFF535768);
  static const hierro = Color(0xFF808080);
  static const niebla = Color(0xFFD0D4E4);
  static const guijarro = Color(0xFFDDDFEB);
  static const nube = Color(0xFFF5F6F8);
  static const nieve = Color(0xFFFFFFFF);

  static const menta = Color(0xFFBCFE90);
  static const cielo = Color(0xFFABF0FF);
  static const albaricoque = Color(0xFFFF8940);
  static const lavanda = Color(0xFFEDDFF7);
  static const periwinkle = Color(0xFFE7ECFF);
  static const agua = Color(0xFFD1FAFF);
  static const bosque = Color(0xFF2A5C4E);
  static const coralSuave = Color(0xFFFFE1DE);
  static const coralTexto = Color(0xFFC0392B);
}

class EstadoPillColors {
  const EstadoPillColors({required this.fondo, required this.texto});
  final Color fondo;
  final Color texto;

  static EstadoPillColors para(String estado) {
    switch (estado) {
      case 'pendiente':
      case 'programada':
      case 'planeado':
        return const EstadoPillColors(fondo: Color(0xFFFFE9D6), texto: Color(0xFF9A5B00));
      case 'en_revision':
        return const EstadoPillColors(fondo: AppColors.periwinkle, texto: AppColors.violeta);
      case 'aprobada':
      case 'activa':
      case 'en_ejecucion':
        return const EstadoPillColors(fondo: AppColors.menta, texto: Color(0xFF2C6A00));
      case 'rechazada':
      case 'cancelada':
      case 'suspendido':
        return const EstadoPillColors(fondo: AppColors.coralSuave, texto: AppColors.coralTexto);
      case 'finalizada':
      case 'finalizado':
      case 'convertida_proyecto':
        return const EstadoPillColors(fondo: Color(0xFFD9F2EC), texto: AppColors.bosque);
      default:
        return const EstadoPillColors(fondo: AppColors.nube, texto: AppColors.pizarra);
    }
  }
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    final textTheme = GoogleFonts.poppinsTextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.poppins(fontSize: 48, fontWeight: FontWeight.w300, letterSpacing: -0.9, color: AppColors.tinta),
      headlineLarge: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w400, letterSpacing: -0.5, color: AppColors.tinta),
      headlineMedium: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w500, color: AppColors.tinta),
      titleLarge: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.tinta),
      titleMedium: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.tinta),
      bodyLarge: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.tinta),
      bodyMedium: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.pizarra),
      bodySmall: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.hierro),
      labelLarge: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.nieve),
    );

    final colorScheme = ColorScheme.fromSeed(seedColor: AppColors.violeta).copyWith(
      primary: AppColors.violeta,
      onPrimary: AppColors.nieve,
      secondary: AppColors.bosque,
      surface: AppColors.nieve,
      onSurface: AppColors.tinta,
      surfaceContainerHighest: AppColors.nube,
      outline: AppColors.niebla,
      outlineVariant: AppColors.guijarro,
      error: AppColors.coralTexto,
    );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.nube,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.nieve,
        foregroundColor: AppColors.tinta,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.tinta),
      ),
      cardTheme: CardThemeData(
        color: AppColors.nieve,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.niebla),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.violeta,
          foregroundColor: AppColors.nieve,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: const StadiumBorder(),
          textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.tinta,
          side: const BorderSide(color: AppColors.pizarra),
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 20),
          shape: const StadiumBorder(),
          textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.pizarra,
          textStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.nieve,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColors.guijarro)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColors.guijarro)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColors.violeta, width: 1.5)),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        labelStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
        side: BorderSide.none,
      ),
      dividerColor: AppColors.guijarro,
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.violeta, brightness: Brightness.dark),
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
      appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
    );
  }
}