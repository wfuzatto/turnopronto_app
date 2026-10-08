import 'package:flutter/material.dart';

import '../models/job.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_logo.dart';
import '../widgets/job_card.dart';
import 'home_classic_screen.dart';
import 'job_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.api});
  final ApiService api;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<String> skin;

  @override
  void initState() {
    super.initState();
    skin = _loadSkin();
  }

  Future<String> _loadSkin() async {
    try {
      final data = await widget.api.appearance();
      return (data['app_skin'] ?? 'modern').toString();
    } catch (_) {
      return 'modern';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: skin,
      builder: (context, snapshot) {
        final value = snapshot.data ?? 'modern';
        if (value == 'classic') {
          return ClassicHomeScreen(api: widget.api);
        }
        return _ModernHome(api: widget.api, minimal: value == 'minimal');
      },
    );
  }
}

class _ModernHome extends StatefulWidget {
  const _ModernHome({required this.api, this.minimal = false});
  final ApiService api;
  final bool minimal;

  @override
  State<_ModernHome> createState() => _ModernHomeState();
}

class _ModernHomeState extends State<_ModernHome> {
  final LocationService location = LocationService();
  late Future<_ModernPayload> future;

  @override
  void initState() {
    super.initState();
    future = _load();
  }

  Future<_ModernPayload> _load() async {
    final jobs = await widget.api.opportunities();
    List<Job> resolved = jobs;
    try {
      resolved = (await location.enrichJobs(jobs)).jobs;
    } catch (_) {}
    return _ModernPayload(jobs: resolved);
  }

  Future<void> refresh() async {
    setState(() => future = _load());
    await future;
  }

