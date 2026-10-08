import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ReliabilityCard extends StatelessWidget {
  const ReliabilityCard({super.key, this.score});
  final int? score;

  @override
  Widget build(BuildContext context) {
    final hasScore = score != null;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: TpColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: hasScore ? TpColors.greenSoft : TpColors.blueSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasScore
                  ? Icons.verified_user_rounded
                  : Icons.hourglass_top_rounded,
              color: hasScore ? TpColors.green : TpColors.blue,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Confiabilidade',
                style: TextStyle(
                  fontSize: 10,
                  color: TpColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                hasScore ? score.toString() + '%' : '—',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: 150,
            child: Text(
              hasScore
                  ? 'Pontuação baseada nos retornos reais das empresas.'
                  : 'Será calculada após o primeiro retorno de uma empresa.',
              style: const TextStyle(
                fontSize: 10,
                color: TpColors.muted,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
