import 'package:sign_application/core/routes/app_router.dart';
import 'package:sign_application/core/widgets/primary_button.dart';
import 'package:sign_application/core/widgets/primary_text_formField.dart';
import 'package:sign_application/features/auth/presentation/widgets/PasswordTextField.dart';
import 'package:sign_application/features/auth/presentation/widgets/TermsAndPrivacyText.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:toastification/toastification.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:signature/signature.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/toastNotif.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'package:flutter/gestures.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Contrôleurs pour les champs
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cinController = TextEditingController();
  final _passwordController = TextEditingController();

  // Contrôleurs pour les champs professionnels
  final _rcController = TextEditingController();
  final _nineaController = TextEditingController();

  // Variables pour les sélections
  String? _selectedRole;
  File? _profileImage;
  File? _logoImage;

  // NOUVEAU : Signature pour les professionnels
  File? _signatureImage;

  // Gestion des étapes
  int _currentStep = 0;
  final _formKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
  ];

  // Rôles disponibles
  final List<String> _roles = ['Particulier', 'Independant', 'Professionnel'];

  // Sélection d'image (profil ou logo)
  Future<void> _pickImage({required bool isProfile}) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        if (isProfile) {
          _profileImage = File(pickedFile.path);
        } else {
          _logoImage = File(pickedFile.path);
        }
      });
    }
  }

  // NOUVEAU : Ouverture du pad de signature
  Future<void> _openSignaturePad() async {
    final controller = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Signez ici',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
        content: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: AppColor.kLine, width: 1.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Signature(
            controller: controller,
            width: MediaQuery.of(context).size.width * 0.8,
            height: 200,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => controller.clear(),
            child: Text(
              'Effacer',
              style: GoogleFonts.plusJakartaSans(color: AppColor.kGrayscale40),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.isEmpty) {
                Navigator.pop(context);
                return;
              }
              final Uint8List? data = await controller.toPngBytes();
              if (data != null) {
                final tempDir = await getTemporaryDirectory();
                final file = File(
                  '${tempDir.path}/signature_${DateTime.now().millisecondsSinceEpoch}.png',
                );
                await file.writeAsBytes(data);
                setState(() {
                  _signatureImage = file;
                });
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.kPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('Valider'),
          ),
        ],
      ),
    );
  }

  // Validation et navigation
  void _goToNextStep() {
    if (_formKeys[_currentStep].currentState!.validate()) {
      if (_currentStep < 1) {
        setState(() => _currentStep += 1);
      } else {
        _submitRegistration();
      }
    }
  }

  void _goToPreviousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
    }
  }

  // Soumission avec les nouveaux champs (incluant signature)
  void _submitRegistration() {
    if (_formKeys[1].currentState!.validate()) {
      context.read<AuthBloc>().add(
        RegisterRequested(
          nom: _lastNameController.text.trim(),
          prenom: _firstNameController.text.trim(),
          email: _emailController.text.trim(),
          mot_de_passe: _passwordController.text,
          adresse: _addressController.text.trim(),
          telephone: _phoneController.text.trim(),
          carte_identite_national_num: _cinController.text.trim(),
          role: _selectedRole ?? 'Particulier',
          photoProfil: _profileImage != null ? XFile(_profileImage!.path) : null,
          // Données professionnelles
          logo: _logoImage != null ? XFile(_logoImage!.path) : null,
          rc: _rcController.text.trim().isNotEmpty ? _rcController.text.trim() : null,
          ninea: _nineaController.text.trim().isNotEmpty ? _nineaController.text.trim() : null,
          // NOUVEAU : Signature
          signature: _signatureImage != null ? XFile(_signatureImage!.path) : null,
        ),
      );
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cinController.dispose();
    _passwordController.dispose();
    _rcController.dispose();
    _nineaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocConsumer<AuthBloc, AuthState>(
        listenWhen: (previous, current) => previous != current,
        listener: (context, state) {
          if (state is AuthSuccess) {
            FocusScope.of(context).unfocus();
            showToast(
              context,
              'Inscription réussie',
              'Vous pouvez maintenant vous connecter !',
              ToastificationType.success,
            );

            Navigator.of(context).pushNamedAndRemoveUntil(
              AppRouter.loginRoute,
                  (route) => false,
            );

            context.read<AuthBloc>().add(ResetAuthState());
          } else if (state is AuthFailure) {
            showToast(
              context,
              'Échec de l\'inscription',
              state.message,
              ToastificationType.error,
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return Stack(
            children: [
              _buildBackground(),
              Positioned(
                top: 48,
                left: 16,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black),
                  ),
                ),
              ),
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),
                      _buildHeader(),
                      const SizedBox(height: 32),
                      _buildStepIndicator(),
                      const SizedBox(height: 32),
                      _buildRegisterForm(isLoading),
                      const SizedBox(height: 32),
                      _buildStepNavigation(isLoading),
                      const SizedBox(height: 40),
                      _buildTermsAndPrivacy(),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBackground() {
    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColor.kPrimary.withOpacity(0.05),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Hero(
            tag: 'app-logo',
            child: Image.asset(
              'assets/images/logosignapk.jpeg',
              width: 150,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _currentStep == 0 ? 'Commençons !' : 'Informations complémentaires',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: AppColor.kGrayscaleDark100,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _currentStep == 0
              ? 'Remplissez vos informations personnelles'
              : 'Complétez votre profil pour commencer à signer',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColor.kGrayscale40,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: [
        _buildStepCircle(1, 'Informations', _currentStep >= 0),
        const Expanded(child: Divider(color: AppColor.kLine, thickness: 1.5)),
        _buildStepCircle(2, 'Profil', _currentStep >= 1),
      ],
    );
  }

  Widget _buildStepCircle(int stepNumber, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? AppColor.kPrimary : AppColor.kGrayscale40,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$stepNumber',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? AppColor.kPrimary : AppColor.kGrayscale40,
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterForm(bool isLoading) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColor.kPrimary.withOpacity(0.1),
            blurRadius: 40,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKeys[_currentStep],
        child: _currentStep == 0 ? _buildStep1Form() : _buildStep2Form(),
      ),
    );
  }

  Widget _buildStep1Form() {
    return Column(
      children: [
        _buildTextFieldWithLabel(
          label: 'Prénom',
          hint: 'Ex: Jane',
          controller: _firstNameController,
          prefixIcon: Icons.person_outline,
          isRequired: true,
        ),
        const SizedBox(height: 16),
        _buildTextFieldWithLabel(
          label: 'Nom',
          hint: 'Ex: Doe',
          controller: _lastNameController,
          prefixIcon: Icons.person_outline,
          isRequired: true,
        ),
        const SizedBox(height: 16),
        _buildTextFieldWithLabel(
          label: 'Téléphone',
          hint: 'Ex: 77 ... .. ..',
          controller: _phoneController,
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          isRequired: true,
        ),
        const SizedBox(height: 16),
        _buildTextFieldWithLabel(
          label: 'Adresse e-mail',
          hint: 'exemple@gmail.com',
          controller: _emailController,
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Ce champ est requis';
            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
              return 'Email invalide';
            }
            return null;
          },
          isRequired: false,
        ),
        const SizedBox(height: 16),
        _buildPasswordField(),
      ],
    );
  }

  Widget _buildStep2Form() {
    return Column(
      children: [
        _buildTextFieldWithLabel(
          label: 'Adresse complète',
          hint: 'Ex: Dakar, Sacré Coeur 3',
          controller: _addressController,
          prefixIcon: Icons.location_on_outlined,
          isRequired: true,
        ),
        const SizedBox(height: 16),
        _buildTextFieldWithLabel(
          label: 'Numéro de carte d\'identité',
          hint: 'Ex: 12345678',
          controller: _cinController,
          prefixIcon: Icons.badge_outlined,
          isRequired: true,
        ),
        const SizedBox(height: 16),
        _buildRoleDropdown(),
        const SizedBox(height: 24),
        _buildProfilePhotoSection(),
        if (_selectedRole == 'Professionnel') ...[
          const SizedBox(height: 24),
          const Divider(color: AppColor.kLine, thickness: 1),
          const SizedBox(height: 16),
          _buildLogoSection(),
          const SizedBox(height: 16),
          _buildTextFieldWithLabel(
            label: 'Registre de Commerce (RC)',
            hint: 'Ex: RC 2023 B 12345',
            controller: _rcController,
            prefixIcon: Icons.business_center_outlined,
            isRequired: true,
          ),
          const SizedBox(height: 16),
          _buildTextFieldWithLabel(
            label: 'NINEA',
            hint: 'Ex: 123456789',
            controller: _nineaController,
            prefixIcon: Icons.numbers_outlined,
            isRequired: true,
          ),
          const SizedBox(height: 16),
          // NOUVEAU : Section signature
          _buildSignatureSection(),
        ],
      ],
    );
  }

  Widget _buildTextFieldWithLabel({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: AppColor.kGrayscaleDark100,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            if (isRequired)
              Text(
                ' *',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
          ],
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
                    keyboardType: keyboardType,
                    validator: validator,
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
        Row(
          children: [
            Text(
              'Mot de passe',
              style: GoogleFonts.plusJakartaSans(
                color: AppColor.kGrayscaleDark100,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            Text(
              ' *',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.red,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
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
                  hintText: 'Créez un mot de passe sécurisé',
                  height: 50,
                  width: double.infinity,
                  borderRadius: BorderRadius.circular(12),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Ce champ est requis';
                    if (value.length < 6) {
                      return 'Le mot de passe doit contenir au moins 6 caractères';
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

  Widget _buildRoleDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Rôle',
              style: GoogleFonts.plusJakartaSans(
                color: AppColor.kGrayscaleDark100,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            Text(
              ' *',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.red,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
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
                child: Icon(Icons.work_outline, color: AppColor.kPrimary, size: 20),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: DropdownButtonFormField<String>(
                    value: _selectedRole,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                    hint: Text(
                      'Sélectionnez votre rôle',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColor.kGrayscale40,
                        fontSize: 16,
                      ),
                    ),
                    items: _roles.map((role) {
                      return DropdownMenuItem<String>(
                        value: role,
                        child: Text(
                          role,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            color: AppColor.kGrayscaleDark100,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedRole = value),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez sélectionner un rôle';
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

  Widget _buildProfilePhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Photo de profil',
          style: GoogleFonts.plusJakartaSans(
            color: AppColor.kGrayscaleDark100,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _pickImage(isProfile: true),
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _profileImage != null ? AppColor.kPrimary : AppColor.kLine,
                width: _profileImage != null ? 2 : 1.5,
              ),
              color: AppColor.kBackground.withOpacity(0.3),
            ),
            child: _profileImage != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(_profileImage!, fit: BoxFit.cover, width: double.infinity),
            )
                : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.camera_alt_outlined, size: 32, color: AppColor.kPrimary),
                const SizedBox(height: 8),
                Text(
                  'Ajouter une photo',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColor.kPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Cliquez pour sélectionner',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColor.kGrayscale40,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Logo de l\'entreprise (optionnel)',
          style: GoogleFonts.plusJakartaSans(
            color: AppColor.kGrayscaleDark100,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _pickImage(isProfile: false),
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _logoImage != null ? AppColor.kPrimary : AppColor.kLine,
                width: _logoImage != null ? 2 : 1.5,
              ),
              color: AppColor.kBackground.withOpacity(0.3),
            ),
            child: _logoImage != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(_logoImage!, fit: BoxFit.cover, width: double.infinity),
            )
                : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_photo_alternate_outlined, size: 28, color: AppColor.kPrimary),
                const SizedBox(height: 4),
                Text(
                  'Ajouter un logo',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColor.kPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Optionnel',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColor.kGrayscale40,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // NOUVEAU : Section signature
  Widget _buildSignatureSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Signature (optionnel)',
          style: GoogleFonts.plusJakartaSans(
            color: AppColor.kGrayscaleDark100,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _openSignaturePad,
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _signatureImage != null ? AppColor.kPrimary : AppColor.kLine,
                width: _signatureImage != null ? 2 : 1.5,
              ),
              color: AppColor.kBackground.withOpacity(0.3),
            ),
            child: _signatureImage != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(_signatureImage!, fit: BoxFit.contain, width: double.infinity),
            )
                : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.draw_outlined, size: 28, color: AppColor.kPrimary),
                const SizedBox(height: 4),
                Text(
                  'Signez ici',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColor.kPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Touchez pour signer',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColor.kGrayscale40,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepNavigation(bool isLoading) {
    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColor.kPrimary, width: 1.5),
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: _goToPreviousStep,
                  borderRadius: BorderRadius.circular(16),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.arrow_back_rounded, color: AppColor.kPrimary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Retour',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColor.kPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (_currentStep > 0) const SizedBox(width: 16),
        Expanded(
          flex: _currentStep == 0 ? 2 : 1,
          child: SizedBox(
            height: 56,
            child: Material(
              borderRadius: BorderRadius.circular(16),
              elevation: 0,
              color: AppColor.kPrimary,
              child: InkWell(
                onTap: isLoading ? null : _goToNextStep,
                borderRadius: BorderRadius.circular(16),
                splashColor: Colors.white.withOpacity(0.2),
                highlightColor: Colors.white.withOpacity(0.1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
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
                          _currentStep == 0 ? 'Suivant' : 'S\'inscrire',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          _currentStep == 0
                              ? Icons.arrow_forward_rounded
                              : Icons.check_circle_outline_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
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