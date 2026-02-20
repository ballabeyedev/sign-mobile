import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toastification/toastification.dart';
import 'package:flutter/gestures.dart';
import 'dart:async';

import 'package:sign_application/core/routes/app_router.dart';
import 'package:sign_application/core/widgets/primary_button.dart';
import 'package:sign_application/core/widgets/primary_text_button.dart';
import 'package:sign_application/core/widgets/primary_text_formField.dart';
import 'package:sign_application/core/widgets/secondary_button.dart';
import 'package:sign_application/core/widgets/toastNotif.dart';
import 'package:sign_application/features/auth/presentation/widgets/Custom_rich_text.dart';
import 'package:sign_application/features/auth/presentation/widgets/Divider_row.dart';
import 'package:sign_application/features/auth/presentation/widgets/PasswordTextField.dart';
import 'package:sign_application/features/auth/presentation/widgets/TermsAndPrivacyText.dart';
import '../../../../core/theme/app_color.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _identifiantController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _showSplash = true;
  late Timer _timer;

  // Animations du splash
  late AnimationController _splashController;
  late Animation<double> _fadeLogo;
  late Animation<double> _scaleLogo;
  late Animation<Offset> _slideLogo;
  late Animation<double> _fadeLoader;

  @override
  void initState() {
    super.initState();

    // Contrôleur principal pour le splash (5 secondes)
    _splashController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );

    // Animation du logo : apparition progressive + zoom + léger slide vers le haut
    _fadeLogo = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _splashController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
      ),
    );
    _scaleLogo = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _splashController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );
    _slideLogo = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _splashController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    // Animation du loader : apparition retardée pour un effet en cascade
    _fadeLoader = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _splashController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeIn),
      ),
    );

    // Lancer l'animation
    _splashController.forward();

    // Après 5 secondes, basculer vers le formulaire de connexion
    _timer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showSplash = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _splashController.dispose();
    _identifiantController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLoginPressed() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        LoginRequested(
          identifiant: _identifiantController.text,
          mot_de_passe: _passwordController.text,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 800),
        switchInCurve: Curves.easeOutQuad,
        switchOutCurve: Curves.easeInQuad,
        child: _showSplash
            ? _buildSplashScreen()
            : _buildLoginScreen(),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // SPLASH SCREEN – ÉLÉGANT, ANIMATIONS FLUIDES
  // -------------------------------------------------------------------------
  Widget _buildSplashScreen() {
    return Container(
      key: const ValueKey('splash'),
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            AppColor.kPrimary.withOpacity(0.05),
            Colors.white,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Center(
        child: AnimatedBuilder(
          animation: _splashController,
          builder: (context, child) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo avec animation complète
                FadeTransition(
                  opacity: _fadeLogo,
                  child: ScaleTransition(
                    scale: _scaleLogo,
                    child: SlideTransition(
                      position: _slideLogo,
                      child: Hero(
                        tag: 'app-logo',
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColor.kPrimary.withOpacity(0.2),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/logo_sign.jpeg',
                            width: 180,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                // Indicateur de chargement avec animation de pulsation
                FadeTransition(
                  opacity: _fadeLoader,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.8, end: 1.0),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeInOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColor.kPrimary.withOpacity(0.1),
                          ),
                          child: Center(
                            child: SizedBox(
                              width: 32,
                              height: 32,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColor.kPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                // Texte de bienvenue qui apparaît en dernier
                FadeTransition(
                  opacity: _fadeLoader,
                  child: Text(
                    'Sign Application',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: AppColor.kGrayscale40, // ✅ Correction : kGrayscale60 → kGrayscale40
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // PAGE DE CONNEXION (identique à votre code d'origine)
  // -------------------------------------------------------------------------
  Widget _buildLoginScreen() {
    return BlocConsumer<AuthBloc, AuthState>(
      key: const ValueKey('login'),
      listener: (context, state) {
        if (state is AuthSuccess) {
          final role = state.user.role.toLowerCase();
          final nom = state.user.nom.toLowerCase();
          final prenom = state.user.prenom.toLowerCase();
          final email = state.user.email.toLowerCase();
          String route = AppRouter.homeRoute;
          final arguments = {
            'nom': state.user.nom,
            'prenom': state.user.prenom,
            'email': state.user.email,
          };

          if (role == 'client') {
            route = AppRouter.clientRoute;
          } else if (role == 'professionnel') {
            route = AppRouter.professionnelRoute;
          }

          Navigator.of(context).pushNamedAndRemoveUntil(
            route,
                (route) => false,
            arguments: state.user,
          );


          showToast(
            context,
            'Connexion réussie',
            'Bienvenue de retour !',
            ToastificationType.success,
          );
        } else if (state is AuthFailure) {
          showToast(
            context,
            'Échec de la connexion',
            'Identifiant ou mot de passe incorrect !',
            ToastificationType.error,
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Stack(
          children: [
            _buildBackground(),
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 60),
                      _buildHeader(),
                      const SizedBox(height: 48),
                      _buildLoginCard(isLoading),
                      const SizedBox(height: 32),
                      _buildTermsAndPrivacy(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBackground() {
    return Column(
      children: [
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColor.kPrimary.withOpacity(0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Expanded(flex: 3, child: Container()),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center( // 🔥 AJOUTE CE CENTER
          child: Hero(
            tag: 'app-logo',
            child: Image.asset(
              'assets/images/logosign.jpeg',
              width: 150,
            ),
          ),
        ),

        const SizedBox(height: 32),

        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Se ',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColor.kGrayscaleDark100,
                  height: 1.2,
                ),
              ),
              TextSpan(
                text: 'Connecter',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColor.kPrimary,
                ),
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            'Connectez-vous pour générer vos factures et signer des contrats en toute sécurité',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColor.kGrayscale40,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildLoginCard(bool isLoading) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColor.kPrimary.withOpacity(0.1),
            blurRadius: 40,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildTextFieldWithLabel(
            label: 'Email ou téléphone',
            hint: 'exemple@entreprise.com ou 77XXXXXXX',
            controller: _identifiantController,
            prefixIcon: Icons.person_outline,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 24),
          _buildPasswordField(),
          const SizedBox(height: 20),
          _buildRememberForgotRow(),
          const SizedBox(height: 32),
          _buildLoginButton(isLoading),
          const SizedBox(height: 24),
          _buildRegisterLink(),
        ],
      ),
    );
  }

  Widget _buildTextFieldWithLabel({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: AppColor.kGrayscaleDark100,
            fontWeight: FontWeight.w600,
            fontSize: 14,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColor.kLine, width: 1.5),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Icon(prefixIcon, color: AppColor.kPrimary, size: 20),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: PrimaryTextFormField(
                    controller: controller,
                    hintText: hint,
                    height: 50,
                    width: double.infinity,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mot de passe',
          style: GoogleFonts.plusJakartaSans(
            color: AppColor.kGrayscaleDark100,
            fontWeight: FontWeight.w600,
            fontSize: 14,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColor.kLine, width: 1.5),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Icon(Icons.lock_outline, color: AppColor.kPrimary, size: 20),
              ),
              Expanded(
                child: PasswordTextField(
                  controller: _passwordController,
                  hintText: 'Votre mot de passe',
                  height: 50,
                  width: double.infinity,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRememberForgotRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        PrimaryTextButton(
          onPressed: () => Navigator.of(context).pushNamed('/forgot-password'),
          titre: 'Mot de passe oublié ?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColor.kPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton(bool isLoading) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        color: AppColor.kPrimary,
        child: InkWell(
          onTap: isLoading ? null : _onLoginPressed,
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.white.withOpacity(0.2),
          highlightColor: Colors.white.withOpacity(0.1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: isLoading
                  ? null
                  : LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AppColor.kPrimary,
                  AppColor.kPrimary.withOpacity(0.8),
                ],
              ),
              boxShadow: isLoading
                  ? null
                  : [
                BoxShadow(
                  color: AppColor.kPrimary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Se connecter',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Nouveau chez nous ? ',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColor.kGrayscale40,
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.of(context).pushNamed('/register'),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: Text(
              'Créer un compte',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColor.kPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTermsAndPrivacy() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'En vous connectant, vous acceptez nos '),
              TextSpan(
                text: 'Conditions d\'utilisation',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  color: AppColor.kPrimary,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () => Navigator.of(context).pushNamed(
                    AppRouter.contiditionUtilisationRoute,
                  ),
              ),
              const TextSpan(text: ' et notre '),
              TextSpan(
                text: 'Politique de confidentialité',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  color: AppColor.kPrimary,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () => Navigator.of(context).pushNamed(
                    AppRouter.politiqueConfRoute,
                  ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColor.kGrayscale40,
            height: 1.6,
          ),
        ),
      ),
    );
  }
}