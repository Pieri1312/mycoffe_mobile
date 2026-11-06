import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/ui.dart';
import '../catalog/coffee.dart';
import 'cart.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final controller = ref.read(cartProvider.notifier);
    return Scaffold(
      appBar: const ShopHeader('Carrinho'),
      body: PageWidth(
        child: cart.lines.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shopping_cart_outlined, size: 48, color: Palette.softPurple),
                      const SizedBox(height: 16),
                      const Text('Seu carrinho está vazio.'),
                      const SizedBox(height: 12),
                      ActionButton('VER CARDÁPIO', onPressed: () => context.go('/')),
                    ],
                  ),
                ),
              )
            : ListView.separated(
                itemCount: cart.lines.length,
                separatorBuilder: (_, _) => const Divider(height: 1, color: Palette.field),
                itemBuilder: (context, index) {
                  final line = cart.lines[index];
                  void remove() {
                    controller.change(line.coffee, line.milliliters, -line.quantity);
                  }
                  void change(int delta) {
                    if (!controller.change(line.coffee, line.milliliters, delta)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Limite de 99 unidades por café.')),
                      );
                    }
                  }
                  return Dismissible(
                    key: ValueKey(line.key),
                    direction: DismissDirection.startToEnd,
                    background: const ColoredBox(
                      color: Color(0xfff1ded4),
                      child: Align(alignment: Alignment.centerLeft,
                          child: Padding(padding: EdgeInsets.all(24),
                              child: Icon(Icons.delete_outline, color: Color(0xffa94c37)))),
                    ),
                    onDismissed: (_) => remove(),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 13, 24, 13),
                      child: Row(
                        children: [
                          CoffeePhoto(line.coffee, size: 61),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: Text(line.coffee.name)),
                                    const SizedBox(width: 8),
                                    Text(money(line.subtotal),
                                        style: const TextStyle(fontWeight: FontWeight.w800)),
                                  ],
                                ),
                                Text('${line.milliliters}ml', style: Theme.of(context).textTheme.bodySmall),
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    QuantityControl(
                                      value: line.quantity,
                                      onDecrease: () => change(-1),
                                      onIncrease: () => change(1),
                                    ),
                                    IconButton(
                                      tooltip: 'Remover ${line.coffee.name}',
                                      onPressed: remove,
                                      icon: const Icon(Icons.delete_outline,
                                          color: Palette.softPurple, size: 19),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      bottomNavigationBar: cart.lines.isEmpty ? null : SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(color: Colors.white, boxShadow: [
            BoxShadow(color: Color(0x13000000), blurRadius: 14, offset: Offset(0, -2)),
          ]),
          child: PageWidth(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 20, 32, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Valor total'),
                    Text(money(cart.subtotal), style: const TextStyle(fontWeight: FontWeight.w800)),
                  ]),
                  const SizedBox(height: 14),
                  ActionButton('CONFIRMAR PEDIDO', onPressed: () => context.push('/checkout')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
