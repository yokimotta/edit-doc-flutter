import 'package:shared_preferences/shared_preferences.dart';

/// MODEL (serviço): persistência chave-valor (String e bool) com o pacote
/// shared_preferences. Guarda o tema, as notificações e a sessão do usuário.
///
/// Substitui a classe SharedPreferences simulada que existia no DartPad.
class PreferencesService {
  static const _chaveTema = 'tema'; // 'Claro' ou 'Escuro'
  static const _chaveNotificacoes = 'notificacoes';
  static const _chaveSessao = 'sessao_email';

  Future<String?> obterTema() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_chaveTema);
  }

  Future<void> salvarTema(String tema) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chaveTema, tema);
  }

  Future<bool?> obterNotificacoes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_chaveNotificacoes);
  }

  Future<void> salvarNotificacoes(bool valor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_chaveNotificacoes, valor);
  }

  /// Sessão: guardamos o e-mail do usuário logado.
  Future<String?> obterSessao() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_chaveSessao);
  }

  Future<void> salvarSessao(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chaveSessao, email);
  }

  Future<void> limparSessao() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_chaveSessao);
  }
}
