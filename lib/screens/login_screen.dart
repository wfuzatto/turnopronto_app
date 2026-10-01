import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_logo.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.api, required this.onLoggedIn});
  final ApiService api;
  final VoidCallback onLoggedIn;
  @override State<LoginScreen> createState()=>_LoginScreenState();
}
class _LoginScreenState extends State<LoginScreen>{
  final email=TextEditingController(text:'juliana@turnopronto.local');
  final password=TextEditingController(); bool loading=false; String? error;
  @override void dispose(){email.dispose();password.dispose();super.dispose();}
  Future<void> login()async{setState((){loading=true;error=null;});try{await widget.api.login(email.text.trim(),password.text);if(mounted)widget.onLoggedIn();}catch(e){if(mounted)setState(()=>error=e.toString());}finally{if(mounted)setState(()=>loading=false);}}
  void demo(){widget.api.loginDemo();widget.onLoggedIn();}
  @override Widget build(BuildContext context)=>Scaffold(body:SafeArea(child:Center(child:SingleChildScrollView(padding:const EdgeInsets.all(24),child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:430),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    const Align(alignment:Alignment.centerLeft,child:BrandLogo()),const SizedBox(height:48),const Text('Seu próximo extra\ncomeça aqui.',style:TextStyle(fontSize:34,fontWeight:FontWeight.w900,letterSpacing:-1.2,height:1.08,color:TpColors.text)),const SizedBox(height:10),const Text('Escolha quando trabalhar. O TurnoPronto conecta seu tempo livre a oportunidades reais.',style:TextStyle(color:TpColors.muted,height:1.45)),const SizedBox(height:30),
    if(error!=null)Container(margin:const EdgeInsets.only(bottom:12),padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:const Color(0xFFFFECEE),borderRadius:BorderRadius.circular(10)),child:Text(error!,style:const TextStyle(color:Color(0xFFA12E38),fontSize:12))),
    TextField(controller:email,keyboardType:TextInputType.emailAddress,decoration:const InputDecoration(labelText:'E-mail')),const SizedBox(height:12),TextField(controller:password,obscureText:true,decoration:const InputDecoration(labelText:'Senha')),const SizedBox(height:16),FilledButton(onPressed:loading?null:login,child:Text(loading?'Entrando...':'Entrar')),const SizedBox(height:10),OutlinedButton(onPressed:demo,child:const Text('Abrir demonstração sem servidor')),const SizedBox(height:18),const Text('API local: inicie o XAMPP e use --dart-define=API_URL=http://IP_DO_PC/turnopronto_web/api/v1',style:TextStyle(fontSize:10,color:TpColors.muted,height:1.4))
  ]))))));
}
