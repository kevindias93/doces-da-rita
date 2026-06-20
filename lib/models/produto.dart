class Produto {
  final String id;
  final String nome;
  final String descricao;
  final double preco;
  final String imagem;

  Produto({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.preco,
    required this.imagem,
  });

  factory Produto.fromFirestore(String id, Map<String, dynamic> data) {
    return Produto(
      id: id,
      nome: data['nome'] ?? '',
      descricao: data['descricao'] ?? '',
      preco: (data['preco'] ?? 0).toDouble(),
      imagem: data['imagem'] ?? '',
    );
  }
}
