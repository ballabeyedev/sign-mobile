import 'package:flutter/material.dart';
import 'package:sign_application/features/auth/domain/entities/user.dart';

class ContratsPage extends StatelessWidget {
  final User? user;
  const ContratsPage({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> contrats = [
      {
        'id': 'CTR-001',
        'client': 'Jean Dupont',
        'type': 'Signature électronique',
        'date': '10/01/2024',
        'statut': 'Actif'
      },
      {
        'id': 'CTR-002',
        'client': 'Marie Martin',
        'type': 'Consultation juridique',
        'date': '12/01/2024',
        'statut': 'En attente'
      },
      {
        'id': 'CTR-003',
        'client': 'Pierre Durand',
        'type': 'Rédaction de contrat',
        'date': '14/01/2024',
        'statut': 'Terminé'
      },
      {
        'id': 'CTR-004',
        'client': 'Sophie Laurent',
        'type': 'Audit légal',
        'date': '16/01/2024',
        'statut': 'Actif'
      },
      {
        'id': 'CTR-005',
        'client': 'Thomas Bernard',
        'type': 'Conseil en propriété',
        'date': '18/01/2024',
        'statut': 'En attente'
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Contrats',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Gérez vos contrats et documents',
              style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add_circle_outline, size: 20),
              label: const Text('Nouveau contrat'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: contrats.length,
              itemBuilder: (context, index) {
                final contrat = contrats[index];
                Color statutColor;
                IconData statutIcon;
                switch (contrat['statut']) {
                  case 'Actif':
                    statutColor = Colors.green;
                    statutIcon = Icons.check_circle;
                    break;
                  case 'En attente':
                    statutColor = Colors.orange;
                    statutIcon = Icons.access_time;
                    break;
                  case 'Terminé':
                    statutColor = Colors.blue;
                    statutIcon = Icons.done_all;
                    break;
                  default:
                    statutColor = Colors.grey;
                    statutIcon = Icons.help;
                }
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: statutColor.withOpacity(0.1),
                      child: Icon(statutIcon, color: statutColor),
                    ),
                    title: Text(contrat['id'] as String,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Client: ${contrat['client']}'),
                        Text('Type: ${contrat['type']}'),
                        Text('Créé le: ${contrat['date']}'),
                      ],
                    ),
                    trailing: Chip(
                      label: Text(
                        contrat['statut'] as String,
                        style: TextStyle(
                            color: statutColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: statutColor.withOpacity(0.1),
                    ),
                    onTap: () {},
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}