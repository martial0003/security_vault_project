import 'package:flutter/material.dart';
import '../services/vault_api.dart';
import 'add_entry_screen.dart';
import 'entry_detail_screen.dart';
import 'verify_vault_screen.dart';

class VaultScreen extends StatefulWidget {
  final int vaultId;
  final String sessionId;

  const VaultScreen({
    super.key,
    required this.vaultId,
    required this.sessionId,
  });

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  List<String> entries = [];
  List<String> filtered = [];
  bool loading = true;

  final TextEditingController searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadEntries();

    searchCtrl.addListener(() {
      final q = searchCtrl.text.trim().toLowerCase();
      setState(() {
        filtered = entries
            .where((e) => e.toLowerCase().contains(q))
            .toList(growable: false);
      });
    });
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  // =========================
  // Chargement des entrées
  // =========================
  Future<void> loadEntries() async {
    try {
      final data = await VaultAPI.getEntries(
        vaultId: widget.vaultId,
        sessionId: widget.sessionId,
      );

      if (!mounted) return;

      setState(() {
        entries = data;
        filtered = data;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() => loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Impossible de charger le coffre"),
        ),
      );
    }
  }

  // =========================
  // Navigation ajout
  // =========================
  Future<void> openAdd() async {
    final added = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEntryScreen(
          vaultId: widget.vaultId,
          sessionId: widget.sessionId,
        ),
      ),
    );

    if (added == true) {
      setState(() => loading = true);
      await loadEntries();
    }
  }

  // =========================
  // Icônes services
  // =========================
  IconData serviceIcon(String s) {
    final t = s.toLowerCase();
    if (t.contains("google")) return Icons.g_mobiledata_rounded;
    if (t.contains("amazon")) return Icons.shopping_bag_rounded;
    if (t.contains("facebook")) return Icons.facebook_rounded;
    if (t.contains("instagram")) return Icons.camera_alt_rounded;
    if (t.contains("microsoft")) return Icons.window_rounded;
    if (t.contains("linkedin")) return Icons.work_rounded;
    return Icons.vpn_key_rounded;
  }

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onLongPress: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VerifyVaultScreen(
                  vaultId: widget.vaultId,
                  sessionId: widget.sessionId,
                ),
              ),
            );
          },
          child: const Text("Mon coffre"),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.lock_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Recherche
              TextField(
                controller: searchCtrl,
                decoration: const InputDecoration(
                  hintText: "Rechercher un service...",
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: 14),

              // Contenu
              if (loading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (filtered.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_open_rounded, size: 54),
                        const SizedBox(height: 10),
                        const Text(
                          "Aucun compte pour le moment",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Ajoute ton premier compte pour commencer.",
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton.icon(
                          onPressed: openAdd,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text("Ajouter un compte"),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                    const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final service = filtered[i];
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            backgroundColor:
                            const Color(0xFF1B1B27),
                            child: Icon(serviceIcon(service)),
                          ),
                          title: Text(
                            service,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: const Text(
                            "Tap pour voir les détails",
                            style: TextStyle(color: Colors.white60),
                          ),
                          trailing:
                          const Icon(Icons.chevron_right_rounded),
                          onTap: () async {
                            final changed = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EntryDetailScreen(
                                  vaultId: widget.vaultId,
                                  sessionId: widget.sessionId,
                                  service: service,
                                ),
                              ),
                            );

                            if (changed == true) {
                              setState(() => loading = true);
                              await loadEntries();
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: openAdd,
        icon: const Icon(Icons.add_rounded),
        label: const Text("Ajouter"),
      ),
    );
  }
}
