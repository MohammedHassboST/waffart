import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../network/supabase_client.dart';

class AuthNotifier extends ChangeNotifier {
  StreamSubscription<AuthState>? _subscription;

  bool _isLoggedIn = false;
  bool _onboardingCompleted = false;
  bool _isAdmin = false;
  String? _role;

  bool get isLoggedIn => _isLoggedIn;
  bool get onboardingCompleted => _onboardingCompleted;
  bool get isAdmin => _isAdmin;
  String? get role => _role;

  // 🎧 ابدأ بسماع تغييرات Supabase
  void initialize() {
    _subscription = SupabaseClientProvider.client.auth.onAuthStateChange.listen(
          (data) {
        final session = data.session;
        _isLoggedIn = session != null;
        _role = session?.user.userMetadata?['role'] as String?;
        _isAdmin = _role == 'admin';
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Auth error: $error');
      },
    );
  }

  void setOnboardingCompleted(bool value) {
    _onboardingCompleted = value;
    notifyListeners();
  }

  void disposeNotifier() {
    _subscription?.cancel();
  }
}

final authNotifier = AuthNotifier();