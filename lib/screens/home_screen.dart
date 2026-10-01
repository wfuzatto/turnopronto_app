import 'package:flutter/material.dart';
import '../models/job.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_logo.dart';
import '../widgets/job_card.dart';
import '../widgets/metric_card.dart';
import '../widgets/reliability_card.dart';
import 'job_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.api});
  final ApiService api;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Job>> jobs;

  @override
  void initState() { super.initState(); jobs = widget.api.opportunities(); }
  void refresh() => setState(() => jobs = widget.api.opportunities());

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(onRefresh: () async => refresh(),child:ListView(padding:const EdgeInsets.fromLTRB(16,12,16,100),children:[
      Row(children:[const BrandLogo(compact:true),const Spacer(),Stack(clipBehavior:Clip.none,children:[IconButton(onPressed:(){},icon:const Icon(Icons.notifications_none_rounded,color:TpColors.text)),Positioned(right:7,top:5,child:Container(width:16,height:16,decoration:const BoxDecoration(color:Colors.red,shape:BoxShape.circle),alignment:Alignment.center,child:const Text('2',style:TextStyle(color:Colors.white,fontSize:8,fontWeight:FontWeight.bold))))]),const SizedBox(width:4),const CircleAvatar(radius:18,backgroundColor:TpColors.blueSoft,child:Text('J',style:TextStyle(color:TpColors.blue,fontWeight:FontWeight.w900)))]),
      const SizedBox(height:23),const Text('Olá, Juliana! 👋',style:TextStyle(fontSize:26,fontWeight:FontWeight.w900,letterSpacing:-.7)),const SizedBox(height:3),const Text('Hoje tem boas oportunidades para você.',style:TextStyle(color:TpColors.muted,fontSize:12)),const SizedBox(height:16),const ReliabilityCard(),const SizedBox(height:12),
      const Row(children:[Expanded(child:MetricCard(icon:Icons.calendar_month_rounded,value:'12',label:'Vagas hoje',compact:true)),SizedBox(width:8),Expanded(child:MetricCard(icon:Icons.trending_up_rounded,value:'R\$ 1.280',label:'Neste mês',accent:TpColors.green,compact:true)),SizedBox(width:8),Expanded(child:MetricCard(icon:Icons.star_rounded,value:'4,9',label:'Avaliação',accent:TpColors.orange,compact:true))]),
      const SizedBox(height:22),Row(children:[const Text('Vagas para você',style:TextStyle(fontSize:18,fontWeight:FontWeight.w900)),const Spacer(),TextButton(onPressed:(){},child:const Text('Ver todas →'))]),
      FutureBuilder<List<Job>>(future:jobs,builder:(context,snapshot){if(snapshot.connectionState!=ConnectionState.done)return const Padding(padding:EdgeInsets.all(40),child:Center(child:CircularProgressIndicator()));if(snapshot.hasError)return _ErrorCard(message:snapshot.error.toString(),onRetry:refresh);final list=snapshot.data??[];return Column(children:list.map((job)=>JobCard(job:job,onDetails:()async{await Navigator.of(context).push(MaterialPageRoute(builder:(_)=>JobDetailScreen(api:widget.api,job:job)));refresh();})).toList());})
    ]));
  }
}
class _ErrorCard extends StatelessWidget{const _ErrorCard({required this.message,required this.onRetry});final String message;final VoidCallback onRetry;@override Widget build(BuildContext context)=>Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:Colors.white,border:Border.all(color:TpColors.line),borderRadius:BorderRadius.circular(14)),child:Column(children:[const Icon(Icons.cloud_off_rounded,color:TpColors.muted),const SizedBox(height:8),Text(message,textAlign:TextAlign.center,style:const TextStyle(fontSize:11,color:TpColors.muted)),const SizedBox(height:8),TextButton(onPressed:onRetry,child:const Text('Tentar novamente'))]));}
