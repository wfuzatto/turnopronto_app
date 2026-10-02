import 'package:flutter/material.dart';
import '../models/job.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/job_card.dart';
import 'current_shift_screen.dart';

class AssignmentsScreen extends StatefulWidget {
  const AssignmentsScreen({
    super.key,
    required this.api,
  });

  final ApiService api;

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  late Future<List<Assignment>> future;

  @override
  void initState() {
    super.initState();
    future = widget.api.assignments();
  }

  void refresh() {
    setState(() => future = widget.api.assignments());
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => refresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
        children: [
          const Text(
            'Meus turnos',
            style: TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tudo que já foi confirmado aparece aqui.',
            style: TextStyle(
              color: TpColors.muted,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 18),
          FutureBuilder<List<Assignment>>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (snapshot.hasError) {
                return _StateCard(
                  icon: Icons.cloud_off_rounded,
                  title: 'Não foi possível carregar os turnos',
                  message: snapshot.error.toString(),
                  onRetry: refresh,
                );
              }

              final list = snapshot.data ?? [];
              if (list.isEmpty) {
                return const _StateCard(
                  icon: Icons.work_history_outlined,
                  title: 'Nenhum turno confirmado',
                  message:
                      'Aceite uma vaga automática ou aguarde a aprovação de uma candidatura.',
                );
              }

              return Column(
                children: list.map((assignment) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: TpColors.line),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: TpColors.blueSoft,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: const Icon(
                            Icons.work_outline_rounded,
                            color: TpColors.blue,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                assignment.role,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                assignment.company,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: TpColors.muted,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                two(assignment.startsAt.day) +
                                    '/' +
                                    two(assignment.startsAt.month) +
                                    ' · ' +
                                    tpTime(assignment.startsAt) +
                                    ' – ' +
                                    tpTime(assignment.endsAt) +
                                    ' · ' +
                                    tpMoney(assignment.value),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        FilledButton(
                          onPressed: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => CurrentShiftScreen(
                                  api: widget.api,
                                  assignmentId: assignment.id,
                                ),
                              ),
                            );
                            refresh();
                          },
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(72, 36),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                            ),
                          ),
                          child: const Text(
                            'Abrir',
                            style: TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.icon,
    required this.title,
    required this.message,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: TpColors.line),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: TpColors.blue, size: 34),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: TpColors.muted,
                fontSize: 10,
                height: 1.4,
              ),
            ),
            if (onRetry != null)
              TextButton(
                onPressed: onRetry,
                child: const Text('Tentar novamente'),
              ),
          ],
        ),
      );
}
