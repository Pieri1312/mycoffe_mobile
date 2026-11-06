import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/store.dart';
import '../../core/ui.dart';
import 'coffee.dart';

class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  String search = '';
  String? category;
  static const groups = ['Tradicionais', 'Doces', 'Especiais'];

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(catalogProvider);
    final recommendations = ref.watch(recommendationsProvider);
    final demo = ref.watch(storeProvider).demo;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Palette.dark,
        foregroundColor: Colors.white,
        scrolledUnderElevation: 0,
        titleSpacing: 24,
        title: const Row(
          children: [
            Icon(Icons.location_on_rounded, color: Palette.softPurple, size: 20),
            SizedBox(width: 5),
            Text('Mauá, SP', style: TextStyle(fontSize: 13)),
          ],
        ),
        actions: [
          if (demo)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 124),
                child: const Center(
                  child: Text(
                    'Modo demonstração',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Palette.yellow, fontSize: 11),
                  ),
                ),
              ),
            )
          else
            IconButton(
              tooltip: 'Minha conta',
              onPressed: () => context.push('/conta'),
              icon: const Icon(Icons.person_outline),
            ),
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: CartIcon(color: Palette.yellow),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: PageWidth(
          child: ListView(
            children: [
              ColoredBox(
                color: Palette.dark,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Encontre o café perfeito para qualquer hora do dia',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          height: 1.23,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        style: const TextStyle(color: Colors.white),
                        onChanged: (value) => setState(() => search = normalized(value.trim())),
                        decoration: const InputDecoration(
                          hintText: 'Pesquisar',
                          hintStyle: TextStyle(color: Colors.white70),
                          prefixIcon: Icon(Icons.search, color: Colors.white70, size: 19),
                          fillColor: Palette.darkField,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (search.isEmpty)
                recommendations.when(
                  data: (items) => items.isEmpty ? const SizedBox.shrink() : _Recommendations(items),
                  error: (error, _) => LoadError(
                    message: 'Recomendações indisponíveis.',
                    retry: () => ref.invalidate(recommendationsProvider),
                  ),
                  loading: () => const LinearProgressIndicator(),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 32, 32, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nossos cafés', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 7,
                      children: [
                        for (final group in groups)
                          FilterChip(
                            label: Text(group.toUpperCase()),
                            labelStyle: const TextStyle(fontSize: 10, color: Palette.purple),
                            selected: category == group,
                            selectedColor: Palette.lilac,
                            showCheckmark: false,
                            side: const BorderSide(color: Palette.softPurple),
                            shape: const StadiumBorder(),
                            onSelected: (selected) => setState(() => category = selected ? group : null),
                          ),
                      ],
                    ),
                    catalog.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (error, _) => LoadError(
                        message: errorMessage(error),
                        retry: () => ref.invalidate(catalogProvider),
                      ),
                      data: (items) {
                        final filtered = items.where((item) =>
                            (category == null || category == item.category) &&
                            normalized('${item.name} ${item.description}').contains(search)).toList();
                        if (filtered.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Text('Nenhum café encontrado.'),
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final group in groups)
                              if (filtered.any((item) => item.category == group)) ...[
                                Padding(
                                  padding: const EdgeInsets.only(top: 20, bottom: 12),
                                  child: Text(group, style: Theme.of(context).textTheme.bodySmall),
                                ),
                                for (final item in filtered.where((coffee) => coffee.category == group))
                                  _CatalogRow(item),
                              ],
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void openCoffee(BuildContext context, Coffee coffee) {
  context.push('/cafe/${coffee.id}', extra: coffee);
}

class _Recommendations extends StatelessWidget {
  const _Recommendations(this.items);
  final List<Coffee> items;

  @override
  Widget build(BuildContext context) => Container(
    height: 285 + (MediaQuery.textScalerOf(context).scale(14) - 14).clamp(0, 42).toDouble() * 5,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: [.42, .42],
        colors: [Palette.dark, Palette.canvas],
      ),
    ),
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(width: 22),
      itemBuilder: (context, index) {
        final coffee = items[index];
        return SizedBox(
          width: 205,
          child: InkWell(
            borderRadius: BorderRadius.circular(26),
            onTap: () => openCoffee(context, coffee),
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Positioned.fill(
                  top: 32,
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      color: Palette.panel,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(9),
                        topRight: Radius.circular(34),
                        bottomLeft: Radius.circular(34),
                        bottomRight: Radius.circular(9),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 100, 12, 12),
                      child: Column(
                        children: [
                          CategoryLabel(coffee.category),
                          const SizedBox(height: 9),
                          Text(coffee.name, style: Theme.of(context).textTheme.titleMedium,
                              textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 5),
                          Expanded(
                            child: Text(
                              coffee.description,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(money(coffee.cents), style: const TextStyle(
                            color: Palette.gold, fontWeight: FontWeight.w900, fontSize: 19,
                          )),
                        ],
                      ),
                    ),
                  ),
                ),
                CoffeePhoto(coffee, size: 116),
              ],
            ),
          ),
        );
      },
    ),
  );
}

class CategoryLabel extends StatelessWidget {
  const CategoryLabel(this.category, {super.key, this.dark = false});
  final String category;
  final bool dark;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: dark ? Palette.darkField : Palette.lilac,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Text(
        switch (category) {
          'Tradicionais' => 'TRADICIONAL',
          'Doces' => 'DOCE',
          'Especiais' => 'ESPECIAL',
          _ => category.toUpperCase(),
        },
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: dark ? Colors.white : Palette.purple,
        ),
      ),
    ),
  );
}

class _CatalogRow extends StatelessWidget {
  const _CatalogRow(this.coffee);
  final Coffee coffee;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Material(
      color: Palette.panel,
      borderRadius: const BorderRadius.only(topRight: Radius.circular(34),
          bottomLeft: Radius.circular(34), topLeft: Radius.circular(8), bottomRight: Radius.circular(8)),
      child: InkWell(
        onTap: () => openCoffee(context, coffee),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CoffeePhoto(coffee, size: 84),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(coffee.name, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(coffee.description, style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 7),
                    Text(money(coffee.cents), style: const TextStyle(
                      color: Palette.gold, fontWeight: FontWeight.w800,
                    )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
