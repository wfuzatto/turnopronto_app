import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'documents_screen.dart';
import 'reputation_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.api,
    required this.onLogout,
  });

  final ApiService api;
  final Future<void> Function() onLogout;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>> future;

  @override
  void initState() {
    super.initState();
    future = widget.api.me();
  }

  void refresh() {
    setState(() => future = widget.api.me());
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => refresh(),
      child: FutureBuilder<Map<String, dynamic>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return ListView(
              children: const [
                SizedBox(height: 220),
                Center(child: CircularProgressIndicator()),
              ],
            );
          }

          if (snapshot.hasError) {
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 80),
                const Icon(
                  Icons.cloud_off_rounded,
                  size: 44,
                  color: TpColors.muted,
                ),
                const SizedBox(height: 12),
                Text(
                  snapshot.error.toString(),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: refresh,
                  child: const Text('Tentar novamente'),
                ),
              ],
            );
          }

          final data = snapshot.data ?? {};
          final rawUser = data['user'];
          final rawProfile = data['profile'];
          final user = rawUser is Map
              ? Map<String, dynamic>.from(rawUser)
              : <String, dynamic>{};
          final profile = rawProfile is Map
              ? Map<String, dynamic>.from(rawProfile)
              : <String, dynamic>{};

          final name = (user['name'] ?? 'Profissional').toString();
          final headline =
              (profile['headline'] ?? 'Profissional TurnoPronto').toString();
          final reliability = _number(
            profile['reliability_score'],
            100,
          ).round();
          final attendance = _number(
            profile['attendance_score'],
            100,
          ).round();
          final punctuality = _number(
            profile['punctuality_score'],
            100,
          ).round();
          final completed = int.tryParse(
                (profile['completed_shifts'] ?? 0).toString(),
              ) ??
              0;
          final status = (profile['status'] ?? 'pending').toString();
          final initial =
              name.trim().isEmpty ? 'P' : name.trim()[0].toUpperCase();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
            children: [
              const Text(
                'Perfil',
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: TpColors.line),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: TpColors.blueSoft,
                      child: Text(
                        initial,
                        style: const TextStyle(
                          fontSize: 30,
                          color: TpColors.blue,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      headline,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: TpColors.muted,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _StatusPill(
                      status: status,
                      reliability: reliability,
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _Score(
                            label: 'Presença',
                            value: attendance.toString() + '%',
                            icon: Icons.groups_rounded,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _Score(
                            label: 'Pontualidade',
                            value: punctuality.toString() + '%',
                            icon: Icons.schedule_rounded,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 13),
              _Menu(
                icon: Icons.badge_outlined,
                title: 'Documentos',
                subtitle: 'Acompanhar status de verificação',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DocumentsScreen(
                        api: widget.api,
                      ),
                    ),
                  );
                },
              ),
              _Menu(
                icon: Icons.star_outline_rounded,
                title: 'Reputação',
                subtitle: completed.toString() + ' turnos concluídos',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ReputationScreen(
                        api: widget.api,
                      ),
                    ),
                  );
                },
              ),
              _Menu(
                icon: Icons.dns_outlined,
                title: 'Servidor conectado',
                subtitle: widget.api.demoMode
                    ? 'Modo demonstração'
                    : widget.api.baseUrl,
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Sair da conta?'),
                      content: const Text(
                        'A sessão deste aplicativo será encerrada.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.pop(context, false),
                          child: const Text('Cancelar'),
                        ),
                        FilledButton(
                          onPressed: () =>
                              Navigator.pop(context, true),
                          child: const Text('Sair'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await widget.onLogout();
                  }
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Sair da conta'),
              ),
              const SizedBox(height: 12),
              const Text(
                'TurnoPronto • APK de teste',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: TpColors.muted,
                  fontSize: 9,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

double _number(dynamic value, double fallback) =>
    double.tryParse((value ?? fallback).toString()) ?? fallback;

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.status,
    required this.reliability,
  });

  final String status;
  final int reliability;

  @override
  Widget build(BuildContext context) {
    final verified = status == 'verified';
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: verified
            ? TpColors.greenSoft
            : const Color(0xFFFFF5D9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            verified
                ? Icons.verified_user_rounded
                : Icons.hourglass_top_rounded,
            color: verified
                ? TpColors.green
                : const Color(0xFFA06B00),
            size: 18,
          ),
          const SizedBox(width: 5),
          Text(
            verified
                ? 'Confiabilidade ' + reliability.toString() + '%'
                : 'Perfil em verificação',
            style: TextStyle(
              color: verified
                  ? const Color(0xFF0A8D50)
                  : const Color(0xFFA06B00),
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _Score extends StatelessWidget {
  const _Score({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: TpColors.line),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: TpColors.blue),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                color: TpColors.muted,
              ),
            ),
          ],
        ),
      );
}

class _Menu extends StatelessWidget {
  const _Menu({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          margin: const EdgeInsets.only(bottom: 9),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: TpColors.line),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: TpColors.blueSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: TpColors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: TpColors.muted,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: TpColors.muted,
                ),
            ],
          ),
        ),
      );
}
