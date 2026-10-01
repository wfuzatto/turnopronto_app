import 'package:flutter/material.dart';
import '../models/job.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/job_card.dart';
import 'current_shift_screen.dart';

class AssignmentsScreen extends StatefulWidget {
  const AssignmentsScreen({super.key, required this.api});
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

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      children: [
        const Text('Meus turnos', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        const Text(
          'Tudo que você já confirmou aparece aqui.',
          style: TextStyle(color: TpColors.muted, fontSize: 11),
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

            final list = snapshot.data ?? ApiService.demoAssignments();
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
                        child: const Icon(Icons.work_outline_rounded, color: TpColors.blue),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(assignment.role, style: const TextStyle(fontWeight: FontWeight.w900)),
                            Text(
                              assignment.company,
                              style: const TextStyle(fontSize: 10, color: TpColors.muted),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '${two(assignment.startsAt.day)}/${two(assignment.startsAt.month)} · '
                              '${tpTime(assignment.startsAt)} – ${tpTime(assignment.endsAt)} · '
                              '${tpMoney(assignment.value)}',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      FilledButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CurrentShiftScreen(
                                api: widget.api,
                                assignmentId: assignment.id,
                              ),
                            ),
                          );
                        },
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(72, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        child: const Text('Abrir', style: TextStyle(fontSize: 10)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
