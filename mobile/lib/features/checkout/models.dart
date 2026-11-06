import '../catalog/coffee.dart';

class Address {
  const Address({
    required this.cep,
    required this.street,
    required this.number,
    required this.district,
    required this.city,
    required this.uf,
    this.extra = '',
  });

  static const states = [
    'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA', 'MT',
    'MS', 'MG', 'PA', 'PB', 'PR', 'PE', 'PI', 'RJ', 'RN', 'RS', 'RO',
    'RR', 'SC', 'SP', 'SE', 'TO',
  ];

  factory Address.fromJson(Json json) => Address(
    cep: json['cep'] as String,
    street: json['logradouro'] as String,
    number: json['numero'] as String,
    district: json['bairro'] as String,
    city: json['cidade'] as String,
    uf: json['uf'] as String,
    extra: json['complemento'] as String? ?? '',
  );

  final String cep, street, number, district, city, uf, extra;

  Json toJson() => {
    'cep': cep.replaceAll(RegExp(r'\D'), ''),
    'logradouro': street,
    'numero': number,
    'bairro': district,
    'cidade': city,
    'uf': uf,
    if (extra.isNotEmpty) 'complemento': extra,
  };
}

class Payment {
  const Payment(this.id, this.code, this.label);

  factory Payment.fromJson(Json json) => Payment(
    json['id'] as int,
    json['codigo'] as String,
    json['descricao'] as String,
  );

  final int id;
  final String code, label;
}

class Session {
  const Session({required this.token, required this.name});

  factory Session.fromJson(Json json) => Session(
    token: json['accessToken'] as String,
    name: (json['usuario'] as Json)['nome'] as String,
  );

  final String token, name;
}

class Receipt {
  const Receipt({
    required this.code,
    required this.status,
    required this.total,
    required this.minMinutes,
    required this.maxMinutes,
    required this.payment,
    required this.address,
  });

  factory Receipt.fromJson(Json json) => Receipt(
    code: json['codigo'] as String,
    status: json['status'] as String,
    total: centsFrom(json['total']),
    minMinutes: json['previsaoMin'] as int,
    maxMinutes: json['previsaoMax'] as int,
    payment: Payment.fromJson(json['formaPagamento'] as Json),
    address: json['endereco'] == null
        ? null
        : Address.fromJson(json['endereco'] as Json),
  );

  final String code, status;
  final int total, minMinutes, maxMinutes;
  final Payment payment;
  final Address? address;

  String get statusLabel => switch (status) {
    'CONFIRMADO' => 'Confirmado',
    'EM_PREPARO' => 'Em preparo',
    'SAIU_PARA_ENTREGA' => 'Saiu para entrega',
    'ENTREGUE' => 'Entregue',
    'CANCELADO' => 'Cancelado',
    _ => status,
  };
}
