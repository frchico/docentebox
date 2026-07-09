# 🚀 J-Bunker

Ambiente automatizado e seguro em Docker para compilação, isolamento e testes de projetos de alunos em Java 17, 21 e 25 (usando Maven ou Gradle).

---

## 📋 Pré-requisitos do Sistema

Antes de executar os scripts, certifique-se de ter instalado e configurado em sua máquina Windows:

1. 🐳 **Docker Desktop para Windows**
   * O Docker deve estar em execução (ícone verde "Running").
   * Certifique-se de que o Docker está configurado para usar containers Linux (padrão).
2. 🚀 **Git para Windows (Git Bash)**
   * Os scripts (`.sh`) devem ser executados obrigatoriamente através do terminal Git Bash.
3. 🌐 **Conexão com a Internet** (caso não tenha o cache das bibliotecas nas pastas locais).

> [!TIP] 
> Não é necessário ter o Java, Maven ou Gradle instalados nativamente na sua máquina física, pois o Docker se encarrega de fornecer todo o ambiente de build de forma isolada.

---

## 📂 Estrutura do Projeto

A arquitetura do projeto é modular, o que facilita a manutenção e execução do orquestrador principal.

```text
📂 CorrecoesSpring/
├── 📂 .cache_m2/              # Cache oculto local do Maven
├── 📂 .cache_gradle/          # Cache oculto local do Gradle
├── 📂 apps/                   # Subpasta onde moram os projetos dos alunos
│   └── 📂 nome_do_aluno/
│       ├── 📂 codigos/        # Código-fonte (Clone do Git ou extração manual)
│       └── 📂 app/            # JAR compilado, Dockerfile e logs de falha (erro_execucao.txt)
├── 📂 gerar_cache/            # Arquivos de templates para pré-carregar dependências
│   ├── 📄 cache.pom.xml
│   └── 📄 cache.build.gradle
├── 📂 modulos/                # Componentes modulares do orquestrador
│   ├── 📄 00_parametros.sh
│   ├── 📄 01_docker.sh
│   ├── 📄 02_1_limpeza.sh
│   ├── 📄 02_5_aquecimento.sh
│   ├── 📄 03_git_local.sh
│   ├── 📄 04_analise.sh
│   ├── 📄 05_build_cache.sh
│   ├── 📄 06_executar.sh
│   └── 📄 07_encerramento.sh
└── 📄 testar_aluno.sh         # Orquestrador principal da Sandbox
```

---

## ⚡ 1. Montagem do Cache (Executar uma única vez ou para atualizar)

Para evitar que o ambiente baixe o ecossistema do Spring Boot da internet para cada aluno, você pode pré-carregar as principais dependências (Spring Boot, Security, Swagger UI, H2, Lombok, etc.). O script detecta a versão do Java no seu molde e baixa as dependências corretas.

1. Abra o `Git Bash` na raiz do projeto.
2. Execute o comando de cache:
   `./testar_aluno.sh --cache` (ou `-c`)
3. O script aguardará interativamente. Caso queira baixar as dependências do Maven ou Gradle, digite 's' durante a contagem.

---

## 🎯 2. Como Testar o Projeto de um Aluno

O script `testar_aluno.sh` é inteligente: ele detecta a ferramenta de build (Maven/Gradle), a versão exata do Java, **descobre automaticamente a porta do aplicativo lendo os arquivos de propriedades (`application.properties` ou `application.yml`)**, gerencia o ciclo de vida do Git e aplica limites severos de segurança no container do aluno.

### 🌐 Cenário A: Baixando direto do GitHub do Aluno
O script clona o repositório automaticamente para dentro da pasta `apps/`:

```sh
./testar_aluno.sh [https://github.com/usuario/projeto-aluno.git](https://github.com/usuario/projeto-aluno.git)
```

Se rodar o comando novamente para o mesmo aluno, ele perguntará interativamente se você deseja atualizar o código. Confirmando, ele faz um `git fetch` e `git reset --hard` instantâneo. Se recusar, ele mantém o código local atual e prossegue.

### 📂 Cenário B: Copiando os arquivos manualmente

Se você já tem a pasta do aluno no seu computador:

1. Execute o comando passando o nome do aluno:
   `./testar_aluno.sh nome_do_aluno`
2. O script detectará que a pasta não existe, criará a estrutura em `apps/nome_do_aluno/codigos/` e pedirá para você extrair os arquivos lá dentro.
3. Cole o código do aluno e pressione ENTER no terminal para continuar.

---

## ⚙️ Opções Avançadas

