import 'package:flutter/material.dart';
import '../services/vault_api.dart';

class AddEntryScreen extends StatefulWidget {
  final int vaultId;
  final String sessionId;

  const AddEntryScreen({
    super.key,
    required this.vaultId,
    required this.sessionId,
  });

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  final serviceCtrl = TextEditingController();
  final userCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    serviceCtrl.dispose();
    userCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final service = serviceCtrl.text.trim();
    final user = userCtrl.text.trim();
    final pass = passCtrl.text;

    if (service.isEmpty || user.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Remplis tous les champs")),
      );
      return;
    }

    setState(() => loading = true);
    try {
      await VaultAPI.addEntry(
        vaultId: widget.vaultId,
        sessionId: widget.sessionId,
        service: service,
        username: user,
        password: pass,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors de l’enregistrement")),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ajouter un compte")),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      TextField(
                        controller: serviceCtrl,
                        decoration: const InputDecoration(
                          labelText: "Service (ex: Google)",
                          prefixIcon: Icon(Icons.apps_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: userCtrl,
                        decoration: const InputDecoration(
                          labelText: "Identifiant / Email",
                          prefixIcon: Icon(Icons.person_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: passCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: "Mot de passe",
                          prefixIcon: Icon(Icons.password_rounded),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 50,
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: loading ? null : save,
                  icon: loading
                      ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Icon(Icons.save_rounded),
                  label: Text(loading ? "Enregistrement..." : "Enregistrer"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
