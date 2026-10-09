import 'dart:async';

import 'package:flutter/material.dart';

import '../models/job.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_logo.dart';
import '../widgets/job_card.dart';
import 'current_shift_screen.dart';
import 'job_detail_screen.dart';
import 'payment_setup_screen.dart';

/// Tela principal TurnoPronto 2.0, reconstruída a partir do mock aprovado.
/// Os dados da vaga, empresa, foto, endereço, horário e valor são sempre reais.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.api,
    this.showAll = false,
    this.onSeeAll,
  });

  final ApiService api;
  final bool showAll;
  final VoidCallback? onSeeAll;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LocationService location = LocationService();
  final TextEditingController searchController = TextEditingController();
  late Future<List<Job>> future;
  List<Job>? enrichedJobs;
  final Set<int> sending = <int>{};

  @override
  void initState() {
    super.initState();
    future = load();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<List<Job>> load() async {
    final jobs = await widget.api.opportunities();
    // As vagas aparecem imediatamente; a localização é enriquecida depois,
    // sem bloquear a primeira renderização ou depender da permissão GPS.
    unawaited(location.enrichJobs(jobs).then((result) {
      if (mounted) setState(() => enrichedJobs = result.jobs);
    }).catchError((Object _) {}));
    return jobs;
  }

  Future<void> refresh() async {
    setState(() {
      enrichedJobs = null;
      future = load();
    });
    await future;
  }

  Future<void> openDetails(Job job) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => JobDetailScreen(api: widget.api, job: job),
      ),
    );
    if (mounted) await refresh();
  }

  Future<void> interest(Job job) async {
    if (sending.contains(job.id)) return;
    setState(() => sending.add(job.id));
    try {
      // Mesma validação utilizada pelo detalhe da vaga: nunca ignora o
      // onboarding nem confirma automaticamente quem ainda não está apto.
      final onboarding = await widget.api.onboarding();
      if (onboarding['payment_complete'] != true) {
        if (!mounted) return;
        final completed = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => PaymentSetupScreen(api: widget.api),
          ),
        );
        if (completed != true || !mounted) return;
      }
      final result = await widget.api.accept(job.id);
      if (!mounted) return;
      if (result.pendingApproval) {
        await showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Candidatura enviada'),
            content: const Text(
              'A empresa analisará sua candidatura. Você será informado quando o turno for confirmado.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Entendi'),
              ),
            ],
          ),
        );
      } else if (result.assignmentId != null) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => CurrentShiftScreen(
              api: widget.api,
              assignmentId: result.assignmentId!,
              fallbackJob: job,
            ),
          ),
        );
      }
      if (mounted) await refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('ApiException: ', ''))),
      );
    } finally {
      if (mounted) setState(() => sending.remove(job.id));
    }
  }

  void showNotifications() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) => const SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.notifications_none_rounded, size: 40, color: TpColors.blue),
              const SizedBox(height: 12),
              const Text('Notificações', style: TextStyle(
                color: TpColors.navy, fontSize: 22, fontWeight: FontWeight.w900,
              )),
              const SizedBox(height: 8),
              const Text(
                'Acompanhe as confirmações e atualizações dos seus turnos em Meus turnos.',
                textAlign: TextAlign.center,
                style: TextStyle(color: TpColors.muted, fontSize: 14),
              ),
              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userName = (widget.api.currentUser?['name'] ?? '').toString().trim();
    final firstName = userName.isEmpty ? 'você' : userName.split(RegExp(r'\s+')).first;
    return RefreshIndicator(
      onRefresh: refresh,
      color: TpColors.blue,
      child: FutureBuilder<List<Job>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const _HomeLoading();
          }
          if (snapshot.hasError) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(22, 25, 22, 120),
              children: [
                const BrandLogo(compact: true),
                const SizedBox(height: 60),
                const Text(
                  'Não foi possível carregar as vagas agora.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: TpColors.muted, fontSize: 15),
                ),
                const SizedBox(height: 18),
                FilledButton(onPressed: refresh, child: const Text('Tentar novamente')),
              ],
            );
          }
          final jobs = enrichedJobs ?? snapshot.data ?? <Job>[];
          if (widget.showAll) return _allJobsPage(jobs);
          return _homePage(jobs, firstName);
        },
      ),
    );
  }

  Widget _homePage(List<Job> jobs, String firstName) {
    final city = jobs.isNotEmpty
        ? (jobs.first.city + ' - ' + jobs.first.state)
        : (widget.api.currentProfile?['city'] ?? 'Sua região').toString();
    final featured = jobs.take(3).toList();
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF8FCFF), Color(0xFFF0F8FF), Color(0xFFF8FBFF)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: ListView(
        key: const Key('turnopronto-home-feed'),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 106),
        children: [
          _HomeHeader(firstName: firstName, onNotifications: showNotifications),
          const SizedBox(height: 27),
          _HeroArea(city: city),
          const SizedBox(height: 26),
          _SectionHeading(
            title: 'Vagas perto de você',
            icon: Icons.location_on_rounded,
            onViewAll: widget.onSeeAll,
          ),
          const SizedBox(height: 12),
          if (featured.isEmpty)
            const _NoJobs()
          else
            SizedBox(
              height: 258,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: featured.length,
                separatorBuilder: (context, index) => const SizedBox(width: 11),
                itemBuilder: (context, index) {
                  final job = featured[index];
                  return _FeaturedCard(
                    job: job,
                    busy: sending.contains(job.id),
                    onDetails: () => openDetails(job),
                    onInterest: () => interest(job),
                  );
                },
              ),
            ),
          const SizedBox(height: 28),
          _SectionHeading(title: 'Mais vagas', onViewAll: widget.onSeeAll),
          const SizedBox(height: 12),
          if (jobs.isEmpty)
            const _NoJobs()
          else
            ...jobs.map((job) => _CompactCard(
              key: ValueKey('home-job-' + job.id.toString()),
              job: job, onTap: () => openDetails(job),
            )),
        ],
      ),
    );
  }

  Widget _allJobsPage(List<Job> jobs) {
    final filter = searchController.text.trim().toLowerCase();
    final visible = filter.isEmpty
        ? jobs
        : jobs.where((job) {
            final terms = [
              job.role, job.title, job.company, job.city, job.state,
            ].join(' ').toLowerCase();
            return terms.contains(filter);
          }).toList();
    return Container(
      color: const Color(0xFFF7FAFE),
      child: ListView(
        key: const Key('turnopronto-all-jobs'),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 112),
        children: [
          const BrandLogo(compact: true),
          const SizedBox(height: 24),
          const Text(
            'Todas as vagas',
            style: TextStyle(
              fontSize: 30, fontWeight: FontWeight.w900,
              color: TpColors.navy, letterSpacing: -0.9,
            ),
          ),
          const SizedBox(height: 5),
          const Text('Encontre oportunidades perto de você.',
              style: TextStyle(fontSize: 14, color: TpColors.muted)),
          const SizedBox(height: 18),
          TextField(
            key: const Key('search-jobs'),
            controller: searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Buscar função, empresa ou cidade',
              prefixIcon: const Icon(Icons.search_rounded, color: TpColors.blue),
              suffixIcon: filter.isEmpty ? null : IconButton(
                tooltip: 'Limpar busca',
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  searchController.clear();
                  setState(() {});
                },
              ),
            ),
          ),
          const SizedBox(height: 15),
          Text(visible.length.toString() + ' vagas encontradas',
              style: const TextStyle(color: TpColors.muted, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          if (visible.isEmpty)
            const _NoJobs()
          else
            ...visible.map((job) => _CompactCard(
              key: ValueKey('search-job-' + job.id.toString()),
              job: job, onTap: () => openDetails(job),
            )),
        ],
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.firstName, required this.onNotifications});
  final String firstName;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Flexible(child: BrandLogo(compact: true)),
        const SizedBox(width: 7),
        Text('Olá, ' + firstName + '!',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: TpColors.navy, fontSize: 14.5,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 9),
        Semantics(
          label: 'Notificações',
          button: true,
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            elevation: 2,
            shadowColor: const Color(0x140C325C),
            child: InkWell(
              onTap: onNotifications,
              borderRadius: BorderRadius.circular(26),
              child: const SizedBox(
                height: 43, width: 43,
                child: Icon(Icons.notifications_none_rounded,
                    size: 27, color: TpColors.navy),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroArea extends StatelessWidget {
  const _HeroArea({required this.city});
  final String city;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 187,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -72, top: -15,
            child: Container(
              width: 228, height: 228,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0x336EBCFD), Color(0x336AD9CD), Color(0x06FFFFFF),
                  ],
                  stops: [0, .70, 1],
                ),
              ),
            ),
          ),
          Positioned(
            top: 28, right: -28,
            child: Container(
              height: 166, width: 172,
              decoration: const BoxDecoration(
                shape: BoxShape.circle, color: Color(0x187FC5F8),
              ),
            ),
          ),
          Positioned(
            right: 45, top: 30,
            child: Container(
              height: 66, width: 66,
              decoration: const BoxDecoration(
                color: Color(0x286FB8FE), shape: BoxShape.circle,
              ),
              child: const Icon(Icons.location_on_rounded,
                  size: 39, color: Color(0xFF0870F6)),
            ),
          ),
          Positioned(
            right: 8, top: 101,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
              constraints: const BoxConstraints(maxWidth: 168),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [
                  BoxShadow(color: Color(0x160E4F93), blurRadius: 13, offset: Offset(0, 5)),
                ],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.location_on_outlined, color: TpColors.blue, size: 18),
                const SizedBox(width: 5),
                Flexible(child: Text(city, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: TpColors.navy, fontSize: 11, fontWeight: FontWeight.w900))),
              ]),
            ),
          ),
          const Positioned(
            top: 0, left: 0, right: 0,
            child: Text(
              'Vagas de trabalho\nperto de você.',
              maxLines: 2,
              style: TextStyle(
                color: TpColors.navy, fontSize: 31,
                height: 1.07, fontWeight: FontWeight.w900,
                letterSpacing: -1.15,
              ),
            ),
          ),
          const Positioned(
            left: 0, right: 0, bottom: 1,
            child: Text(
              'Turnos flexíveis, pagamentos seguros e\noportunidades em empresas da sua região.',
              maxLines: 2,
              style: TextStyle(
                color: Color(0xFF6A7990), fontSize: 13.5, height: 1.42,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, this.icon, this.onViewAll});
  final String title;
  final IconData? icon;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 26, color: const Color(0xFF1267C4)),
          const SizedBox(width: 8),
        ],
        Expanded(child: Text(title,
          style: const TextStyle(
            color: TpColors.navy, fontSize: 21.5,
            letterSpacing: -0.45, fontWeight: FontWeight.w900,
          ),
        )),
        TextButton(
          onPressed: onViewAll,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            foregroundColor: TpColors.blue,
          ),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Text('Ver todas', style: TextStyle(fontSize: 12.5)),
            Icon(Icons.chevron_right_rounded, size: 19),
          ]),
        ),
      ],
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({
    required this.job, required this.onDetails,
    required this.onInterest, required this.busy,
  });

  final Job job;
  final VoidCallback onDetails;
  final VoidCallback onInterest;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final cardWidth = MediaQuery.sizeOf(context).width - 46;
    final narrow = cardWidth < 350;
    return Container(
      width: cardWidth,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .98),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: const [
          BoxShadow(color: Color(0x200C477B), blurRadius: 24, offset: Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          Expanded(child: InkWell(
            onTap: onDetails,
            borderRadius: BorderRadius.circular(14),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _JobMark(job: job, size: narrow ? 65 : 76),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _RolePill(label: job.role),
                          const SizedBox(height: 8),
                          Text(_title(job), maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: TpColors.navy,
                              fontWeight: FontWeight.w900, fontSize: 18)),
                          const SizedBox(height: 3),
                          Text(job.company, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Color(0xFF647590),
                              fontWeight: FontWeight.w700, fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
                          decoration: BoxDecoration(
                            color: TpColors.greenSoft, borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.bolt_rounded, color: TpColors.green, size: 15),
                            const SizedBox(width: 3),
                            Text(job.distanceKm != null && job.distanceKm! <= 20
                              ? 'Perto de você' : 'Disponível',
                              style: const TextStyle(color: Color(0xFF168E5B),
                                fontWeight: FontWeight.w900, fontSize: 9)),
                          ]),
                        ),
                        const SizedBox(height: 12),
                        Text(tpMoney(job.value), style: TextStyle(
                          color: TpColors.navy,
                          fontSize: narrow ? 19 : 22,
                          fontWeight: FontWeight.w900, letterSpacing: -.55,
                        )),
                        const Text('por turno',
                          style: TextStyle(color: TpColors.muted, fontSize: 10)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                _JobMeta(job: job, compact: false),
              ],
            ),
          )),
          SizedBox(
            width: double.infinity,
            height: 49,
            child: FilledButton(
              key: ValueKey('interest-' + job.id.toString()),
              onPressed: busy ? null : onInterest,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                backgroundColor: TpColors.blue,
                textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
              child: busy
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Tenho interesse'),
                      SizedBox(width: 6),
                      Icon(Icons.chevron_right_rounded, size: 23),
                    ],
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactCard extends StatelessWidget {
  const _CompactCard({super.key, required this.job, required this.onTap});
  final Job job;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shadowColor: const Color(0x1A0C3766),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFEAF0F7))),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  _JobMark(job: job, size: 62),
                  const SizedBox(width: 11),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _RolePill(label: job.role, compact: true),
                      const SizedBox(height: 5),
                      Text(_title(job), maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 15.5,
                          fontWeight: FontWeight.w900, color: TpColors.navy)),
                      const SizedBox(height: 2),
                      Text(job.company, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11.5, color: TpColors.muted)),
                    ],
                  )),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(tpMoney(job.value), style: const TextStyle(
                        fontSize: 17, color: TpColors.navy, fontWeight: FontWeight.w900)),
                      const Text('por turno', style: TextStyle(color: TpColors.muted, fontSize: 9)),
                      const SizedBox(height: 5),
                      Container(width: 34, height: 34,
                        decoration: const BoxDecoration(color: TpColors.blueSoft, shape: BoxShape.circle),
                        child: const Icon(Icons.chevron_right_rounded,
                          color: TpColors.blue, size: 23)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _JobMeta(job: job, compact: true),
            ],
          ),
        ),
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  const _RolePill({required this.label, this.compact = false});
  final String label;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 9, vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F2FF), borderRadius: BorderRadius.circular(13),
      ),
      child: Text(label,
        maxLines: 1, overflow: TextOverflow.ellipsis,
        style: TextStyle(color: TpColors.blue,
          fontSize: compact ? 9.5 : 10.5, fontWeight: FontWeight.w900)),
    );
  }
}

