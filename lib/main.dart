import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stronger/infrastructure/services/theme_notifier.dart';
import 'package:stronger/theme/theme.dart';

import 'firebase_options.dart';
import 'infrastructure/services/firebase/auth_state_notifier.dart';
import 'router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } else {
      await Firebase.initializeApp();
    }
  } catch (error, stackTrace) {
    debugPrint('Firebase initialization failed: $error\n$stackTrace');
    runApp(const StartupErrorApp());
    return;
  }

  try {
    await _activateAppCheck();
  } catch (error, stackTrace) {
    debugPrint('App Check activation failed: $error\n$stackTrace');
  }

  final authState = AuthStateNotifier();
  router = createRouter(authState);

  runApp(ChangeNotifierProvider.value(value: authState, child: const MyApp()));
}

class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Stronger no ha podido iniciar Firebase.\n\n'
              'Comprueba la conexión y la configuración de Firebase, '
              'después cierra y vuelve a abrir la aplicación.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _activateAppCheck() async {
  if (kIsWeb) {
    const siteKey = String.fromEnvironment('RECAPTCHA_SITE_KEY');
    if (siteKey.isEmpty) {
      debugPrint(
        'App Check web no está activo: falta RECAPTCHA_SITE_KEY. '
        'El coach IA rechazará peticiones hasta configurarla.',
      );
      return;
    }
    await FirebaseAppCheck.instance.activate(
      providerWeb: ReCaptchaV3Provider(siteKey),
    );
    return;
  }

  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      await FirebaseAppCheck.instance.activate(
        providerAndroid: kDebugMode
            ? const AndroidDebugProvider()
            : const AndroidPlayIntegrityProvider(),
      );
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      await FirebaseAppCheck.instance.activate(
        providerApple: kDebugMode
            ? const AppleDebugProvider()
            : const AppleAppAttestWithDeviceCheckFallbackProvider(),
      );
    case TargetPlatform.fuchsia:
    case TargetPlatform.linux:
    case TargetPlatform.windows:
      debugPrint('App Check no está configurado para esta plataforma.');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = ThemeNotifier();
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp.router(
          title: 'Stronger',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          routerConfig: router,
        );
      },
    );
  }
}
