import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/store.dart';
import '../../core/ui.dart';
import '../cart/cart.dart';
import '../catalog/coffee.dart';
import 'models.dart';

class SuccessScreen extends ConsumerWidget {
  const SuccessScreen(this.receipt, {super.key, this.historical = false});

  final Receipt receipt;
  final bool historical;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demo = ref.watch(storeProvider).demo;
    final address = receipt.address;
    return Scaffold(
      appBar: historical ? const ShopHeader('Detalhes do pedido') : null,
      body: SafeArea(
        child: PageWidth(
          child: LayoutBuilder(
            builder: (context, box) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: (box.maxHeight - 48).clamp(0.0, double.infinity).toDouble()),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!historical) ...[
                      Image.asset('assets/delivery.png', width: 245, excludeFromSemantics: true),
                      const SizedBox(height: 24),
                    ],
                    Text(
                      historical ? receipt.statusLabel
                          : demo ? 'Demonstração concluída' : 'Uhu! Pedido confirmado',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: Palette.gold),
                    ),
                    const SizedBox(height: 8),
                    if (!historical)
                      Text(
                        demo ? 'Nenhum pedido foi enviado.'
                            : 'Agora é só aguardar que logo o café chegará até você!',
                        textAlign: TextAlign.center,
                      ),
                    if (!demo) ...[
                      const SizedBox(height: 16),
                      SelectableText('Pedido ${receipt.code}', textAlign: TextAlign.center),
                    ],
                    const SizedBox(height: 12),
                    Text(money(receipt.total), style: const TextStyle(fontWeight: FontWeight.w800)),
                    if (historical && address != null) ...[
                      const SizedBox(height: 8),
                      Text('${address.street}, ${address.number} · ${address.city} – ${address.uf}',
                          textAlign: TextAlign.center),
                    ],
                    if (!historical || receipt.status == 'CONFIRMADO' || receipt.status == 'EM_PREPARO')
                      Text('Previsão: ${receipt.minMinutes}–${receipt.maxMinutes} min'),
                    Text('Na entrega: ${receipt.payment.label}'),
                    const SizedBox(height: 24),
                    if (!historical)
                      ActionButton('IR PARA A HOME', onPressed: () => context.go('/')),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final orders = ref.watch(ordersProvider);
    final needsReview = ref.watch(orderNeedsReviewProvider);
    return Scaffold(
      appBar: const ShopHeader('Meus pedidos'),
      body: PageWidth(
        child: session == null
            ? Center(child: TextButton(
                onPressed: () => context.push('/conta'),
                child: const Text('Entre para ver seus pedidos'),
              ))
            : orders.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: LoadError(
                  message: expiredSession(error) ? 'Sua sessão expirou.' : errorMessage(error),
                  retry: () {
                    if (expiredSession(error)) {
                      ref.read(sessionProvider.notifier).state = null;
                    }
                    ref.invalidate(ordersProvider);
                  },
                )),
                data: (receipts) => Column(
                  children: [
                    if (needsReview)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text(
                              'Confira se o pedido do envio anterior aparece abaixo.',
                              textAlign: TextAlign.center,
                            ),
                            TextButton(
                              onPressed: () {
                                ref.read(orderNeedsReviewProvider.notifier).state = false;
                                ref.read(cartProvider.notifier).clear();
                                context.go('/');
                              },
                              child: const Text('Pedido encontrado. Limpar carrinho'),
                            ),
                            TextButton(
                              onPressed: () {
                                ref.read(orderNeedsReviewProvider.notifier).state = false;
                                if (context.canPop()) context.pop();
                              },
                              child: const Text('Pedido não encontrado. Liberar novo envio'),
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(ordersProvider);
                          try {
                            await ref.read(ordersProvider.future);
                          } catch (_) {
                            // The provider's error state offers retry.
                          }
                        },
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            if (receipts.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(24),
                                child: Center(child: Text('Nenhum pedido encontrado.')),
                              ),
                            for (final order in receipts) ...[
                              ListTile(
                                title: Text(order.statusLabel),
                                subtitle: Text(order.code),
                                trailing: Text(money(order.total)),
                                onTap: () => context.push('/pedidos/detalhe', extra: order),
                              ),
                              const Divider(height: 1),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
