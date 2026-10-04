import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final rg = TextEditingController();
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

  final Map<String, FocusNode> _focus = {
    'name': FocusNode(),
    'phone': FocusNode(),
    'email': FocusNode(),
    'cpf': FocusNode(),
    'rg': FocusNode(),
    'birthDate': FocusNode(),
    'headline': FocusNode(),
    'cnpj': FocusNode(),
    'responsibleCpf': FocusNode(),
    'legalName': FocusNode(),
    'tradeName': FocusNode(),
    'postalCode': FocusNode(),
    'address': FocusNode(),
    'city': FocusNode(),
    'state': FocusNode(),
    'pixKey': FocusNode(),
    'pixHolderName': FocusNode(),
    'pixHolderDocument': FocusNode(),
    'password': FocusNode(),
    'passwordConfirm': FocusNode(),
  };

  final _categoriesKey = GlobalKey();
  final _termsKey = GlobalKey();
  final _privacyKey = GlobalKey();
  final _whatsappKey = GlobalKey();

  String role = 'professional';
  String pixType = 'cpf';
  bool termsAccepted = false;
  bool privacyAccepted = false;
  bool whatsappConsent = false;
  bool passwordVisible = false;
  bool passwordConfirmVisible = false;
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
      rg,
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
    for (final node in _focus.values) {
      node.dispose();
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
        'rg': rg.text.trim(),
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

  String _digits(String value) => value.replaceAll(RegExp(r'\D'), '');

  String _rgValue(String value) =>
      value.toUpperCase().replaceAll(RegExp(r'[^0-9A-Z]'), '');

  bool _validEmail(String value) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim());

  bool _validCpf(String value) {
    final d = _digits(value);
    if (d.length != 11 || RegExp(r'^(\d)\1{10}$').hasMatch(d)) return false;
    for (var t = 9; t < 11; t++) {
      var sum = 0;
      for (var i = 0; i < t; i++) {
        sum += int.parse(d[i]) * ((t + 1) - i);
      }
      final digit = ((10 * sum) % 11) % 10;
      if (int.parse(d[t]) != digit) return false;
    }
    return true;
  }

  bool _validCnpj(String value) {
    final d = _digits(value);
    if (d.length != 14 || RegExp(r'^(\d)\1{13}$').hasMatch(d)) return false;

    int calc(String base, List<int> weights) {
      var sum = 0;
      for (var i = 0; i < weights.length; i++) {
        sum += int.parse(base[i]) * weights[i];
      }
      final rest = sum % 11;
      return rest < 2 ? 0 : 11 - rest;
    }

    final d1 = calc(d, const [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]);
    if (int.parse(d[12]) != d1) return false;
    final d2 = calc(d, const [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]);
    return int.parse(d[13]) == d2;
  }

  void _validationError(
    String message, {
    FocusNode? focusNode,
    GlobalKey? targetKey,
  }) {
    setState(() => error = message);
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      focusNode?.requestFocus();
      final targetContext = targetKey?.currentContext;
      if (targetContext != null) {
        Scrollable.ensureVisible(
          targetContext,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
          alignment: 0.2,
        );
      }
    });
  }

  bool _validateBeforeSubmit() {
    if (name.text.trim().length < 3) {
      _validationError(
        role == 'professional'
            ? 'Informe seu nome completo.'
            : 'Informe o nome completo do responsável.',
        focusNode: _focus['name'],
      );
      return false;
    }

    final phoneDigits = _digits(phone.text);
    if (phoneDigits.length != 10 && phoneDigits.length != 11) {
      _validationError(
        'Informe um WhatsApp válido com DDD.',
        focusNode: _focus['phone'],
      );
      return false;
    }

    if (!_validEmail(email.text)) {
      _validationError('Informe um e-mail válido.', focusNode: _focus['email']);
      return false;
    }

    if (role == 'professional') {
      if (!_validCpf(cpf.text)) {
        _validationError('CPF inválido.', focusNode: _focus['cpf']);
        return false;
      }
      final cleanRg = _rgValue(rg.text);
      if (cleanRg.length < 7 || cleanRg.length > 12) {
        _validationError('Informe um RG válido.', focusNode: _focus['rg']);
        return false;
      }
      if (birthDate.text.trim().isEmpty) {
        _validationError(
          'Informe sua data de nascimento.',
          focusNode: _focus['birthDate'],
        );
        return false;
      }
      if (headline.text.trim().isEmpty) {
        _validationError(
          'Informe sua atividade principal.',
          focusNode: _focus['headline'],
        );
        return false;
      }
      if (selectedCategories.isEmpty) {
        _validationError(
          'Selecione pelo menos uma função de interesse.',
          targetKey: _categoriesKey,
        );
        return false;
      }
    } else {
      if (!_validCpf(responsibleCpf.text)) {
        _validationError(
          'CPF do responsável inválido.',
          focusNode: _focus['responsibleCpf'],
        );
        return false;
      }
      if (!_validCnpj(cnpj.text)) {
        _validationError('CNPJ inválido.', focusNode: _focus['cnpj']);
        return false;
      }
      if (legalName.text.trim().isEmpty) {
        _validationError(
          'Informe a razão social.',
          focusNode: _focus['legalName'],
        );
        return false;
      }
      if (tradeName.text.trim().isEmpty) {
        _validationError(
          'Informe o nome fantasia.',
          focusNode: _focus['tradeName'],
        );
        return false;
      }
    }

    if (_digits(postalCode.text).length != 8) {
      _validationError('Informe um CEP válido.', focusNode: _focus['postalCode']);
      return false;
    }
    if (address.text.trim().isEmpty) {
      _validationError('Informe o endereço.', focusNode: _focus['address']);
      return false;
    }
    if (city.text.trim().isEmpty) {
      _validationError('Informe a cidade.', focusNode: _focus['city']);
      return false;
    }
    if (!RegExp(r'^[A-Za-z]{2}$').hasMatch(state.text.trim())) {
      _validationError('Informe a UF com 2 letras.', focusNode: _focus['state']);
      return false;
    }

    if (pixKey.text.trim().isEmpty) {
      _validationError('Informe a chave Pix.', focusNode: _focus['pixKey']);
      return false;
    }
    if (pixType == 'cpf' && !_validCpf(pixKey.text)) {
      _validationError('A chave Pix CPF é inválida.', focusNode: _focus['pixKey']);
      return false;
    }
    if (pixType == 'cnpj' && !_validCnpj(pixKey.text)) {
      _validationError('A chave Pix CNPJ é inválida.', focusNode: _focus['pixKey']);
      return false;
    }
    if (pixType == 'email' && !_validEmail(pixKey.text)) {
      _validationError(
        'A chave Pix de e-mail é inválida.',
        focusNode: _focus['pixKey'],
      );
      return false;
    }
    if (pixType == 'phone') {
      final pixPhoneDigits = _digits(pixKey.text);
      if (pixPhoneDigits.length != 10 && pixPhoneDigits.length != 11) {
        _validationError(
          'A chave Pix de telefone é inválida.',
          focusNode: _focus['pixKey'],
        );
        return false;
      }
    }

    if (pixHolderName.text.trim().length < 3) {
      _validationError(
        'Informe o nome do titular da conta Pix.',
        focusNode: _focus['pixHolderName'],
      );
      return false;
    }

    final holderDigits = _digits(pixHolderDocument.text);
    if (holderDigits.length == 11) {
      if (!_validCpf(holderDigits)) {
        _validationError(
          'CPF do titular do Pix inválido.',
          focusNode: _focus['pixHolderDocument'],
        );
        return false;
      }
    } else if (holderDigits.length == 14) {
      if (!_validCnpj(holderDigits)) {
        _validationError(
          'CNPJ do titular do Pix inválido.',
          focusNode: _focus['pixHolderDocument'],
        );
        return false;
      }
    } else {
      _validationError(
        'Informe o CPF ou CNPJ do titular do Pix.',
        focusNode: _focus['pixHolderDocument'],
      );
      return false;
    }

    if (password.text.length < 8) {
      _validationError(
        'A senha deve ter pelo menos 8 caracteres.',
        focusNode: _focus['password'],
      );
      return false;
    }
    if (passwordConfirm.text.isEmpty) {
      _validationError(
        'Confirme a senha digitada.',
        focusNode: _focus['passwordConfirm'],
      );
      return false;
    }
    if (password.text != passwordConfirm.text) {
      _validationError(
        'As senhas não coincidem.',
        focusNode: _focus['passwordConfirm'],
      );
      return false;
    }

    if (!termsAccepted) {
      _validationError(
        'Aceite os Termos de Uso para continuar.',
        targetKey: _termsKey,
      );
      return false;
    }
    if (!privacyAccepted) {
      _validationError(
        'Aceite a Política de Privacidade para continuar.',
        targetKey: _privacyKey,
      );
      return false;
    }
    if (!whatsappConsent) {
      _validationError(
        'Autorize as mensagens transacionais no WhatsApp para continuar.',
        targetKey: _whatsappKey,
      );
      return false;
    }

    return true;
  }

  List<TextInputFormatter>? _pixKeyFormatters() {
    switch (pixType) {
      case 'cpf':
        return [const _DigitsMaskFormatter('###.###.###-##', 11)];
      case 'cnpj':
        return [const _DigitsMaskFormatter('##.###.###/####-##', 14)];
      case 'phone':
        return [const _DigitsMaskFormatter('(##) #####-####', 11)];
      default:
        return null;
    }
  }

  TextInputType _pixKeyKeyboardType() {
    switch (pixType) {
      case 'cpf':
      case 'cnpj':
      case 'phone':
        return TextInputType.number;
      case 'email':
        return TextInputType.emailAddress;
      default:
        return TextInputType.text;
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_validateBeforeSubmit()) return;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final result = await widget.api.startRegistration(_payload());
      if (!mounted) return;
      final registrationId = (result['registration_id'] ?? '').toString();
      final phoneMasked = (result['phone_masked'] ?? phone.text).toString();
      final developmentBypass = result['development_bypass'] == true;
      final developmentCode =
          (result['development_code'] ?? '000111').toString();

      final verifiedRole = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (_) => _VerifyRegistrationScreen(
            api: widget.api,
            registrationId: registrationId,
            phoneMasked: phoneMasked,
            developmentBypass: developmentBypass,
            developmentCode: developmentCode,
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
      if (mounted) _validationError(e.toString());
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
    FocusNode? focusNode,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffixIcon,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLength: maxLength,
      readOnly: readOnly,
      onTap: onTap,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        counterText: '',
        suffixIcon: suffixIcon,
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
                    ? 'Nome completo *'
                    : 'Nome completo do responsável *',
                keyboardType: TextInputType.name,
                focusNode: _focus['name'],
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              _input(
                phone,
                'WhatsApp com DDD *',
                keyboardType: TextInputType.phone,
                focusNode: _focus['phone'],
                inputFormatters: const [
                  _DigitsMaskFormatter('(##) #####-####', 11),
                ],
              ),
              const SizedBox(height: 12),
              _input(
                email,
                'E-mail *',
                keyboardType: TextInputType.emailAddress,
                focusNode: _focus['email'],
              ),
              const SizedBox(height: 12),
              if (isProfessional) ...[
                _input(
                  cpf,
                  'CPF *',
                  keyboardType: TextInputType.number,
                  focusNode: _focus['cpf'],
                  inputFormatters: const [
                    _DigitsMaskFormatter('###.###.###-##', 11),
                  ],
                ),
                const SizedBox(height: 12),
                _input(
                  rg,
                  'RG *',
                  keyboardType: TextInputType.text,
                  focusNode: _focus['rg'],
                  inputFormatters: const [_RgMaskFormatter()],
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 12),
                _input(
                  birthDate,
                  'Data de nascimento *',
                  keyboardType: TextInputType.datetime,
                  readOnly: true,
                  focusNode: _focus['birthDate'],
                  onTap: _pickBirthDate,
                ),
                const SizedBox(height: 12),
                _input(
                  headline,
                  'Atividade principal *',
                  focusNode: _focus['headline'],
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 18),
                Text(
                  'Funções de interesse *',
                  key: _categoriesKey,
                  style: const TextStyle(fontWeight: FontWeight.w800),
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
                  'CPF do responsável *',
                  keyboardType: TextInputType.number,
                  focusNode: _focus['responsibleCpf'],
                  inputFormatters: const [
                    _DigitsMaskFormatter('###.###.###-##', 11),
                  ],
                ),
                const SizedBox(height: 12),
                _input(
                  cnpj,
                  'CNPJ *',
                  keyboardType: TextInputType.number,
                  focusNode: _focus['cnpj'],
                  inputFormatters: const [
                    _DigitsMaskFormatter('##.###.###/####-##', 14),
                  ],
                ),
                const SizedBox(height: 12),
                _input(
                  legalName,
                  'Razão social *',
                  focusNode: _focus['legalName'],
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                _input(
                  tradeName,
                  'Nome fantasia *',
                  focusNode: _focus['tradeName'],
                  textCapitalization: TextCapitalization.words,
                ),
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
                'CEP *',
                keyboardType: TextInputType.number,
                focusNode: _focus['postalCode'],
                inputFormatters: const [
                  _DigitsMaskFormatter('#####-###', 8),
                ],
              ),
              const SizedBox(height: 12),
              _input(
                address,
                'Endereço *',
                focusNode: _focus['address'],
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _input(
                      city,
                      'Cidade *',
                      focusNode: _focus['city'],
                      textCapitalization: TextCapitalization.words,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 90,
                    child: _input(
                      state,
                      'UF *',
                      maxLength: 2,
                      keyboardType: TextInputType.text,
                      focusNode: _focus['state'],
                      inputFormatters: const [_UpperCaseFormatter()],
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
                  if (value != null && value != pixType) {
                    setState(() {
                      pixType = value;
                      pixKey.clear();
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              _input(
                pixKey,
                'Chave Pix *',
                keyboardType: _pixKeyKeyboardType(),
                focusNode: _focus['pixKey'],
                inputFormatters: _pixKeyFormatters(),
              ),
              const SizedBox(height: 12),
              _input(
                pixHolderName,
                'Nome do titular da conta Pix *',
                focusNode: _focus['pixHolderName'],
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              _input(
                pixHolderDocument,
                'CPF/CNPJ do titular Pix *',
                keyboardType: TextInputType.number,
                focusNode: _focus['pixHolderDocument'],
                inputFormatters: const [_CpfCnpjFormatter()],
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
              _input(
                password,
                'Senha (mínimo 8 caracteres) *',
                obscureText: !passwordVisible,
                focusNode: _focus['password'],
                suffixIcon: IconButton(
                  tooltip: passwordVisible ? 'Ocultar senha' : 'Mostrar senha',
                  onPressed: () =>
                      setState(() => passwordVisible = !passwordVisible),
                  icon: Icon(
                    passwordVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _input(
                passwordConfirm,
                'Confirmar senha *',
                obscureText: !passwordConfirmVisible,
                focusNode: _focus['passwordConfirm'],
                suffixIcon: IconButton(
                  tooltip: passwordConfirmVisible
                      ? 'Ocultar confirmação'
                      : 'Mostrar confirmação',
                  onPressed: () => setState(
                    () => passwordConfirmVisible = !passwordConfirmVisible,
                  ),
                  icon: Icon(
                    passwordConfirmVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              CheckboxListTile(
                key: _termsKey,
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
                key: _privacyKey,
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
                key: _whatsappKey,
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
    required this.developmentBypass,
    required this.developmentCode,
  });

  final ApiService api;
  final String registrationId;
  final String phoneMasked;
  final bool developmentBypass;
  final String developmentCode;

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
        SnackBar(
          content: Text(
            widget.developmentBypass
                ? 'Modo de desenvolvimento: use o código ' +
                    widget.developmentCode +
                    '. Nenhum WhatsApp foi enviado.'
                : 'Novo código enviado por WhatsApp.',
          ),
        ),
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
              widget.developmentBypass
                  ? 'Modo de desenvolvimento ativo. Nenhuma mensagem foi enviada para ' +
                      widget.phoneMasked +
                      '. Digite o código fixo ' +
                      widget.developmentCode +
                      ' para validar o fluxo.'
                  : 'Enviamos um código de 6 dígitos para ' +
                      widget.phoneMasked +
                      '.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: widget.developmentBypass
                    ? const Color(0xFFA06B00)
                    : TpColors.muted,
                height: 1.4,
                fontWeight: widget.developmentBypass
                    ? FontWeight.w700
                    : FontWeight.normal,
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
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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


class _DigitsMaskFormatter extends TextInputFormatter {
  const _DigitsMaskFormatter(this.mask, this.maxDigits);

  final String mask;
  final int maxDigits;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > maxDigits) digits = digits.substring(0, maxDigits);

    final buffer = StringBuffer();
    var digitIndex = 0;
    for (var i = 0; i < mask.length && digitIndex < digits.length; i++) {
      if (mask[i] == '#') {
        buffer.write(digits[digitIndex++]);
      } else {
        buffer.write(mask[i]);
      }
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _CpfCnpjFormatter extends TextInputFormatter {
  const _CpfCnpjFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 14) digits = digits.substring(0, 14);

    final formatter = digits.length <= 11
        ? const _DigitsMaskFormatter('###.###.###-##', 11)
        : const _DigitsMaskFormatter('##.###.###/####-##', 14);

    return formatter.formatEditUpdate(
      oldValue,
      TextEditingValue(
        text: digits,
        selection: TextSelection.collapsed(offset: digits.length),
      ),
    );
  }
}

class _RgMaskFormatter extends TextInputFormatter {
  const _RgMaskFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var raw = newValue.text
        .toUpperCase()
        .replaceAll(RegExp(r'[^0-9A-Z]'), '');
    if (raw.length > 9) raw = raw.substring(0, 9);

    final buffer = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      if (i == 2 || i == 5) buffer.write('.');
      if (i == 8) buffer.write('-');
      buffer.write(raw[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  const _UpperCaseFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z]'), '');
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
