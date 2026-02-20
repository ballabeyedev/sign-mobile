import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sign_application/features/auth/domain/entities/user.dart';
import 'package:sign_application/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sign_application/features/auth/presentation/bloc/auth_event.dart';
import './accueil_professionnel_page.dart';
import './listeclients_page.dart';
import './factures_page.dart';
import './contrats_page.dart';

class ProfessionnelPage extends StatefulWidget {
  final User? user;

  const ProfessionnelPage({super.key, this.user});

  @override
  State<ProfessionnelPage> createState() => _ProfessionnelPageState();
}

class _ProfessionnelPageState extends State<ProfessionnelPage> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    print('Professionnel connecté: ${widget.user?.toJson()}');
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.logout, size: 50, color: Colors.red),
                const SizedBox(height: 15),
                const Text(
                  "Déconnexion",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Voulez-vous vraiment vous déconnecter ?",
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 25),

                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Annuler"),
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          context.read<AuthBloc>().add(LogoutRequested());
                          Navigator.of(context).pushNamedAndRemoveUntil(
                              '/login', (route) => false);
                        },
                        child: const Text("Oui"),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final user =
        widget.user ?? ModalRoute.of(context)?.settings.arguments as User?;

    final nom = user?.nom ?? '';
    final prenom = user?.prenom ?? '';
    final email = user?.email ?? '';

    final String fullName =
    (prenom.isNotEmpty || nom.isNotEmpty) ? '$prenom $nom' : 'Professionnel';

    final List<Widget> pages = [
      HomeProfessionnelPage(user: user),
      ClientsPage(user: user),
      FacturesPage(user: user),
      ContratsPage(user: user),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              fullName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (email.isNotEmpty)
              Text(
                email,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _confirmLogout,
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Accueil'),
          BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'Clients'),
          BottomNavigationBarItem(
              icon: Icon(Icons.receipt_outlined),
              activeIcon: Icon(Icons.receipt),
              label: 'Factures'),
          BottomNavigationBarItem(
              icon: Icon(Icons.description_outlined),
              activeIcon: Icon(Icons.description),
              label: 'Contrats'),
        ],
      ),
    );
  }
}