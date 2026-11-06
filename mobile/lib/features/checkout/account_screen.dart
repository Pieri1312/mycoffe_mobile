import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/store.dart';
import '../../core/ui.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key, required this.fromCheckout});
  final bool fromCheckout;

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  bool registering = false;
  bool busy = false;
  String? error;

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> authenticate() async {
    if (busy || !form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final session = await ref.read(storeProvider).authenticate(
        email.text.trim(),
        password.text,
        name: registering ? name.text.trim() : null,
      );
      if (!mounted) return;
      password.clear();
      ref.read(sessionProvider.notifier).state = session;
      if (widget.fromCheckout && context.canPop()) context.pop();
    } catch (failure) {
      if (mounted) setState(() => error = errorMessage(failure));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final demo = ref.watch(storeProvider).demo;
    return Scaffold(
      appBar: const ShopHeader('Minha conta'),
      body: PageWidth(
        child: ListView(
          padding: const EdgeInsets.all(32),
          children: [
            if (demo)
              const Text('Conta disponível no modo conectado.')
            else if (session != null) ...[
              Text('Olá, ${session.name}', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              ActionButton('MEUS PEDIDOS', onPressed: () => context.push('/pedidos')),
              TextButton(
                onPressed: () {
                  ref.read(sessionProvider.notifier).state = null;
                },
                child: const Text('Sair'),
              ),
            ] else
              AutofillGroup(
                child: Form(
                  key: form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(registering ? 'Crie sua conta' : 'Acesse sua conta',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 20),
                      if (registering) ...[
                        TextFormField(
                          controller: name,
                          enabled: !busy,
                          autofillHints: const [AutofillHints.name],
                          maxLength: 100,
                          decoration: const InputDecoration(labelText: 'Nome', counterText: ''),
                          validator: (value) => (value ?? '').trim().length < 2
                              ? 'Informe seu nome.' : null,
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextFormField(
                        controller: email,
                        enabled: !busy,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(labelText: 'E-mail'),
                        validator: (value) => RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                            .hasMatch((value ?? '').trim()) ? null : 'E-mail inválido.',
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: password,
                        enabled: !busy,
                        obscureText: true,
                        autofillHints: [registering ? AutofillHints.newPassword : AutofillHints.password],
                        decoration: const InputDecoration(labelText: 'Senha'),
                        onFieldSubmitted: (_) => authenticate(),
                        validator: (value) {
                          final text = value ?? '';
                          if (text.isEmpty || text.length > 72) return 'Informe uma senha de até 72 caracteres.';
                          if (registering && !RegExp(r'^(?=.*[A-Za-z])(?=.*\d).{8,}$').hasMatch(text)) {
                            return 'Use pelo menos 8 caracteres, incluindo letras e números.';
                          }
                          return null;
                        },
                      ),
                      if (error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                        ),
                      const SizedBox(height: 16),
                      ActionButton(registering ? 'CADASTRAR' : 'ENTRAR',
                          busy: busy, onPressed: authenticate),
                      TextButton(
                        onPressed: busy ? null : () => setState(() {
                          registering = !registering;
                          error = null;
                        }),
                        child: Text(registering ? 'Já tenho conta' : 'Criar conta'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
