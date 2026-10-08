import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';

class PaymentSetupScreen extends StatefulWidget {
  const PaymentSetupScreen({
    super.key,
    required this.api,
  });

  final ApiService api;

  @override
  State<PaymentSetupScreen> createState() => _PaymentSetupScreenState();
}

class _PaymentSetupScreenState extends State<PaymentSetupScreen> {
  String pixType = 'cpf';
  late final TextEditingController pixKey;
  late final TextEditingController holderName;
  late final TextEditingController holderDocument;
  bool loading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    final user = widget.api.currentUser ?? <String, dynamic>{};
    final profile = widget.api.currentProfile ?? <String, dynamic>{};
    final cpf = _digits((profile['cpf'] ?? '').toString());
    pixKey = TextEditingController(text: cpf);
    holderName = TextEditingController(
      text: (user['name'] ?? '').toString(),
    );
    holderDocument = TextEditingController(text: cpf);
  }

  @override
  void dispose() {
    pixKey.dispose();
    holderName.dispose();
    holderDocument.dispose();
    super.dispose();
  }

  String _digits(String value) => value.replaceAll(RegExp(r'\D'), '');

  TextInputType get _keyKeyboard {
    switch (pixType) {
      case 'cpf':
      case 'phone':
        return TextInputType.number;
      case 'email':
        return TextInputType.emailAddress;
      default:
        return TextInputType.text;
    }
  }

  List<TextInputFormatter>? get _keyFormatters {
    if (pixType == 'cpf' || pixType == 'phone') {
      return <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly];
    }
    return null;
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final key = pixKey.text.trim();
    final name = holderName.text.trim();
    final document = _digits(holderDocument.text);

    if (key.isEmpty) {
      setState(() => error = 'Informe sua chave Pix.');
      return;
    }
    if (name.length < 3) {
      setState(() => error = 'Informe o nome do titular da chave Pix.');
      return;
    }
    if (document.length != 11) {
      setState(
        () => error =
            'O CPF do titular deve ser o mesmo CPF cadastrado no TurnoPronto.',
      );
      return;
    }

    setState(() {
      loading = true;
      error = null;
    });

    try {
      await widget.api.completePayment({
        'pix_key_type': pixType,
        'pix_key': key,
        'pix_holder_name': name,
        'pix_holder_document': document,
      });
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dados para pagamento',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: TpColors.blueSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    color: TpColors.blue,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Antes da sua primeira candidatura, precisamos saber onde você receberá os pagamentos. Estes dados ficam vinculados à sua conta.',
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.45,
                        color: TpColors.text,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFECEE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  error!,
                  style: const TextStyle(
                    color: Color(0xFFA12E38),
                    fontSize: 11,
                  ),
                ),
              ),
            DropdownButtonFormField<String>(
              initialValue: pixType,
              decoration: const InputDecoration(
                labelText: 'Tipo da chave Pix',
              ),
              items: const [
                DropdownMenuItem(value: 'cpf', child: Text('CPF')),
                DropdownMenuItem(value: 'email', child: Text('E-mail')),
                DropdownMenuItem(value: 'phone', child: Text('Telefone')),
                DropdownMenuItem(
                  value: 'random',
                  child: Text('Chave aleatória'),
                ),
              ],
              onChanged: loading
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() {
                        pixType = value;
                        if (value == 'cpf') {
                          pixKey.text = holderDocument.text;
                        } else {
                          pixKey.clear();
                        }
                      });
                    },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pixKey,
              keyboardType: _keyKeyboard,
              inputFormatters: _keyFormatters,
              decoration: const InputDecoration(
                labelText: 'Chave Pix *',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: holderName,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nome do titular *',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: holderDocument,
              enabled: false,
              decoration: const InputDecoration(
                labelText: 'CPF do titular',
                helperText:
                    'Por segurança, deve ser o mesmo CPF da sua conta.',
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: loading ? null : _save,
              child: Text(
                loading ? 'Salvando...' : 'Salvar e continuar candidatura',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
