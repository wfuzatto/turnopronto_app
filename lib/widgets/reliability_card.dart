import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ReliabilityCard extends StatelessWidget {
  const ReliabilityCard({super.key,this.score=97});final int score;
  @override Widget build(BuildContext context)=>Container(padding:const EdgeInsets.all(13),decoration:BoxDecoration(color:Colors.white,border:Border.all(color:TpColors.line),borderRadius:BorderRadius.circular(14)),child:Row(children:[Container(width:44,height:44,decoration:const BoxDecoration(color:TpColors.greenSoft,shape:BoxShape.circle),child:const Icon(Icons.verified_user_rounded,color:TpColors.green)),const SizedBox(width:10),Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Confiabilidade',style:TextStyle(fontSize:10,color:TpColors.muted,fontWeight:FontWeight.w700)),Text('$score%',style:const TextStyle(fontSize:24,fontWeight:FontWeight.w900))]),const Spacer(),const SizedBox(width:130,child:Text('Você é uma profissional muito bem avaliada!',style:TextStyle(fontSize:10,color:TpColors.muted,height:1.35))),const Icon(Icons.chevron_right_rounded,color:TpColors.muted)]));
}
