import 'package:flutter/foundation.dart';

import '../models/user_session.dart';
import '../services/local_store.dart';
import '../utils/validators.dart';

/// Sign-in state.
///
/// **This is a local simulation.** The app talks to a read-only public product
/// API and has no accounts backend, so nothing is checked against a server and
/// no password is stored anywhere — not even hashed. Any correctly formatted
/// email and password will sign you in, and the UI says so.
///
/// What is real: the field validation, and the session surviving a restart.
class AuthProvider with ChangeNotifier {
  AuthProvider({LocalStore? store, Duration latency = _defaultLatency})
      : _store = store,
        _latency = latency {
    final saved = store?.readSession();
    if (saved != null) _session = UserSession.fromJson(saved);
  }

  /// A short pause on submit so the loading state is a real thing the user
  /// sees, rather than a flash. Tests pass [Duration.zero].
  static const Duration _defaultLatency = Duration(milliseconds: 600);

  final LocalStore? _store;
  final Duration _latency;

  UserSession? _session;
  bool _isSubmitting = false;
  String? _errorMessage;

  UserSession? get session => _session;
  bool get isAuthenticated => _session != null;
  bool get isSubmitting => _isSubmitting;

  /// Set when a submission fails for a reason no single field explains.
  String? get errorMessage => _errorMessage;

  /// Signs in. Returns false, with [errorMessage] set, if the input is not
  /// well formed.
  ///
  /// A previously registered profile with the same email keeps its name and
  /// phone; anything else gets a profile built from the email.
  Future<bool> login({required String email, required String password}) async {
    final invalid = Validators.email(email) ?? Validators.password(password);
    if (invalid != null) return _fail(invalid);

    await _pause();

    final normalised = email.trim().toLowerCase();
    final known = _accountFor(normalised);

    return _succeed(known ?? UserSession(name: '', email: normalised));
  }

  /// Creates the local profile and signs in.
  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final invalid = Validators.name(name) ??
        Validators.email(email) ??
        Validators.phone(phone) ??
        Validators.newPassword(password);
    if (invalid != null) return _fail(invalid);

    await _pause();

    final session = UserSession(
      name: name.trim(),
      email: email.trim().toLowerCase(),
      phone: phone.trim(),
    );
    await _rememberAccount(session);
    return _succeed(session);
  }

  /// The profile registered on this device for [email], if there is one.
  UserSession? _accountFor(String email) {
    for (final account in _store?.readAccounts() ??
        const <Map<String, dynamic>>[]) {
      final session = UserSession.fromJson(account);
      if (session.email == email) return session;
    }
    return null;
  }

  /// Registering keeps the profile beyond the session: signing out ends a
  /// session, it does not delete the account.
  Future<void> _rememberAccount(UserSession session) async {
    final store = _store;
    if (store == null) return;

    final accounts = store.readAccounts()
      ..removeWhere((account) => account['email'] == session.email);
    await store.writeAccounts([...accounts, session.toJson()]);
  }

  Future<void> logout() async {
    _session = null;
    _errorMessage = null;
    notifyListeners();
    await _store?.clearSession();
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _pause() async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();
    if (_latency > Duration.zero) {
      await Future<void>.delayed(_latency);
    }
  }

  Future<bool> _succeed(UserSession session) async {
    _session = session;
    _isSubmitting = false;
    _errorMessage = null;
    notifyListeners();
    await _store?.writeSession(session.toJson());
    return true;
  }

  bool _fail(String message) {
    _errorMessage = message;
    _isSubmitting = false;
    notifyListeners();
    return false;
  }
}
