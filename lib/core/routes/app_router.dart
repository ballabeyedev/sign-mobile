import 'package:flutter/material.dart';
import 'package:sign_application/features/auth/presentation/pages/login_page.dart';
import 'package:sign_application/features/auth/presentation/pages/register_page.dart';
import 'package:sign_application/features/home/presentation/pages/home.dart';
import 'package:sign_application/features/home/presentation/pages/client/clientpage.dart';
import 'package:sign_application/features/home/presentation/pages/professionnel/professionnelpage.dart';
import 'package:sign_application/features/auth/presentation/widgets/ContiditionUtilisation.dart';
import 'package:sign_application/features/auth/presentation/widgets/PolitiqueConfidentialite.dart';
import 'package:sign_application/features/auth/domain/entities/user.dart';

import 'package:sign_application/features/auth/presentation/pages/onboarding_page.dart';


class AppRouter {
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String homeRoute = '/home';
  static const String clientRoute = '/client';
  static const String professionnelRoute = '/professionnel';

  static const String politiqueConfRoute = '/politique-confidentialite';
  static const String contiditionUtilisationRoute = '/condition-utilisation';

  static const String onboardingRoute = '/onboarding';



  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case loginRoute:
        return MaterialPageRoute(builder: (_) => LoginPage());

      case registerRoute:
        return MaterialPageRoute(builder: (_) => const RegisterPage());

      case homeRoute:
        return MaterialPageRoute(builder: (_) => const HomePage());

      case clientRoute:
        final user = settings.arguments as User?;
        return MaterialPageRoute(
          builder: (_) => ClientPage(user: user),
        );

      case professionnelRoute:
        final user = settings.arguments as User?;
        return MaterialPageRoute(
            builder: (_) => ProfessionnelPage(user: user)
        );

      case politiqueConfRoute:
        return MaterialPageRoute(builder: (_) => PolitiqueConfidentialite());

      case contiditionUtilisationRoute:
        return MaterialPageRoute(builder: (_) => const ConditionUtilisation());

      case onboardingRoute:
        return MaterialPageRoute(builder: (_) => const OnboardingPage1());


      default:
        return MaterialPageRoute(
          builder: (_) => const LoginPage(),
        );
    }
  }
}
