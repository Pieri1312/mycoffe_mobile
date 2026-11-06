import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/store.dart';
import '../../core/ui.dart';
import '../cart/cart.dart';
import '../catalog/coffee.dart';
import 'models.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final form = GlobalKey<FormState>();
  final cep = TextEditingController();
  final street = TextEditingController();
  final number = TextEditingController();
  final extra = TextEditingController();
  final district = TextEditingController();
  final city = TextEditingController();
  final uf = TextEditingController();
  int? paymentId;
  bool busy = false;
  String? error;

  @override
  void dispose() {
    for (final field in [cep, street, number, extra, district, city, uf]) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> placeOrder(Cart cart, Payment payment) async {
    if (busy || ref.read(orderNeedsReviewProvider) || !form.currentState!.validate()) return;
    final store = ref.read(storeProvider);
    final session = ref.read(sessionProvider);
    if (!store.demo && session == null) {
      await context.push('/conta?checkout=1');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final receipt = await store.submit(
        cart: cart,
        payment: payment,
        session: session,
        address: Address(
          cep: cep.text.trim(),
          street: street.text.trim(),
          number: number.text.trim(),
          district: district.text.trim(),
          city: city.text.trim(),
          uf: uf.text.trim().toUpperCase(),
          extra: extra.text.trim(),
        ),
      );
      if (!mounted) return;
      context.go('/pedido', extra: receipt);
      ref.read(cartProvider.notifier).clear();
      ref.invalidate(ordersProvider);
    } catch (failure) {
      if (!mounted) return;
      if (expiredSession(failure)) ref.read(sessionProvider.notifier).state = null;
      final checkOrder = !store.demo && unknownOrderResult(failure);
      if (checkOrder) ref.read(orderNeedsReviewProvider.notifier).state = true;
      setState(() {
        error = checkOrder
            ? 'Não foi possível verificar se o pedido foi recebido. Confira Meus pedidos antes de fazer um novo envio.'
            : expiredSession(failure)
                ? 'Sua sessão expirou. Entre novamente para continuar.'
                : errorMessage(failure);
      });
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget field(
    String label,
    TextEditingController controller,
    int max, {
    TextInputType? keyboard,
    String? Function(String)? validate,
    bool optional = false,
    List<TextInputFormatter>? formatters,
    TextCapitalization capitalization = TextCapitalization.sentences,
  }) => TextFormField(
    controller: controller,
    keyboardType: keyboard,
    textCapitalization: capitalization,
    inputFormatters: [
      ...?formatters,
      LengthLimitingTextInputFormatter(max),
    ],
    textInputAction: TextInputAction.next,
    decoration: InputDecoration(
      labelText: label,
      errorMaxLines: 2,
      suffixText: optional ? 'Opcional' : null,
    ),
    validator: (value) {
      final text = (value ?? '').trim();
      if (text.isEmpty && !optional) return 'Obrigatório';
      return validate?.call(text);
    },
  );

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final paymentState = ref.watch(paymentsProvider);
    final demo = ref.watch(storeProvider).demo;
    final signedIn = ref.watch(sessionProvider) != null;
    final uncertain = ref.watch(orderNeedsReviewProvider);
    final options = paymentState.asData?.value ?? const <Payment>[];
    final selected = options.where((option) => option.id == paymentId).firstOrNull;

    return PopScope(
      canPop: !busy,
      child: Scaffold(
        appBar: const ShopHeader('Complete seu pedido'),
        body: PageWidth(
          child: cart.lines.isEmpty
              ? Center(child: TextButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Carrinho vazio. Voltar ao cardápio'),
                ))
              : Form(
                  key: form,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                      if (demo)
                        const Padding(
                          padding: EdgeInsets.fromLTRB(12, 0, 12, 8),
                          child: Text('Demonstração. Nenhum pedido será enviado.'),
                        ),
                      _CheckoutPanel(
                        title: 'Endereço de Entrega',
                        subtitle: 'Informe o endereço onde deseja receber seu pedido',
                        icon: Icons.location_on_outlined,
                        color: Palette.gold,
                        children: [
                          Row(children: [
                            Expanded(flex: 2, child: field(
                              'CEP', cep, 9, keyboard: TextInputType.number,
                              formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9-]'))],
                              validate: (value) => RegExp(r'^\d{5}-?\d{3}$').hasMatch(value)
                                  ? null : 'CEP inválido',
                            )),
                            const SizedBox(width: 8),
                            Expanded(child: field('Número', number, 10)),
                          ]),
                          field('Rua', street, 120),
                          field('Complemento', extra, 60, optional: true),
                          LayoutBuilder(builder: (context, box) {
                            final stateField = field(
                              'UF', uf, 2, capitalization: TextCapitalization.characters,
                              validate: (value) => Address.states.contains(value.toUpperCase())
                                  ? null : 'UF inválida',
                            );
                            if (box.maxWidth < 285 || MediaQuery.textScalerOf(context).scale(14) > 18) {
                              return Column(children: [
                                field('Bairro', district, 60),
                                const SizedBox(height: 8),
                                field('Cidade', city, 60),
                                const SizedBox(height: 8),
                                stateField,
                              ]);
                            }
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 2, child: field('Bairro', district, 60)),
                                const SizedBox(width: 8),
                                Expanded(flex: 2, child: field('Cidade', city, 60)),
                                const SizedBox(width: 8),
                                Expanded(flex: 1, child: stateField),
                              ],
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _CheckoutPanel(
                        title: 'Pagamento',
                        subtitle: 'Escolha a forma que deseja pagar na entrega',
                        icon: Icons.attach_money,
                        color: Palette.softPurple,
                        children: [
                          paymentState.when(
                            loading: () => const LinearProgressIndicator(),
                            error: (error, _) => LoadError(
                              message: errorMessage(error),
                              retry: () => ref.invalidate(paymentsProvider),
                            ),
                            data: (payments) => payments.isEmpty
                                ? const Text('Nenhuma forma de pagamento disponível.')
                                : Column(children: [
                                    for (final payment in payments)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 5),
                                        child: _PaymentTile(
                                          payment: payment,
                                          selected: payment.id == paymentId,
                                          onTap: busy ? null : () => setState(() => paymentId = payment.id),
                                        ),
                                      ),
                                  ]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Column(
                          children: [
                            _SummaryLine('Total de itens', money(cart.subtotal)),
                            _SummaryLine('Entrega estimada', money(deliveryEstimate)),
                            _SummaryLine('Total estimado', money(cart.subtotal + deliveryEstimate)),
                          ],
                        ),
                      ),
                      if (error != null && !uncertain)
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                        ),
                      if (uncertain) ...[
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text(
                            'O envio anterior pode ter sido recebido. Confira Meus pedidos antes de tentar novamente.',
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/pedidos'),
                          child: const Text('Ver meus pedidos'),
                        ),
                      ],
                      ],
                    ),
                  ),
                ),
        ),
        bottomNavigationBar: cart.lines.isEmpty ? null : SafeArea(
          top: false,
          child: PageWidth(child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 8, 32, 14),
            child: ActionButton(
              demo ? 'FINALIZAR DEMONSTRAÇÃO' : signedIn ? 'FINALIZAR PEDIDO' : 'ENTRAR PARA FINALIZAR',
              busy: busy,
              onPressed: uncertain || selected == null ? null : () => placeOrder(cart, selected),
            ),
          )),
        ),
      ),
    );
  }
}

class _CheckoutPanel extends StatelessWidget {
  const _CheckoutPanel({
    required this.title, required this.subtitle, required this.icon,
    required this.color, required this.children,
  });

  final String title, subtitle;
  final IconData icon;
  final Color color;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Palette.panel,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 7),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            )),
          ]),
          const SizedBox(height: 15),
          for (final child in children)
            Padding(padding: const EdgeInsets.only(bottom: 8), child: child),
        ],
      ),
    ),
  );
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({required this.payment, required this.selected, required this.onTap});

  final Payment payment;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    child: Material(
      color: selected ? Palette.lilac : Palette.field,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(color: selected ? Palette.softPurple : Colors.transparent),
      ),
      child: ListTile(
        dense: true,
        minTileHeight: 43,
        leading: Icon(
          payment.code == 'DINHEIRO' ? Icons.payments_outlined : Icons.credit_card,
          color: Palette.softPurple, size: 20,
        ),
        title: Text(payment.label.toUpperCase(), style: const TextStyle(fontSize: 11)),
        onTap: onTap,
      ),
    ),
  );
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine(this.label, this.value);
  final String label, value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    ),
  );
}
