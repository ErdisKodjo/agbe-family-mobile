/// Client HTTP — API REST AGBE Family (Railway).
///
/// - dio + PersistCookieJar : la session httpOnly `pgf_session` survit
///   aux redémarrages de l'application (session serveur de 7 jours).
/// - Toutes les erreurs serveur ({error: "…"}) deviennent [ApiException]
///   avec un message français prêt à afficher.
library;

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';

import 'config.dart';

class ApiException implements Exception {
  ApiException(this.status, this.message);

  /// Code HTTP (null = erreur réseau / timeout).
  final int? status;
  final String message;

  bool get estAuthExpiree => status == 401;

  @override
  String toString() => message;
}

class ApiClient {
  Dio? _dio;
  PersistCookieJar? _jar;

  Future<void> init() async {
    if (_dio != null) return;
    final dir = await getApplicationDocumentsDirectory();
    _jar = PersistCookieJar(
      storage: FileStorage('${dir.path}/agbe-cookies'),
    );
    _dio = Dio(
      BaseOptions(
        baseUrl: apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 45),
        sendTimeout: const Duration(seconds: 60),
        headers: {'Accept': 'application/json'},
        // Les 4xx sont gérés manuellement (corps {error: "…"} en français).
        validateStatus: (status) => status != null && status < 500,
      ),
    )..interceptors.add(CookieManager(_jar!));
  }

  Dio get dio => _dio!;

  // ----------------------------------------------------------
  // Verbes HTTP — retournent le corps JSON décodé
  // ----------------------------------------------------------

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _envoyer(() => dio.get<dynamic>(path, queryParameters: query));

  Future<dynamic> post(String path, {Object? body}) =>
      _envoyer(() => dio.post<dynamic>(path, data: body));

  Future<dynamic> patch(String path, {Object? body}) =>
      _envoyer(() => dio.patch<dynamic>(path, data: body));

  Future<dynamic> delete(String path) =>
      _envoyer(() => dio.delete<dynamic>(path));

  /// Téléverse une preuve de paiement (image JPEG compressée).
  /// Retourne l'URL relative du fichier ({url: "/api/files/…"}).
  Future<String> televerserPreuve(String cheminFichier) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        cheminFichier,
        filename: 'preuve.jpg',
        contentType: MediaType('image', 'jpeg'),
      ),
    });
    final data = await _envoyer(() => dio.post<dynamic>('/api/upload', data: form));
    final url = (data as Map?)?['url'];
    if (url == null || url.toString().isEmpty) {
      throw ApiException(null, 'Téléversement de la preuve impossible');
    }
    return url.toString();
  }

  /// URL absolue d'une pièce (proofUrl relatif → URL complète).
  String urlAbsolue(String chemin) {
    if (chemin.startsWith('http')) return chemin;
    return '$apiBaseUrl$chemin';
  }

  // ----------------------------------------------------------
  // Passerelle commune — traduction des erreurs en français
  // ----------------------------------------------------------

  Future<dynamic> _envoyer(Future<Response<dynamic>> Function() requete) async {
    await init();
    try {
      final reponse = await requete();
      final code = reponse.statusCode ?? 0;
      if (code >= 400) {
        final corps = reponse.data;
        String message = 'Erreur $code';
        if (corps is Map && corps['error'] is String && corps['error'].toString().isNotEmpty) {
          message = corps['error'].toString();
        }
        throw ApiException(code, message);
      }
      return reponse.data;
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      final sansReseau = e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionError;
      if (sansReseau) {
        throw ApiException(
          null,
          'Connexion impossible — vérifiez votre réseau mobile ou Wi-Fi.',
        );
      }
      throw ApiException(null, 'Erreur réseau inattendue. Réessayez.');
    }
  }

  /// Oublie la session locale (après logout serveur ou expiration).
  Future<void> oublierSession() async {
    await init();
    await _jar?.deleteAll();
  }
}
