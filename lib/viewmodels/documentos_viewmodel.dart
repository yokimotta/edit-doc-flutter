import 'package:flutter/foundation.dart';

import '../models/documento.dart';
import '../models/services/documento_storage_service.dart';

/// VIEWMODEL: listagem e operações CRUD dos documentos do usuário logado.
class DocumentosViewModel extends ChangeNotifier {
  DocumentosViewModel({DocumentoStorageService? storage})
      : _storage = storage ?? DocumentoStorageService();

  final DocumentoStorageService _storage;

  List<Documento> _documentos = [];
  String? _usuarioEmail;
  bool _carregando = false;
  String? _erro;

  List<Documento> get documentos => List.unmodifiable(_documentos);
  bool get carregando => _carregando;
  String? get erro => _erro;

  /// READ: carrega os documentos do usuário informado.
  Future<void> carregar(String usuarioEmail) async {
    _usuarioEmail = usuarioEmail;
    _carregando = true;
    _erro = null;
    notifyListeners();

    _documentos = await _storage.listarPorUsuario(usuarioEmail);

    _carregando = false;
    notifyListeners();
  }

  /// CREATE (existente == null) ou UPDATE (existente != null).
  Future<bool> salvar({
    Documento? existente,
    required String titulo,
    required String conteudo,
  }) async {
    final email = _usuarioEmail;
    if (email == null) {
      _erro = 'Nenhum usuário logado.';
      notifyListeners();
      return false;
    }

    _carregando = true;
    _erro = null;
    notifyListeners();

    final agora = DateTime.now();

    if (existente == null) {
      await _storage.criar(Documento(
        id: agora.microsecondsSinceEpoch.toString(),
        titulo: titulo.trim(),
        conteudo: conteudo,
        usuarioEmail: email,
        atualizadoEm: agora,
      ));
    } else {
      await _storage.atualizar(existente.copyWith(
        titulo: titulo.trim(),
        conteudo: conteudo,
        atualizadoEm: agora,
      ));
    }

    _documentos = await _storage.listarPorUsuario(email);
    _carregando = false;
    notifyListeners();
    return true;
  }

  /// DELETE
  Future<void> excluir(String id) async {
    final email = _usuarioEmail;
    if (email == null) return;

    await _storage.excluir(id);
    _documentos = await _storage.listarPorUsuario(email);
    notifyListeners();
  }

  /// Usado no logout: limpa o estado em memória (os dados continuam salvos).
  void limpar() {
    _documentos = [];
    _usuarioEmail = null;
    _erro = null;
    notifyListeners();
  }
}
