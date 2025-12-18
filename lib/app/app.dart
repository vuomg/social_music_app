import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../providers/audio_player_provider.dart';
import '../widgets/common/network_banner.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => app_auth.AuthProvider()),
          ChangeNotifierProvider(create: (_) => AudioPlayerProvider()),
        ],
      child: NetworkBanner(
        child: MaterialApp(
          title: 'Music Social',
          theme: AppTheme.lightTheme,
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', 'US'),
            Locale('vi', 'VN'),
          ],
          locale: const Locale('vi', 'VN'),
          home: const AuthGate(),
          routes: {
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/home': (context) => const HomeScreen(),
          },
        ),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<app_auth.AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.user == null) {
          // Chưa đăng nhập - hiển thị Splash rồi chuyển sang Login
          return const SplashScreen();
        } else {
          // Đã đăng nhập - chuyển sang Home
          return const HomeScreen();
        }
      },
    );
  }
}
