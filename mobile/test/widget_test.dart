import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mycoffe/core/store.dart';
import 'package:mycoffe/features/catalog/coffee.dart';
import 'package:mycoffe/features/checkout/models.dart';
import 'package:mycoffe/main.dart';

void main() {
  const latte = Coffee(
    id: 6, name: 'Latte', description: 'Café e leite', cents: 990,
    tags: ['Tradicional'],
  );

  testWidgets('navega do catálogo ao carrinho e confirma a demonstração', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        storeProvider.overrideWithValue(Store('')),
        catalogProvider.overrideWith((ref) async => [latte]),
        recommendationsProvider.overrideWith((ref) async => [latte]),
        paymentsProvider.overrideWith((ref) async => const [
          Payment(1, 'CARTAO_CREDITO', 'Cartão de crédito'),
        ]),
      ],
      child: const MyCoffeApp(),
    ));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Modo demonstração'), findsOneWidget);
    await tester.tap(find.text('Latte').first);
    await tester.pumpAndSettle();
    expect(tester.getBottomRight(find.text('ADICIONAR')).dy, greaterThan(760));
    await tester.ensureVisible(find.text('ADICIONAR'));
    await tester.tap(find.text('ADICIONAR'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Carrinho (1 itens)'));
    await tester.pumpAndSettle();
    expect(find.text('Carrinho'), findsOneWidget);
    expect(find.text('R\$ 9,90'), findsNWidgets(2));
    await tester.tap(find.text('CONFIRMAR PEDIDO'));
    await tester.pumpAndSettle();

    for (final entry in const {
      'CEP': '09390120',
      'Número': '804',
      'Rua': 'Av. Antônia Rosa Fioravanti',
      'Bairro': 'Centro',
      'Cidade': 'Mauá',
      'UF': 'SP',
    }.entries) {
      final field = find.widgetWithText(TextFormField, entry.key);
      await tester.ensureVisible(field);
      await tester.enterText(field, entry.value);
    }
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    final payment = find.text('CARTÃO DE CRÉDITO');
    await tester.ensureVisible(payment);
    await tester.tap(payment);
    await tester.pumpAndSettle();
    await tester.tap(find.text('FINALIZAR DEMONSTRAÇÃO'));
    await tester.pumpAndSettle();
    expect(find.text('Demonstração concluída'), findsOneWidget);
    expect(find.text('Nenhum pedido foi enviado.'), findsOneWidget);
    expect(find.text('R\$ 13,40'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
