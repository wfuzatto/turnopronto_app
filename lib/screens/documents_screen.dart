import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key, required this.api});
  final ApiService api;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Documentos',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: api.documents(),
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

          final documents = snapshot.data ?? [];
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            children: [
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: TpColors.blueSoft,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.security_rounded,
                      color: TpColors.blue,
                    ),
                    SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'Documento de identidade e CPF precisam estar verificados antes do primeiro turno. Neste APK de teste, novos uploads continuam sendo feitos pelo portal web.',
                        style: TextStyle(
                          fontSize: 10,
                          color: TpColors.text,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              if (documents.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Nenhum documento encontrado.',
                      style: TextStyle(color: TpColors.muted),
                    ),
                  ),
                ),
              ...documents.map((doc) {
                final status = (doc['status'] ?? 'pending').toString();
                final verified = status == 'verified';
                final rejected = status == 'rejected';
                return Container(
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
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: verified
                              ? TpColors.greenSoft
                              : rejected
                                  ? const Color(0xFFFFECEE)
                                  : TpColors.blueSoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          verified
                              ? Icons.verified_rounded
                              : rejected
                                  ? Icons.error_outline_rounded
                                  : Icons.hourglass_top_rounded,
                          color: verified
                              ? TpColors.green
                              : rejected
                                  ? const Color(0xFFB73340)
                                  : TpColors.blue,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (doc['label'] ?? doc['type'] ?? 'Documento')
                                  .toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              verified
                                  ? 'Verificado'
                                  : rejected
                                      ? 'Rejeitado'
                                      : 'Em análise',
                              style: TextStyle(
                                fontSize: 10,
                                color: verified
                                    ? TpColors.green
                                    : rejected
                                        ? const Color(0xFFB73340)
                                        : TpColors.muted,
                              ),
                            ),
                          ],
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
