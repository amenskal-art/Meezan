import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/ckb_localizations.dart';
import 'core/locale_provider.dart';
import 'core/models.dart';
import 'core/services/auth_service.dart';
import 'core/services/firestore_service.dart';
import 'core/theme.dart';
import 'features/admin/admin_panel.dart';
import 'features/auth/login_screen.dart';
import 'features/client/client_shell.dart';
import 'features/lawyer/lawyer_shell.dart';
import 'features/onboarding/status_screen.dart';
import 'features/onboarding/verification_screen.dart';
import 'firebase_options.dart';
import 'l10n/gen/app_localizations.dart';

class MeezanApp extends StatelessWidget {
  const MeezanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LocaleProvider(),
      child: Consumer<LocaleProvider>(
        builder: (context, lp, _) => MaterialApp(
          title: 'MEEZAN',
          debugShowCheckedModeBanner: false,
          theme: MeezanTheme.light(),
          locale: lp.locale,
          supportedLocales: const [Locale('ar'), Locale('ckb'), Locale('en')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            // ckb fallbacks MUST come before the Global delegates.
            CkbMaterialLocalizationsDelegate(),
            CkbCupertinoLocalizationsDelegate(),
            CkbWidgetsLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          // Guarantee RTL for both Arabic and Kurdish Sorani.
          builder: (context, child) => Directionality(
            textDirection: LocaleProvider.isRtl(lp.locale)
                ? TextDirection.rtl
                : TextDirection.ltr,
            child: child ?? const SizedBox.shrink(),
          ),
          home: DefaultFirebaseOptions.isConfigured
              ? const AuthGate()
              : const _SetupMissingScreen(),
        ),
      ),
    );
  }
}

/// Auth state -> role -> dashboard routing.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.authState,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _Splash();
        }
        final user = snap.data;
        if (user == null) return const LoginScreen();
        return RoleGate(uid: user.uid);
      },
    );
  }
}

/// Reads users/{uid} + admin claim, then routes dynamically:
///   admin claim          -> AdminPanel
///   lawyer + no document -> VerificationScreen (upload syndicate card)
///   lawyer + pending     -> StatusScreen (locked out of B2B tools)
///   lawyer + rejected    -> StatusScreen (reason + resubmit)
///   lawyer + approved    -> LawyerShell
///   client               -> ClientShell
class RoleGate extends StatelessWidget {
  final String uid;
  const RoleGate({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService.isAdmin(),
      builder: (context, adminSnap) {
        if (!adminSnap.hasData) return const _Splash();
        if (adminSnap.data == true) return const AdminPanel();
        return StreamBuilder<AppUser?>(
          stream: FirestoreService.userStream(uid),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const _Splash();
            }
            final u = snap.data;
            if (u == null) return const _Splash();
            // Sync app language with the user's saved preference once.
            final lp = context.read<LocaleProvider>();
            if (u.language.isNotEmpty && u.language != lp.locale.languageCode) {
              WidgetsBinding.instance
                  .addPostFrameCallback((_) => lp.setLocale(u.language));
            }
            if (u.isLawyer) {
              if (u.status == 'approved') return LawyerShell(user: u);
              if (u.syndicateDocPath.isEmpty || u.status == 'rejected') {
                return u.status == 'rejected'
                    ? StatusScreen(user: u)
                    : VerificationScreen(user: u);
              }
              return StatusScreen(user: u);
            }
            return ClientShell(user: u);
          },
        );
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();
  @override
  Widget build(BuildContext context) => const Scaffold(
        backgroundColor: MeezanTheme.navy,
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.balance, size: 72, color: MeezanTheme.gold),
            SizedBox(height: 16),
            CircularProgressIndicator(color: MeezanTheme.gold),
          ]),
        ),
      );
}

class _SetupMissingScreen extends StatelessWidget {
  const _SetupMissingScreen();
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.settings_suggest, size: 64, color: MeezanTheme.gold),
            const SizedBox(height: 16),
            Text(t.setupMissingTitle,
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Text(t.setupMissingBody, textAlign: TextAlign.center),
          ]),
        ),
      ),
    );
  }
}
