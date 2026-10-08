import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key, required this.api});

  final ApiService api;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: api.earnings(),
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

        final data = snapshot.data ?? <String, dynamic>{};
        final rawSummary = data['summary'];
        final summary = rawSummary is Map
            ? Map<String, dynamic>.from(rawSummary)
            : <String, dynamic>{};
        final total = _money(summary['total']);
        final available = _money(summary['available']);
        final nextPayout = _money(
          summary['next_payout'] ?? summary['available'],
        );

        final rawMonths = data['months'];
        final months = rawMonths is List
            ? rawMonths
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList()
            : <Map<String, dynamic>>[];

        var maxAmount = 1.0;
        for (final month in months) {
          final amount = _money(month['amount']);
          if (amount > maxAmount) maxAmount = amount;
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
          children: [
            const Text(
              'Ganhos',
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Acompanhe valores de turnos, saldo e histórico de repasses.',
              style: TextStyle(
                color: TpColors.muted,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF075FE9), Color(0xFF0B79F4)],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total registrado',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    _formatMoney(total),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _MoneyPill(
                          label: 'Disponível',
                          value: available,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MoneyPill(
                          label: 'Próximo repasse',
                          value: nextPayout,
                        ),
                      ),
                    ],
                  ),
                  if (nextPayout <= 0) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'Nenhum valor pendente para repasse.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: TpColors.line),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Evolução mensal',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (months.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 28),
                      child: Center(
                        child: Text(
                          'Seus ganhos aparecerão aqui após a conclusão do primeiro turno.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: TpColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      height: 180,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: months.map((month) {
                          final amount = _money(month['amount']);
                          final height =
                              130 * (amount / maxAmount).clamp(0.08, 1.0);
                          return Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  _formatMoney(amount),
                                  style: const TextStyle(
                                    fontSize: 8,
                                    color: TpColors.muted,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  height: height,
                                  width: 32,
                                  decoration: const BoxDecoration(
                                    color: TpColors.blue,
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(6),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  (month['month'] ?? '').toString(),
                                  style: const TextStyle(
                                    fontSize: 8,
                                    color: TpColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

double _money(dynamic value) =>
    double.tryParse((value ?? 0).toString()) ?? 0;

String _formatMoney(double value) =>
    'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';

class _MoneyPill extends StatelessWidget {
  const _MoneyPill({
    required this.label,
    required this.value,
  });

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .14),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 9,
              ),
            ),
            Text(
              _formatMoney(value),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
}
