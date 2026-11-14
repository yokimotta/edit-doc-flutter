# edit-doc-flutter

Editor de documentos em Flutter (Web) com arquitetura **MVVM**, persistência local com `shared_preferences` e tema claro/escuro.

Relatório técnico da migração: [ARQUITETURA.md](ARQUITETURA.md)

## Estrutura

```
lib/
├── main.dart                         # Ponto de entrada, ThemeData reativo e rotas nomeadas
├── models/
│   ├── usuario.dart
│   ├── documento.dart
│   └── services/
│       ├── preferences_service.dart        # Tema, notificações e sessão
│       ├── banco_local_service.dart        # CRUD de usuários
│       └── documento_storage_service.dart  # CRUD de documentos (JSON)
├── viewmodels/
│   ├── auth_viewmodel.dart
│   └── documentos_viewmodel.dart
├── views/
│   ├── login_view.dart               # /
│   ├── cadastro_view.dart            # /cadastro
│   ├── home_view.dart                # /home
│   └── editor_view.dart              # /editor
└── utils/
    └── validadores.dart
```

## Como rodar (Codespaces)

```bash
flutter create . --project-name edit_doc_flutter
flutter pub add shared_preferences
rm -f test/widget_test.dart   # o teste padrão referencia MyApp, que não existe mais
```

Depois pressione **F5** (Run and Debug). O preview abre na porta 8080.

Usuário de teste: `prof@email.com` / `123456`.
