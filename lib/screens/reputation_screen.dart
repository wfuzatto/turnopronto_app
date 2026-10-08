import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ReputationScreen extends StatelessWidget {
  const ReputationScreen({super.key, required this.api});
  final ApiService api;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reputação',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: api.reputation(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(snapshot.error.toString()),
              ),
            );
          }

          final data = snapshot.data ?? {};
          final rawProfile = data['profile'];
          final profile = rawProfile is Map
              ? Map<String, dynamic>.from(rawProfile)
              : <String, dynamic>{};
          final rawEvents = data['events'];
          final events = rawEvents is List
              ? rawEvents
                  .map((e) => Map<String, dynamic>.from(e as Map))
                  .toList()
              : <Map<String, dynamic>>[];

          final feedbackCount = int.tryParse((profile['company_feedback_count'] ?? 0).toString()) ?? 0;
          final hasFeedback = profile['has_company_feedback'] == true || feedbackCount > 0;
          final reliability = _num(profile['reliability_score'], 0);
          final attendance = _num(profile['attendance_score'], 0);
          final punctuality = _num(profile['punctuality_score'], 0);
          final rating = _num(profile['rating'], 0);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: TpColors.line),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 104,
                      height: 104,
                      decoration: const BoxDecoration(
                        color: TpColors.greenSoft,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        hasFeedback ? reliability.round().toString() + '%' : '—',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: TpColors.green,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Confiabilidade',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      hasFeedback
                          ? feedbackCount.toString() + ' retorno(s) de empresa'
                          : 'A pontuação será calculada somente após o primeiro turno concluído receber o retorno da empresa.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: TpColors.muted,
                        fontSize: 10,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 15),
                    if (hasFeedback) ...[
                      _Progress(
                        label: 'Presença',
                        value: attendance,
                      ),
                      _Progress(
                        label: 'Pontualidade',
                        value: punctuality,
                      ),
                      _Progress(
                        label: 'Avaliação',
                        value: rating * 20,
                        suffix: rating.toStringAsFixed(1) + ' / 5',
                      ),
                    ] else ...[
                      const _PendingMetric(label: 'Presença'),
                      const _PendingMetric(label: 'Pontualidade'),
                      const _PendingMetric(label: 'Avaliação'),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Eventos recentes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              if (events.isEmpty)
                const Text(
                  'Nenhuma ocorrência registrada.',
                  style: TextStyle(color: TpColors.muted),
                ),
              ...events.map((event) {
                final delta = _num(event['points_delta'], 0);
                final positive = delta >= 0;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: TpColors.line),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor:
                            positive ? TpColors.greenSoft : const Color(0xFFFFECEE),
                        child: Icon(
                          positive
                              ? Icons.check_rounded
                              : Icons.priority_high_rounded,
                          color: positive
                              ? TpColors.green
                              : const Color(0xFFB73340),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          (event['description'] ?? 'Evento').toString(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        (delta > 0 ? '+' : '') + delta.toStringAsFixed(0),
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: positive
                              ? TpColors.green
                              : const Color(0xFFB73340),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

double _num(dynamic value, double fallback) =>
    double.tryParse((value ?? fallback).toString()) ?? fallback;

class _Progress extends StatelessWidget {
  const _Progress({
    required this.label,
    required this.value,
    this.suffix,
  });

  final String label;
  final double value;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    final normalized = value.clamp(0, 100).toDouble();
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: TpColors.muted,
                ),
              ),
              const Spacer(),
              Text(
                suffix ?? normalized.round().toString() + '%',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: normalized / 100,
              minHeight: 7,
              backgroundColor: TpColors.line,
              color: TpColors.green,
            ),
          ),
        ],
      ),
    );
  }
}


class _PendingMetric extends StatelessWidget {
  const _PendingMetric({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 11),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: TpColors.muted,
                  ),
                ),
                const Spacer(),
                const Text(
                  '—',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: const LinearProgressIndicator(
                value: 0,
                minHeight: 7,
                backgroundColor: TpColors.line,
                color: TpColors.line,
              ),
            ),
          ],
        ),
      );
}