class _JobMeta extends StatelessWidget {
  const _JobMeta({required this.job, required this.compact});
  final Job job;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final date = two(job.startsAt.day) + '/' +
        two(job.startsAt.month) + '/' + job.startsAt.year.toString();
    return Wrap(
      spacing: compact ? 9 : 14,
      runSpacing: 6,
      children: [
        _MetaText(icon: Icons.calendar_month_outlined, text: date, compact: compact),
        _MetaText(icon: Icons.schedule_outlined,
          text: tpTime(job.startsAt) + ' – ' + tpTime(job.endsAt), compact: compact),
        _MetaText(icon: Icons.location_on_outlined,
          text: job.city + ' - ' + job.state, compact: compact),
      ],
    );
  }
}

class _MetaText extends StatelessWidget {
  const _MetaText({required this.icon, required this.text, required this.compact});
  final IconData icon;
  final String text;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: compact ? 15 : 17, color: const Color(0xFF71839C)),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: compact ? 9.5 : 10.5,
          color: const Color(0xFF71839C))),
      ],
    );
  }
}

String _title(Job job) => job.title.trim().isEmpty ? job.role : job.title;

class _JobMark extends StatelessWidget {
  const _JobMark({required this.job, required this.size});
  final Job job;
  final double size;
  @override
  Widget build(BuildContext context) {
    final role = (job.role + ' ' + job.title).toLowerCase();
    final isKitchen = role.contains('cozinha') || role.contains('confeit');
    final isService = role.contains('atend') || role.contains('café');
    final colors = isKitchen
      ? const [Color(0xFF067D70), Color(0xFF005E4D)]
      : isService
        ? const [Color(0xFF8D2039), Color(0xFF5F1029)]
        : const [Color(0xFFFFBB35), Color(0xFFF29A0D)];
    final icon = isKitchen
      ? Icons.restaurant_rounded
      : isService ? Icons.local_cafe_outlined : Icons.room_service_rounded;
    final fallback = Container(
      width: size, height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(size * .22),
      ),
      child: Icon(icon, color: Colors.white, size: size * .43),
    );
    if (job.imageUrl.isEmpty) return fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * .22),
      child: Image.network(job.imageUrl, width: size, height: size,
        fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback),
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
        color: Colors.white, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TpColors.line),
      ),
      child: const Text('Nenhuma vaga disponível agora.',
        textAlign: TextAlign.center,
        style: TextStyle(color: TpColors.muted, fontSize: 14)),
    );
  }
}

class _HomeLoading extends StatelessWidget {
  const _HomeLoading();
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
      children: const [
        BrandLogo(compact: true),
        SizedBox(height: 110),
        Center(child: CircularProgressIndicator(color: TpColors.blue)),
      ],
    );
  }
}
