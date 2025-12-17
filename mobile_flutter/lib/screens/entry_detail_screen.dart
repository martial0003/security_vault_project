import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/vault_api.dart';

class EntryDetailScreen extends StatefulWidget {
  final int vaultId;
  final String sessionId;
  final String service;

  const EntryDetailScreen({
    super.key,
    required this.vaultId,
    required this.sessionId,
    required this.service,
  });

  @override
  State<EntryDetailScreen> createState() => _EntryDetailScreenState();
}

class _EntryDetailScreenState extends State<EntryDetailScreen> {
  String username = '';
  String password = '';
  bool showPassword = false;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadEntry();
  }

  Future<void> loadEntry() async {
    try {
      final data = await VaultAPI.readEntry(
        vaultId: widget.vaultId,
        sessionId: widget.sessionId,
        service: widget.service,
      );
      setState(() {
        username = data['username'] ?? '';
        password = data['password'] ?? '';
        loading = false;
      });
    } catch (_) {
      setState(() => loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Impossible de lire l’entrée")),
      );
    }
  }

  Future<void> copy(String value, String label) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$label copié ✅")),
    );
  }

  Future<void> confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Supprimer ce compte ?"),
        content: const Text("Cette action est définitive."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await VaultAPI.deleteEntry(
        vaultId: widget.vaultId,
        sessionId: widget.sessionId,
        service: widget.service,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.service),
        actions: [
          IconButton(
            onPressed: confirmDelete,
            icon: const Icon(Icons.delete_rounded),
          )
        ],
      ),
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person_rounded),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              "Identifiant",
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => copy(username, "Identifiant"),
                            icon: const Icon(Icons.copy_rounded),
                          )
                        ],
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          username,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const Icon(Icons.password_rounded),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              "Mot de passe",
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() => showPassword = !showPassword);
                            },
                            icon: Icon(
                              showPassword
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                            ),
                          ),
                          IconButton(
                            onPressed: () => copy(password, "Mot de passe"),
                            icon: const Icon(Icons.copy_rounded),
                          ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          showPassword ? password : "••••••••••••",
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.info_outline_rounded),
                  title: const Text(
                    "Astuce sécurité",
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text(
                    "Les données sont chiffrées en base et déchiffrées à la demande.",
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
