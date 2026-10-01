import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MetricCard extends StatelessWidget {
  const MetricCard({super.key,required this.icon,required this.value,required this.label,this.accent=TpColors.blue,this.compact=false});final IconData icon;final String value,label;final Color accent;final bool compact;
  @override Widget build(BuildContext context)=>Container(padding:EdgeInsets.all(compact?11:13),decoration:BoxDecoration(color:Colors.white,border:Border.all(color:TpColors.line),borderRadius:BorderRadius.circular(14)),child:compact?Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(icon,size:20,color:accent),const SizedBox(height:7),Text(value,style:const TextStyle(fontSize:16,fontWeight:FontWeight.w900)),const SizedBox(height:2),Text(label,style:const TextStyle(fontSize:10,color:TpColors.muted))]):Row(children:[Container(width:40,height:40,decoration:BoxDecoration(color:accent.withValues(alpha:.10),borderRadius:BorderRadius.circular(11)),child:Icon(icon,color:accent,size:21)),const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(label,style:const TextStyle(fontSize:10,color:TpColors.muted,fontWeight:FontWeight.w600)),Text(value,style:const TextStyle(fontSize:18,fontWeight:FontWeight.w900))]))]));
}
