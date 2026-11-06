import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/cart/cart.dart';
import '../features/catalog/coffee.dart';
import '../features/checkout/models.dart';

const apiUrl = String.fromEnvironment('MYCOFFE_API_URL');
const deliveryEstimate = int.fromEnvironment('MYCOFFE_DELIVERY_CENTS', defaultValue: 350);

final storeProvider = Provider<Store>((ref) => Store(apiUrl));
final sessionProvider = StateProvider<Session?>((ref) => null);
final orderNeedsReviewProvider = StateProvider<bool>((ref) => false);
final catalogProvider = FutureProvider((ref) => ref.watch(storeProvider).catalog());
final recommendationsProvider = FutureProvider((ref) => ref.watch(storeProvider).recommendations());
final paymentsProvider = FutureProvider((ref) => ref.watch(storeProvider).payments());
final ordersProvider = FutureProvider<List<Receipt>>((ref) async {
  final session = ref.watch(sessionProvider);
  if (session == null) return [];
  return ref.watch(storeProvider).orders(session);
});

class Store {
  Store(this.baseUrl, {Dio? client})
      : _client = client ?? Dio(BaseOptions(
          baseUrl: baseUrl.replaceFirst(RegExp(r'/+$'), ''),
          connectTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 20),
        ));

  final String baseUrl;
  final Dio _client;

  bool get demo => baseUrl.isEmpty;

  Future<List<Coffee>> catalog() async {
    final data = demo
        ? jsonDecode(await rootBundle.loadString('assets/catalogo_demo.json'))
        : (await _client.get<List<dynamic>>('/cafes')).data!;
    return (data as List<dynamic>).map((json) => Coffee.fromJson(json as Json)).toList();
  }

  Future<List<Coffee>> recommendations() async {
    if (demo) {
      final coffees = await catalog();
      return [for (final id in [6, 9, 14]) coffees.firstWhere((coffee) => coffee.id == id)];
    }
    final data = (await _client.get<List<dynamic>>(
      '/cafes/recomendacoes',
      queryParameters: {'limite': 6},
    )).data!;
    return data.map((json) => Coffee.fromJson(json as Json)).toList();
  }

  Future<List<Payment>> payments() async {
    if (demo) {
      return const [
        Payment(1, 'CARTAO_CREDITO', 'Cartão de crédito'),
        Payment(2, 'CARTAO_DEBITO', 'Cartão de débito'),
        Payment(3, 'DINHEIRO', 'Dinheiro'),
      ];
    }
    final data = (await _client.get<List<dynamic>>('/formas-pagamento')).data!;
    return data.map((json) => Payment.fromJson(json as Json)).toList();
  }

  Future<Session> authenticate(String email, String password, {String? name}) async {
    final result = await _client.post<Json>(
      name == null ? '/auth/login' : '/auth/cadastro',
      data: {'email': email, 'senha': password, if (name != null) 'nome': name},
    );
    return Session.fromJson(result.data!);
  }

  Future<Receipt> submit({
    required Cart cart,
    required Address address,
    required Payment payment,
    required Session? session,
  }) async {
    if (cart.lines.isEmpty) throw StateError('O carrinho está vazio.');
    if (demo) {
      return Receipt(
        code: 'DEMO',
        status: 'CONFIRMADO',
        total: cart.subtotal + deliveryEstimate,
        minMinutes: 20,
        maxMinutes: 30,
        payment: payment,
        address: address,
      );
    }
    if (session == null) throw StateError('Entre na sua conta.');
    if (cart.lines.any((line) => line.milliliters != 227)) {
      throw StateError('A API aceita apenas o tamanho padrão.');
    }
    final result = await _client.post<Json>(
      '/pedidos',
      options: _authorized(session),
      data: {
        'formaPagamentoId': payment.id,
        'itens': cart.lines.map((line) => line.apiItem).toList(),
        'endereco': address.toJson(),
      },
    );
    return Receipt.fromJson(result.data!);
  }

  Future<List<Receipt>> orders(Session session) async {
    final data = (await _client.get<List<dynamic>>(
      '/pedidos/meus', options: _authorized(session),
    )).data!;
    return data.map((json) => Receipt.fromJson(json as Json)).toList();
  }

  Options _authorized(Session session) =>
      Options(headers: {'Authorization': 'Bearer ${session.token}'});

  String? imageUrl(Coffee coffee) {
    final url = Uri.tryParse(coffee.imageUrl);
    if (url == null || coffee.imageUrl.isEmpty) return null;
    if (url.hasScheme) {
      return const ['https', 'http'].contains(url.scheme) ? url.toString() : null;
    }
    return demo ? null : Uri.parse('$baseUrl/').resolveUri(url).toString();
  }
}

bool expiredSession(Object error) =>
    error is DioException && error.response?.statusCode == 401;

bool unknownOrderResult(Object error) =>
    error is FormatException ||
    error is TypeError ||
    (error is DioException &&
        (error.response == null || (error.response?.statusCode ?? 0) >= 500));

String errorMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    final status = error.response?.statusCode;
    if (data is Map && status != null && status < 500) {
      final message = data['message'];
      if (message is String && message.isNotEmpty) return message;
      if (message is List && message.isNotEmpty) return message.join('\n');
    }
    return 'Não foi possível conectar ao serviço. Confira a conexão e tente novamente.';
  }
  if (error is StateError) return error.message;
  return 'Não foi possível concluir esta ação.';
}
