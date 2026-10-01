import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key,this.compact=false}); final bool compact;
  @override Widget build(BuildContext context)=>Row(mainAxisSize:MainAxisSize.min,children:[Container(width:compact?32:38,height:compact?32:38,decoration:const BoxDecoration(gradient:LinearGradient(colors:[TpColors.blue,TpColors.green],begin:Alignment.topLeft,end:Alignment.bottomRight),borderRadius:BorderRadius.all(Radius.circular(12))),child:const Icon(Icons.check_rounded,color:Colors.white,size:23)),const SizedBox(width:8),RichText(text:TextSpan(style:TextStyle(fontSize:compact?19:22,fontWeight:FontWeight.w900,color:TpColors.text,letterSpacing:-.5),children:const [TextSpan(text:'Turno'),TextSpan(text:'Pronto',style:TextStyle(color:TpColors.green))]))]);
}
