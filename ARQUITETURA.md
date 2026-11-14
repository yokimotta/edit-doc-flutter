Migração do código único do DartPad (`telas.dart`: Login, Cadastro e Home) para a arquitetura **MVVM** no repositório `edit-doc-flutter`.

## 1. Mapeamento de Classes e Widgets

| Código no DartPad | Onde ficou | Observação |
|---|---|---|
| `main()` | `lib/main.dart` | Agora é `async`: chama `WidgetsFlutterBinding.ensureInitialized()`, cria os ViewModels e carrega as preferências antes do `runApp`. |
| `MeuApp` (MaterialApp, tema, rotas) | `lib/main.dart` | `ThemeData` reativo (claro/escuro) via `ListenableBuilder` e rotas nomeadas `/`, `/cadastro`, `/home` (e `/editor` na Etapa 5). |
| `validarNome`, `validarEmail`, `validarSenha` | `lib/utils/validadores.dart` | Mesmas funções e mesmas regras, apenas movidas. |
| `Usuario` | `lib/models/usuario.dart` | Ganhou `toJson`/`fromJson` e construtor `const`. |
| `BancoDadosLocal` (lista estática em memória) | `lib/models/services/banco_local_service.dart` (`BancoLocalService`) | Métodos `static` viraram métodos de instância; a lista passou a ser salva em JSON no `shared_preferences`. |
| `SharedPreferences` (classe simulada) | **Removida**; substituída pelo pacote real, encapsulado em `lib/models/services/preferences_service.dart` | Evita conflito de nome com o pacote `shared_preferences`. |
| `TelaLogin` / `_TelaLoginState` | `lib/views/login_view.dart` (`LoginView`) | Só interface; chama `AuthViewModel.login`. |
| `TelaCadastro` / `_TelaCadastroState` | `lib/views/cadastro_view.dart` (`CadastroView`) | Só interface; chama `AuthViewModel.cadastrar`. |
| `TelaHome` (+ `_criarCard`, `_mostrarPreferencias`, `_mostrarUsuarios`) | `lib/views/home_view.dart` (`HomeView`) | `_criarCard` e os diálogos continuam na View (são interface); os dados vêm do ViewModel. |
| Lógica de `_fazerLogin` e `_cadastrar` (autenticar, cadastrar, gravar preferências) | `lib/viewmodels/auth_viewmodel.dart` (`AuthViewModel`) | Regra de negócio saiu das telas. |
| `_tema` e `_notificacoes` da `_TelaCadastroState` | `AuthViewModel` (`temaCadastro`, `notificacoesCadastro`) | Antes eram variáveis de estado da tela. |
| Leitura de preferências em `_mostrarPreferencias` | `AuthViewModel` (`tema`, `notificacoes`) | A View só exibe os valores. |
| Leitura de usuários em `_mostrarUsuarios` | `AuthViewModel.obterTodosUsuarios()` | Delega ao `BancoLocalService`. |

## 2. Alterações de Estrutura e Imports

- **Imports relativos entre camadas.** Cada arquivo importa só o que precisa: Views importam ViewModels e `utils`; ViewModels importam Models/Services; Models não importam nada das camadas de cima. O `main.dart` importa as Views e os ViewModels.
- **Renomeação das telas** (`TelaLogin` → `LoginView`, `TelaCadastro` → `CadastroView`, `TelaHome` → `HomeView`) para seguir a estrutura obrigatória do roteiro.
- **Construtores com injeção de dependência.** Sem pacote de injeção (Provider etc.), os ViewModels são criados uma vez no `main()` e passados por construtor às Views (`LoginView(authViewModel: ...)`). Os ViewModels também recebem os services por construtor (parâmetros opcionais), o que facilita trocar por um fake em testes.
- **Visibilidade (`_` é privado por arquivo em Dart).** Os atributos privados como `_tabelaUsuarios` deixaram de existir: o estado agora fica em campos privados dos ViewModels (`_usuarioLogado`, `_tema` etc.) expostos por **getters** públicos. As classes `_XxxState` continuaram privadas, no mesmo arquivo do seu widget.
- **Remoção de `static`.** `BancoDadosLocal.autenticar(...)` virou `BancoLocalService().autenticar(...)`, usado só pelo ViewModel.
- **Dado do usuário logado.** Antes, o nome ia para a Home via `arguments` da rota. Agora a Home lê `authViewModel.usuarioLogado`, e a sessão fica salva para sobreviver ao F5.
- **Rotas nomeadas** continuam em `main.dart` no mapa `routes`. Cada rota é uma função que constrói a View já com seus ViewModels; `/editor` recebe o `Documento` (ou `null`) em `arguments`.
- **Pacote real.** `flutter pub add shared_preferences` substitui a classe simulada do DartPad.

## 3. Mudanças no Gerenciamento de Estado

**`setState()` removidos das Views** (ambos na antiga `TelaCadastro`):

1. `setState` ao escolher o tema (`RadioGroup`) → `AuthViewModel.definirTemaCadastro(valor)`.
2. `setState` ao ligar/desligar notificações (`SwitchListTile`) → `AuthViewModel.definirNotificacoesCadastro(valor)`.

`TelaLogin` e `TelaHome` não usavam `setState`; a Home era `StatelessWidget` e hoje é `StatefulWidget` apenas para disparar o carregamento da lista no `initState`, sem `setState`. Nas Views não resta nenhum `setState`.

**Estado que passou a viver nos ViewModels**

| ViewModel | Variáveis de estado |
|---|---|
| `AuthViewModel` | `_usuarioLogado`, `_tema`, `_notificacoes`, `_carregando`, `_erro`, `_temaCadastro`, `_notificacoesCadastro` |
| `DocumentosViewModel` (Etapa 5) | `_documentos`, `_usuarioEmail`, `_carregando`, `_erro` |

**Como as telas reagem**

- Os ViewModels estendem `ChangeNotifier` e chamam `notifyListeners()` sempre que o estado muda (login, cadastro, troca de tema, CRUD de documentos).
- As Views usam `ListenableBuilder(listenable: viewModel, builder: ...)` apenas na parte da árvore que depende do estado:
  - `CadastroView`: a seção de tema, notificações e botão (`carregando`).
  - `LoginView`: o botão "Entrar" (desabilitado durante a autenticação).
  - `HomeView`: `Listenable.merge([auth, documentos])` para o banner, o ícone de tema e a lista de documentos.
  - `MeuApp`: escuta o `AuthViewModel` para trocar `themeMode` (claro/escuro) em tempo real.
- Estado puramente visual e local (os `TextEditingController` e o `GlobalKey<FormState>`) continua nas Views, pois não é regra de negócio.

---

## Etapa 5 (resumo)

- `PreferencesService`: tema (`String`), notificações (`bool`) e sessão (e-mail do usuário logado) no `shared_preferences`.
- `DocumentoStorageService`: CRUD completo; a lista de `Documento` é serializada com `jsonEncode`/`jsonDecode` em uma chave do `shared_preferences`.
- `DocumentosViewModel`: `carregar`, `salvar` (cria ou atualiza), `excluir` e `limpar`.
- `EditorView` (`/editor`): cria e edita documentos pelo ViewModel; a `HomeView` lista, abre para edição e exclui (com confirmação).
- Persistência após F5: documentos, usuários, tema e sessão ficam salvos.
