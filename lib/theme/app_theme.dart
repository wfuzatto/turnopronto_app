import 'package:flutter/material.dart';

class TpColors {
  static const navy = Color(0xFF0D2245);
  static const text = Color(0xFF10213D);
  static const muted = Color(0xFF75849B);
  static const page = Color(0xFFF6F9FD);
  static const line = Color(0xFFE3EAF3);
  static const blue = Color(0xFF0866FF);
  static const blueSoft = Color(0xFFEAF3FF);
  static const green = Color(0xFF12B76A);
  static const greenSoft = Color(0xFFE9FBF1);
  static const orange = Color(0xFFF4A51C);
}

ThemeData turnoprontoTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: TpColors.blue, brightness: Brightness.light, primary: TpColors.blue, secondary: TpColors.green, surface: Colors.white);
  return ThemeData(useMaterial3:true,colorScheme:scheme,scaffoldBackgroundColor:TpColors.page,fontFamily:'Roboto',appBarTheme:const AppBarTheme(backgroundColor:Colors.white,foregroundColor:TpColors.text,elevation:0,surfaceTintColor:Colors.transparent,centerTitle:true),cardTheme:const CardThemeData(color:Colors.white,surfaceTintColor:Colors.transparent,elevation:0,margin:EdgeInsets.zero,shape:RoundedRectangleBorder(side:BorderSide(color:TpColors.line),borderRadius:BorderRadius.all(Radius.circular(16)))),inputDecorationTheme:InputDecorationTheme(filled:true,fillColor:Colors.white,contentPadding:const EdgeInsets.symmetric(horizontal:14,vertical:14),border:OutlineInputBorder(borderRadius:BorderRadius.circular(12),borderSide:const BorderSide(color:TpColors.line)),enabledBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(12),borderSide:const BorderSide(color:TpColors.line)),focusedBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(12),borderSide:const BorderSide(color:TpColors.blue,width:1.5))),filledButtonTheme:FilledButtonThemeData(style:FilledButton.styleFrom(backgroundColor:TpColors.blue,foregroundColor:Colors.white,minimumSize:const Size(0,48),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(11)),textStyle:const TextStyle(fontWeight:FontWeight.w700))),outlinedButtonTheme:OutlinedButtonThemeData(style:OutlinedButton.styleFrom(foregroundColor:TpColors.blue,minimumSize:const Size(0,48),side:const BorderSide(color:Color(0xFFBFD8FF)),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(11)),textStyle:const TextStyle(fontWeight:FontWeight.w700))));
}
