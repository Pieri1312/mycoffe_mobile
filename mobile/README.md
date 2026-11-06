# MyCoffe Mobile

Aplicativo Flutter e Dart para Android e iOS. Inclui splash, catálogo com busca, categorias e recomendações, detalhes do café, carrinho, checkout com endereço e pagamento na entrega e confirmação. O modo conectado inclui cadastro, login, saída e consulta de pedidos.

## Executar

Requer Flutter estável 3.29 ou superior e o SDK da plataforma desejada. Para iOS, use macOS com Xcode. Na pasta do projeto, rode:

```sh
flutter doctor
dart tool/setup.dart
flutter pub get
flutter run
```

O script gera os projetos nativos com a versão instalada do Flutter e habilita acesso à internet no Android. Por padrão o app abre em **Modo demonstração** com o catálogo do seed, um checkout local e o aviso de que nenhum pedido foi enviado.

## Conectar ao backend

Suba a [MyCoffee API](https://github.com/MtRocha/MyCoffe) com SQL Server seguindo o README dela, ou use a URL HTTPS de uma instância da equipe. Passe a URL sem o caminho do Swagger:

```sh
flutter run --dart-define=MYCOFFE_API_URL=https://mycoffeapi-atb2aybxbdhdercb.brazilsouth-01.azurewebsites.net
```

O comando acima usa o endereço do deploy registrado pelo GitHub Actions. A disponibilidade da instância não foi confirmada durante a entrega. Substitua a URL se a equipe usar outro ambiente.

Para API local na porta 3000, use `http://10.0.2.2:3000` no emulador Android com build de debug. Em dispositivos reais, configure um host acessível ao aparelho. Use HTTPS no iOS e em builds distribuídos. Se a instância tiver outra taxa de entrega, passe `--dart-define=MYCOFFE_DELIVERY_CENTS=350` com o valor correto. A tela de confirmação usa o total retornado pela API.

O app conecta catálogo, recomendações, pagamentos, autenticação, criação e consulta de pedidos ao contrato OpenAPI do projeto. O pagamento acontece na entrega. O app só envia a forma escolhida. A API não recebe tamanho, então o modo conectado oferece 227 ml como opção padrão. No modo demonstração os tamanhos de 114, 140 e 227 ml são independentes no carrinho. Carrinho e sessão ficam em memória. No modo conectado, o histórico e os pedidos são persistidos pelo backend.

## Validar e compilar

```sh
dart format lib test tool
flutter analyze
flutter test
flutter build apk --debug
# Em macOS com Xcode:
flutter build ios --simulator
```

Para testar uma instância real, entre com uma conta de teste, selecione um café e confirme o pedido em Meus pedidos. Para validar o layout, compare capturas do emulador com os frames Catálogo, Produto, Carrinho, Dados do pedido e Compra finalizada no [Figma](https://www.figma.com/design/mZaoksUcb1MCcH0NCevEI6/MyCoffe?node-id=0-1).

O pacote inclui testes de carrinho, contrato do checkout com cliente HTTP interceptado e fluxo de widgets. O ambiente de entrega não disponibilizou Flutter/Dart nem acesso aos downloads do SDK. A execução dos testes, compilação, validação contra uma instância real e comparação visual com capturas do app estão pendentes. As cores principais e a composição foram reproduzidas a partir dos frames visíveis. A tipografia usa a fonte padrão do dispositivo.
