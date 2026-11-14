import 'package:flutter/material.dart';

import '../models/documento.dart';
import '../utils/validadores.dart';
import '../viewmodels/documentos_viewmodel.dart';

/// VIEW: criação/edição de documento (rota "/editor").
/// Se [documento] for nulo, cria um novo; caso contrário, edita o existente.
class EditorView extends StatefulWidget {
  const EditorView({
    super.key,
    required this.documentosViewModel,
    this.documento,
  });

  final DocumentosViewModel documentosViewModel;
  final Documento? documento;

  @override
  State<EditorView> createState() => _EditorViewState();
}

class _EditorViewState extends State<EditorView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tituloController;
  late final TextEditingController _conteudoController;

  bool get _editando => widget.documento != null;

  @override
  void initState() {
    super.initState();
    _tituloController = TextEditingController(text: widget.documento?.titulo);
    _conteudoController =
        TextEditingController(text: widget.documento?.conteudo);
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final ok = await widget.documentosViewModel.salvar(
      existente: widget.documento,
      titulo: _tituloController.text,
      conteudo: _conteudoController.text,
    );

    if (!mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.documentosViewModel.erro ?? 'Não foi possível salvar',
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_editando ? 'Documento atualizado!' : 'Documento criado!'),
      ),
    );
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _conteudoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editando ? 'Editar Documento' : 'Novo Documento'),
        actions: [
          ListenableBuilder(
            listenable: widget.documentosViewModel,
            builder: (context, _) {
              return IconButton(
                icon: const Icon(Icons.save),
                tooltip: 'Salvar',
                onPressed:
                    widget.documentosViewModel.carregando ? null : _salvar,
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(
                  labelText: 'Título',
                  border: OutlineInputBorder(),
                ),
                validator: validarTituloDocumento,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TextFormField(
                  controller: _conteudoController,
                  decoration: const InputDecoration(
                    labelText: 'Conteúdo',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                  expands: true,
                  maxLines: null,
                  textAlignVertical: TextAlignVertical.top,
                  keyboardType: TextInputType.multiline,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ListenableBuilder(
                  listenable: widget.documentosViewModel,
                  builder: (context, _) {
                    return ElevatedButton(
                      onPressed: widget.documentosViewModel.carregando
                          ? null
                          : _salvar,
                      child: Text(_editando ? 'Salvar alterações' : 'Criar'),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
