import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key, required this.api});
  final ApiService api;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: api.earnings(),
      builder: (context, snapshot) {
        final rawSummary = snapshot.data?['summary'];
        final summary = rawSummary is Map ? Map<String, dynamic>.from(rawSummary) : <String, dynamic>{'total': 6420.0, 'available': 780.0};
        final total = double.tryParse(summary['total'].toString()) ?? 6420;
        final available = double.tryParse(summary['available'].toString()) ?? 780;
        return ListView(padding: const EdgeInsets.fromLTRB(16,20,16,100),children:[
          const Text('Ganhos',style:TextStyle(fontSize:27,fontWeight:FontWeight.w900)),const SizedBox(height:4),const Text('Acompanhe seus extras e próximos repasses.',style:TextStyle(color:TpColors.muted,fontSize:11)),const SizedBox(height:18),
          Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFF075FE9),Color(0xFF0B79F4)]),borderRadius:BorderRadius.circular(18)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Total acumulado',style:TextStyle(color:Colors.white70,fontSize:11)),Text('R\$ ${total.toStringAsFixed(2).replaceAll('.', ',')}',style:const TextStyle(color:Colors.white,fontSize:30,fontWeight:FontWeight.w900)),const SizedBox(height:20),Row(children:[Expanded(child:_MoneyPill(label:'Disponível',value:available)),const SizedBox(width:8),const Expanded(child:_MoneyPill(label:'Próximo repasse',value:780))])])),
          const SizedBox(height:15),Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:Colors.white,border:Border.all(color:TpColors.line),borderRadius:BorderRadius.circular(16)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Últimos meses',style:TextStyle(fontSize:16,fontWeight:FontWeight.w900)),const SizedBox(height:20),SizedBox(height:180,child:Row(crossAxisAlignment:CrossAxisAlignment.end,children:[980,1250,1850,2340,780].map((v)=>Expanded(child:Column(mainAxisAlignment:MainAxisAlignment.end,children:[Text('R\$ $v',style:const TextStyle(fontSize:8,color:TpColors.muted)),const SizedBox(height:4),Container(height:v/14,width:32,decoration:BoxDecoration(color:v==2340?TpColors.blue:const Color(0xFFB8D7FF),borderRadius:const BorderRadius.vertical(top:Radius.circular(6))))]))).toList()))]))
        ]);
      },
    );
  }
}
class _MoneyPill extends StatelessWidget{const _MoneyPill({required this.label,required this.value});final String label;final double value;@override Widget build(BuildContext context)=>Container(padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:Colors.white.withValues(alpha:.14),borderRadius:BorderRadius.circular(12)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(label,style:const TextStyle(color:Colors.white70,fontSize:9)),Text('R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}',style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w900,fontSize:14))]));}
