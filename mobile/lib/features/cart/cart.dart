import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../catalog/coffee.dart';

final cartProvider = StateNotifierProvider<CartController, Cart>(
  (ref) => CartController(),
);

class CartLine {
  const CartLine(this.coffee, this.milliliters, this.quantity);
  final Coffee coffee;
  final int milliliters;
  final int quantity;
  int get subtotal => coffee.cents * quantity;
  String get key => '${coffee.id}:$milliliters';
  Json get apiItem => {'cafeId': coffee.id, 'quantidade': quantity};
}

class Cart {
  Cart([Iterable<CartLine> lines = const []]) : lines = List.unmodifiable(lines);
  final List<CartLine> lines;
  int get count => lines.fold(0, (sum, line) => sum + line.quantity);
  int get subtotal => lines.fold(0, (sum, line) => sum + line.subtotal);
}

class CartController extends StateNotifier<Cart> {
  CartController() : super(Cart());

  bool change(Coffee coffee, int milliliters, int delta) {
    final items = [...state.lines];
    final index = items.indexWhere(
      (line) => line.coffee.id == coffee.id && line.milliliters == milliliters,
    );
    final previous = index < 0 ? 0 : items[index].quantity;
    final requested = previous + delta;
    final next = requested < 0 ? 0 : requested;
    final totalForCoffee = items.where((line) => line.coffee.id == coffee.id)
        .fold<int>(0, (sum, line) => sum + line.quantity);
    if (totalForCoffee - previous + next > 99) return false;
    if (index < 0 && next > 0) {
      if (items.length >= 50) return false;
      items.add(CartLine(coffee, milliliters, next));
    } else if (index >= 0 && next == 0) {
      items.removeAt(index);
    } else if (index >= 0) {
      items[index] = CartLine(coffee, milliliters, next);
    }
    state = Cart(items);
    return true;
  }

  void clear() => state = Cart();
}
