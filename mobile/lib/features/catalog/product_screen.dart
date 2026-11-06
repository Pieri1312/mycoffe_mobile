import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/store.dart';
import '../../core/ui.dart';
import '../cart/cart.dart';
import 'catalog_screen.dart';
import 'coffee.dart';

class ProductScreen extends ConsumerStatefulWidget {
  const ProductScreen(this.coffee, {super.key});
  final Coffee coffee;

  @override
  ConsumerState<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends ConsumerState<ProductScreen> {
  int size = 227;
  int quantity = 1;

  @override
  Widget build(BuildContext context) {
    final coffee = widget.coffee;
    final demo = ref.watch(storeProvider).demo;
    final remaining = 99 - ref.watch(cartProvider).lines
        .where((line) => line.coffee.id == coffee.id)
        .fold<int>(0, (sum, line) => sum + line.quantity);
    return Scaffold(
      appBar: const ShopHeader('', dark: true, actions: [CartIcon()]),
      body: PageWidth(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                color: Palette.dark,
                padding: const EdgeInsets.fromLTRB(32, 20, 32, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CategoryLabel(coffee.category, dark: true),
                    const SizedBox(height: 9),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: Text(coffee.name, style: const TextStyle(
                          color: Colors.white, fontSize: 23, fontWeight: FontWeight.w800,
                        ))),
                        const SizedBox(width: 10),
                        Text(money(coffee.cents), style: const TextStyle(
                          color: Palette.yellow, fontSize: 23, fontWeight: FontWeight.w900,
                        )),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(coffee.description, style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: ColoredBox(
                color: Palette.dark,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                        stops: [.91, .91], colors: [Palette.dark, Palette.canvas],
                      ),
                    ),
                    height: 290,
                    child: Center(
                      child: normalized(coffee.name) == 'irlandes'
                          ? Image.asset('assets/product-irlandes.png', fit: BoxFit.contain, height: 290)
                          : CoffeePhoto(coffee, size: 248),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: PageWidth(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 20, 32, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(demo ? 'Selecione o tamanho:' : 'Tamanho padrão'),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final option in [114, 140, 227])
                      ChoiceChip(
                        label: Text('${option}ml'),
                        selected: size == option,
                        showCheckmark: false,
                        selectedColor: Palette.lilac,
                        onSelected: demo || option == 227
                            ? (_) => setState(() => size = option)
                            : null,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    QuantityControl(
                      value: quantity,
                      onDecrease: quantity > 1 ? () => setState(() => quantity--) : null,
                      onIncrease: quantity < remaining ? () => setState(() => quantity++) : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: ActionButton(
                      'ADICIONAR',
                      color: Palette.purple,
                      onPressed: quantity > remaining ? null : () {
                        final added = ref.read(cartProvider.notifier).change(coffee, size, quantity);
                        final messenger = ScaffoldMessenger.of(context);
                        messenger.hideCurrentSnackBar();
                        messenger.showSnackBar(SnackBar(
                          content: Text(added ? 'Adicionado ao carrinho.' : 'Limite do carrinho atingido.'),
                        ));
                        if (added) setState(() => quantity = 1);
                      },
                    )),
                  ],
                ),
                if (remaining == 0) const Text('Limite de 99 unidades por café atingido.'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