Você pode passar chaves extras para customizar o comportamento do hardware, ferramentas e o fluxo do terminal:

| Flag / Opção              | Descrição                                                                                                                                                                       | Exemplo de Uso                                                  |
| :------------------------ | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | :-------------------------------------------------------------- |
| `-h`, `--help`            | Exibe o menu de ajuda e instruções de uso no terminal sem iniciar o ambiente.                                                                                                   | `./testar_aluno.sh --help`                                      |
| `--buildpath`             | Define um subdiretório específico dentro do repositório como a raiz para o build (ideal para monorepos).                                                                        | `./testar_aluno.sh URL_Git --buildpath backend`                 |
| `-c`, `--cache`, `/cache` | Dispara o módulo isolado de aquecimento dos caches globais do Maven e Gradle.                                                                                                   | `./testar_aluno.sh -c`                                          |
| `--clean`, `/clean`       | Remove imagens antigas acumuladas no Docker e apaga pastas locais em `apps/`. O processo é interativo, permitindo confirmar item a item ou usar o atalho `t` para varrer todas. | `./testar_aluno.sh --clean`                                     |
| `-f`, `--force`           | Force: Pula perguntas de Git, substituição, porta e **confirmações de limpeza**, forçando a ação imediata.                                                                      | `./testar_aluno.sh aluno1 -f`<br>`./testar_aluno.sh --clean -f` |
| `-mem`, `--mem`           | Customiza o limite de memória RAM do container (Padrão: 2g).                                                                                                                    | `./testar_aluno.sh aluno1 --mem 4g`                             |
| `-cpu`, `--cpu`           | Customiza a quantidade de núcleos de CPU alocados (Padrão: 4).                                                                                                                  | `./testar_aluno.sh aluno1 --cpu 2`                              |

**Exemplo combinando tudo:**
`./testar_aluno.sh https://github.com/aluno/projeto.git --force --mem 1g --cpu 2`

---

## 🌍 Acessando a Aplicação Rodando

A porta exposta será definida dinamicamente com base no código do aluno. Caso o script não consiga detectar (e a flag de força não estiver ativa), você poderá digitar a porta manualmente.

**Espera Inteligente (Healthcheck):** O script iniciará o container e aguardará silenciosamente até que o Spring Boot finalize o seu carregamento. Assim que a porta estiver pronta para responder, os atalhos de rede serão exibidos na tela:

* 💻 **Aplicação Base:** `http://localhost:<PORTA_DETECTADA>`
* 📑 **Documentação Swagger UI:** `http://localhost:<PORTA_DETECTADA>/swagger-ui/index.html`

**Em caso de Falha (Crash):** Se o projeto compilar com sucesso, mas a aplicação encontrar um erro fatal ao tentar subir, o script detectará a queda do container automaticamente. O processo será abortado com segurança e um arquivo `erro_execucao.txt` será salvo na pasta do aluno com o log completo.

**Encerramento do Teste:** Para fechar o ambiente, basta pressionar `CTRL + C` na janela do Git Bash. O container em segundo plano será encerrado e a porta liberada. Em seguida, o script perguntará interativamente se você deseja excluir a pasta física daquele aluno (`apps/nome_do_aluno`) imediatamente para poupar espaço em disco. Se a flag de força `-f` estiver ligada, a pasta é preservada e o prompt é omitido.

---

## 🔒 Camada de Segurança Aplicada (Sandbox)

O container do aluno é executado sob as seguintes restrições em ambiente isolado:
* **Não-Root:** Roda sob o usuário comum `sandboxuser`.
* **Read-Only File System:** O container não pode alterar arquivos internos do sistema (exceto a pasta `/tmp` que é limpa ao fechar).
* **Cap drop:** Remoção de todas as permissões administrativas do Kernel (`--cap-drop=ALL`).
* **Isolamento de Imagem:** A imagem Docker gerada usa o nome da pasta atual onde os scripts estão (ex: `sandbox-20261_prog1`). Um aluno sobrescreve o outro na execução padrão para proteger o espaço em disco do seu computador.

---
> [!Info]
> ## 🤖 Nota de Transparência e Desenvolvimento
> 
> Este repositório, incluindo a arquitetura dos scripts modulares de automação do **J-Bunker** e a documentação deste `README.md`, foi estruturado e refinado com o auxílio de Inteligência Artificial (IA). 
> 
> A IA atuou como copiloto de desenvolvimento para acelerar a formatação de manuais, otimizar a lógica de detecção inteligente, implementação de healthchecks no terminal, captura automática de logs de erro, isolamento de containers e garantir as melhores práticas de organização de código Bash para o ambiente docente.