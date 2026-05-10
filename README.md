# HiVision TCC – Sistema Integrado de Gestão e Monitoramento de Clínicas

## Visão Geral

Este repositório contém o projeto completo do TCC "HIVision", uma solução integrada para gestão de clínicas, acompanhamento de pacientes e suporte à tomada de decisão médica. O sistema é composto por múltiplos módulos, incluindo backend (APIs), aplicativos móveis, web e ferramentas administrativas.

## Estrutura do Projeto

- **apis/**: Backend em Node.js (NestJS) com PostgreSQL, responsável por autenticação, gerenciamento de usuários (médicos, pacientes), agendamentos, locais de atendimento e integrações.
- **hivision/**: Aplicativo principal multiplataforma (Flutter) para médicos e pacientes, com versões para Android, iOS e Web.
  - **android/**, **ios/**, **web/**: Plataformas específicas do app Flutter.
- **gerenciador/**: Ferramenta administrativa (Flutter) para gestão avançada, relatórios e análise de dados.
- **hivision_design/**: Materiais de design e prototipação.
- **hivision_relatorios/**: Relatórios e documentos de apoio ao TCC.

## Funcionalidades Principais

- Cadastro e autenticação de usuários (médicos, pacientes, administradores)
- Edição de perfil com validação de senha
- Agendamento e gerenciamento de consultas
- Cadastro de locais de atendimento
- Relatórios e dashboards administrativos
- Interface moderna e responsiva (Flutter)
- Backend seguro com validação e integração ao banco de dados

## Tecnologias Utilizadas

- **Frontend:** Flutter (Dart)
- **Backend:** NestJS (TypeScript)
- **Banco de Dados:** PostgreSQL
- **DevOps:** Docker, docker-compose
- **Outros:** CocoaPods (iOS), ferramentas de build Android/iOS/Web

## Como Executar

1. **APIs:**
   - Entre em `apis/` e rode `npm install`.
   - Configure o banco PostgreSQL (veja `docker-compose.yml` e arquivos em `postgres/`).
   - Execute `npm run start:dev`.
2. **Aplicativo Flutter:**
   - Entre em `hivision/` ou `gerenciador/`.
   - Rode `flutter pub get`.
   - Execute emulador ou dispositivo: `flutter run`.
3. **Web:**
   - Entre em `hivision/web` ou `gerenciador/web` e rode `flutter run -d chrome`.

## Organização dos Códigos

- Cada módulo tem seu próprio `.gitignore` e README.
- Apenas código-fonte, configs e assets essenciais são versionados.
- Builds, dependências e arquivos temporários são ignorados.

## Contribuição

1. Crie uma branch a partir da `main` ou `develop`.
2. Faça commits claros e objetivos.
3. Abra um Pull Request descrevendo as mudanças.

## Licença

Projeto acadêmico – uso livre para fins educacionais.

---

**Autores:**

- Erick Veríssimo
- Colaboradores e orientadores do TCC

Dúvidas? Abra uma issue ou entre em contato.
