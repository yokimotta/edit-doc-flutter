import 'package:flutter/foundation.dart';

import '../models/services/banco_local_service.dart';
import '../models/services/preferences_service.dart';
import '../models/usuario.dart';

/// VIEWMODEL: autenticação, cadastro e preferências (tema/notificações).
class AuthViewModel extends ChangeNotifier {
  AuthViewModel({PreferencesService? preferencias, BancoLocalService? banco})
      : _preferencias = preferencias ?? PreferencesService(),
        _banco = banco ?? BancoLocalService();

  final PreferencesService _preferencias;
  final BancoLocalService _banco;

  // ----- Estado -----
  Usuario? _usuarioLogado;
  String? _tema; // preferência salva: 'Claro' | 'Escuro' | null (não definido)
  bool? _notificacoes; // preferência salva (null = não definido)
  bool _carregando = false;
  String? _erro;

  // Rascunho do formulário de cadastro (antes era setState na TelaCadastro).
  String _temaCadastro = 'Claro';
  bool _notificacoesCadastro = true;

  Usuario? get usuarioLogado => _usuarioLogado;
  String? get tema => _tema;
  bool? get notificacoes => _notificacoes;
  bool get temaEscuro => _tema == 'Escuro';
  bool get carregando => _carregando;
  String? get erro => _erro;
  String get temaCadastro => _temaCadastro;
  bool get notificacoesCadastro => _notificacoesCadastro;

  // ----- Preferências e sessão -----

  /// Lê tema, notificações e sessão salvos. Chamado antes do runApp.
  Future<void> carregarPreferencias() async {
    _tema = await _preferencias.obterTema();
    _notificacoes = await _preferencias.obterNotificacoes();

    final email = await _preferencias.obterSessao();
    if (email != null) {
      _usuarioLogado = await _banco.buscarPorEmail(email);
    }
    notifyListeners();
  }

  Future<void> alterarTema(bool escuro) async {
    _tema = escuro ? 'Escuro' : 'Claro';
    notifyListeners();
    await _preferencias.salvarTema(_tema!);
  }

  void definirTemaCadastro(String valor) {
    _temaCadastro = valor;
    notifyListeners();
  }

  void definirNotificacoesCadastro(bool valor) {
    _notificacoesCadastro = valor;
    notifyListeners();
  }

  // ----- Autenticação -----

  Future<bool> login(String email, String senha) async {
    _carregando = true;
    _erro = null;
    notifyListeners();

    final usuario = await _banco.autenticar(email.trim().toLowerCase(), senha);

    if (usuario == null) {
      _erro = 'E-mail ou senha incorretos';
      _carregando = false;
      notifyListeners();
      return false;
    }

    _usuarioLogado = usuario;
    await _preferencias.salvarSessao(usuario.email);
    _carregando = false;
    notifyListeners();
    return true;
  }

  Future<bool> cadastrar(String nome, String email, String senha) async {
    _carregando = true;
    _erro = null;
    notifyListeners();

    final novoUsuario = Usuario(
      nome: nome.trim(),
      email: email.trim().toLowerCase(),
      senha: senha,
    );

    final cadastrou = await _banco.cadastrarUsuario(novoUsuario);

    if (!cadastrou) {
      _erro = 'Este e-mail já está cadastrado!';
      _carregando = false;
      notifyListeners();
      return false;
    }

    // Salva as preferências escolhidas no cadastro e aplica o tema.
    _tema = _temaCadastro;
    _notificacoes = _notificacoesCadastro;
    await _preferencias.salvarTema(_tema!);
    await _preferencias.salvarNotificacoes(_notificacoes!);

    _temaCadastro = 'Claro';
    _notificacoesCadastro = true;
    _carregando = false;
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    _usuarioLogado = null;
    await _preferencias.limparSessao();
    notifyListeners();
  }

  Future<List<Usuario>> obterTodosUsuarios() => _banco.obterTodosUsuarios();
}
