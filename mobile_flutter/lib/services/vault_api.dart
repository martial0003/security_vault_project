import 'dart:convert';
import 'package:http/http.dart' as http;

class VaultAPI {
  // Android Emulator → 10.0.2.2
  static const String baseUrl = 'http://172.16.81.86:8000';


  // =========================
  // LOGIN
  // =========================
  static Future<Map<String, dynamic>> login(String password) async {
    try {
      final response = await http
          .post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'password': password}),
      )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        throw Exception(
          'Erreur login (${response.statusCode})',
        );
      }

      final data = jsonDecode(response.body);

      if (!data.containsKey('vault_id') ||
          !data.containsKey('session_id')) {
        throw Exception('Réponse login invalide');
      }

      return data;
    } catch (_) {
      throw Exception('Connexion au moteur impossible');
    }
  }

  // =========================
  // LISTE DES ENTRÉES
  // =========================
  static Future<List<String>> getEntries({
    required int vaultId,
    required String sessionId,
  }) async {
    try {
      final response = await http
          .get(
        Uri.parse(
          '$baseUrl/entries/$vaultId?session_id=$sessionId',
        ),
      )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        throw Exception('Erreur récupération entrées');
      }

      final data = jsonDecode(response.body);
      return List<String>.from(data['entries']);
    } catch (_) {
      throw Exception('Impossible de charger le coffre');
    }
  }

  // =========================
  // AJOUT D’UNE ENTRÉE
  // =========================
  static Future<void> addEntry({
    required int vaultId,
    required String sessionId,
    required String service,
    required String username,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
        Uri.parse('$baseUrl/entries'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'vault_id': vaultId,
          'session_id': sessionId,
          'service': service,
          'username': username,
          'password': password,
        }),
      )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        throw Exception('Erreur ajout entrée');
      }
    } catch (_) {
      throw Exception('Impossible d’ajouter le compte');
    }
  }

  // =========================
  // LECTURE D’UNE ENTRÉE
  // =========================
  static Future<Map<String, String>> readEntry({
    required int vaultId,
    required String sessionId,
    required String service,
  }) async {
    try {
      final response = await http
          .post(
        Uri.parse('$baseUrl/entry/read'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'vault_id': vaultId,
          'session_id': sessionId,
          'service': service,
        }),
      )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        throw Exception('Erreur lecture entrée');
      }

      final data = jsonDecode(response.body);
      return {
        'username': data['username'],
        'password': data['password'],
      };
    } catch (_) {
      throw Exception('Impossible de lire le compte');
    }
  }

  // =========================
  // SUPPRESSION D’UNE ENTRÉE
  // =========================
  static Future<void> deleteEntry({
    required int vaultId,
    required String sessionId,
    required String service,
  }) async {
    try {
      final response = await http
          .post(
        Uri.parse('$baseUrl/entry/delete'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'vault_id': vaultId,
          'session_id': sessionId,
          'service': service,
        }),
      )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        throw Exception('Erreur suppression');
      }
    } catch (_) {
      throw Exception('Impossible de supprimer le compte');
    }
  }

  // =========================
  // OWNER — PROPRIÉTAIRE
  // =========================
  static Future<void> setOwnerSecret({
    required int vaultId,
    required String sessionId,
    required String ownerSecret,
  }) async {
    final response = await http
        .post(
      Uri.parse('$baseUrl/vault/set_owner_secret'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'vault_id': vaultId,
        'session_id': sessionId,
        'owner_secret': ownerSecret,
      }),
    )
        .timeout(const Duration(seconds: 5));

    if (response.statusCode != 200) {
      throw Exception('Erreur set owner secret');
    }
  }

  static Future<bool> verifyVault({
    required int vaultId,
    required String sessionId,
    required String ownerSecret,
  }) async {
    final response = await http
        .post(
      Uri.parse('$baseUrl/vault/verify'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'vault_id': vaultId,
        'session_id': sessionId,
        'owner_secret': ownerSecret,
      }),
    )
        .timeout(const Duration(seconds: 5));

    if (response.statusCode != 200) {
      throw Exception('Erreur verify owner');
    }

    final data = jsonDecode(response.body);
    return data['is_real'] == true;
  }
}
