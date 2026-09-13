/// Configuration — AGBE Family mobile
///
/// L'application consomme l'API REST de la plateforme AGBE Family (PGF)
/// hébergée sur Railway. Le cookie de session httpOnly `pgf_session`
/// est conservé par le cookie-jar persistant (7 jours de validité côté serveur).
library;

/// URL de base de l'API de production (Railway).
const String apiBaseUrl = 'https://agbe-family-production.up.railway.app';

/// Durée de la session côté serveur (heures) — information indicative.
const int sessionDurationHours = 168;

/// Nom de l'application affiché à l'utilisateur.
const String appName = 'AGBE Family';

/// Devise de la famille AGBETOSSOU (sceau d'emblème).
const String motto = 'AGBE TƆ SƆ · La vie appartient à Dieu';
