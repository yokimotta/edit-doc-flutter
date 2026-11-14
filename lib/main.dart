import 'package:flutter/material.dart';

import 'models/documento.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/documentos_viewmodel.dart';
import 'views/cadastro_view.dart';
import 'views/editor_view.dart';
import 'views/home_view.dart';
import 'views/login_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authViewModel = AuthViewModel();
  final documentosViewModel = DocumentosViewModel();

  // Carrega tema, preferências e sessão salvos antes de desenhar o app.
  await authViewModel.carregarPreferencias();

  final usuario = authViewModel.usuarioLogado;
  if (usuario != null) {
    await documentosViewModel.carregar(usuario.email);
  }

  runApp(
    MeuApp(
      authViewModel: authViewModel,
      documentosViewModel: documentosViewModel,
      rotaInicial: usuario != null ? '/home' : '/',
    ),
  );
}

class MeuApp extends StatelessWidget {
  const MeuApp({
    super.key,
    required this.authViewModel,
    required this.documentosViewModel,
    required this.rotaInicial,
  });

  final AuthViewModel authViewModel;
  final DocumentosViewModel documentosViewModel;
  final String rotaInicial;

  @override
  Widget build(BuildContext context) {
    // O ThemeData reage ao AuthViewModel: ao mudar o tema, o app se redesenha.
    return ListenableBuilder(
      listenable: authViewModel,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Aula de Roteamento e Form',
          theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
          darkTheme: ThemeData(
            primarySwatch: Colors.blue,
            useMaterial3: true,
            brightness: Brightness.dark,
          ),
          themeMode: authViewModel.temaEscuro ? ThemeMode.dark : ThemeMode.light,
          initialRoute: rotaInicial,
          routes: {
            '/': (context) => LoginView(authViewModel: authViewModel),
            '/cadastro': (context) => CadastroView(authViewModel: authViewModel),
            '/home': (context) => HomeView(
                  authViewModel: authViewModel,
                  documentosViewModel: documentosViewModel,
                ),
            '/editor': (context) => EditorView(
                  documentosViewModel: documentosViewModel,
                  documento:
                      ModalRoute.of(context)?.settings.arguments as Documento?,
                ),
          },
        );
      },
    );
  }
}
