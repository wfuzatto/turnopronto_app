import 'package:flutter/material.dart';
import '../models/job.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/job_card.dart';
import 'current_shift_screen.dart';
import 'payment_setup_screen.dart';

class JobDetailScreen extends StatefulWidget {
  const JobDetailScreen({super.key, required this.api, required this.job});
  final ApiService api;
  final Job job;
  @override State<JobDetailScreen> createState()=>_JobDetailScreenState();
}
class _JobDetailScreenState extends State<JobDetailScreen>{
  bool accepting=false;
  bool followingBusy=false;
  late Job currentJob;

  @override
  void initState(){
    super.initState();
    currentJob=widget.job;
    _refreshJob();
  }

  Future<void> _refreshJob() async {
    try {
      final fresh=await widget.api.job(widget.job.id);
      if(mounted){
        setState(()=>currentJob=fresh.copyWith(
          distanceKm: widget.job.distanceKm,
          distanceMode: widget.job.distanceMode,
        ));
      }
    } catch (_) {}
  }

  Future<void> toggleFollow() async {
    setState(()=>followingBusy=true);
    try{
      final next=currentJob.following
          ? await widget.api.unfollowShift(currentJob.id)
          : await widget.api.followShift(currentJob.id);
      if(mounted){
        setState(()=>currentJob=currentJob.copyWith(following:next));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:Text(next
              ? 'Você está acompanhando esta vaga sem assumir compromisso.'
              : 'Você deixou de acompanhar esta vaga.'),
        ));
      }
    }catch(e){
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));
    }finally{
      if(mounted)setState(()=>followingBusy=false);
    }
  }
  Future<void> accept() async {
    setState(() => accepting = true);
    try {
      final onboarding = await widget.api.onboarding();
      if (onboarding['payment_complete'] != true) {
        if (mounted) setState(() => accepting = false);
        if (!mounted) return;
        final completed = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => PaymentSetupScreen(api: widget.api),
          ),
        );
        if (completed != true || !mounted) return;
        setState(() => accepting = true);
      }

      final result = await widget.api.accept(currentJob.id);
      if (!mounted) return;

      if (result.pendingApproval) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(
              Icons.hourglass_top_rounded,
              color: TpColors.blue,
            ),
            title: const Text('Candidatura enviada'),
            content: const Text(
              'Esta vaga exige aprovação da empresa. Quando você for aprovado, o turno aparecerá em Meus turnos.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Entendi'),
              ),
            ],
          ),
        );
        if (mounted) Navigator.of(context).pop(true);
        return;
      }

      final id = result.assignmentId;
      if (id == null) {
        throw ApiException('A confirmação não retornou o turno.');
      }
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => CurrentShiftScreen(
            api: widget.api,
            assignmentId: id,
            fallbackJob: currentJob,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => accepting = false);
    }
  }
  @override Widget build(BuildContext context){final j=currentJob;return Scaffold(backgroundColor:Colors.white,appBar:AppBar(actions:[IconButton(onPressed:(){},icon:const Icon(Icons.favorite_border_rounded)),IconButton(onPressed:(){},icon:const Icon(Icons.ios_share_rounded))]),body:SafeArea(top:false,child:Column(children:[
    Expanded(child:ListView(padding:EdgeInsets.zero,children:[Stack(alignment:Alignment.bottomCenter,children:[j.imageUrl.isNotEmpty?Image.network(j.imageUrl,width:double.infinity,height:190,fit:BoxFit.cover,errorBuilder:(_,__,___)=>Container(height:190,decoration:const BoxDecoration(gradient:LinearGradient(colors:[Color(0xFF4F3A28),Color(0xFFC29762),Color(0xFF25344A)],begin:Alignment.topLeft,end:Alignment.bottomRight)))):Container(height:190,decoration:const BoxDecoration(gradient:LinearGradient(colors:[Color(0xFF4F3A28),Color(0xFFC29762),Color(0xFF25344A)],begin:Alignment.topLeft,end:Alignment.bottomRight))),Padding(padding:const EdgeInsets.fromLTRB(18,0,18,14),child:Container(padding:const EdgeInsets.all(11),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(14),boxShadow:const [BoxShadow(color:Color(0x22000000),blurRadius:16,offset:Offset(0,6))]),child:Row(children:[Container(width:42,height:42,decoration:BoxDecoration(color:TpColors.blue,borderRadius:BorderRadius.circular(10)),child:const Icon(Icons.apartment_rounded,color:Colors.white)),const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(j.company,style:const TextStyle(fontWeight:FontWeight.w900)),Row(children:[const Icon(Icons.star_rounded,size:15,color:TpColors.orange),Text(' ${j.companyRating.toStringAsFixed(1)}',style:const TextStyle(fontSize:10,color:TpColors.muted))])])),TextButton(onPressed:(){},child:const Text('Ver perfil'))]))) ]),
    Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(j.role,style:const TextStyle(fontSize:27,fontWeight:FontWeight.w900,letterSpacing:-.7)),const SizedBox(height:3),Row(children:[const Icon(Icons.location_on_outlined,size:16,color:TpColors.muted),Text(j.company,style:const TextStyle(color:TpColors.muted,fontSize:12))])])),Container(padding:const EdgeInsets.symmetric(horizontal:9,vertical:7),decoration:BoxDecoration(color:TpColors.greenSoft,borderRadius:BorderRadius.circular(20)),child:const Row(children:[Icon(Icons.verified_user_rounded,size:16,color:TpColors.green),SizedBox(width:4),Text('Vaga verificada',style:TextStyle(fontSize:10,color:Color(0xFF078B4C),fontWeight:FontWeight.w800))]))]),const SizedBox(height:15),if(j.requiresApproval)Container(margin:const EdgeInsets.only(bottom:10),padding:const EdgeInsets.all(11),decoration:BoxDecoration(color:TpColors.blueSoft,borderRadius:BorderRadius.circular(12)),child:const Row(children:[Icon(Icons.groups_rounded,color:TpColors.blue,size:20),SizedBox(width:8),Expanded(child:Text('Esta vaga exige aprovação da empresa após a candidatura.',style:TextStyle(fontSize:10,color:TpColors.text,fontWeight:FontWeight.w700)))])),_InfoPanel(job:j),const SizedBox(height:10),Row(children:[Expanded(child:_MiniStat(icon:Icons.location_on_rounded,label:'Distância',value:tpDistance(j),caption:j.distanceMode=='straight'?'estimativa em linha reta':'pela rota rodoviária')),const SizedBox(width:9),Expanded(child:_MiniStat(icon:Icons.groups_rounded,label:'Candidatos',value:'${j.candidates}',caption:'já se candidataram'))]),const SizedBox(height:11),Container(width:double.infinity,padding:const EdgeInsets.all(14),decoration:BoxDecoration(border:Border.all(color:TpColors.line),borderRadius:BorderRadius.circular(14)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Row(children:[Icon(Icons.checkroom_rounded,color:TpColors.blue),SizedBox(width:8),Text('Uniforme / Dress code',style:TextStyle(fontWeight:FontWeight.w900))]),const SizedBox(height:5),Text(j.dressCode.isEmpty?'Sem exigência informada.':j.dressCode,style:const TextStyle(fontSize:11,color:TpColors.muted,height:1.45)),const Divider(height:24),const Row(children:[Icon(Icons.description_outlined,color:TpColors.blue),SizedBox(width:8),Text('Observações da empresa',style:TextStyle(fontWeight:FontWeight.w900))]),const SizedBox(height:5),Text(j.notes.isEmpty?'Nenhuma observação adicional.':j.notes,style:const TextStyle(fontSize:11,color:TpColors.muted,height:1.45))]))]))])),
    Container(padding:const EdgeInsets.fromLTRB(16,10,16,12),decoration:const BoxDecoration(color:Colors.white,border:Border(top:BorderSide(color:TpColors.line))),child:Column(children:[Container(width:double.infinity,margin:const EdgeInsets.only(bottom:8),padding:const EdgeInsets.all(10),decoration:BoxDecoration(color:TpColors.blueSoft,borderRadius:BorderRadius.circular(10)),child:const Text('Acompanhar não confirma o turno. Você recebe alterações da vaga e a empresa pode ver seu interesse.',style:TextStyle(fontSize:9,color:TpColors.text,height:1.35))),Row(children:[Expanded(child:OutlinedButton.icon(onPressed:followingBusy?null:toggleFollow,icon:Icon(j.following?Icons.notifications_active_rounded:Icons.notifications_none_rounded,size:18),label:Text(followingBusy?'Aguarde...':(j.following?'Acompanhando':'Acompanhar')))),const SizedBox(width:9),Expanded(child:FilledButton.icon(onPressed:accepting?null:accept,icon:const Icon(Icons.calendar_month_rounded,size:18),label:Text(accepting?'Enviando...':(j.requiresApproval?'Candidatar-se':'Aceitar vaga'))))])]))
  ])));}
}
class _InfoPanel extends StatelessWidget{const _InfoPanel({required this.job});final Job job;@override Widget build(BuildContext context)=>Container(decoration:BoxDecoration(border:Border.all(color:TpColors.line),borderRadius:BorderRadius.circular(14)),child:Column(children:[Row(children:[Expanded(child:_InfoCell(icon:Icons.calendar_month_rounded,label:'Data',value:'${two(job.startsAt.day)}/${two(job.startsAt.month)}/${job.startsAt.year}')),Expanded(child:_InfoCell(icon:Icons.schedule_rounded,label:'Horário',value:'${tpTime(job.startsAt)} – ${tpTime(job.endsAt)}'))]),const Divider(height:1),Row(children:[Expanded(child:_InfoCell(icon:Icons.attach_money_rounded,label:'Valor',value:tpMoney(job.value))),Expanded(child:_InfoCell(icon:Icons.location_on_rounded,label:'Local',value:'${job.address}\n${job.city} - ${job.state}'))])])) ;}
class _InfoCell extends StatelessWidget{const _InfoCell({required this.icon,required this.label,required this.value});final IconData icon;final String label,value;@override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.all(13),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(icon,color:TpColors.blue,size:21),const SizedBox(width:8),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(label,style:const TextStyle(fontSize:9,color:TpColors.muted)),const SizedBox(height:2),Text(value,style:const TextStyle(fontSize:11,fontWeight:FontWeight.w800,height:1.35))]))]));}
class _MiniStat extends StatelessWidget{const _MiniStat({required this.icon,required this.label,required this.value,required this.caption});final IconData icon;final String label,value,caption;@override Widget build(BuildContext context)=>Container(padding:const EdgeInsets.all(12),decoration:BoxDecoration(border:Border.all(color:TpColors.line),borderRadius:BorderRadius.circular(13)),child:Row(children:[Icon(icon,color:TpColors.blue),const SizedBox(width:8),Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(label,style:const TextStyle(fontSize:9,color:TpColors.muted)),Text(value,style:const TextStyle(fontSize:16,fontWeight:FontWeight.w900)),Text(caption,style:const TextStyle(fontSize:8,color:TpColors.muted))])])) ;}
