/// Session — authentification et membre connecté (Provider ChangeNotifier).
library;

import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'format.dart' as fmt;
import '../models/member.dart';

enum EtatSession { demarrage, deconnecte, connecte }

class SessionController extends ChangeNotifier {
  SessionController(this._api);

  final ApiClient _api;

  Membre? _moi;
  EtatSession _etat = EtatSession.demarrage;
  bool _occupe = false;

  EtatSession get etat => _etat;
  Membre? get moi => _moi;
  bool get occupe => _occupe;
  bool get estAdmin => fmt.estAdmin(_moi?.role);

  /// Au lancement : restaure la session persistée (cookie-jar) si valide.
  Future<void> demarrer() async {
    _etat = EtatSession.demarrage;
    notifyListeners();
    try {
      final data = await _api.get('/api/auth/me');
      final brut = (data as Map?)?['member'];
      _moi = brut == null ? null : Membre.fromJson(brut);
      _etat = _moi == null ? EtatSession.deconnecte : EtatSession.connecte;
    } on ApiException {
      _moi = null;
      _etat = EtatSession.deconnecte;
    }
    notifyListeners();
  }

  /// Connexion (téléphone + mot de passe) → session serveur 7 jours.
  Future<void> connecter(String telephone, String motDePasse) async {
    if (_occupe) return;
    _occupe = true;
    notifyListeners();
    try {
      final data = await _api.post('/api/auth/login', body: {
        'phone': telephone.trim(),
        'password': motDePasse,
      });
      _moi = Membre.fromJson((data as Map)['member']);
      _etat = EtatSession.connecte;
    } finally {
      _occupe = false;
      notifyListeners();
    }
  }

  /// Changement de mot de passe (obligatoire à la première connexion).
  Future<void> changerMotDePasse(String actuel, String nouveau) async {
    if (_occupe) return;
    _occupe = true;
    notifyListeners();
    try {
      await _api.post('/api/auth/change-password', body: {
        'currentPassword': actuel,
        'newPassword': nouveau,
      });
      _moi = _moi == null
          ? null
          : Membre.fromJson({
              ...?_profilJson(),
              'mustChangePassword': false,
            });
    } finally {
      _occupe = false;
      notifyListeners();
    }
  }

  Map<String, dynamic>? _profilJson() {
    final m = _moi;
    if (m == null) return null;
    return <String, dynamic>{
      'id': m.id,
      'firstName': m.prenom,
      'lastName': m.nom,
      'phone': m.telephone,
      'city': m.ville,
      'role': m.role,
      'registryId': m.registreId,
      'registryName': m.nomRegistre,
      'mustChangePassword': m.doitChangerMdp,
    };
  }

  /// Déconnexion serveur + purge locale (dans tous les cas).
  Future<void> deconnecter() async {
    try {
      await _api.post('/api/auth/logout');
    } catch (_) {
      // Même hors réseau : on purge la session locale.
    }
    await _api.oublierSession();
    _moi = null;
    _etat = EtatSession.deconnecte;
    notifyListeners();
  }

  /// Après expiration de session détectée par un écran.
  void marquerDeconnecte() {
    _moi = null;
    _etat = EtatSession.deconnecte;
    notifyListeners();
  }
}
