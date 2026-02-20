import 'package:flutter/material.dart';

Widget buildClientAvatar(Map<String, dynamic> client, {double radius = 20}) {
  final String? photoUrl = client['photoProfil'];
  final String prenom = client['prenom']?.toString() ?? '';
  final String nom = client['nom']?.toString() ?? '';
  final String initiale = (prenom.isNotEmpty
      ? prenom[0]
      : (nom.isNotEmpty ? nom[0] : '?'))
      .toUpperCase();

  if (photoUrl != null && photoUrl.isNotEmpty) {
    return ClipOval(
      child: Image.network(
        photoUrl,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return CircleAvatar(
            radius: radius,
            backgroundColor: Colors.blue[100],
            child: Text(
              initiale,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return CircleAvatar(
            radius: radius,
            backgroundColor: Colors.grey[200],
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        },
      ),
    );
  } else {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.blue[100],
      child: Text(
        initiale,
        style: const TextStyle(
            fontWeight: FontWeight.bold, color: Colors.blue),
      ),
    );
  }
}