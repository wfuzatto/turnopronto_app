import 'package:flutter/material.dart';

import '../models/job.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_logo.dart';
import '../widgets/job_card.dart';
import '../widgets/metric_card.dart';
import '../widgets/reliability_card.dart';
import 'job_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.api});
  final ApiService api;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final location = LocationService();
  late Future<_HomePayload> future;

  @override
  void initState() {
    super.initState();
    future = _load();
  }

  Future<_HomePayload> _load() async {
    final dashboard = await widget.api.home();
    final jobs = await widget.api.opportunities();
    try {
      final located = await location.enrichJobs(jobs);
      return _HomePayload(
        dashboard: dashboard,
        jobs: located.jobs,
        locationMessage: located.message,
      );
    } catch (e) {
      return _HomePayload(
        dashboard: dashboard,
        jobs: jobs,
        locationMessage: e.toString(),
      );
    }
  }

  Future<void> refresh() async {
    setState(() => future = _load());
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: refresh,
      child: FutureBuilder<_HomePayload>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              children: const [
                Row(
                  children: [
                    BrandLogo(compact: true),
                    Spacer(),
                    CircularProgressIndicator(),
                  ],
                ),
                SizedBox(height: 180),
              ],
            );
          }

          if (snapshot.hasError) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              children: [
                _ErrorCard(
                  message: snapshot.error.toString(),
                  onRetry: refresh,
                ),
              ],
            );
          }

          final payload = snapshot.data!;
          final dashboard = payload.dashboard;
          final rawKpis = dashboard['kpis'];
          final kpis = rawKpis is Map
              ? Map<String, dynamic>.from(rawKpis)
              : <String, dynamic>{};
          final rawProfile = dashboard['profile'];
          final profile = rawProfile is Map
              ? Map<String, dynamic>.from(rawProfile)
              : <String, dynamic>{};

          final name = (widget.api.currentUser?['name'] ?? 'Profissional')
              .toString()
              .trim();
          final firstName =
              name.isEmpty ? 'Profissional' : name.split(RegExp(r'\s+')).first;
          final feedbackCount = int.tryParse(
                (kpis['company_feedback_count'] ?? 0).toString(),
              ) ??
              0;
          final hasFeedback = feedbackCount > 0;
          final reliability = int.tryParse(
            (kpis['reliability'] ?? 0).toString(),
          );
          final monthEarnings = double.tryParse(
                (kpis['earnings'] ?? 0).toString(),
              ) ??
              0;
          final rating = double.tryParse(
                (kpis['rating'] ?? profile['rating'] ?? 0).toString(),
              ) ??
              0;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            children: [
              Row(
                children: [
                  const BrandLogo(compact: true),
                  const Spacer(),
                  const Icon(
                    Icons.notifications_none_rounded,
                    color: TpColors.text,
                  ),
                  const SizedBox(width: 10),
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: TpColors.blueSoft,
                    child: Text(
                      firstName.isEmpty
                          ? 'P'
                          : firstName[0].toUpperCase(),
                      style: const TextStyle(
                        color: TpColors.blue,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 23),
              Text(
                'Olá, ' + firstName + '! 👋',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.7,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Encontre turnos próximos e acompanhe seu histórico real.',
                style: TextStyle(
                  color: TpColors.muted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              ReliabilityCard(
                score: hasFeedback ? reliability : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: MetricCard(
                      icon: Icons.calendar_month_rounded,
                      value: (kpis['week'] ?? 0).toString(),
                      label: 'Turnos esta semana',
                      compact: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: MetricCard(
                      icon: Icons.trending_up_rounded,
                      value: tpMoney(monthEarnings),
                      label: 'Ganhos do mês',
                      accent: TpColors.green,
                      compact: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: MetricCard(
                      icon: Icons.star_rounded,
                      value: hasFeedback
                          ? rating.toStringAsFixed(1).replaceAll('.', ',')
                          : '—',
                      label: 'Avaliação',
                      accent: TpColors.orange,
                      compact: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: TpColors.blueSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      color: TpColors.blue,
                      size: 19,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        payload.locationMessage,
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: TpColors.text,
                          height: 1.4,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: refresh,
                      child: const Text('Atualizar'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Text(
                    'Vagas para você',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    payload.jobs.length.toString() + ' oportunidade(s)',
                    style: const TextStyle(
                      color: TpColors.muted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (payload.jobs.isEmpty)
                const _EmptyCard()
              else
                ...payload.jobs.map(
                  (job) => JobCard(
                    job: job,
                    onDetails: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => JobDetailScreen(
                            api: widget.api,
                            job: job,
                          ),
                        ),
                      );
                      refresh();
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _HomePayload {
  const _HomePayload({
    required this.dashboard,
    required this.jobs,
    required this.locationMessage,
  });

  final Map<String, dynamic> dashboard;
  final List<Job> jobs;
  final String locationMessage;
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: TpColors.line),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.work_outline_rounded,
              color: TpColors.blue,
              size: 34,
            ),
            SizedBox(height: 8),
            Text(
              'Nenhuma oportunidade encontrada agora.',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      );
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: TpColors.line),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: TpColors.muted,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: TpColors.muted,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onRetry,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
}
