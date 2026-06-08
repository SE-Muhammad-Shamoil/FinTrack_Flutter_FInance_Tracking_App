import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:finguard_ai/core/theme/app_theme.dart';

final biometricLockEnabledProvider = StateProvider<bool>((ref) => false); // Wire to SharedPreferences later
final isAuthenticatedProvider = StateProvider<bool>((ref) => false);

class BiometricInterceptor extends ConsumerStatefulWidget {
  final Widget child;
  const BiometricInterceptor({super.key, required this.child});

  @override
  ConsumerState<BiometricInterceptor> createState() => _BiometricInterceptorState();
}

class _BiometricInterceptorState extends ConsumerState<BiometricInterceptor> {
  final LocalAuthentication auth = LocalAuthentication();
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuth();
    });
  }

  Future<void> _checkAuth() async {
    final isEnabled = ref.read(biometricLockEnabledProvider);
    if (!isEnabled) {
      ref.read(isAuthenticatedProvider.notifier).state = true;
      return;
    }

    try {
      setState(() => _isAuthenticating = true);
      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Please authenticate to unlock FinTrack',
      );
      if (didAuthenticate) {
        ref.read(isAuthenticatedProvider.notifier).state = true;
      }
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _isAuthenticating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final isEnabled = ref.watch(biometricLockEnabledProvider);

    if (!isEnabled || isAuthenticated) {
      return widget.child;
    }

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_rounded, size: 80, color: Theme.of(context).primaryColor),
            const SizedBox(height: 24),
            const Text('App Locked', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (_isAuthenticating)
              const CircularProgressIndicator()
            else
              ElevatedButton.icon(
                onPressed: _checkAuth,
                icon: const Icon(Icons.fingerprint),
                label: const Text('Unlock with Biometrics'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
