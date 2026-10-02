import 'package:flutter/material.dart';
import '../models/job.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/job_card.dart';

class CurrentShiftScreen extends StatefulWidget {
  const CurrentShiftScreen({super.key, required this.api, required this.assignmentId, this.fallbackJob});
  final ApiService api;
  final int assignmentId;
  final Job? fallbackJob;

  @override
  State<CurrentShiftScreen> createState() => _CurrentShiftScreenState();
}

class _CurrentShiftScreenState extends State<CurrentShiftScreen> {
  Assignment? assignment;
  bool loading = true;
  bool processing = false;
  String status = 'confirmed';

  @override
  void initState() { super.initState(); load(); }

  Future<void> load() async {
    try { assignment = await widget.api.assignment(widget.assignmentId); status = assignment!.status; }
    catch (_) { final j = widget.fallbackJob ?? ApiService.demoJobs().first; assignment = Assignment(id: widget.assignmentId, shiftId: j.id, role: j.role, company: j.company, startsAt: j.startsAt, endsAt: j.endsAt, value: j.value, status: 'confirmed', address: j.address, city: j.city, state: j.state); }
    finally { if (mounted) setState(() => loading = false); }
  }

  Future<void> checkIn(String pin) async {
    setState(() => processing = true);
    try {
      await widget.api.checkIn(widget.assignmentId, pin: pin);
      if (mounted) setState(() => status = 'checked_in');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => processing = false);
    }
  }
  Future<void> checkOut() async { setState(() => processing = true); try { await widget.api.checkOut(widget.assignmentId); setState(() => status = 'completed'); } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); } finally { if (mounted) setState(() => processing = false); } }

  @override
  Widget build(BuildContext context) {
    if (loading || assignment == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final a = assignment!;
    return Scaffold(appBar: AppBar(title: const Text('Turno atual', style: TextStyle(fontWeight: FontWeight.w900)), actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.headset_mic_outlined))]), body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 90), children: [
      Container(padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: TpColors.line), borderRadius: BorderRadius.circular(14)), child: Column(children: [
        Row(children: [Container(width: 54,height:54,decoration:BoxDecoration(borderRadius:BorderRadius.circular(11),gradient:const LinearGradient(colors:[Color(0xFF4F3A28),Color(0xFFC99D6B)])),child:const Icon(Icons.room_service_rounded,color:Colors.white)),const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(a.company,style:const TextStyle(fontWeight:FontWeight.w900,fontSize:15)),Text(a.role,style:const TextStyle(color:TpColors.muted,fontSize:11))])),Container(padding:const EdgeInsets.symmetric(horizontal:8,vertical:6),decoration:BoxDecoration(color:TpColors.greenSoft,borderRadius:BorderRadius.circular(20)),child:Text(status=='completed'?'Concluído':'Em andamento',style:const TextStyle(color:Color(0xFF0A8D50),fontSize:9,fontWeight:FontWeight.w800)))]),
        const SizedBox(height:14),Row(children:[Expanded(child:_TopInfo(icon:Icons.calendar_month_rounded,text:'${two(a.startsAt.day)}/${two(a.startsAt.month)}/${a.startsAt.year}',caption:'Hoje')),Expanded(child:_TopInfo(icon:Icons.schedule_rounded,text:'${tpTime(a.startsAt)} – ${tpTime(a.endsAt)}',caption:'8 horas')),Expanded(child:_TopInfo(icon:Icons.location_on_outlined,text:'${a.city} - ${a.state}',caption:'2,1 km'))])
      ])),
      const SizedBox(height:18),_Progress(status:status),const SizedBox(height:16),
      if(status=='confirmed') _CheckInCard(onCheckIn:checkIn,processing:processing) else if(status=='checked_in') _WorkingCard(onCheckOut:checkOut,processing:processing) else _CompletedCard(value:a.value),
      const SizedBox(height:12),Container(padding:const EdgeInsets.all(13),decoration:BoxDecoration(color:Colors.white,border:Border.all(color:TpColors.line),borderRadius:BorderRadius.circular(14)),child:const Row(children:[Icon(Icons.security_rounded,color:TpColors.blue),SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Validação atual: PIN do turno',style:TextStyle(fontWeight:FontWeight.w800,fontSize:11)),SizedBox(height:2),Text('A confirmação de GPS/QR ainda não é usada como prova neste APK de teste.',style:TextStyle(color:TpColors.muted,fontSize:10))]))])),
      const SizedBox(height:12),Row(children:[Expanded(child:Container(padding:const EdgeInsets.all(13),decoration:BoxDecoration(color:Colors.white,border:Border.all(color:TpColors.line),borderRadius:BorderRadius.circular(14)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Row(children:[Icon(Icons.account_balance_wallet_outlined,color:TpColors.green,size:18),SizedBox(width:5),Text('Ganhos deste turno',style:TextStyle(fontSize:9,fontWeight:FontWeight.w700))]),const SizedBox(height:5),Text(tpMoney(a.value),style:const TextStyle(fontSize:19,fontWeight:FontWeight.w900))]))),const SizedBox(width:8),Expanded(child:Container(padding:const EdgeInsets.all(13),decoration:BoxDecoration(color:Colors.white,border:Border.all(color:TpColors.line),borderRadius:BorderRadius.circular(14)),child:const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Icon(Icons.calendar_month_rounded,color:TpColors.blue,size:18),SizedBox(width:5),Text('Próximo repasse',style:TextStyle(fontSize:9,fontWeight:FontWeight.w700))]),SizedBox(height:5),Text('28 abr 2026',style:TextStyle(fontSize:15,fontWeight:FontWeight.w900)),Text('via Pix',style:TextStyle(fontSize:9,color:TpColors.muted))])))]),
    ]));
  }
}
class _TopInfo extends StatelessWidget { const _TopInfo({required this.icon,required this.text,required this.caption}); final IconData icon;final String text,caption;@override Widget build(BuildContext context)=>Column(children:[Icon(icon,color:TpColors.blue,size:18),const SizedBox(height:3),Text(text,textAlign:TextAlign.center,style:const TextStyle(fontSize:9,fontWeight:FontWeight.w800)),Text(caption,style:const TextStyle(fontSize:8,color:TpColors.muted))]);}
class _Progress extends StatelessWidget { const _Progress({required this.status});final String status;@override Widget build(BuildContext context){final current=status=='completed'?4:status=='checked_in'?3:2;final labels=['Confirmado','Check-in','Em andamento','Concluído'];return Row(children:List.generate(4,(i)=>Expanded(child:Column(children:[Row(children:[if(i>0)Expanded(child:Container(height:3,color:i<current?TpColors.green:TpColors.line)),Container(width:30,height:30,decoration:BoxDecoration(shape:BoxShape.circle,color:i<current?TpColors.green:const Color(0xFFE7EDF5)),child:Icon(i<current?Icons.check_rounded:Icons.circle,size:i<current?18:8,color:i<current?Colors.white:const Color(0xFFB0BDCC))),if(i<3)Expanded(child:Container(height:3,color:i+1<current?TpColors.green:TpColors.line))]),const SizedBox(height:5),Text(labels[i],textAlign:TextAlign.center,style:TextStyle(fontSize:8.5,color:i<current?const Color(0xFF0A8D50):TpColors.muted,fontWeight:i<current?FontWeight.w700:FontWeight.normal))]))));}}
class _CheckInCard extends StatefulWidget {
  const _CheckInCard({
    required this.onCheckIn,
    required this.processing,
  });

