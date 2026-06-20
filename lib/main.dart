import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'pages/admin_login_page.dart';
import 'pages/carrinho_page.dart';
import 'pages/meus_pedidos_page.dart';
import 'services/cliente_service.dart';
import 'services/push_service.dart';
import 'pages/produto_detalhe_page.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'pages/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pages/sobre.dart';
import 'pages/meus_cupons_page.dart';

// ── WHATSAPP ─────────────────────────────────────────────────────────────────
void abrirWhatsApp() async {
  const numero = "5519993504701";
  const mensagem = "Olá! Vim pelo app Doces da Rita 🍰";

  final url = Uri.parse(
    "https://wa.me/$numero?text=${Uri.encodeComponent(mensagem)}",
  );

  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}

// ── INICIALIZAÇÃO ─────────────────────────────────────────────────────────────
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final clienteId = await ClienteService.getClienteId();
  debugPrint("CLIENTE ID: $clienteId");

  await PushService.init();

  runApp(const DocesDaRitaApp());
}

// ── APP ───────────────────────────────────────────────────────────────────────
class DocesDaRitaApp extends StatelessWidget {
  const DocesDaRitaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Doces da Rita',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthCheck(),
    );
  }
}

// ── AUTH CHECK ────────────────────────────────────────────────────────────────
class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        // 🔥 DEBUG IMPORTANTE
        debugPrint("AUTH STATE: ${user?.email}");

        if (user != null) {
          return const HomePage();
        }

        return const LoginPage();
      },
    );
  }
}

// ── MODEL ─────────────────────────────────────────────────────────────────────
class Produto {
  final String id;
  final String nome;
  final String descricao;
  final double preco;
  final String imagem;

