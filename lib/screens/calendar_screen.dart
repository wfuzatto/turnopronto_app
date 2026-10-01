import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      children: [
        const Text('Agenda', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        const Text('Visualize disponibilidade e turnos confirmados.', style: TextStyle(color: TpColors.muted, fontSize: 11)),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: TpColors.line), borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              IconButton(onPressed: () {}, icon: const Icon(Icons.chevron_left_rounded)),
              Text('${_month(now.month)} ${now.year}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
              IconButton(onPressed: () {}, icon: const Icon(Icons.chevron_right_rounded)),
            ]),
            const SizedBox(height: 8),
            const Row(children: [_WeekDay('D'),_WeekDay('S'),_WeekDay('T'),_WeekDay('Q'),_WeekDay('Q'),_WeekDay('S'),_WeekDay('S')]),
            const SizedBox(height: 8),
            GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:7,mainAxisSpacing:5,crossAxisSpacing:5), itemCount:35, itemBuilder:(context,i){
              final day=i-2; final active=day==now.day; final booked=[now.day,now.day+2,now.day+5].contains(day);
              return Container(decoration:BoxDecoration(color:active?TpColors.blue:(booked?TpColors.greenSoft:Colors.transparent),borderRadius:BorderRadius.circular(9)),alignment:Alignment.center,child:day>0&&day<=31?Column(mainAxisAlignment:MainAxisAlignment.center,children:[Text('$day',style:TextStyle(fontSize:11,fontWeight:active?FontWeight.w900:FontWeight.w600,color:active?Colors.white:TpColors.text)),if(booked&&!active)Container(width:4,height:4,margin:const EdgeInsets.only(top:2),decoration:const BoxDecoration(color:TpColors.green,shape:BoxShape.circle))]):const SizedBox());
            }),
          ]),
        ),
        const SizedBox(height: 13),
        Container(padding: const EdgeInsets.all(14),decoration:BoxDecoration(color:Colors.white,border:Border.all(color:TpColors.line),borderRadius:BorderRadius.circular(14)),child:const Row(children:[Icon(Icons.info_outline_rounded,color:TpColors.blue),SizedBox(width:9),Expanded(child:Text('No MVP, sua disponibilidade poderá bloquear automaticamente horários em que você não quer receber ofertas.',style:TextStyle(fontSize:10,color:TpColors.muted,height:1.4)))])),
      ],
    );
  }
}
class _WeekDay extends StatelessWidget { const _WeekDay(this.label); final String label; @override Widget build(BuildContext context)=>Expanded(child:Center(child:Text(label,style:const TextStyle(fontSize:10,color:TpColors.muted,fontWeight:FontWeight.w700)))); }
String _month(int m)=>const ['','Janeiro','Fevereiro','Março','Abril','Maio','Junho','Julho','Agosto','Setembro','Outubro','Novembro','Dezembro'][m];
