import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
    required this.api,
    required this.onProfessionalRegistered,
  });

  final ApiService api;
  final VoidCallback onProfessionalRegistered;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final name = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final cpf = TextEditingController();
  final birthDate = TextEditingController();
  final headline = TextEditingController();
  final cnpj = TextEditingController();
  final responsibleCpf = TextEditingController();
  final legalName = TextEditingController();
  final tradeName = TextEditingController();
  final postalCode = TextEditingController();
  final address = TextEditingController();
  final city = TextEditingController();
  final state = TextEditingController(text: 'MG');
  final pixKey = TextEditingController();
  final pixHolderName = TextEditingController();
  final pixHolderDocument = TextEditingController();
  final password = TextEditingController();
  final passwordConfirm = TextEditingController();

  String role = 'professional';
  String pixType = 'cpf';
  bool termsAccepted = false;
  bool privacyAccepted = false;
  bool whatsappConsent = false;
  bool loading = false;
  String? error;

  List<Map<String, dynamic>> categories = [];
  final Set<int> selectedCategories = <int>{};

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final items = await widget.api.categories();
      if (mounted) setState(() => categories = items);
    } catch (_) {
      // O servidor fará a validação; a tela continua utilizável para empresa.
    }
  }

  @override
  void dispose() {
    for (final controller in [
      name,
      phone,
      email,
      cpf,
      birthDate,
      headline,
      cnpj,
      responsibleCpf,
      legalName,
      tradeName,
      postalCode,
      address,
      city,
      state,
      pixKey,
      pixHolderName,
      pixHolderDocument,
      password,
      passwordConfirm,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Map<String, dynamic> _payload() {
    return <String, dynamic>{
      'role': role,
      'name': name.text.trim(),
      'phone': phone.text.trim(),
      'email': email.text.trim(),
      'password': password.text,
      'password_confirm': passwordConfirm.text,
      'postal_code': postalCode.text.trim(),
      'address': address.text.trim(),
      'city': city.text.trim(),
      'state': state.text.trim().toUpperCase(),
      'pix_key_type': pixType,
      'pix_key': pixKey.text.trim(),
      'pix_holder_name': pixHolderName.text.trim(),
      'pix_holder_document': pixHolderDocument.text.trim(),
      'terms_accepted': termsAccepted,
      'privacy_accepted': privacyAccepted,
      'whatsapp_consent': whatsappConsent,
      if (role == 'professional') ...{
        'cpf': cpf.text.trim(),
        'birth_date': birthDate.text.trim(),
        'headline': headline.text.trim(),
        'categories': selectedCategories.toList(),
      } else ...{
        'cnpj': cnpj.text.trim(),
        'responsible_cpf': responsibleCpf.text.trim(),
        'legal_name': legalName.text.trim(),
        'trade_name': tradeName.text.trim(),
      },
    };
  }

  Future<void> _submit() async {
    if (!termsAccepted || !privacyAccepted || !whatsappConsent) {
      setState(() {
        error =
            'Aceite os Termos, a Política de Privacidade e as mensagens transacionais no WhatsApp.';
      });
      return;
    }
    if (role == 'professional' && selectedCategories.isEmpty) {
      setState(() => error = 'Selecione pelo menos uma função de interesse.');
      return;
    }

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final result = await widget.api.startRegistration(_payload());
      if (!mounted) return;
      final registrationId = (result['registration_id'] ?? '').toString();
      final phoneMasked = (result['phone_masked'] ?? phone.text).toString();

      final verifiedRole = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (_) => _VerifyRegistrationScreen(
            api: widget.api,
            registrationId: registrationId,
            phoneMasked: phoneMasked,
          ),
        ),
      );

      if (!mounted || verifiedRole == null) return;

      if (verifiedRole == 'professional') {
        Navigator.of(context).popUntil((route) => route.isFirst);
        widget.onProfessionalRegistered();
      } else {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Cadastro concluído'),
            content: const Text(
              'Seu WhatsApp foi validado. A conta da empresa seguirá para verificação. O painel empresarial pode ser acessado pelo site TurnoPronto.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Entendi'),
              ),
            ],
          ),
        );
        if (mounted) Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 100),
      lastDate: DateTime(now.year - 18, now.month, now.day),
      initialDate: DateTime(now.year - 25),
    );
    if (picked != null) {
      birthDate.text =
          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _showLegal(String title, String text) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  text,
                  style: const TextStyle(
                    height: 1.5,
                    color: TpColors.text,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: const Text('Fechar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _input(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
    bool obscureText = false,
    int? maxLength,
    VoidCallback? onTap,
    bool readOnly = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLength: maxLength,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        counterText: '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isProfessional = role == 'professional';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Criar conta',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Como você vai usar o TurnoPronto?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Profissional'),
                      selected: isProfessional,
                      onSelected: (_) =>
                          setState(() => role = 'professional'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Empresa'),
                      selected: !isProfessional,
                      onSelected: (_) => setState(() => role = 'company'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
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
                      fontSize: 12,
                    ),
                  ),
                ),
              _input(
                name,
                isProfessional
                    ? 'Nome completo'
                    : 'Nome completo do responsável',
                keyboardType: TextInputType.name,
              ),
              const SizedBox(height: 12),
              _input(
                phone,
                'WhatsApp com DDD',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              _input(
                email,
                'E-mail',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              if (isProfessional) ...[
                _input(cpf, 'CPF', keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                _input(
                  birthDate,
                  'Data de nascimento',
                  keyboardType: TextInputType.datetime,
                  readOnly: true,
                  onTap: _pickBirthDate,
                ),
                const SizedBox(height: 12),
                _input(headline, 'Atividade principal'),
                const SizedBox(height: 18),
                const Text(
                  'Funções de interesse',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                if (categories.isEmpty)
                  const Text(
                    'Carregando funções...',
                    style: TextStyle(color: TpColors.muted, fontSize: 11),
                  )
                else
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: categories.map((category) {
                      final id =
                          int.tryParse((category['id'] ?? '').toString()) ?? 0;
                      return FilterChip(
                        label: Text(
                          (category['name'] ?? 'Função').toString(),
                        ),
                        selected: selectedCategories.contains(id),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              selectedCategories.add(id);
                            } else {
                              selectedCategories.remove(id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
              ] else ...[
                _input(
                  responsibleCpf,
                  'CPF do responsável',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                _input(cnpj, 'CNPJ', keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                _input(legalName, 'Razão social'),
                const SizedBox(height: 12),
                _input(tradeName, 'Nome fantasia'),
              ],
              const SizedBox(height: 22),
              const Text(
                'Endereço',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              _input(
                postalCode,
                'CEP',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              _input(address, 'Endereço'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _input(city, 'Cidade')),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 90,
                    child: _input(
                      state,
                      'UF',
                      maxLength: 2,
                      keyboardType: TextInputType.text,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                isProfessional
                    ? 'Pix para receber pagamentos'
                    : 'Pix para devoluções/reembolsos',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: pixType,
                decoration: const InputDecoration(
                  labelText: 'Tipo da chave Pix',
                ),
                items: const [
                  DropdownMenuItem(value: 'cpf', child: Text('CPF')),
                  DropdownMenuItem(value: 'cnpj', child: Text('CNPJ')),
                  DropdownMenuItem(value: 'email', child: Text('E-mail')),
                  DropdownMenuItem(value: 'phone', child: Text('Telefone')),
                  DropdownMenuItem(
                    value: 'random',
                    child: Text('Chave aleatória'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => pixType = value);
                },
              ),
              const SizedBox(height: 12),
              _input(pixKey, 'Chave Pix'),
              const SizedBox(height: 12),
              _input(pixHolderName, 'Nome do titular da conta Pix'),
              const SizedBox(height: 12),
              _input(
                pixHolderDocument,
                'CPF/CNPJ do titular Pix',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 22),
              const Text(
                'Segurança da conta',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              _input(password, 'Senha (mínimo 8 caracteres)', obscureText: true),
              const SizedBox(height: 12),
              _input(
                passwordConfirm,
                'Confirmar senha',
                obscureText: true,
              ),
              const SizedBox(height: 18),
              CheckboxListTile(
                value: termsAccepted,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (value) =>
                    setState(() => termsAccepted = value ?? false),
                title: const Text(
                  'Aceito os Termos de Uso',
                  style: TextStyle(fontSize: 13),
                ),
                subtitle: TextButton(
                  style: TextButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: () => _showLegal(
                    'Termos de Uso',
                    'O TurnoPronto conecta empresas e profissionais para turnos pontuais. Os dados informados devem ser verdadeiros. Ao confirmar um turno, as partes assumem o compromisso de cumprir data, horário, valor e condições. Cancelamentos, faltas e atrasos podem gerar registros operacionais e efeitos na reputação, com possibilidade de contestação quando aplicável.',
                  ),
                  child: const Text('Ler Termos'),
                ),
              ),
              CheckboxListTile(
                value: privacyAccepted,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (value) =>
                    setState(() => privacyAccepted = value ?? false),
                title: const Text(
                  'Aceito a Política de Privacidade',
                  style: TextStyle(fontSize: 13),
                ),
                subtitle: TextButton(
                  style: TextButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: () => _showLegal(
                    'Política de Privacidade',
                    'Tratamos dados cadastrais, CPF/CNPJ, contato, endereço, dados Pix, documentos de verificação, histórico de turnos e avaliações para operar e proteger a plataforma. O WhatsApp é usado para validação do número e comunicações transacionais de cadastro, segurança, interesse em vagas e turnos.',
                  ),
                  child: const Text('Ler Política'),
                ),
              ),
              CheckboxListTile(
                value: whatsappConsent,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (value) =>
                    setState(() => whatsappConsent = value ?? false),
                title: const Text(
                  'Autorizo mensagens transacionais no WhatsApp',
                  style: TextStyle(fontSize: 13),
                ),
                subtitle: const Text(
                  'Inclui validação do telefone, segurança, interesse em vagas e informações de turnos.',
                  style: TextStyle(fontSize: 10),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: loading ? null : _submit,
                child: Text(
                  loading
                      ? 'Enviando código...'
                      : 'Continuar e validar WhatsApp',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerifyRegistrationScreen extends StatefulWidget {
  const _VerifyRegistrationScreen({
    required this.api,
    required this.registrationId,
    required this.phoneMasked,
  });

  final ApiService api;
  final String registrationId;
  final String phoneMasked;

  @override
  State<_VerifyRegistrationScreen> createState() =>
      _VerifyRegistrationScreenState();
}

class _VerifyRegistrationScreenState
    extends State<_VerifyRegistrationScreen> {
  final code = TextEditingController();
  bool loading = false;
  String? error;

  @override
  void dispose() {
    code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data = await widget.api.verifyRegistration(
        widget.registrationId,
        code.text.trim(),
      );
      if (!mounted) return;
      final user = data['user'];
      final role = user is Map ? (user['role'] ?? '').toString() : '';
      Navigator.of(context).pop(role);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _resend() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      await widget.api.resendRegistration(widget.registrationId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Novo código enviado por WhatsApp.')),
      );
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Validar WhatsApp')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Icon(
              Icons.verified_user_outlined,
              color: TpColors.blue,
              size: 58,
            ),
            const SizedBox(height: 16),
            const Text(
              'Confirme seu número',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enviamos um código de 6 dígitos para ${widget.phoneMasked}.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: TpColors.muted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
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
                  style: const TextStyle(color: Color(0xFFA12E38)),
                ),
              ),
            TextField(
              controller: code,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 8,
              ),
              decoration: const InputDecoration(
                labelText: 'Código',
                counterText: '',
                hintText: '000000',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: loading ? null : _verify,
              child: Text(loading ? 'Validando...' : 'Validar e concluir'),
            ),
            TextButton(
              onPressed: loading ? null : _resend,
              child: const Text('Reenviar código'),
            ),
          ],
        ),
      ),
    );
  }
}