  const Produto({
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

// ── HOME PAGE ─────────────────────────────────────────────────────────────────
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with RouteAware {
  final FocusNode _pesquisaFocus = FocusNode();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final ScrollController scrollController = ScrollController();

  List<Produto> produtosCache = [];
  List<Produto> produtosFiltrados = [];

  String pesquisa = '';
  bool _cardExpandido = true;

  final Map<String, int> carrinho = {};

  int _adminTapCount = 0;

  void _handleAdminSecretTap() {
    _adminTapCount++;

    if (_adminTapCount >= 5) {
      _adminTapCount = 0;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AdminLoginPage()),
      );
    }

    Future.delayed(const Duration(seconds: 2), () {
      _adminTapCount = 0;
    });
  }

  // ── Carrinho ──────────────────────────────────────────────────────────────
  void adicionarProduto(Produto produto) {
    setState(() {
      carrinho[produto.id] = (carrinho[produto.id] ?? 0) + 1;
    });
  }

  void removerProduto(Produto produto) {
    setState(() {
      final qtd = carrinho[produto.id] ?? 0;
      if (qtd > 1) {
        carrinho[produto.id] = qtd - 1;
      } else {
        carrinho.remove(produto.id);
      }
    });
  }

  void limparCarrinho() {
    setState(() => carrinho.clear());
  }

  double get total {
    double soma = 0;
    for (final produto in produtosCache) {
      soma += produto.preco * (carrinho[produto.id] ?? 0);
    }
    return soma;
  }

  int get quantidadeTotal => carrinho.values.fold(0, (a, b) => a + b);

  void finalizarPedido() async {
    final carrinhoAtualizado = await Navigator.push<Map<String, int>>(
      context,
      MaterialPageRoute(
        builder: (_) => CarrinhoPage(
          total: total,
          quantidadeTotal: quantidadeTotal,
          carrinho: carrinho,
          produtos: produtosCache,
          firestore: firestore,
          onPedidoFinalizado: limparCarrinho,
        ),
      ),
    );

    if (carrinhoAtualizado != null) {
      setState(() {
        carrinho
          ..clear()
          ..addAll(carrinhoAtualizado);
      });
    }
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    carregarProdutos();
  }

  @override
  void didPopNext() {
    _pesquisaFocus.unfocus();
  }

  @override
  void dispose() {
    scrollController.dispose();
    _pesquisaFocus.dispose();
    super.dispose();
  }

  // ── Dados ─────────────────────────────────────────────────────────────────
  Future<void> carregarProdutos() async {
    final snapshot = await firestore.collection('produtos').get();

    final lista =
        snapshot.docs
            .map((doc) => Produto.fromFirestore(doc.id, doc.data()))
            .toList()
          ..shuffle();

    setState(() {
      produtosCache = lista;
      produtosFiltrados = pesquisa.isEmpty
          ? lista
          : lista
                .where(
                  (p) => p.nome.toLowerCase().contains(pesquisa.toLowerCase()),
                )
                .toList();
    });
  }

  void _filtrarProdutos(String valor) {
    setState(() {
      pesquisa = valor;
      produtosFiltrados = valor.isEmpty
          ? produtosCache
          : produtosCache
                .where(
                  (p) => p.nome.toLowerCase().contains(valor.toLowerCase()),
                )
                .toList();
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _handleAdminSecretTap,
          child: const Row(
            children: [
              Icon(Icons.cake),
              SizedBox(width: 8),
              Text('Doces da Rita'),
            ],
          ),
        ),
        centerTitle: false,
        elevation: 4,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Badge(
              label: Text('$quantidadeTotal'),
              isLabelVisible: quantidadeTotal > 0,
              child: const Icon(Icons.shopping_cart),
            ),
            onPressed: quantidadeTotal == 0 ? null : finalizarPedido,
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MeusPedidosPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();

              if (!context.mounted) return;

              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AuthCheck()),
                (route) => false,
              );
            },
          ),
        ],
      ),

      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: SafeArea(
          child: Column(
            children: [
              _CardUsuario(
                expandido: _cardExpandido,
                onToggle: () =>
                    setState(() => _cardExpandido = !_cardExpandido),
                carrinho: carrinho,
                produtos: produtosCache,
                onAdicionar: adicionarProduto,
                onRemover: removerProduto,
                onPedidoFinalizado: limparCarrinho,
                onCarrinhoAtualizado: (atualizado) {
                  setState(() {
                    carrinho
                      ..clear()
                      ..addAll(atualizado);
                  });
                },
              ),

              const SizedBox(height: 10),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  focusNode: _pesquisaFocus,
                  autofocus: false,
                  decoration: InputDecoration(
                    hintText: 'Pesquisar doces...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onChanged: _filtrarProdutos,
                ),
              ),

              const SizedBox(height: 10),

              Expanded(
                child: produtosCache.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: carregarProdutos,
                        color: Colors.deepPurple,
                        child: GridView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.all(12),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.68,
                              ),
                          itemCount: produtosFiltrados.length,
                          itemBuilder: (context, index) {
                            final produto = produtosFiltrados[index];
                            final qtd = carrinho[produto.id] ?? 0;

                            return _ProdutoCard(
                              produto: produto,
                              quantidade: qtd,
                              onAdicionar: () => adicionarProduto(produto),
                              onRemover: () => removerProduto(produto),
                              onTap: () => showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                builder: (_) => ProdutoDetalhePage(
                                  produto: produto,
                                  adicionarProduto: adicionarProduto,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),

      // ── BOTTOM BAR COM WHATSAPP ──────────────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: quantidadeTotal == 0 ? null : finalizarPedido,
                  child: Text(
                    "Finalizar Pedido — R\$ ${total.toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              SizedBox(
                height: 50,
                width: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: abrirWhatsApp,
                  child: const FaIcon(
                    FontAwesomeIcons.whatsapp,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── CARD DO USUÁRIO ───────────────────────────────────────────────────────────
class _CardUsuario extends StatelessWidget {
  final bool expandido;
  final VoidCallback onToggle;
  final Map<String, int> carrinho;
  final List<Produto> produtos;
  final void Function(Produto) onAdicionar;
  final void Function(Produto) onRemover;
  final VoidCallback onPedidoFinalizado;
  final void Function(Map<String, int>) onCarrinhoAtualizado;

  const _CardUsuario({
    required this.expandido,
    required this.onToggle,
    required this.carrinho,
    required this.produtos,
    required this.onAdicionar,
    required this.onRemover,
    required this.onPedidoFinalizado,
    required this.onCarrinhoAtualizado,
  });

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return GestureDetector(
      onTap: onToggle,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Colors.deepPurple, Colors.pink],
          ),
        ),
        child: uid.isEmpty
            ? const SizedBox.shrink()
            : StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('usuarios')
                    .doc(uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  String nome = "Cliente";

                  if (snapshot.hasData && snapshot.data!.data() != null) {
                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    nome = data['nome'] ?? "Cliente";
                  }

                  final inicial = nome.isNotEmpty ? nome[0].toUpperCase() : "C";

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.white24,
                            child: Text(
                              inicial,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Olá, $nome!",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  "Os melhores doces da cidade",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            expandido
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: Colors.white70,
                          ),
                        ],
                      ),
                      AnimatedCrossFade(
                        duration: const Duration(milliseconds: 250),
                        crossFadeState: expandido
                            ? CrossFadeState.showFirst
                            : CrossFadeState.showSecond,
                        firstChild: Column(
                          children: [
                            const Divider(color: Colors.white30),
                            _MenuTile(
                              icon: Icons.person,
                              label: "Meu Perfil",
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PerfilPageNovo(),
                                ),
                              ),
                            ),
                            _MenuTile(
                              icon: Icons.local_offer_outlined,
                              label: "Promoção da Semana",
                              onTap: () async {
                                final atualizado =
                                    await Navigator.push<Map<String, int>>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => SobrePage(
                                          carrinho: carrinho,
                                          produtos: produtos,
                                          onAdicionar: onAdicionar,
                                          onRemover: onRemover,
                                          firestore: FirebaseFirestore.instance,
                                          onPedidoFinalizado:
                                              onPedidoFinalizado,
                                        ),
                                      ),
                                    );
                                if (atualizado != null) {
                                  onCarrinhoAtualizado(atualizado);
                                }
                              },
                            ),
                            _CuponsTile(uid: uid),
                          ],
                        ),
                        secondChild: const SizedBox.shrink(),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}

