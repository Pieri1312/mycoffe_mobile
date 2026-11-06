typedef Json = Map<String, dynamic>;

String money(int cents) =>
    'R\$ ${cents ~/ 100},${(cents % 100).toString().padLeft(2, '0')}';

int centsFrom(Object? value) => ((value as num) * 100).round();

String normalized(String value) {
  const accents = 'áàâãäéèêëíìîïóòôõöúùûüç';
  const plain = 'aaaaaeeeeiiiiooooouuuuc';
  return value.toLowerCase().replaceAllMapped(RegExp('[$accents]'), (m) {
    return plain[accents.indexOf(m[0]!)];
  });
}

class Coffee {
  const Coffee({
    required this.id,
    required this.name,
    required this.description,
    required this.cents,
    required this.tags,
    this.imageUrl = '',
  });

  factory Coffee.fromJson(Json json) => Coffee(
    id: json['id'] as int,
    name: json['nome'] as String,
    description: json['descricao'] as String,
    cents: centsFrom(json['preco']),
    imageUrl: json['imagemUrl'] as String? ?? '',
    tags: (json['tags'] as List<dynamic>)
        .map((tag) => (tag as Json)['nome'] as String)
        .toList(growable: false),
  );

  final int id;
  final String name;
  final String description;
  final int cents;
  final List<String> tags;
  final String imageUrl;

  String get category {
    if (tags.any((tag) => normalized(tag) == 'especial')) return 'Especiais';
    if (const ['mocaccino', 'chocolate quente'].contains(normalized(name))) {
      return 'Doces';
    }
    return 'Tradicionais';
  }

  String? get localAsset {
    const names = {
      'expresso tradicional': 'traditional-espresso',
      'expresso americano': 'american-espresso',
      'expresso cremoso': 'creamy-espresso',
      'expresso gelado': 'ice-espresso',
      'cafe com leite': 'coffe-milk',
      'latte': 'latte',
      'capuccino': 'capuccino',
      'macchiato': 'macchiato',
      'mocaccino': 'mocaccino',
      'chocolate quente': 'hot-chocolate',
      'cubano': 'cubano',
      'havaiano': 'havaiano',
      'arabe': 'arabe',
      'irlandes': 'irlandes',
    };
    final file = names[normalized(name)];
    return file == null ? null : 'assets/$file.png';
  }
}
