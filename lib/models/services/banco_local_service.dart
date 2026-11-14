import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../usuario.dart';

/// MODEL (serviço): "banco" local de usuários.
///
/// Era a classe BancoDadosLocal do DartPad (lista em memória). Agora a lista
/// é serializada em JSON e guardada no shared_preferences, então sobrevive ao
/// recarregamento da página (F5).
class BancoLocalService {
  static const _chaveUsuarios = 'usuarios';

  // Mesmo usuário inicial que existia no DartPad.
  static const _usuarioInicial = Usuario(
    nome: 'Professor',
    email: 'prof@email.com',
    senha: '123456',
  );

  Future<List<Usuario>> obterTodosUsuarios() async {
    final prefs = await SharedPreferences.getInstance();
    final texto = prefs.getString(_chaveUsuarios);

    if (texto == null) {
      const inicial = [_usuarioInicial];
      await _salvar(prefs, inicial);
      return inicial;
    }

    final lista = jsonDecode(texto) as List<dynamic>;
    return lista
        .map((item) => Usuario.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<bool> cadastrarUsuario(Usuario novoUsuario) async {
    final prefs = await SharedPreferences.getInstance();
    final usuarios = await obterTodosUsuarios();

    final jaExiste = usuarios.any((u) => u.email == novoUsuario.email);
    if (jaExiste) return false;

    await _salvar(prefs, [...usuarios, novoUsuario]);
    return true;
  }

  Future<Usuario?> autenticar(String email, String senha) async {
    final usuarios = await obterTodosUsuarios();
    for (final u in usuarios) {
      if (u.email == email && u.senha == senha) return u;
    }
    return null;
  }

  Future<Usuario?> buscarPorEmail(String email) async {
    final usuarios = await obterTodosUsuarios();
    for (final u in usuarios) {
      if (u.email == email) return u;
    }
    return null;
  }

  Future<void> _salvar(SharedPreferences prefs, List<Usuario> usuarios) async {
    final texto = jsonEncode(usuarios.map((u) => u.toJson()).toList());
    await prefs.setString(_chaveUsuarios, texto);
  }
}