// ── TILE GENÉRICO DO MENU ─────────────────────────────────────────────────────
class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.white),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.white,
      ),
      onTap: onTap,
    );
  }
}

// ── TILE DE CUPONS COM BADGE ──────────────────────────────────────────────────
class _CuponsTile extends StatelessWidget {
  final String uid;

  const _CuponsTile({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('cupons').snapshots(),
      builder: (context, snapshot) {
        int disponiveis = 0;

        if (snapshot.hasData && uid.isNotEmpty) {
          disponiveis = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final ativo = data['ativo'] == true;
            final utilizado = data['utilizado'] == true;
            final ehGlobal = data['nomeUsuario'] == 'Todos';
            final ehDoUsuario = data['usuarioId'] == uid;
            return ativo && !utilizado && (ehGlobal || ehDoUsuario);
          }).length;
        }

        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.confirmation_number, color: Colors.white),
          title: const Text("Cupons", style: TextStyle(color: Colors.white)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (disponiveis > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "$disponiveis disponíveis",
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              const SizedBox(width: 6),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.white,
              ),
            ],
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MeusCuponsPage()),
          ),
        );
      },
    );
  }
}

// ── CARD DE PRODUTO ───────────────────────────────────────────────────────────
class _ProdutoCard extends StatelessWidget {
  final Produto produto;
  final int quantidade;
  final VoidCallback onAdicionar;
  final VoidCallback onRemover;
  final VoidCallback onTap;

  const _ProdutoCard({
    required this.produto,
    required this.quantidade,
    required this.onAdicionar,
    required this.onRemover,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: onTap,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 1.2,
                  child: produto.imagem.isNotEmpty
                      ? Image.network(produto.imagem, fit: BoxFit.cover)
                      : const Icon(Icons.cake, size: 60),
                ),
              ),
            ),

            const SizedBox(height: 6),

            GestureDetector(
              onTap: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    produto.nome,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    "R\$ ${produto.preco.toStringAsFixed(2)}",
                    style: const TextStyle(color: Colors.deepPurple),
                  ),
                ],
              ),
            ),

            const Spacer(),

            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: quantidade == 0
                  ? _BotaoAdicionar(
                      key: const ValueKey('btn'),
                      onTap: onAdicionar,
                    )
                  : _Stepper(
                      key: const ValueKey('stepper'),
                      quantidade: quantidade,
                      onAdicionar: onAdicionar,
                      onRemover: onRemover,
                    ),
            ),

            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

// ── BOTÃO "ADICIONAR" ─────────────────────────────────────────────────────────
class _BotaoAdicionar extends StatelessWidget {
  final VoidCallback onTap;

  const _BotaoAdicionar({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: Colors.deepPurple,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: Colors.white, size: 16),
            SizedBox(width: 4),
            Text(
              "Adicionar",
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── STEPPER COMPACTO ──────────────────────────────────────────────────────────
class _Stepper extends StatelessWidget {
  final int quantidade;
  final VoidCallback onAdicionar;
  final VoidCallback onRemover;

  const _Stepper({
    super.key,
    required this.quantidade,
    required this.onAdicionar,
    required this.onRemover,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.deepPurple, width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: onRemover,
            child: Container(
              width: 36,
              alignment: Alignment.center,
              child: const Icon(
                Icons.remove,
                color: Colors.deepPurple,
                size: 18,
              ),
            ),
          ),
          Text(
            "$quantidade",
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.deepPurple,
            ),
          ),
          GestureDetector(
            onTap: onAdicionar,
            child: Container(
              width: 36,
              decoration: const BoxDecoration(
                color: Colors.deepPurple,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.add, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
