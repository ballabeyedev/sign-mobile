import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toastification/toastification.dart';
import 'package:flutter/gestures.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';

import 'package:sign_application/core/routes/app_router.dart';
import 'package:sign_application/core/widgets/primary_text_button.dart';
import 'package:sign_application/core/widgets/primary_text_formField.dart';
import 'package:sign_application/core/widgets/toastNotif.dart';
import 'package:sign_application/features/auth/presentation/widgets/PasswordTextField.dart';
import '../../../../core/theme/app_color.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Variables pour le téléphone
  String? _phoneNumber; // numéro complet avec indicatif
  bool _isEmail = true; // true = email, false = téléphone

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLoginPressed() {
    if (_formKey.currentState!.validate()) {
      String identifiant;
      if (_isEmail) {
        identifiant = _emailController.text.trim();
      } else {
        identifiant = _phoneNumber ?? '';
      }
      context.read<AuthBloc>().add(
        LoginRequested(
          identifiant: identifiant,
          mot_de_passe: _passwordController.text,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess) {
          final role = state.user.role.toLowerCase();
          String route = AppRouter.homeRoute;

          if (role == 'particulier') {
            route = AppRouter.clientRoute;
          } else if (role == 'professionnel' || role == 'independant') {
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

        return Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              SafeArea(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 10),
                          _buildLoginCard(isLoading),
                          const SizedBox(height: 32),
                          _buildTermsAndPrivacy(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Hero(
            tag: 'app-logo',
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/logosign.jpeg',
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
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
          // Sélecteur Email / Téléphone
          _buildSelector(),
          const SizedBox(height: 16),
          // Champ conditionnel
          _buildIdentifierField(),
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

  Widget _buildSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColor.kBackground,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: ChoiceChip(
              label: Text(
                'Email',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              selected: _isEmail,
              onSelected: (selected) {
                setState(() {
                  _isEmail = true;
                  _phoneNumber = null; // reset phone
                });
              },
              selectedColor: AppColor.kPrimary,
              backgroundColor: Colors.transparent,
              labelStyle: TextStyle(
                color: _isEmail ? Colors.white : AppColor.kGrayscale40,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
          Expanded(
            child: ChoiceChip(
              label: Text(
                'Téléphone',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              selected: !_isEmail,
              onSelected: (selected) {
                setState(() {
                  _isEmail = false;
                  _emailController.clear(); // reset email
                });
              },
              selectedColor: AppColor.kPrimary,
              backgroundColor: Colors.transparent,
              labelStyle: TextStyle(
                color: !_isEmail ? Colors.white : AppColor.kGrayscale40,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentifierField() {
    if (_isEmail) {
      return _buildEmailField();
    } else {
      return _buildPhoneField();
    }
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email',
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
                child: Icon(Icons.email_outlined, color: AppColor.kPrimary, size: 20),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: PrimaryTextFormField(
                    controller: _emailController,
                    hintText: 'exemple@email.com',
                    height: 50,
                    width: double.infinity,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ce champ est requis';
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return 'Email invalide';
                      }
                      return null;
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Téléphone',
          style: GoogleFonts.plusJakartaSans(
            color: AppColor.kGrayscaleDark100,
            fontWeight: FontWeight.w600,
            fontSize: 14,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColor.kLine, width: 1.5),
          ),
          child: IntlPhoneField(
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              hintText: 'Votre numéro',
              hintStyle: GoogleFonts.plusJakartaSans(
                color: AppColor.kGrayscale40,
                fontSize: 16,
              ),
            ),
            initialCountryCode: 'SN',
            onChanged: (phone) {
              setState(() {
                _phoneNumber = phone.completeNumber;
              });
            },
            validator: (phone) {
              if (phone == null || phone.number.isEmpty) {
                return 'Ce champ est requis';
              }
              if (!phone.isValidNumber()) {
                return 'Numéro invalide pour le pays sélectionné';
              }
              return null;
            },
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ce champ est requis';
                    }
                    return null;
                  },
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