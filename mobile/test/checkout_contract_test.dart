import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mycoffe/core/store.dart';
import 'package:mycoffe/features/cart/cart.dart';
import 'package:mycoffe/features/catalog/coffee.dart';
import 'package:mycoffe/features/checkout/models.dart';

void main() {
  const address = Address(
    cep: '09390-120', street: 'Rua de teste', number: '804',
    district: 'Centro', city: 'Mauá', uf: 'SP',
  );
  const payment = Payment(1, 'CARTAO_CREDITO', 'Cartão de crédito');
  const coffee = Coffee(id: 6, name: 'Latte', description: '', cents: 990, tags: []);
  const session = Session(token: 'token-teste', name: 'Cliente');

  test('checkout envia o DTO oficial e usa o valor efetivo do servidor', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'));
    dio.interceptors.add(InterceptorsWrapper(onRequest: (request, handler) {
      expect(request.method, 'POST');
      expect(request.path, '/pedidos');
      expect(request.headers['Authorization'], 'Bearer token-teste');
      expect(request.data, {
        'formaPagamentoId': 1,
        'itens': [{'cafeId': 6, 'quantidade': 2}],
        'endereco': {
          'cep': '09390120', 'logradouro': 'Rua de teste', 'numero': '804',
          'bairro': 'Centro', 'cidade': 'Mauá', 'uf': 'SP',
        },
      });
      handler.resolve(Response<Json>(
        requestOptions: request,
        statusCode: 201,
        data: {
          'codigo': 'pedido-1', 'status': 'CONFIRMADO', 'total': 24.90,
          'previsaoMin': 20, 'previsaoMax': 30, 'endereco': address.toJson(),
          'formaPagamento': {'id': 1, 'codigo': payment.code, 'descricao': payment.label},
        },
      ));
    }));
    final receipt = await Store('https://example.invalid', client: dio).submit(
      cart: Cart([const CartLine(coffee, 227, 2)]),
      address: address, payment: payment, session: session,
    );
    expect(receipt.code, 'pedido-1');
    expect(receipt.total, 2490);
  });

  test('checkout conectado rejeita tamanhos ausentes no contrato', () async {
    final store = Store('https://example.invalid');
    await expectLater(
      store.submit(
        cart: Cart([const CartLine(coffee, 114, 1)]),
        address: address, payment: payment, session: session,
      ),
      throwsStateError,
    );
  });
}
