import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.nom,
    required super.prenom,
    required super.email,
    required super.mot_de_passe,
    required super.adresse,
    required super.telephone,
    required super.carte_identite_national_num,
    required super.role,
    super.photoProfil,
    super.logo,
    super.rc,
    super.ninea,
    super.signature,
    super.nomEntreprise,
    super.adresseEntreprise,
    super.telephoneEntreprise,
    super.emailEntreprise,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'].toString(),
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      email: json['email'] ?? '',
      mot_de_passe: json['mot_de_passe'] ?? '',
      adresse: json['adresse'] ?? '',
      telephone: json['telephone'] ?? '',
      carte_identite_national_num: json['carte_identite_national_num'] ?? '',
      role: json['role'] ?? '',
      photoProfil: json['photoProfil'],
      logo: json['logo'],
      rc: json['rc'],
      ninea: json['ninea'],
      signature: json['signature'],
      nomEntreprise: json['nomEntreprise'],
      adresseEntreprise: json['adresseEntreprise'],
      telephoneEntreprise: json['telephoneEntreprise'],
      emailEntreprise: json['emailEntreprise'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'mot_de_passe': mot_de_passe,
      'adresse': adresse,
      'telephone': telephone,
      'carte_identite_national_num': carte_identite_national_num,
      'role': role,
      'photoProfil': photoProfil,
      'logo': logo,
      'rc': rc,
      'ninea': ninea,
      'signature': signature,
      'nomEntreprise': nomEntreprise,
      'adresseEntreprise': adresseEntreprise,
      'telephoneEntreprise': telephoneEntreprise,
      'emailEntreprise': emailEntreprise,
    };
  }
}

class AuthResponseModel {
  final String token;
  final UserModel user;

  AuthResponseModel({required this.token, required this.user});

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    final userData = json['utilisateur'] ?? {};

    return AuthResponseModel(
      token: json['token'] ?? '',
      user: UserModel.fromJson(userData as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'utilisateur': user.toJson(),
    };
  }
}