import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../documento.dart';

/// MODEL (serviço): CRUD de documentos.
/// A lista de objetos Documento é serializada em JSON (jsonEncode/jsonDecode)
/// e guardada em uma única chave do shared_preferences.
class DocumentoStorageService {
  static const _chaveDocumentos = 'documentos';

  // READ
  Future<List<Documento>> listarPorUsuario(String usuarioEmail) async {
    final todos = await _lerTodos();
    final doUsuario =
        todos.where((d) => d.usuarioEmail == usuarioEmail).toList();
    // Mais recentes primeiro.
    doUsuario.sort((a, b) => b.atualizadoEm.compareTo(a.atualizadoEm));
    return doUsuario;
  }

  // CREATE
  Future<void> criar(Documento documento) async {
    final todos = await _lerTodos();
    await _salvarTodos([...todos, documento]);
  }

  // UPDATE
  Future<void> atualizar(Documento documento) async {
    final todos = await _lerTodos();
    final atualizados =
        todos.map((d) => d.id == documento.id ? documento : d).toList();
    await _salvarTodos(atualizados);
  }

  // DELETE
  Future<void> excluir(String id) async {
    final todos = await _lerTodos();
    await _salvarTodos(todos.where((d) => d.id != id).toList());
  }

  Future<List<Documento>> _lerTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final texto = prefs.getString(_chaveDocumentos);
    if (texto == null) return [];

    final lista = jsonDecode(texto) as List<dynamic>;
    return lista
        .map((item) => Documento.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> _salvarTodos(List<Documento> documentos) async {
    final prefs = await SharedPreferences.getInstance();
    final texto = jsonEncode(documentos.map((d) => d.toJson()).toList());
    await prefs.setString(_chaveDocumentos, texto);
  }
}
