import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'providers/theme_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const ExpenseManagerApp(),
    ),
  );
}

class ExpenseManagerApp extends StatelessWidget {
  const ExpenseManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final lightPalette =
            ThemePaletteConfig.of(themeProvider.palette, Brightness.light);
        final darkPalette =
            ThemePaletteConfig.of(themeProvider.palette, Brightness.dark);

        ThemeData buildTheme(ThemePaletteConfig palette, Brightness brightness) {
          final scheme = ColorScheme(
            brightness: brightness,
            primary: palette.primary,
            onPrimary: brightness == Brightness.dark ? Colors.black : Colors.white,
            secondary: palette.secondary,
            onSecondary: brightness == Brightness.dark ? Colors.black : Colors.white,
            tertiary: palette.tertiary,
            onTertiary: brightness == Brightness.dark ? Colors.black : Colors.white,
            error: const Color(0xFFE57373),
            onError: Colors.white,
            surface: palette.surface,
            onSurface: palette.onSurface,
            background: palette.background,
            onBackground: palette.onBackground,
          );

          return ThemeData(
            useMaterial3: true,
            colorScheme: scheme,
            scaffoldBackgroundColor: palette.background,
            iconTheme: IconThemeData(color: scheme.onSurface),
            appBarTheme: AppBarTheme(
              backgroundColor: palette.background,
              foregroundColor: scheme.onSurface,
              elevation: 0,
              titleTextStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            cardTheme: CardThemeData(
              color: palette.surface,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                foregroundColor: scheme.onSurface,
                backgroundColor: scheme.surface,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: scheme.secondary,
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: palette.surface,
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
                borderSide: BorderSide.none,
              ),
              labelStyle: TextStyle(color: scheme.onSurface.withOpacity(0.6)),
            ),
            segmentedButtonTheme: SegmentedButtonThemeData(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.resolveWith((states) {
                  if (states.contains(MaterialState.selected)) {
                    return scheme.secondary.withOpacity(0.2);
                  }
                  return palette.surface;
                }),
                foregroundColor: MaterialStateProperty.resolveWith((states) {
                  if (states.contains(MaterialState.selected)) {
                    return scheme.secondary;
                  }
                  return scheme.onSurface;
                }),
                shape: MaterialStateProperty.all(
                  const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(14)),
                  ),
                ),
                side: MaterialStateProperty.resolveWith((states) {
                  if (states.contains(MaterialState.selected)) {
                    return BorderSide(color: scheme.secondary, width: 1.2);
                  }
                  return BorderSide.none;
                }),
              ),
            ),
            textTheme: const TextTheme(
              titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          );
        }

        return MaterialApp(
          title: 'Autofi',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(lightPalette, Brightness.light),
          darkTheme: buildTheme(darkPalette, Brightness.dark),
          themeMode: themeProvider.flutterMode,
          home: const SplashScreen(),
        );
      },
    );
  }
}
