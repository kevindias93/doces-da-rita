import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminCuponsPage extends StatefulWidget {
  const AdminCuponsPage({super.key});

  @override
  State<AdminCuponsPage> createState() => _AdminCuponsPageState();
}

String? usuarioSelecionadoId;
String? usuarioSelecionadoNome;

class _AdminCuponsPageState extends State<AdminCuponsPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  final TextEditingController codigoController = TextEditingController();
  final TextEditingController valorController = TextEditingController();
  final TextEditingController limiteController = TextEditingController();

  String tipo = "percentual";
  bool ativo = true;
  bool cupomParaTodos = false;

  Future<void> salvarCupom({String? id}) async {
    final codigo = codigoController.text.trim().toUpperCase();
    final valor = double.tryParse(valorController.text) ?? 0;
    final limite = int.tryParse(limiteController.text) ?? 999999;

    if (codigo.isEmpty) return;

    final data = {
      "usuarioId": cupomParaTodos ? null : usuarioSelecionadoId,
      "nomeUsuario": cupomParaTodos ? "Todos" : usuarioSelecionadoNome,
      "criadoEm": FieldValue.serverTimestamp(),
      "codigo": codigo,
      "tipo": tipo,
      "valor": valor,
      "ativo": ativo,
      "limiteUsos": limite,
      "usos": 0,
      "esgotado": false,
    };

    if (id == null) {
      await firestore.collection("cupons").add(data);
    } else {
      await firestore.collection("cupons").doc(id).update(data);
    }

    limparCampos();
  }

  void limparCampos() {
    codigoController.clear();
    valorController.clear();
    limiteController.clear();
    tipo = "percentual";
    ativo = true;
    setState(() {});
  }

  void editar(DocumentSnapshot doc) {
    final data = Map<String, dynamic>.from(doc.data() as Map);

    codigoController.text = data["codigo"] ?? "";
    valorController.text = (data["valor"] ?? "").toString();
    limiteController.text = (data["limiteUsos"] ?? 999999).toString();

    tipo = data["tipo"] ?? "percentual";
    ativo = data["ativo"] ?? true;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin - Cupons")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: codigoController,
                  decoration: const InputDecoration(
                    labelText: "Código do cupom",
                  ),
                ),
                TextField(
                  controller: valorController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Valor (10 ou 5.50)",
                  ),
                ),
                TextField(
                  controller: limiteController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Limite de usos",
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text("Tipo: "),
                    DropdownButton<String>(
                      value: tipo,
                      items: const [
                        DropdownMenuItem(
                          value: "percentual",
                          child: Text("Percentual (%)"),
                        ),
                        DropdownMenuItem(
                          value: "fixo",
                          child: Text("Valor fixo (R\$)"),
                        ),
                      ],
                      onChanged: (v) {
                        setState(() {
                          tipo = v!;
                        });
                      },
                    ),
                  ],
                ),
                SwitchListTile(
                  value: ativo,
                  title: const Text("Ativo"),
                  onChanged: (v) {
                    setState(() {
                      ativo = v;
                    });
                  },
                ),

                if (!cupomParaTodos)
                  StreamBuilder<QuerySnapshot>(
                    stream: firestore.collection("usuarios").snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const CircularProgressIndicator();
                      }

                      final usuarios = snapshot.data!.docs;

                      return DropdownButtonFormField<String>(
                        value: usuarioSelecionadoId,
                        decoration: const InputDecoration(
                          labelText: "Selecionar usuário",
                        ),
                        items: usuarios.map((doc) {
                          final data = Map<String, dynamic>.from(
                            doc.data() as Map,
                          );

                          return DropdownMenuItem<String>(
                            value: doc.id,
                            child: Text(data["nome"] ?? "Sem nome"),
                          );
                        }).toList(),
                        onChanged: (value) {
                          final doc = usuarios.firstWhere((e) => e.id == value);

                          final data = Map<String, dynamic>.from(
                            doc.data() as Map,
                          );

                          setState(() {
                            usuarioSelecionadoId = doc.id;
                            usuarioSelecionadoNome = data["nome"] ?? "";
                          });
                        },
                      );
                    },
                  ),

                SwitchListTile(
                  value: cupomParaTodos,
                  title: const Text("Cupom para todos os usuários"),
                  onChanged: (v) {
                    setState(() {
                      cupomParaTodos = v;
                    });
                  },
                ),

                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => salvarCupom(),
                  child: const Text("Salvar Cupom"),
                ),
              ],
            ),
          ),

          const Divider(),

          Expanded(
            child: StreamBuilder(
              stream: firestore.collection("cupons").snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = Map<String, dynamic>.from(doc.data() as Map);

                    final usos = data["usos"] ?? 0;
                    final limite = data["limiteUsos"] ?? 0;
                    final esgotado = usos >= limite;

                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        title: Text(data["codigo"]),
                        subtitle: Text(
                          "Tipo: ${data["tipo"]} | Valor: ${data["valor"]} | Usos: $usos / $limite",
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => editar(doc),
                            ),
                            IconButton(
                              icon: Icon(
                                esgotado
                                    ? Icons.block
                                    : (data["ativo"]
                                          ? Icons.check_circle
                                          : Icons.cancel),
                                color: esgotado
                                    ? Colors.orange
                                    : (data["ativo"]
                                          ? Colors.green
                                          : Colors.red),
                              ),
                              onPressed: () {
                                firestore
                                    .collection("cupons")
                                    .doc(doc.id)
                                    .update({"ativo": !data["ativo"]});
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                firestore
                                    .collection("cupons")
                                    .doc(doc.id)
                                    .delete();
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
