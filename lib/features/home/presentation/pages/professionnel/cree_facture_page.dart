import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import './client_avatar.dart';
import './dio_handler.dart';

class CreeFacture extends StatefulWidget {
  const CreeFacture({super.key});

  @override
  State<CreeFacture> createState() => _CreeFactureState();
}

class _CreeFactureState extends State<CreeFacture> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _rechercheController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dateEcheanceController = TextEditingController();
  final TextEditingController _delaisExecutionController = TextEditingController();
  final TextEditingController _lieuExecutionController = TextEditingController();
  final TextEditingController _avanceController = TextEditingController();
  final TextEditingController _moyenPaiementController = TextEditingController();

  List<dynamic> _clientsTrouves = [];
  bool _isRechercheLoading = false;
  String _rechercheErreur = '';
  dynamic _clientSelectionne;
  DateTime? _dateEcheance;
  Dio? _dio;

  List<Map<String, dynamic>> _items = [
    {'designation': '', 'quantite': 1, 'prix_unitaire': 0.0}
  ];

  final List<String> _moyensPaiement = [
    'ESPECES',
    'VIREMENT BANCAIRE',
    'CARTE BANCAIRE',
    'CHEQUE',
    'MOBILE MONEY',
    'AUTRE'
  ];
  String? _selectedMoyenPaiement;

  @override
  void initState() {
    super.initState();
    _initDio();
    _lieuExecutionController.text = 'Dakar';
  }

  void _initDio() {
    try {
      _dio = GetIt.instance<Dio>();
    } catch (e) {
      _dio = Dio(BaseOptions(
        baseUrl: 'https://sign-backend-kmf1.onrender.com',
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ));
    }
  }

  void _ajouterItem() => setState(() => _items.add(
      {'designation': '', 'quantite': 1, 'prix_unitaire': 0.0}));

  void _supprimerItem(int index) {
    if (_items.length > 1) {
      setState(() => _items.removeAt(index));
    } else {
      setState(() =>
      _items[0] = {'designation': '', 'quantite': 1, 'prix_unitaire': 0.0});
    }
  }

  void _mettreAJourItem(int index, String champ, dynamic valeur) =>
      setState(() => _items[index][champ] = valeur);

  double _calculerMontantTotal() {
    double total = 0;
    for (var item in _items) {
      total += (item['quantite'] ?? 0) * (item['prix_unitaire'] ?? 0);
    }
    return total;
  }

  double _calculerSolde() {
    double total = _calculerMontantTotal();
    double avance = double.tryParse(_avanceController.text) ?? 0;
    return total - avance;
  }

  Future<void> _rechercherClients(String query) async {
    if (query.isEmpty) {
      setState(() {
        _clientsTrouves = [];
        _rechercheErreur = '';
      });
      return;
    }
    setState(() {
      _isRechercheLoading = true;
      _rechercheErreur = '';
    });
    try {
      await handleDioRequest(context, () async {
        Map<String, dynamic> params = {};
        if (query.isNotEmpty) params['nom'] = query;
        final response = await _dio!.get(
          '/professionnel/client/recherche-client',
          queryParameters: params,
          options: Options(headers: {'Content-Type': 'application/json'}),
        );
        if (response.statusCode == 200) {
          setState(() {
            _clientsTrouves = response.data['utilisateurs'] ?? [];
            _isRechercheLoading = false;
          });
        } else {
          throw Exception('Erreur serveur: ${response.statusCode}');
        }
      });
    } catch (e) {
      setState(() {
        _rechercheErreur = 'Erreur: $e';
        _isRechercheLoading = false;
        _clientsTrouves = [];
      });
    }
  }

  void _selectionnerClient(dynamic client) {
    setState(() {
      _clientSelectionne = client;
      _clientsTrouves = [];
      _rechercheController.clear();
    });
  }

  void _annulerSelectionClient() =>
      setState(() => _clientSelectionne = null);

  Future<void> _selectDateEcheance(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _dateEcheance = picked;
        _dateEcheanceController.text =
        "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  void _soumettreFacture() async {
    if (_formKey.currentState!.validate()) {
      if (_clientSelectionne == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Veuillez sélectionner un client'),
              backgroundColor: Colors.red),
        );
        return;
      }
      for (int i = 0; i < _items.length; i++) {
        final item = _items[i];
        if (item['designation'] == null ||
            item['designation']!.toString().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Veuillez remplir la désignation de l\'article ${i + 1}'),
                backgroundColor: Colors.red),
          );
          return;
        }
        if ((item['quantite'] ?? 0) <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'La quantité de l\'article ${i + 1} doit être > 0'),
                backgroundColor: Colors.red),
          );
          return;
        }
        if ((item['prix_unitaire'] ?? 0) <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Le prix unitaire de l\'article ${i + 1} doit être > 0'),
                backgroundColor: Colors.red),
          );
          return;
        }
      }
      try {
        await handleDioRequest(context, () async {
          final nouvelleFacture = {
            'clientId': _clientSelectionne['id'],
            'delais_execution': _delaisExecutionController.text,
            'date_execution': _dateEcheance?.toIso8601String(),
            'avance': double.tryParse(_avanceController.text) ?? 0,
            'lieu_execution': _lieuExecutionController.text,
            'moyen_paiement': _selectedMoyenPaiement ?? 'ESPECES',
            'items': _items.map((item) => ({
              'designation': item['designation'],
              'quantite': item['quantite'],
              'prix_unitaire': item['prix_unitaire'],
            })).toList(),
            'montant_total': _calculerMontantTotal(),
            'solde': _calculerSolde(),
            'description': _descriptionController.text,
          };
          final response = await _dio!.post(
            '/professionnel/document/creer-document',
            data: nouvelleFacture,
            options: Options(headers: {'Content-Type': 'application/json'}),
          );
          if (response.statusCode == 201 || response.statusCode == 200) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Facture créée avec succès!'),
                  backgroundColor: Colors.green),
            );
            Navigator.pop(context);
          } else {
            throw Exception('Erreur serveur: ${response.statusCode}');
          }
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double total = _calculerMontantTotal();
    final double solde = _calculerSolde();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Nouvelle Facture',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Créer une nouvelle facture',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Remplissez les informations',
                  style: TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 24),

              const Text('Client *',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (_clientSelectionne != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green)),
                  child: Row(
                    children: [
                      buildClientAvatar(_clientSelectionne, radius: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                '${_clientSelectionne['prenom']} ${_clientSelectionne['nom']}',
                                style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                            Text(_clientSelectionne['email'] ?? '',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                            Text(_clientSelectionne['telephone'] ?? '',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: _annulerSelectionClient),
                    ],
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _rechercheController,
                      decoration: InputDecoration(
                        labelText: 'Rechercher un client *',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _isRechercheLoading
                            ? const SizedBox(
                            width: 20,
                            height: 20,
                            child:
                            CircularProgressIndicator(strokeWidth: 2))
                            : null,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onChanged: (value) =>
                          Future.delayed(const Duration(milliseconds: 500), () {
                            if (value == _rechercheController.text) {
                              _rechercherClients(value);
                            }
                          }),
                    ),
                    if (_rechercheErreur.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(_rechercheErreur,
                            style: const TextStyle(color: Colors.red)),
                      ),
                    if (_clientsTrouves.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8)),
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _clientsTrouves.length,
                          itemBuilder: (context, index) {
                            final client = _clientsTrouves[index];
                            return ListTile(
                              leading: buildClientAvatar(client, radius: 20),
                              title:
                              Text('${client['prenom']} ${client['nom']}'),
                              subtitle: Text(client['email'] ?? ''),
                              trailing: const Icon(Icons.arrow_forward_ios,
                                  size: 16),
                              onTap: () => _selectionnerClient(client),
                            );
                          },
                        ),
                      ),
                  ],
                ),

              const SizedBox(height: 24),

              const Text('Articles *',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Ajoutez les produits ou services',
                  style: TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 12),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Article ${index + 1}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              if (_items.length > 1)
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () => _supprimerItem(index),
                                  iconSize: 20,
                                  padding: EdgeInsets.zero,
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Désignation *',
                              hintText: 'Ex: Prestation test 1',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            initialValue: _items[index]['designation'],
                            onChanged: (value) =>
                                _mettreAJourItem(index, 'designation', value),
                            validator: (value) => value == null ||
                                value.isEmpty
                                ? 'Veuillez entrer une désignation'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  decoration: InputDecoration(
                                    labelText: 'Quantité *',
                                    hintText: 'Ex: 1',
                                    border: OutlineInputBorder(
                                        borderRadius:
                                        BorderRadius.circular(8)),
                                  ),
                                  keyboardType: TextInputType.number,
                                  initialValue: _items[index]['quantite']
                                      .toString(),
                                  onChanged: (value) {
                                    int? quantite = int.tryParse(value);
                                    if (quantite != null && quantite > 0) {
                                      _mettreAJourItem(
                                          index, 'quantite', quantite);
                                    }
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Veuillez entrer une quantité';
                                    }
                                    final quantite = int.tryParse(value);
                                    if (quantite == null || quantite <= 0) {
                                      return 'Quantité invalide';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  decoration: InputDecoration(
                                    labelText: 'Prix unitaire (FCFA) *',
                                    hintText: 'Ex: 700000',
                                    border: OutlineInputBorder(
                                        borderRadius:
                                        BorderRadius.circular(8)),
                                  ),
                                  keyboardType: TextInputType.number,
                                  initialValue: _items[index]['prix_unitaire']
                                      .toString(),
                                  onChanged: (value) {
                                    double? prix = double.tryParse(value);
                                    if (prix != null && prix >= 0) {
                                      _mettreAJourItem(
                                          index, 'prix_unitaire', prix);
                                    }
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Veuillez entrer un prix';
                                    }
                                    final prix = double.tryParse(value);
                                    if (prix == null || prix < 0) {
                                      return 'Prix invalide';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          if (_items[index]['quantite'] > 0 &&
                              _items[index]['prix_unitaire'] > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'Sous-total: ${(_items[index]['quantite'] * _items[index]['prix_unitaire']).toStringAsFixed(0)} FCFA',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _ajouterItem,
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter un article'),
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12)),
                ),
              ),

              const SizedBox(height: 16),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Récapitulatif',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Montant total:'),
                          Text('${total.toStringAsFixed(0)} FCFA',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Divider(color: Colors.grey[300]),
                      const SizedBox(height: 8),
                      const Text('Avance',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _avanceController,
                        decoration: InputDecoration(
                          labelText: 'Montant de l\'avance (FCFA)',
                          prefixIcon: const Icon(Icons.payment),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) => setState(() {}),
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final avance = double.tryParse(value);
                            if (avance == null || avance < 0) {
                              return 'Avance invalide';
                            }
                            if (avance > total) {
                              return 'L\'avance ne peut pas dépasser le montant total';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Solde à payer:'),
                          Text(
                            '${solde.toStringAsFixed(0)} FCFA',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: solde > 0 ? Colors.red : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              const Text('Délais d\'exécution *',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _delaisExecutionController,
                decoration: InputDecoration(
                  labelText: 'Ex: 2 jours',
                  prefixIcon: const Icon(Icons.timer),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Veuillez spécifier les délais'
                    : null,
              ),

              const SizedBox(height: 16),

              const Text('Lieu d\'exécution *',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _lieuExecutionController,
                decoration: InputDecoration(
                  labelText: 'Lieu',
                  prefixIcon: const Icon(Icons.location_on),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Veuillez spécifier le lieu'
                    : null,
              ),

              const SizedBox(height: 16),

              const Text('Moyen de paiement *',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedMoyenPaiement,
                decoration: InputDecoration(
                  labelText: 'Sélectionnez',
                  prefixIcon: const Icon(Icons.payment),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                items: _moyensPaiement
                    .map((moyen) => DropdownMenuItem(
                    value: moyen, child: Text(moyen)))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedMoyenPaiement = value),
                validator: (value) => value == null
                    ? 'Veuillez sélectionner un moyen de paiement'
                    : null,
              ),

              const SizedBox(height: 16),

              const Text('Date d\'échéance *',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _dateEcheanceController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Date d\'échéance',
                  prefixIcon: const Icon(Icons.calendar_today),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.date_range),
                    onPressed: () => _selectDateEcheance(context),
                  ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Veuillez sélectionner une date'
                    : null,
              ),

              const SizedBox(height: 16),

              const Text('Description',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Optionnel',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _soumettreFacture,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Créer la facture',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _rechercheController.dispose();
    _descriptionController.dispose();
    _dateEcheanceController.dispose();
    _delaisExecutionController.dispose();
    _lieuExecutionController.dispose();
    _avanceController.dispose();
    _moyenPaiementController.dispose();
    super.dispose();
  }
}