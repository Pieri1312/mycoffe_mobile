import 'package:flutter_test/flutter_test.dart';
import 'package:mycoffe/features/cart/cart.dart';
import 'package:mycoffe/features/catalog/coffee.dart';

void main() {
  const coffee = Coffee(id: 1, name: 'Latte', description: 'Café com leite',
      cents: 990, tags: ['Tradicional']);
  test('soma centavos, limita quantidade e remove linha zerada', () {
    final cart = CartController();
    expect(cart.change(coffee, 227, 2), isTrue);
    expect(cart.state.subtotal, 1980);
    expect(cart.change(coffee, 227, 98), isFalse);
    expect(cart.state.count, 2);
    cart.change(coffee, 227, -2);
    expect(cart.state.lines, isEmpty);
  });

  test('separa tamanhos na demonstração e mantém limite por café', () {
    final cart = CartController();
    cart.change(coffee, 114, 98);
    expect(cart.change(coffee, 227, 2), isFalse);
    expect(cart.change(coffee, 227, 1), isTrue);
    expect(cart.state.lines.length, 2);
    expect(cart.state.count, 99);
  });
}
