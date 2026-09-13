# AGBE Family — Application Mobile 📱

Application mobile officielle de la **Plateforme de Gestion Familiale (PGF)** de la famille AGBETOSSOU.
Elle se connecte directement à l'API de production hébergée sur **Railway** :

> 🔗 https://agbe-family-production.up.railway.app

![Plateforme](https://img.shields.io/badge/API-Railway%20production-0D5C46) ![Flutter](https://img.shields.io/badge/Flutter-3.47%20stable-027DFD) ![Langue](https://img.shields.io/badge/Langue-Fran%C3%A7ais-D4AF37)

---

## ✨ Fonctionnalités

### Espace membre
- **Connexion sécurisée** (téléphone + mot de passe, session httpOnly persistée 7 jours)
- **Changement de mot de passe forcé** à la première connexion (même règle que le web)
- **Tableau de bord personnel** : total cotisé, reste à payer, paiements en attente, projets et tâches
- **Cotisations en cours** : avancement campagne par campagne
- **Déclaration de paiement** en 3 gestes : montant → méthode (Mobile Money, espèces, virement) → **photo de la preuve** (caméra ou galerie), avec référence et note
- **Projets & tâches** : suivi de l'avancement, mise à jour du statut de ses tâches en un tap
- **Annonces** de la famille (globales et de registre)
- **Profil** : identité, registre, changement de mot de passe, déconnexion

### Fonctions administration (SUPER_ADMIN, Tête de Liste, Trésorier)
- **Tableau de bord KPIs** : membres, solde de trésorerie, recettes du mois, total collecté, projets
- **Alerte paiements en attente** → écran de validation dédié
- **Validation / rejet des paiements déclarés** : visionneuse de preuve plein écran (zoom), validation
  qui porte automatiquement la recette au journal de caisse du registre
- **Flux de trésorerie** des 6 derniers mois (recettes / dépenses)
- **Activité récente** (journal d'audit)

---

## 🏗️ Architecture

| Élément | Choix |
|---|---|
| Framework | Flutter 3.47 (stable), Material 3 |
| Réseau | `dio` + `cookie_jar` persistant (session `pgf_session` httpOnly) |
| État | `provider` (ChangeNotifier) |
| Preuves photo | `image_picker` (compression JPEG qualité 85, ≤ 8 Mo côté serveur) |
| Charte | « Émeraude & Or » (#0D5C46 / #D4AF37), emblème AGBETOSSOU |
| Langue | 100 % français (formatage FCFA et dates intégré, sans `intl`) |

```
lib/
├── core/          # config (URL Railway), client API + cookies, session, thème, formatage FR
├── models/        # Member, Campaign, Payment, Project, Announcement, Stats
├── screens/       # login, MDP forcé, accueil (rôle), cotisations, déclaration,
│                  # projets, annonces, profil, validation paiements (admin)
└── widgets/       # splash, cartes KPI, statuts, états vides/erreurs, visionneuse preuve
```

---

## 🤖 Intégration continue (GitHub Actions)

À **chaque push sur `main`** : `flutter analyze` + `flutter test` (23 tests) + construction de l'APK.

À **chaque tag `v*`** : en plus, l'APK est publié dans une **GitHub Release** téléchargeable.

```bash
# Publier une nouvelle version
git tag v1.0.1 && git push origin v1.0.1
```

➡️ L'APK est ensuite disponible sur la page **Releases** du dépôt. Installation sur Android :
télécharger `app-release.apk`, puis *Paramètres → Sécurité → Installer des applications inconnues*
(ou simplement ouvrir le fichier téléchargé et suivre les instructions).

---

## 🔧 Développement local

```bash
flutter pub get
flutter analyze
flutter test
flutter run            # émulateur ou appareil Android branché
flutter build apk --release
```

L'URL de l'API est définie dans `lib/core/config.dart` (`apiBaseUrl`).

> ⚠️ Note signature : l'APK est signé avec la clé de debug Flutter (distribution interne).
> Pour une distribution Play Store, ajoutez un keystore de production
> (`android/key.properties` + `signingConfigs.release`, cf. documentation Flutter).

---

## 🔐 Sécurité

- Le mot de passe ne transite qu'en HTTPS vers l'API ; il n'est jamais stocké sur l'appareil
- La session est un cookie httpOnly (inaccessible au JavaScript / aux autres apps)
- Aucune donnée sensible n'est présente dans ce dépôt
