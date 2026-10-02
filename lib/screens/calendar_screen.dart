import 'package:flutter/material.dart';
import '../models/job.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/job_card.dart';
import 'current_shift_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key, required this.api});
  final ApiService api;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
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
            'Agenda',
            style: TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Seus próximos turnos confirmados.',
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
                return _MessageCard(
                  icon: Icons.cloud_off_rounded,
                  title: 'Não foi possível carregar a agenda',
                  message: snapshot.error.toString(),
                  action: TextButton(
                    onPressed: refresh,
                    child: const Text('Tentar novamente'),
                  ),
                );
              }

              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return const _MessageCard(
                  icon: Icons.event_available_rounded,
                  title: 'Agenda livre',
                  message:
                      'Quando um turno for confirmado, ele aparecerá aqui.',
                );
              }

              return Column(
                children: items.map((assignment) {
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
                          width: 52,
                          height: 58,
                          decoration: BoxDecoration(
                            color: TpColors.blueSoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                two(assignment.startsAt.day),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: TpColors.blue,
                                ),
                              ),
                              Text(
                                two(assignment.startsAt.month),
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: TpColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 11),
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
                        IconButton(
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
                          icon: const Icon(
                            Icons.chevron_right_rounded,
                            color: TpColors.blue,
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

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: TpColors.line),
        borderRadius: BorderRadius.circular(16),
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
          if (action != null) action!,
        ],
      ),
    );
  }
}
