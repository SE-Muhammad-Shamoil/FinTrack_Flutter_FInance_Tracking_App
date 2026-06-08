import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telephony/telephony.dart';
import 'package:finguard_ai/core/theme/app_theme.dart';
import 'package:finguard_ai/presentation/router/app_router.dart';
import 'package:finguard_ai/services/sms/sms_background_handler.dart';
import 'package:finguard_ai/presentation/features/auth/biometric_interceptor.dart';
import 'package:finguard_ai/presentation/providers/app_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize dependency injection, database, etc. here
  final telephony = Telephony.instance;
  
  bool? permissionsGranted = await telephony.requestPhoneAndSmsPermissions;

  if (permissionsGranted != null && permissionsGranted) {
    telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) {
        // Handle message in foreground if needed, or just let background handle it
        backgroundMessageHandler(message);
      },
      onBackgroundMessage: backgroundMessageHandler,
    );
  }

  runApp(
    const ProviderScope(
      child: FinGuardApp(),
    ),
  );
}

class FinGuardApp extends ConsumerWidget {
  const FinGuardApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    
    return MaterialApp.router(
      title: 'FinTrack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        return BiometricInterceptor(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
