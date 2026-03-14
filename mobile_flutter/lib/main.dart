import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/services/supabase_service.dart';
import 'core/services/auth_provider.dart';
import 'core/router.dart';
import 'core/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseService.url,
    anonKey: SupabaseService.anonKey,
  );

  runApp(const HealthCartApp());
}

class HealthCartApp extends StatelessWidget {
  const HealthCartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return MaterialApp.router(
            title: 'HealthCart',
            debugShowCheckedModeBanner: false,
            theme: HealthCartTheme.lightTheme,
            darkTheme: HealthCartTheme.darkTheme,
            themeMode: ThemeMode.light,
            routerConfig: AppRouter.router(auth),
            localizationsDelegates: const [
              DefaultMaterialLocalizations.delegate,
              DefaultWidgetsLocalizations.delegate,
            ],
          );
        },
      ),
    );
  }
}