  Future<void> openDetails(Job job) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => JobDetailScreen(api: widget.api, job: job),
      ),
    );
    if (mounted) refresh();
  }

  Future<void> interest(Job job) async {
    try {
      final result = await widget.api.accept(job.id);
      if (!mounted) return;
      final message = result.confirmed
          ? 'Turno confirmado com sucesso.'
          : 'Seu interesse foi enviado para a empresa.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('ApiException: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentName =
        (widget.api.currentUser?['name'] ?? 'Profissional').toString().trim();
    final firstName =
        currentName.isEmpty ? 'Profissional' : currentName.split(RegExp(r'\s+')).first;

    return RefreshIndicator(
      onRefresh: refresh,
      child: FutureBuilder<_ModernPayload>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const _ModernLoading();
          }
          if (snapshot.hasError) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
              children: [
                const BrandLogo(compact: true),
                const SizedBox(height: 80),
                Center(
                  child: FilledButton(
                    onPressed: refresh,
                    child: const Text('Tentar novamente'),
                  ),
                ),
              ],
            );
          }

          final jobs = snapshot.data?.jobs ?? <Job>[];
          final featured = jobs.take(3).toList();
          final city = jobs.isNotEmpty
              ? '${jobs.first.city} - ${jobs.first.state}'
              : ((widget.api.currentProfile?['city'] ?? 'Perto de você').toString());

          return Stack(
            children: [
              Positioned(
                top: 84,
                right: -105,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Color(0x3346D7FF),
                        Color(0x223CCCA4),
                        Color(0x00FFFFFF),
                      ],
                    ),
                  ),
                ),
              ),
              ListView(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 112),
                children: [
                  Row(
                    children: [
                      const BrandLogo(compact: true),
                      const Spacer(),
                      Text(
                        'Olá, $firstName!',
                        style: const TextStyle(
                          color: TpColors.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .94),
                              shape: BoxShape.circle,
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x150D2B55),
                                  blurRadius: 18,
                                  offset: Offset(0, 7),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.notifications_none_rounded,
                              color: TpColors.navy,
                              size: 26,
                            ),
                          ),
                          Positioned(
                            top: 3,
                            right: 2,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF414D),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 33),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.minimal
                              ? 'Oportunidades que\ncabem na sua rotina.'
                              : 'Vagas de trabalho\nperto de você.',
                          style: const TextStyle(
                            color: TpColors.navy,
                            fontSize: 34,
                            height: 1.04,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.1,
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 5),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .92),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x110B315E),
                              blurRadius: 16,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              color: TpColors.blue,
                              size: 18,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              city,
                              style: const TextStyle(
                                color: TpColors.navy,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 11),
                  const Text(
                    'Turnos flexíveis, pagamentos seguros e\noportunidades em empresas da sua região.',
                    style: TextStyle(
                      color: Color(0xFF6A7990),
                      fontSize: 14,
                      height: 1.42,
                    ),
                  ),
                  const SizedBox(height: 31),
                  _SectionTitle(
                    icon: Icons.location_on_rounded,
                    title: 'Vagas perto de você',
                    onTap: () {},
                  ),
                  const SizedBox(height: 13),
                  if (featured.isEmpty)
                    const _NoJobs()
                  else
                    SizedBox(
                      height: 305,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        itemCount: featured.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final job = featured[index];
                          return _FeaturedJobCard(
                            job: job,
                            onDetails: () => openDetails(job),
                            onInterest: () => interest(job),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 30),
                  _SectionTitle(
                    title: 'Mais vagas',
                    onTap: () {},
                  ),
                  const SizedBox(height: 13),
                  if (jobs.isEmpty)
                    const _NoJobs()
                  else
                    ...jobs.map(
                      (job) => _CompactJobCard(
                        job: job,
                        onTap: () => openDetails(job),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.onTap,
    this.icon,
  });

  final String title;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: const Color(0xFF0D58B2), size: 25),
          const SizedBox(width: 9),
        ],
        Text(
          title,
          style: const TextStyle(
            color: TpColors.navy,
            fontSize: 21,
            fontWeight: FontWeight.w900,
            letterSpacing: -.4,
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: onTap,
          child: const Row(
            children: [
              Text('Ver todas'),
              SizedBox(width: 3),
              Icon(Icons.chevron_right_rounded, size: 19),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeaturedJobCard extends StatelessWidget {
  const _FeaturedJobCard({
    required this.job,
    required this.onDetails,
    required this.onInterest,
  });

  final Job job;
  final VoidCallback onDetails;
  final VoidCallback onInterest;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDetails,
      child: Container(
        width: MediaQuery.sizeOf(context).width - 55,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .95),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white, width: 1.4),
          boxShadow: const [
            BoxShadow(
              color: Color(0x160A356B),
              blurRadius: 28,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _JobMark(job: job, size: 90),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: TpColors.blueSoft,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Text(
                          job.role,
                          style: const TextStyle(
                            color: TpColors.blue,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        job.title.trim().isEmpty ? job.role : job.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: TpColors.navy,
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        job.company,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF66778F),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: TpColors.greenSoft,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.bolt_rounded,
                            color: TpColors.green,
                            size: 17,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Perto de você',
                            style: TextStyle(
                              color: Color(0xFF168E5B),
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      tpMoney(job.value),
                      style: const TextStyle(
                        color: TpColors.navy,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text(
                      'por turno',
                      style: TextStyle(
                        color: TpColors.muted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 19),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _Meta(
                  icon: Icons.calendar_month_outlined,
                  text:
                      '${two(job.startsAt.day)}/${two(job.startsAt.month)}/${job.startsAt.year}',
                ),
                _Meta(
                  icon: Icons.schedule_rounded,
                  text: '${tpTime(job.startsAt)} – ${tpTime(job.endsAt)}',
                ),
                _Meta(
                  icon: Icons.location_on_outlined,
                  text: '${job.city} - ${job.state}',
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: onInterest,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Tenho interesse'),
                    SizedBox(width: 5),
                    Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactJobCard extends StatelessWidget {
  const _CompactJobCard({required this.job, required this.onTap});
  final Job job;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .96),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x100B315E),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _JobMark(job: job, size: 72),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: TpColors.blueSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    job.role,
                    style: const TextStyle(
                      color: TpColors.blue,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  job.role,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: TpColors.navy,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  job.company,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF677A94),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 11,
                  runSpacing: 5,
                  children: [
                    _Meta(
                      icon: Icons.calendar_month_outlined,
                      text:
                          '${two(job.startsAt.day)}/${two(job.startsAt.month)}/${job.startsAt.year}',
                      compact: true,
                    ),
                    _Meta(
                      icon: Icons.schedule_rounded,
                      text: '${tpTime(job.startsAt)} – ${tpTime(job.endsAt)}',
                      compact: true,
                    ),
                    _Meta(
                      icon: Icons.location_on_outlined,
                      text: '${job.city} - ${job.state}',
                      compact: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                tpMoney(job.value),
                style: const TextStyle(
                  color: TpColors.navy,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Text(
                'por turno',
                style: TextStyle(color: TpColors.muted, fontSize: 9),
              ),
              const SizedBox(height: 9),
              InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: TpColors.blueSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: TpColors.blue,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _JobMark extends StatelessWidget {
  const _JobMark({required this.job, required this.size});
  final Job job;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isKitchen = job.role.toLowerCase().contains('cozinha') ||
        job.role.toLowerCase().contains('confeit');
    final isService = job.role.toLowerCase().contains('atend');
    final colors = isKitchen
        ? const [Color(0xFF087767), Color(0xFF005646)]
        : (isService
            ? const [Color(0xFF8E1937), Color(0xFF5F1027)]
            : const [Color(0xFFFFBC38), Color(0xFFF49B10)]);
    final radius=BorderRadius.circular(size * .22);
    if(job.imageUrl.isNotEmpty){
      return ClipRRect(
        borderRadius: radius,
        child: Image.network(
          job.imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _JobMarkFallback(
            size: size,
            radius: radius,
            colors: colors,
            icon: isKitchen
                ? Icons.local_florist_outlined
                : (isService ? Icons.local_cafe_outlined : Icons.restaurant_menu),
          ),
        ),
      );
    }
    return _JobMarkFallback(
      size: size,
      radius: radius,
      colors: colors,
      icon: isKitchen
          ? Icons.local_florist_outlined
          : (isService ? Icons.local_cafe_outlined : Icons.restaurant_menu),
    );
  }
}

class _JobMarkFallback extends StatelessWidget {
  const _JobMarkFallback({
    required this.size,
    required this.radius,
    required this.colors,
    required this.icon,
  });

  final double size;
  final BorderRadius radius;
  final List<Color> colors;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: radius,
      ),
      child: Icon(icon, color: Colors.white, size: size * .38),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({
    required this.icon,
    required this.text,
    this.compact = false,
  });

  final IconData icon;
  final String text;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: const Color(0xFF71839C),
          size: compact ? 14 : 18,
        ),
        SizedBox(width: compact ? 4 : 6),
        Text(
          text,
          style: TextStyle(
            color: const Color(0xFF71839C),
            fontSize: compact ? 9 : 11,
          ),
        ),
      ],
    );
  }
}

class _ModernLoading extends StatelessWidget {
  const _ModernLoading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 112),
      children: const [
        BrandLogo(compact: true),
        SizedBox(height: 120),
        Center(child: CircularProgressIndicator()),
      ],
    );
  }
}

class _NoJobs extends StatelessWidget {
  const _NoJobs();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Text(
        'Nenhuma vaga disponível agora.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: TpColors.muted,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ModernPayload {
  const _ModernPayload({required this.jobs});
  final List<Job> jobs;
}
