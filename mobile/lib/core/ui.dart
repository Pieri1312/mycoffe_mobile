import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/cart/cart.dart';
import '../features/catalog/coffee.dart';
import 'store.dart';

abstract final class Palette {
  static const canvas = Color(0xfffafafa);
  static const panel = Color(0xffefefef);
  static const field = Color(0xffe9e9e9);
  static const dark = Color(0xff272121);
  static const darkField = Color(0xff413937);
  static const ink = Color(0xff292423);
  static const muted = Color(0xff69615e);
  static const gold = Color(0xffb87516);
  static const splash = Color(0xffc7881c);
  static const yellow = Color(0xffe3b745);
  static const purple = Color(0xff482797);
  static const lilac = Color(0xffede5fa);
  static const softPurple = Color(0xff8052dc);
}

ThemeData shopTheme() => ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: Palette.canvas,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Palette.purple,
    primary: Palette.purple,
    surface: Palette.canvas,
  ),
  textTheme: const TextTheme(
    headlineSmall: TextStyle(fontWeight: FontWeight.w800, color: Palette.ink),
    titleLarge: TextStyle(fontWeight: FontWeight.w800, color: Palette.ink),
    titleMedium: TextStyle(fontWeight: FontWeight.w700, color: Palette.ink),
    titleSmall: TextStyle(fontWeight: FontWeight.w700, color: Palette.ink),
    bodyMedium: TextStyle(color: Palette.ink),
    bodySmall: TextStyle(color: Palette.muted),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Palette.field,
    isDense: true,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(5),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
  ),
);

class PageWidth extends StatelessWidget {
  const PageWidth({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
    heightFactor: 1,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: SizedBox(width: double.infinity, child: child),
    ),
  );
}

class ShopHeader extends StatelessWidget implements PreferredSizeWidget {
  const ShopHeader(this.title, {super.key, this.dark = false, this.actions = const []});
  final String title;
  final bool dark;
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) => AppBar(
    title: Text(title),
    centerTitle: true,
    backgroundColor: dark ? Palette.dark : Palette.canvas,
    foregroundColor: dark ? Colors.white : Palette.ink,
    titleTextStyle: TextStyle(
      color: dark ? Colors.white : Palette.ink,
      fontWeight: FontWeight.w800,
      fontSize: 15,
    ),
    scrolledUnderElevation: 0,
    actions: actions,
  );
}

class ActionButton extends StatelessWidget {
  const ActionButton(this.label, {
    super.key,
    required this.onPressed,
    this.color = Palette.gold,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final bool busy;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
      ),
      onPressed: busy ? null : onPressed,
      child: busy
          ? const SizedBox.square(
              dimension: 19,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label, textAlign: TextAlign.center),
    ),
  );
}

class CoffeePhoto extends ConsumerWidget {
  const CoffeePhoto(this.coffee, {super.key, required this.size});

  final Coffee coffee;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asset = coffee.localAsset;
    final fallback = asset == null
        ? Icon(Icons.coffee_rounded, size: size * .55, color: Palette.gold)
        : Image.asset(asset, fit: BoxFit.contain);
    final url = ref.watch(storeProvider).imageUrl(coffee);
    return SizedBox.square(
      dimension: size,
      child: url == null || (asset != null && coffee.imageUrl.startsWith('/img/'))
          ? fallback
          : Image.network(url, fit: BoxFit.contain, errorBuilder: (_, _, _) => fallback),
    );
  }
}

class CartIcon extends ConsumerWidget {
  const CartIcon({super.key, this.color = Palette.softPurple});

  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(cartProvider).count;
    return IconButton(
      tooltip: 'Carrinho ($count itens)',
      onPressed: () => context.push('/carrinho'),
      color: color,
      icon: Badge(
        isLabelVisible: count > 0,
        backgroundColor: Palette.softPurple,
        label: Text('$count'),
        child: const Icon(Icons.shopping_cart_rounded, size: 22),
      ),
    );
  }
}

class QuantityControl extends StatelessWidget {
  const QuantityControl({
    super.key,
    required this.value,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int value;
  final VoidCallback? onDecrease, onIncrease;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: Palette.field),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Diminuir quantidade',
          icon: const Icon(Icons.remove, size: 18),
          color: Palette.softPurple,
          onPressed: onDecrease,
        ),
        Text('$value'),
        IconButton(
          tooltip: 'Aumentar quantidade',
          icon: const Icon(Icons.add, size: 18),
          color: Palette.softPurple,
          onPressed: onIncrease,
        ),
      ],
    ),
  );
}

class LoadError extends StatelessWidget {
  const LoadError({super.key, required this.message, required this.retry});
  final String message;
  final VoidCallback retry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message, textAlign: TextAlign.center),
        TextButton(onPressed: retry, child: const Text('Tentar novamente')),
      ],
    ),
  );
}
