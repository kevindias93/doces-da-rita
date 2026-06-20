import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart' show Produto;
import 'carrinho_page.dart';

class SobrePage extends StatefulWidget {
  final Map<String, int> carrinho;
  final List<Produto> produtos;
  final void Function(Produto produto) onAdicionar;
  final void Function(Produto produto) onRemover;
  final FirebaseFirestore firestore;
  final VoidCallback onPedidoFinalizado;

  const SobrePage({
    super.key,
    required this.carrinho,
    required this.produtos,
    required this.onAdicionar,
    required this.onRemover,
    required this.firestore,
    required this.onPedidoFinalizado,
  });

  @override
  State<SobrePage> createState() => _SobrePageState();
}

class _SobrePageState extends State<SobrePage> {
  int get quantidadeTotalCarrinho {
    return widget.carrinho.values.fold(0, (a, b) => a + b);
  }

  double get totalCarrinho {
    double total = 0;
    for (var produto in widget.produtos) {
      total += produto.preco * (widget.carrinho[produto.id] ?? 0);
    }
    return total;
  }

  void _voltar() {
    Navigator.pop(context, Map<String, int>.from(widget.carrinho));
  }

  /// Abre o CarrinhoPage e, ao voltar, repassa o carrinho atualizado para a HomePage
  Future<void> _irParaCarrinho() async {
    final carrinhoAtualizado = await Navigator.push<Map<String, int>>(
      context,
      MaterialPageRoute(
        builder: (_) => CarrinhoPage(
          carrinho: widget.carrinho,
          produtos: widget.produtos,
          total: totalCarrinho,
          quantidadeTotal: quantidadeTotalCarrinho,
          firestore: widget.firestore,
          onPedidoFinalizado: widget.onPedidoFinalizado,
        ),
      ),
    );

    if (!mounted) return;

    if (carrinhoAtualizado != null) {
      setState(() {
        widget.carrinho
          ..clear()
          ..addAll(carrinhoAtualizado);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _voltar();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Promoção da Semana"),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _voltar,
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('produtos')
                .where('promocao', isEqualTo: true)
                .limit(1)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("Sem promoção no momento"));
              }

              final doc = snapshot.data!.docs.first;
              final data = doc.data() as Map<String, dynamic>;
              final id = doc.id;

              Produto? produto;
              try {
                produto = widget.produtos.firstWhere((p) => p.id == id);
              } catch (_) {
                produto = null;
              }

              final qtd = widget.carrinho[id] ?? 0;

              return SingleChildScrollView(
                child: Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        child: Image.network(
                          data['imagem'] ?? '',
                          width: double.infinity,
                          height: 220,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox(
                            height: 220,
                            child: Center(child: Icon(Icons.cake, size: 60)),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['nome'] ?? '',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if ((data['descricao'] ?? '').isNotEmpty)
                              Text(
                                data['descricao'],
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    "Itens no carrinho: $quantidadeTotalCarrinho",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Total: R\$ ${totalCarrinho.toStringAsFixed(2)}",
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "R\$ ${(data['preco'] as num).toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                                Container(
                                  height: 36,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.deepPurple,
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      GestureDetector(
                                        onTap: (produto == null || qtd == 0)
                                            ? null
                                            : () {
                                                widget.onRemover(produto!);
                                                setState(() {});
                                              },
                                        child: Container(
                                          width: 36,
                                          alignment: Alignment.center,
                                          child: Icon(
                                            Icons.remove,
                                            color: (produto == null || qtd == 0)
                                                ? Colors.grey
                                                : Colors.deepPurple,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        child: Text(
                                          "$qtd",
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.deepPurple,
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: produto == null
                                            ? null
                                            : () {
                                                widget.onAdicionar(produto!);
                                                setState(() {});
                                              },
                                        child: Container(
                                          width: 36,
                                          decoration: BoxDecoration(
                                            color: produto == null
                                                ? Colors.grey
                                                : Colors.deepPurple,
                                            borderRadius:
                                                const BorderRadius.only(
                                                  topRight: Radius.circular(8),
                                                  bottomRight: Radius.circular(
                                                    8,
                                                  ),
                                                ),
                                          ),
                                          alignment: Alignment.center,
                                          child: const Icon(
                                            Icons.add,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepPurple,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                // Navega direto para o CarrinhoPage
                                onPressed: quantidadeTotalCarrinho == 0
                                    ? null
                                    : _irParaCarrinho,
                                icon: const Icon(Icons.shopping_cart),
                                label: const Text("Ir para o carrinho"),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
//  MEU PERFIL
// ─────────────────────────────────────────

class PerfilPageNovo extends StatefulWidget {
  const PerfilPageNovo({super.key});

  @override
  State<PerfilPageNovo> createState() => _PerfilPageNovoState();
}

class _PerfilPageNovoState extends State<PerfilPageNovo> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final _nomeController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _enderecoController = TextEditingController();
  final _numeroController = TextEditingController();
  final _bairroController = TextEditingController();
  final _complementoController = TextEditingController();

  bool _carregando = true;
  bool _salvando = false;

  User? _user;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    try {
      if (_user == null) {
        setState(() => _carregando = false);
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(_user!.uid)
          .get();

      final data = doc.data();
      if (data != null) {
        _nomeController.text = data['nome'] ?? '';
        _telefoneController.text = data['telefone'] ?? '';
        _enderecoController.text = data['endereco'] ?? '';
        _numeroController.text = data['numero'] ?? '';
        _bairroController.text = data['bairro'] ?? '';
        _complementoController.text = data['complemento'] ?? '';
      }
    } catch (_) {}

    if (mounted) setState(() => _carregando = false);
  }

  Future<void> _salvar() async {
    if (_user == null) return;

    if (_nomeController.text.trim().isEmpty ||
        _telefoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Preencha nome e telefone")));
      return;
    }

    try {
      setState(() => _salvando = true);

      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(_user!.uid)
          .set({
            'nome': _nomeController.text.trim(),
            'telefone': _telefoneController.text.trim(),
            'endereco': _enderecoController.text.trim(),
            'numero': _numeroController.text.trim(),
            'bairro': _bairroController.text.trim(),
            'complemento': _complementoController.text.trim(),
            'email': _user!.email,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Dados salvos com sucesso!")),
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _enviarRedefinicaoSenha() async {
    final email = _user?.email;
    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nenhum e-mail associado à conta")),
      );
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("E-mail enviado"),
          content: Text(
            "Um link para redefinir sua senha foi enviado para $email.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro ao enviar e-mail: $e")));
    }
  }

  Future<void> _excluirConta() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Excluir conta"),
        content: const Text(
          "Tem certeza? Esta ação é irreversível e todos os seus dados serão removidos.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Excluir"),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      final uid = _user!.uid;
      await FirebaseFirestore.instance.collection('usuarios').doc(uid).delete();
      await _user!.delete();

      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      if (e.code == 'requires-recent-login') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Por segurança, faça logout e login novamente antes de excluir a conta.",
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao excluir conta: ${e.message}")),
        );
      }
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    _enderecoController.dispose();
    _numeroController.dispose();
    _bairroController.dispose();
    _complementoController.dispose();
    super.dispose();
  }

  Widget _campo({
    required TextEditingController controller,
    required String label,
    TextInputType teclado = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        keyboardType: teclado,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Meu Perfil"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _user == null
          ? const Center(child: Text("Usuário não logado"))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        const CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.deepPurple,
                          child: Icon(
                            Icons.person,
                            size: 44,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _user!.email ?? '',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Dados pessoais",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _campo(controller: _nomeController, label: "Nome"),
                  _campo(
                    controller: _telefoneController,
                    label: "Telefone",
                    teclado: TextInputType.phone,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Endereço de entrega",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _campo(
                    controller: _enderecoController,
                    label: "Rua / Avenida",
                  ),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _campo(
                          controller: _numeroController,
                          label: "Número",
                          teclado: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 4,
                        child: _campo(
                          controller: _bairroController,
                          label: "Bairro",
                        ),
                      ),
                    ],
                  ),
                  _campo(
                    controller: _complementoController,
                    label: "Complemento (opcional)",
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _salvando ? null : _salvar,
                      child: _salvando
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text("Salvar dados"),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.lock_reset,
                      color: Colors.deepPurple,
                    ),
                    title: const Text("Redefinir senha"),
                    subtitle: const Text("Enviaremos um link para seu e-mail"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: _enviarRedefinicaoSenha,
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.delete_forever,
                      color: Colors.red,
                    ),
                    title: const Text(
                      "Excluir conta",
                      style: TextStyle(color: Colors.red),
                    ),
                    subtitle: const Text("Remove permanentemente seus dados"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: _excluirConta,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }
}
