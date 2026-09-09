import 'package:ecommerce_app/models/user_session.dart';
import 'package:ecommerce_app/services/local_store.dart';
import 'package:ecommerce_app/state/auth_provider.dart';
import 'package:ecommerce_app/utils/validators.dart';
import 'package:ecommerce_app/views/login_page.dart';
import 'package:ecommerce_app/views/profile_page.dart';
import 'package:ecommerce_app/views/register_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/pump_app.dart';

Future<LocalStore> openStore([Map<String, Object> initial = const {}]) async {
  SharedPreferences.setMockInitialValues(initial);
  return LocalStore.open();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Validators.email', () {
    test('rejects malformed addresses', () {
      for (final value in ['', 'ada', 'ada@', '@example.com', 'ada@example']) {
        expect(Validators.email(value), isNotNull, reason: 'for "$value"');
      }
    });

    test('accepts ordinary addresses', () {
      for (final value in [
        'ada@example.com',
        'ada.lovelace+shop@example.co.uk',
        '  ada@example.com  ',
      ]) {
        expect(Validators.email(value), isNull, reason: 'for "$value"');
      }
    });
  });

  group('Validators.name', () {
    test('requires something more than blank', () {
      expect(Validators.name(''), 'Enter your name');
      expect(Validators.name('   '), 'Enter your name');
      expect(Validators.name('A'), isNotNull);
    });

    test('accepts a real name', () {
      expect(Validators.name('Ada Lovelace'), isNull);
    });
  });

  group('Validators.phone', () {
    test('rejects letters and wrong lengths', () {
      expect(Validators.phone(''), isNotNull);
      expect(Validators.phone('call me'), isNotNull);
      expect(Validators.phone('12345'), isNotNull);
      expect(Validators.phone('1234567890123456'), isNotNull);
    });

    test('accepts the shapes people actually type', () {
      for (final value in [
        '08123456789',
        '+62 812 3456 7890',
        '(021) 555-0100',
      ]) {
        expect(Validators.phone(value), isNull, reason: 'for "$value"');
      }
    });
  });

  group('Validators passwords', () {
    test('sign-in only checks length', () {
      expect(Validators.password(''), isNotNull);
      expect(Validators.password('short'), isNotNull);
      expect(Validators.password('longenough'), isNull);
    });

    test('sign-up also wants letters and numbers', () {
      expect(Validators.newPassword('lettersonly'), 'Mix letters and numbers');
      expect(Validators.newPassword('12345678'), 'Mix letters and numbers');
      expect(Validators.newPassword('letters123'), isNull);
    });

    test('confirmation must match', () {
      expect(Validators.confirmPassword('', 'letters123'), isNotNull);
      expect(Validators.confirmPassword('nope123456', 'letters123'), isNotNull);
      expect(Validators.confirmPassword('letters123', 'letters123'), isNull);
    });
  });

  group('AuthProvider', () {
    test('starts signed out', () {
      final auth = AuthProvider(latency: Duration.zero);

      expect(auth.isAuthenticated, isFalse);
      expect(auth.session, isNull);
    });

    test('rejects a malformed login without touching the session', () async {
      final auth = AuthProvider(latency: Duration.zero);

      final ok = await auth.login(email: 'nope', password: 'letters123');

      expect(ok, isFalse);
      expect(auth.isAuthenticated, isFalse);
      expect(auth.errorMessage, 'Enter a valid email address');
    });

    test('rejects a short password', () async {
      final auth = AuthProvider(latency: Duration.zero);

      expect(
        await auth.login(email: 'ada@example.com', password: 'short'),
        isFalse,
      );
      expect(auth.errorMessage, contains('8'));
    });

    test('signs in and normalises the email', () async {
      final auth = AuthProvider(latency: Duration.zero);

      expect(
        await auth.login(email: '  Ada@Example.COM ', password: 'letters123'),
        isTrue,
      );
      expect(auth.session!.email, 'ada@example.com');
      expect(auth.isAuthenticated, isTrue);
    });

    test('registration validates every field in turn', () async {
      final auth = AuthProvider(latency: Duration.zero);

      Future<String?> attempt({
        String name = 'Ada Lovelace',
        String email = 'ada@example.com',
        String phone = '08123456789',
        String password = 'letters123',
      }) async {
        await auth.register(
          name: name,
          email: email,
          phone: phone,
          password: password,
        );
        return auth.errorMessage;
      }

      expect(await attempt(name: ''), 'Enter your name');
      expect(await attempt(email: 'nope'), 'Enter a valid email address');
      expect(await attempt(phone: 'call me'), isNotNull);
      expect(await attempt(password: 'lettersonly'), 'Mix letters and numbers');
      expect(auth.isAuthenticated, isFalse);

      expect(await attempt(), isNull);
      expect(auth.isAuthenticated, isTrue);
    });

    test('a successful sign-in survives a restart', () async {
      final store = await openStore();

      await AuthProvider(store: store, latency: Duration.zero).register(
        name: 'Ada Lovelace',
        email: 'ada@example.com',
        phone: '08123456789',
        password: 'letters123',
      );

      final restarted = AuthProvider(store: store, latency: Duration.zero);

      expect(restarted.isAuthenticated, isTrue);
      expect(restarted.session!.name, 'Ada Lovelace');
      expect(restarted.session!.phone, '08123456789');
    });

    test('signing in again keeps the registered name and phone', () async {
      final store = await openStore();
      final auth = AuthProvider(store: store, latency: Duration.zero);

      await auth.register(
        name: 'Ada Lovelace',
        email: 'ada@example.com',
        phone: '08123456789',
        password: 'letters123',
      );
      await auth.logout();
      await auth.login(email: 'ada@example.com', password: 'letters123');

      expect(auth.session!.name, 'Ada Lovelace');
    });

    test('logout clears the stored session', () async {
      final store = await openStore();
      final auth = AuthProvider(store: store, latency: Duration.zero);
      await auth.login(email: 'ada@example.com', password: 'letters123');

      await auth.logout();

      expect(auth.isAuthenticated, isFalse);
      expect(store.readSession(), isNull);
      expect(
        AuthProvider(store: store, latency: Duration.zero).isAuthenticated,
        isFalse,
      );
    });

    test('never stores a password', () async {
      final store = await openStore();
      final auth = AuthProvider(store: store, latency: Duration.zero);

      await auth.register(
        name: 'Ada Lovelace',
        email: 'ada@example.com',
        phone: '08123456789',
        password: 'letters123',
      );

      expect(store.readSession()!.values.join(), isNot(contains('letters123')));
    });

    test('reports a submitting state around the simulated delay', () async {
      final auth = AuthProvider(latency: const Duration(milliseconds: 20));
      final states = <bool>[];
      auth.addListener(() => states.add(auth.isSubmitting));

      await auth.login(email: 'ada@example.com', password: 'letters123');

      expect(states, [true, false]);
    });
  });

  group('UserSession', () {
    test('initials come from the name, then the email', () {
      expect(
        const UserSession(name: 'Ada Lovelace', email: 'a@b.com').initials,
        'AL',
      );
      expect(const UserSession(name: 'Ada', email: 'a@b.com').initials, 'A');
      expect(const UserSession(name: '', email: 'ada@b.com').initials, 'A');
    });

    test('display name falls back to the email local part', () {
      expect(
        const UserSession(name: '', email: 'ada@example.com').displayName,
        'ada',
      );
    });

    test('round-trips through JSON', () {
      const session = UserSession(
        name: 'Ada',
        email: 'ada@example.com',
        phone: '0812',
      );

      expect(UserSession.fromJson(session.toJson()), session);
    });
  });

  group('LoginPage', () {
    testWidgets('blocks submission and shows inline errors', (tester) async {
      setViewport(tester, const Size(420, 900));
      final auth = AuthProvider(latency: Duration.zero);

      await pumpApp(
        tester,
        const LoginPage(),
        providers: [ChangeNotifierProvider.value(value: auth)],
      );

      await tester.enterText(find.byType(TextFormField).first, 'nope');
      await tester.enterText(find.byType(TextFormField).last, 'short');
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid email address'), findsOneWidget);
      expect(find.textContaining('at least 8'), findsOneWidget);
      expect(auth.isAuthenticated, isFalse);
    });

    testWidgets('signs in with valid input', (tester) async {
      setViewport(tester, const Size(420, 900));
      final auth = AuthProvider(latency: Duration.zero);

      await pumpApp(
        tester,
        const LoginPage(),
        providers: [ChangeNotifierProvider.value(value: auth)],
      );

      await tester.enterText(
        find.byType(TextFormField).first,
        'ada@example.com',
      );
      await tester.enterText(find.byType(TextFormField).last, 'letters123');
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pumpAndSettle();

      expect(auth.isAuthenticated, isTrue);
      expect(find.textContaining('Signed in as ada'), findsOneWidget);
    });

    testWidgets('the password can be revealed', (tester) async {
      setViewport(tester, const Size(420, 900));
      await pumpApp(tester, const LoginPage());

      expect(find.byTooltip('Show password'), findsOneWidget);

      await tester.tap(find.byTooltip('Show password'));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Hide password'), findsOneWidget);
    });

    testWidgets('says it is a demo account', (tester) async {
      setViewport(tester, const Size(420, 900));
      await pumpApp(tester, const LoginPage());

      expect(find.textContaining('no password is stored'), findsOneWidget);
    });
  });

  group('RegisterPage', () {
    testWidgets('every field reports its own error', (tester) async {
      setViewport(tester, const Size(420, 1200));
      final auth = AuthProvider(latency: Duration.zero);

      await pumpApp(
        tester,
        const RegisterPage(),
        providers: [ChangeNotifierProvider.value(value: auth)],
      );

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), '');
      await tester.enterText(fields.at(1), 'nope');
      await tester.enterText(fields.at(2), 'call me');
      await tester.enterText(fields.at(3), 'lettersonly');
      await tester.enterText(fields.at(4), 'different');
      await tester.pumpAndSettle();

      expect(find.text('Enter your name'), findsOneWidget);
      expect(find.text('Enter a valid email address'), findsOneWidget);
      expect(find.text('Use digits, spaces, brackets, + or -'), findsOneWidget);
      expect(find.text('Mix letters and numbers'), findsOneWidget);
      expect(find.text('Those passwords do not match'), findsOneWidget);
      expect(auth.isAuthenticated, isFalse);
    });

    testWidgets('creates the account with valid input', (tester) async {
      setViewport(tester, const Size(420, 1200));
      final auth = AuthProvider(latency: Duration.zero);

      await pumpApp(
        tester,
        const RegisterPage(),
        providers: [ChangeNotifierProvider.value(value: auth)],
      );

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Ada Lovelace');
      await tester.enterText(fields.at(1), 'ada@example.com');
      await tester.enterText(fields.at(2), '08123456789');
      await tester.enterText(fields.at(3), 'letters123');
      await tester.enterText(fields.at(4), 'letters123');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
      await tester.pumpAndSettle();

      expect(auth.isAuthenticated, isTrue);
      expect(auth.session!.name, 'Ada Lovelace');
    });
  });

  group('ProfilePage', () {
    testWidgets('signed out offers sign in and register', (tester) async {
      setViewport(tester, const Size(420, 900));
      await pumpApp(tester, const ProfilePage());

      expect(find.text('Not signed in'), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);
      expect(find.text('Create account'), findsOneWidget);
    });

    testWidgets('signed in shows the profile and confirms sign out',
        (tester) async {
      setViewport(tester, const Size(420, 900));
      final auth = AuthProvider(latency: Duration.zero);
      await auth.register(
        name: 'Ada Lovelace',
        email: 'ada@example.com',
        phone: '08123456789',
        password: 'letters123',
      );

      await pumpApp(
        tester,
        const ProfilePage(),
        providers: [ChangeNotifierProvider.value(value: auth)],
      );
      await tester.pumpAndSettle();

      expect(find.text('Ada Lovelace'), findsOneWidget);
      expect(find.text('ada@example.com'), findsOneWidget);
      expect(find.text('AL'), findsOneWidget);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Sign out'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Stay signed in'));
      await tester.pumpAndSettle();
      expect(auth.isAuthenticated, isTrue);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Sign out'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
      await tester.pumpAndSettle();

      expect(auth.isAuthenticated, isFalse);
      expect(find.text('Not signed in'), findsOneWidget);
    });
  });
}
