import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// firebase_auth is still needed for User, but hide PhoneAuthProvider
import 'package:firebase_auth/firebase_auth.dart' hide PhoneAuthProvider;

// use PhoneAuthProvider from firebase_ui_auth
import 'package:firebase_ui_auth/firebase_ui_auth.dart'
    show SignInScreen, PhoneAuthProvider, AuthStateChangeAction, SignedIn;

// localization delegate
import 'package:firebase_ui_localizations/firebase_ui_localizations.dart';

import 'src/ui/home_screen.dart';
import 'src/ui/owner_admin_screen.dart';
import 'src/services/user_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voter List Dashboard',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [
        FirebaseUILocalizations.delegate,
      ],
      theme: ThemeData(useMaterial3: true),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        final user = snap.data;
        if (user == null) {
          return SignInScreen(
            providers: [PhoneAuthProvider()],
            headerBuilder: (context, _, __) => const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Sign in with your phone (OTP)'),
            ),
            actions: [
              AuthStateChangeAction<SignedIn>((context, state) async {
                await ref.read(userServiceProvider).upsertCurrentUser();
              })
            ],
          );
        }
        ref.read(userServiceProvider).touchLastLogin();
        return const RoleRouter();
      },
    );
  }
}

class RoleRouter extends ConsumerWidget {
  const RoleRouter({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleAsync = ref.watch(currentUserRoleProvider);
    return roleAsync.when(
      data: (role) {
        if (role == 'owner') return const OwnerAdminScreen();
        return const HomeScreen();
      },
      loading: () =>
      const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}
