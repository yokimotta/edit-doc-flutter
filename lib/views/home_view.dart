import 'package:flutter/material.dart';

import '../models/documento.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/documentos_viewmodel.dart';

/// VIEW: tela principal (rota "/home").
/// Mantém o layout original (banner + menu de cards) e acrescenta a lista
/// de documentos da Etapa 5.
class HomeView extends StatefulWidget {
  const HomeView({
    super.key,
    required this.authViewModel,
    required this.documentosViewModel,
  });

  final AuthViewModel authViewModel;
  final DocumentosViewModel documentosViewModel;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    final usuario = widget.authViewModel.usuarioLogado;
    if (usuario != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.documentosViewModel.carregar(usuario.email);
      });
    }
  }

  void _mostrarPreferencias() {
    final vm = widget.authViewModel;
    final tema = vm.tema ?? 'Não definido';

    String textoNotificacoes = 'Não definido';
    if (vm.notificacoes != null) {
      textoNotificacoes = vm.notificacoes! ? 'Ativadas' : 'Desativadas';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Preferências do Usuário'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tema: $tema'),
            const SizedBox(height: 8),
            Text('Notificações: $textoNotificacoes'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Future<void> _mostrarUsuarios() async {
    final usuarios = await widget.authViewModel.obterTodosUsuarios();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usuários no Banco Local'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: usuarios.length,
            itemBuilder: (context, index) {
              final usuario = usuarios[index];
              return ListTile(
                leading: const Icon(Icons.person),
                title: Text(usuario.nome),
                subtitle: Text(usuario.email),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarExclusao(Documento documento) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir documento'),
        content: Text('Deseja excluir "${documento.titulo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await widget.documentosViewModel.excluir(documento.id);
    }
  }

  Future<void> _sair() async {
    await widget.authViewModel.logout();
    widget.documentosViewModel.limpar();

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/');
  }

  Widget _criarCard(
    IconData icone,
    String titulo,
    Color cor,
    VoidCallback aoClicar,
  ) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: aoClicar,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icone, size: 48, color: cor),
            const SizedBox(height: 12),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  String _formatarData(DateTime d) {
    String dois(int n) => n.toString().padLeft(2, '0');
    return '${dois(d.day)}/${dois(d.month)}/${d.year} ${dois(d.hour)}:${dois(d.minute)}';
  }

  Widget _listaDocumentos() {
    final docs = widget.documentosViewModel;

    if (docs.carregando && docs.documentos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (docs.documentos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text('Nenhum documento ainda. Toque em "Novo documento".'),
        ),
      );
    }

    return Column(
      children: [
        for (final doc in docs.documentos)
          Card(
            child: ListTile(
              leading: const Icon(Icons.description),
              title: Text(doc.titulo),
              subtitle: Text(
                '${doc.conteudo.isEmpty ? '(sem conteúdo)' : doc.conteudo}\n'
                '${_formatarData(doc.atualizadoEm)}',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              isThreeLine: true,
              onTap: () =>
                  Navigator.pushNamed(context, '/editor', arguments: doc),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                tooltip: 'Excluir',
                onPressed: () => _confirmarExclusao(doc),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = widget.authViewModel;

    return ListenableBuilder(
      listenable: Listenable.merge([auth, widget.documentosViewModel]),
      builder: (context, _) {
        final nomeUsuario = auth.usuarioLogado?.nome ?? 'Usuário';

        return Scaffold(
          appBar: AppBar(
            title: const Text('Tela Principal'),
            actions: [
              IconButton(
                icon: Icon(auth.temaEscuro ? Icons.light_mode : Icons.dark_mode),
                tooltip: 'Alternar tema',
                onPressed: () => auth.alterarTema(!auth.temaEscuro),
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Sair',
                onPressed: _sair,
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.pushNamed(context, '/editor'),
            icon: const Icon(Icons.add),
            label: const Text('Novo documento'),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.account_circle,
                      size: 56,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Olá, $nomeUsuario!',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'O que você quer ver hoje?',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Menu',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
                children: [
                  _criarCard(
                    Icons.settings,
                    'Preferências do Usuário',
                    Colors.orange,
                    _mostrarPreferencias,
                  ),
                  _criarCard(
                    Icons.group,
                    'Usuários no Banco Local',
                    Colors.green,
                    _mostrarUsuarios,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Meus Documentos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _listaDocumentos(),
            ],
          ),
          bottomNavigationBar: Container(
            height: 50,
            color: Colors.blue,
            alignment: Alignment.center,
            child: const Text(
              'Desenvolvido por: Danilo Motta',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        );
      },
    );
  }
}
