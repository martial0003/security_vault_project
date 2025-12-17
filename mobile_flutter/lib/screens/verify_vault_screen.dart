import 'package:flutter/material.dart';
import '../services/vault_api.dart';

class VerifyVaultScreen extends StatefulWidget {
  final int vaultId;
  final String sessionId;

  const VerifyVaultScreen({
    super.key,
    required this.vaultId,
    required this.sessionId,
  });

  @override
  State<VerifyVaultScreen> createState() => _VerifyVaultScreenState();
}

class _VerifyVaultScreenState extends State<VerifyVaultScreen> {
  final ctrl = TextEditingController();
  String result = "";

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Vérifier le coffre")),
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
                      const Text(
                        "Ce menu sert à la démonstration (prof).",
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: ctrl,
                        decoration: const InputDecoration(
                          labelText: "Secret propriétaire",
                          prefixIcon: Icon(Icons.verified_user_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                await VaultAPI.setOwnerSecret(
                                  vaultId: widget.vaultId,
                                  sessionId: widget.sessionId,
                                  ownerSecret: ctrl.text,
                                );
                                setState(() => result = "Secret enregistré ✅");
                              },
                              child: const Text("Définir"),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                final ok = await VaultAPI.verifyVault(
                                  vaultId: widget.vaultId,
                                  sessionId: widget.sessionId,
                                  ownerSecret: ctrl.text,
                                );
                                setState(() {
                                  result = ok ? "✅ COFFRE RÉEL" : "⚠️ COFFRE LEURRE";
                                });
                              },
                              child: const Text("Vérifier"),
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              if (result.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        const Icon(Icons.bolt_rounded),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            result,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
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
