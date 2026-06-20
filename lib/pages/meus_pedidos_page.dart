import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'acompanhamento_page.dart';

class MeusPedidosPage extends StatefulWidget {
  const MeusPedidosPage({super.key});

  @override
  State<MeusPedidosPage> createState() => _MeusPedidosPageState();
}

class _MeusPedidosPageState extends State<MeusPedidosPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> pedidos = [];
  bool carregando = false;
  String busca = '';

  @override
  void initState() {
    super.initState();
    buscarPedidos();
  }

  Future<void> buscarPedidos() async {
    setState(() {
      carregando = true;
      pedidos = [];
    });

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() {
        carregando = false;
      });
      return;
    }

    final snapshot = await firestore
        .collection("pedidos")
        .where("userId", isEqualTo: user.uid)
        .get();

    pedidos = snapshot.docs.map((doc) {
      final data = doc.data();
      data["id"] = doc.id;
      return data;
    }).toList();

    pedidos.sort((a, b) {
      final dataA = a["data"] as Timestamp?;
      final dataB = b["data"] as Timestamp?;

      if (dataA == null || dataB == null) return 0;

      return dataB.compareTo(dataA);
    });

    setState(() {
      carregando = false;
    });
  }

  String formatarData(Timestamp? timestamp) {
    if (timestamp == null) return "Sem data";

    final data = timestamp.toDate();

    return "${data.day.toString().padLeft(2, '0')}/"
        "${data.month.toString().padLeft(2, '0')}/"
        "${data.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Meus Pedidos"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.receipt_long, size: 80, color: Colors.deepPurple),

            const SizedBox(height: 16),

            const Text(
              "Seus pedidos recentes",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),

            TextField(
              decoration: InputDecoration(
                hintText: 'Buscar produto...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  busca = value.toLowerCase();
                });
              },
            ),

            const SizedBox(height: 20),

            if (carregando)
              const Expanded(child: Center(child: CircularProgressIndicator())),

            if (!carregando && pedidos.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: pedidos.length,
                  itemBuilder: (context, index) {
                    final pedido = pedidos[index];

                    final Timestamp? dataPedido = pedido["data"] as Timestamp?;

                    final itens = pedido["itens"] as List<dynamic>? ?? [];

                    final encontrou =
                        busca.isEmpty ||
                        itens.any(
                          (item) => (item["nome"] ?? "")
                              .toString()
                              .toLowerCase()
                              .contains(busca),
                        );

                    if (!encontrou) {
                      return const SizedBox.shrink();
                    }

                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),

                        leading: CircleAvatar(
                          backgroundColor: Colors.deepPurple.shade100,
                          child: const Icon(
                            Icons.receipt_long,
                            color: Colors.deepPurple,
                          ),
                        ),

                        title: Text(
                          "Pedido #${pedido["id"].toString().substring(0, 6)}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),

                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("📅 ${formatarData(dataPedido)}"),
                              Text(
                                "💰 R\$ ${(pedido["total"] ?? 0).toString()}",
                              ),
                              Text("🚚 ${pedido["status"] ?? "Novo"}"),
                            ],
                          ),
                        ),

                        trailing: const Icon(Icons.arrow_forward_ios),

                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AcompanhamentoPage(pedidoId: pedido["id"]),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),

            if (!carregando && pedidos.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    "Nenhum pedido encontrado",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
