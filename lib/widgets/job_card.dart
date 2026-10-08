import 'package:flutter/material.dart';
import '../models/job.dart';
import '../theme/app_theme.dart';

String tpMoney(double v) => 'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';
String two(int v) => v.toString().padLeft(2, '0');
const _months = ['', 'jan', 'fev', 'mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set', 'out', 'nov', 'dez'];
String tpDate(DateTime d) => '${two(d.day)} ${_months[d.month]}';
String tpTime(DateTime d) => '${two(d.hour)}:${two(d.minute)}';
String tpDistance(Job job) {
  final value = job.distanceKm;
  if (value == null) return 'distância indisponível';
  final text = value < 10
      ? value.toStringAsFixed(1).replaceAll('.', ',')
      : value.round().toString();
  final suffix = job.distanceMode == 'road'
      ? ' pela rota'
      : (job.distanceMode == 'straight' ? ' em linha reta' : '');
  return text + ' km' + suffix;
}

class JobCard extends StatelessWidget {
  const JobCard({super.key, required this.job, required this.onDetails}); final Job job; final VoidCallback onDetails;
  @override Widget build(BuildContext context)=>Container(margin:const EdgeInsets.only(bottom:11),padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:Colors.white,border:Border.all(color:TpColors.line),borderRadius:BorderRadius.circular(14)),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Container(width:66,height:66,decoration:BoxDecoration(borderRadius:BorderRadius.circular(12),gradient:const LinearGradient(colors:[Color(0xFF1D3557),Color(0xFFC18D4E)],begin:Alignment.topLeft,end:Alignment.bottomRight)),child:const Icon(Icons.room_service_rounded,color:Colors.white,size:30)),const SizedBox(width:11),
    Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Expanded(child:Text(job.role,style:const TextStyle(fontWeight:FontWeight.w900,fontSize:15))),Icon(job.following?Icons.notifications_active_rounded:Icons.notifications_none_rounded,size:20,color:job.following?TpColors.blue:TpColors.muted)]),Text(job.company,style:const TextStyle(fontSize:11,color:TpColors.text)),const SizedBox(height:2),Row(children:[const Icon(Icons.star_rounded,size:15,color:TpColors.orange),Text(' ${job.companyRating.toStringAsFixed(1)}',style:const TextStyle(fontSize:10,color:TpColors.muted))]),const SizedBox(height:9),Wrap(spacing:8,runSpacing:5,children:[_Info(icon:Icons.calendar_month_rounded,text:tpDate(job.startsAt)),_Info(icon:Icons.schedule_rounded,text:'${tpTime(job.startsAt)} – ${tpTime(job.endsAt)}'),Container(padding:const EdgeInsets.symmetric(horizontal:8,vertical:5),decoration:BoxDecoration(color:TpColors.greenSoft,borderRadius:BorderRadius.circular(8)),child:Text(tpMoney(job.value),style:const TextStyle(fontSize:11,color:Color(0xFF0A8F50),fontWeight:FontWeight.w800)))]),const SizedBox(height:8),Row(children:[const Icon(Icons.location_on_outlined,size:14,color:TpColors.muted),Expanded(child:Text('${tpDistance(job)} · ${job.city} - ${job.state}',style:const TextStyle(fontSize:10,color:TpColors.muted))),SizedBox(height:34,child:FilledButton(onPressed:onDetails,style:FilledButton.styleFrom(minimumSize:const Size(108,34),padding:const EdgeInsets.symmetric(horizontal:12),textStyle:const TextStyle(fontSize:11,fontWeight:FontWeight.w800)),child:const Text('Ver detalhes →')))])]))
  ]));
}
class _Info extends StatelessWidget{const _Info({required this.icon,required this.text});final IconData icon;final String text;@override Widget build(BuildContext context)=>Row(mainAxisSize:MainAxisSize.min,children:[Icon(icon,size:15,color:TpColors.blue),const SizedBox(width:4),Text(text,style:const TextStyle(fontSize:10,fontWeight:FontWeight.w600))]);}
