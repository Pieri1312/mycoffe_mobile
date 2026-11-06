import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/store.dart';
import 'core/ui.dart';
import 'features/cart/cart_screen.dart';
import 'features/catalog/catalog_screen.dart';
import 'features/catalog/coffee.dart';
import 'features/catalog/product_screen.dart';
import 'features/checkout/account_screen.dart';
import 'features/checkout/checkout_screen.dart';
import 'features/checkout/models.dart';
import 'features/checkout/order_screens.dart';

void main() => runApp(const ProviderScope(child: MyCoffeApp()));

final _routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/abertura',
    routes: [
      GoRoute(path: '/abertura', builder: (_, _) => const _Splash()),
      GoRoute(path: '/', builder: (_, _) => const CatalogScreen()),
      GoRoute(
        path: '/cafe/:id',
        builder: (_, state) => _ProductRoute(
          id: int.tryParse(state.pathParameters['id'] ?? ''),
          coffee: state.extra is Coffee ? state.extra as Coffee : null,
        ),
      ),
      GoRoute(path: '/carrinho', builder: (_, _) => const CartScreen()),
      GoRoute(path: '/checkout', builder: (_, _) => const CheckoutScreen()),
      GoRoute(
        path: '/conta',
        builder: (_, state) => AccountScreen(fromCheckout: state.uri.queryParameters['checkout'] == '1'),
      ),
      GoRoute(path: '/pedidos', builder: (_, _) => const OrdersScreen()),
      for (final route in ['/pedido', '/pedidos/detalhe'])
        GoRoute(
          path: route,
          redirect: (_, state) => state.extra is Receipt ? null : '/',
          builder: (_, state) => SuccessScreen(state.extra as Receipt, historical: route != '/pedido'),
        ),
    ],
    errorBuilder: (context, state) => const _MissingPage('Página indisponível.'),
  );
  ref.onDispose(router.dispose);
  return router;
});

class MyCoffeApp extends ConsumerWidget {
  const MyCoffeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: 'MyCoffe',
    debugShowCheckedModeBanner: false,
    theme: shopTheme(),
    routerConfig: ref.watch(_routerProvider),
  );
}

class _Splash extends StatefulWidget {
  const _Splash();

  @override
  State<_Splash> createState() => _SplashState();
}

class _SplashState extends State<_Splash> {
  late final Timer timer;

  @override
  void initState() {
    super.initState();
    timer = Timer(const Duration(milliseconds: 750), () {
      if (mounted) context.go('/');
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: Palette.splash,
    body: Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.coffee_rounded, color: Palette.dark, size: 28),
          SizedBox(width: 6),
          Text('MyCoffe', style: TextStyle(
            color: Palette.dark, fontSize: 20, fontWeight: FontWeight.w900,
          )),
        ],
      ),
    ),
  );
}

class _ProductRoute extends ConsumerWidget {
  const _ProductRoute({required this.id, required this.coffee});

  final int? id;
  final Coffee? coffee;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initial = coffee;
    if (initial != null && initial.id == id) return ProductScreen(initial);
    if (id == null) return const _MissingPage('Café indisponível.');
    return ref.watch(catalogProvider).when(
      data: (items) {
        final coffee = items.where((item) => item.id == id).firstOrNull;
        return coffee == null ? const _MissingPage('Café indisponível.') : ProductScreen(coffee);
      },
      loading: () => const Scaffold(appBar: ShopHeader('Café'),
          body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        appBar: const ShopHeader('Café'),
        body: Center(child: LoadError(message: errorMessage(error),
            retry: () => ref.invalidate(catalogProvider))),
      ),
    );
  }
}

class _MissingPage extends StatelessWidget {
  const _MissingPage(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const ShopHeader('MyCoffe'),
    body: Center(child: TextButton(
      onPressed: () => context.go('/'),
      child: Text('$message Voltar ao cardápio'),
    )),
  );
}