  final Future<void> Function(String pin) onCheckIn;
  final bool processing;

  @override
  State<_CheckInCard> createState() => _CheckInCardState();
}

class _CheckInCardState extends State<_CheckInCard> {
  final pin = TextEditingController();

  @override
  void dispose() {
    pin.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final value = pin.text.trim();
    if (value.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe o PIN de 6 dígitos da empresa.'),
        ),
      );
      return;
    }
    await widget.onCheckIn(value);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FCF5),
        border: Border.all(color: const Color(0xFFD5F2E2)),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: Color(0xFFCFF2DE),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.pin_rounded,
              color: TpColors.green,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Faça seu check-in',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Solicite o PIN de 6 dígitos no local. GPS e QR assinado entram na próxima etapa do app.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: TpColors.muted,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: pin,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 10,
            ),
            decoration: const InputDecoration(
              counterText: '',
              labelText: 'PIN da empresa',
              hintText: '••••••',
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: widget.processing ? null : submit,
              child: Text(
                widget.processing
                    ? 'Confirmando...'
                    : 'Confirmar check-in',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkingCard extends StatelessWidget { const _WorkingCard({required this.onCheckOut,required this.processing});final VoidCallback onCheckOut;final bool processing;@override Widget build(BuildContext context)=>Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(color:TpColors.blueSoft,borderRadius:BorderRadius.circular(17)),child:Column(children:[const Icon(Icons.schedule_rounded,color:TpColors.blue,size:42),const SizedBox(height:8),const Text('Turno em andamento',style:TextStyle(fontSize:18,fontWeight:FontWeight.w900)),const SizedBox(height:4),const Text('Seu check-in já foi registrado. Ao terminar, faça o check-out.',textAlign:TextAlign.center,style:TextStyle(fontSize:10,color:TpColors.muted)),const SizedBox(height:14),SizedBox(width:double.infinity,child:FilledButton(onPressed:processing?null:onCheckOut,child:Text(processing?'Encerrando...':'Encerrar turno / check-out')))]));}
class _CompletedCard extends StatelessWidget { const _CompletedCard({required this.value});final double value;@override Widget build(BuildContext context)=>Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(color:TpColors.greenSoft,borderRadius:BorderRadius.circular(17)),child:Column(children:[const Icon(Icons.check_circle_rounded,color:TpColors.green,size:48),const SizedBox(height:8),const Text('Turno concluído',style:TextStyle(fontSize:18,fontWeight:FontWeight.w900)),const SizedBox(height:4),Text('${tpMoney(value)} foi lançado nos seus ganhos.',style:const TextStyle(fontSize:10,color:TpColors.muted))]));}
