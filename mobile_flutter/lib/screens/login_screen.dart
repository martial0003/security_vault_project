import 'package:flutter/material.dart';
import '../services/vault_api.dart';
import 'vault_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final controller = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> doLogin() async {
    final pwd = controller.text.trim();
    if (pwd.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Entre un mot de passe")),
      );
      return;
    }

    setState(() => loading = true);
    try {
      final res = await VaultAPI.login(pwd);
      final int vaultId = res['vault_id'];
      final String sessionId = res['session_id'];

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VaultScreen(
            vaultId: vaultId,
            sessionId: sessionId,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur de connexion au moteur")),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              const SizedBox(height: 22),
              Container(
                height: 76,
                width: 76,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C4DFF), Color(0xFF3D5AFE)],
                  ),
                ),
                child: const Icon(Icons.lock_rounded, size: 40),
              ),
              const SizedBox(height: 18),
              const Text(
                "Secure Vault",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              const Text(
                "Ton coffre local chiffré ",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.white70),
              ),
              const Spacer(),
              TextField(
                controller: controller,
                obscureText: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => doLogin(),
                decoration: const InputDecoration(
                  labelText: "Mot de passe maître",
                  prefixIcon: Icon(Icons.key_rounded),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: loading ? null : doLogin,
                  icon: loading
                      ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Icon(Icons.arrow_forward_rounded),
                  label: Text(loading ? "Connexion..." : "Ouvrir le coffre"),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                  "Astuce : vos données restent sous votre contrôle",

                  style: TextStyle(fontSize: 11, color: Colors.white54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
