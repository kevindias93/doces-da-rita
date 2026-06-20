import 'package:flutter/material.dart';

class PrivacidadePage extends StatelessWidget {
  const PrivacidadePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Política de Privacidade',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      color: Colors.white70,
                      size: 32,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Política de Privacidade',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Doces da Rita · Última atualização: Junho de 2026',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              _PrivacidadeSection(
                numero: '1',
                titulo: 'Dados Coletados',
                conteudo: 'O aplicativo pode coletar:',
                itens: const [
                  'Nome',
                  'E-mail',
                  'Telefone',
                  'Endereço de entrega',
                  'Histórico de pedidos',
                  'Identificador do dispositivo',
                ],
              ),
              _PrivacidadeSection(
                numero: '2',
                titulo: 'Finalidade',
                conteudo: 'Os dados são utilizados para:',
                itens: const [
                  'Processar pedidos',
                  'Realizar entregas',
                  'Entrar em contato com o cliente',
                  'Enviar notificações relacionadas aos pedidos',
                  'Melhorar a experiência de uso',
                ],
              ),
              _PrivacidadeSection(
                numero: '3',
                titulo: 'Armazenamento',
                conteudo:
                    'Os dados são armazenados utilizando os serviços do Firebase, fornecidos pela Google.',
              ),
              _PrivacidadeSection(
                numero: '4',
                titulo: 'Compartilhamento',
                conteudo:
                    'A Doces da Rita não vende, aluga ou compartilha dados pessoais com terceiros para fins comerciais.',
              ),
              _PrivacidadeSection(
                numero: '5',
                titulo: 'Segurança',
                conteudo:
                    'São adotadas medidas técnicas para proteger as informações dos usuários contra acesso não autorizado.',
              ),
              _PrivacidadeSection(
                numero: '6',
                titulo: 'Exclusão de Dados',
                conteudo:
                    'O usuário poderá solicitar a exclusão de sua conta e de seus dados entrando em contato com a Doces da Rita.',
              ),
              _PrivacidadeSection(
                numero: '7',
                titulo: 'Alterações',
                conteudo:
                    'Esta Política de Privacidade poderá ser atualizada periodicamente para refletir melhorias ou exigências legais.',
              ),
              _PrivacidadeSection(
                numero: '8',
                titulo: 'Contato',
                conteudo:
                    'Em caso de dúvidas sobre privacidade ou tratamento de dados, entre em contato com a equipe da Doces da Rita.',
                isLast: true,
              ),

              const SizedBox(height: 8),

              // Rodapé
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.deepPurple.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      color: Colors.deepPurple,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Seus dados são tratados com segurança e respeito.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.deepPurple.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrivacidadeSection extends StatelessWidget {
  final String numero;
  final String titulo;
  final String conteudo;
  final List<String> itens;
  final bool isLast;

  const _PrivacidadeSection({
    required this.numero,
    required this.titulo,
    required this.conteudo,
    this.itens = const [],
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 16 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Número da seção
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.deepPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                numero,
                style: const TextStyle(
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Conteúdo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    conteudo,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      height: 1.55,
                    ),
                  ),
                  if (itens.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ...itens.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 5),
                              child: Icon(
                                Icons.circle,
                                size: 5,
                                color: Colors.deepPurple,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                  height: 1.55,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
