<!-- TOC -->autoauto- [🚀 J-Bunker](#🚀-j-bunker)auto	- [📋 Pré-requisitos do Sistema](#📋-pré-requisitos-do-sistema)auto	- [📂 Estrutura do Projeto](#📂-estrutura-do-projeto)auto	- [⚡ 1. Montagem do Cache (Executar uma única vez)](#⚡-1-montagem-do-cache-executar-uma-única-vez)auto	- [🎯 2. Como Testar o Projeto de um Aluno](#🎯-2-como-testar-o-projeto-de-um-aluno)auto		- [🌐 Cenário A: Baixando direto do GitHub do Aluno](#🌐-cenário-a-baixando-direto-do-github-do-aluno)auto		- [📂 Cenário B: Copiando os arquivos manualmente](#📂-cenário-b-copiando-os-arquivos-manualmente)auto	- [⚙️ Opções Avançadas](#⚙️-opções-avançadas)auto	- [🌍 Acessando a Aplicação Rodando](#🌍-acessando-a-aplicação-rodando)auto	- [🔒 Camada de Segurança Aplicada (Sandbox)](#🔒-camada-de-segurança-aplicada-sandbox)autoauto<!-- /TOC -->

# 🚀 J-Bunker



Ambiente automatizado e seguro em Docker para compilação, isolamento e testes de projetos de alunos em Java 17, 21 e 25 (usando Maven ou Gradle).

---

## 📋 Pré-requisitos do Sistema

Antes de executar os scripts, certifique-se de ter instalado e configurado em sua máquina Windows:

1. 🐳 Docker Desktop para Windows
   * O Docker deve estar em execução (ícone verde "Running").
   * Certifique-se de que o Docker está configurado para usar containers Linux (padrão).
2. 🚀 Git para Windows (Git Bash)
   * Os scripts (.sh) devem ser executados obrigatoriamente através do terminal Git Bash.
3. 🌐 Conexão com a Internet (caso não tenha o cache das bibliotecas nas pastas locais)

> [!TIP] Não é necessário ter o Java, Maven ou Gradle instalados nativamente na sua máquina física, pois o Docker se encarrega de fornecer todo o ambiente de build de forma isolada.
---

## 📂 Estrutura do Projeto

```text
📂 CorrecoesSpring/
├── 📂 .cache_m2/              # Cache oculto local do Maven
├── 📂 .cache_gradle/          # Cache oculto local do Gradle
├── 📂 apps/                   # Subpasta onde moram os projetos dos alunos
│    └── 📂 nome_do_aluno/
│         ├── 📂 codigos/      # Código-fonte (Clone do Git ou extração manual)
│         └── 📂 app/          # JAR compilado e Dockerfile gerado
├── 📂 gerar_cache/            # Arquivos de templates para pré-carregar dependências
│    ├── 📄 cache.pom.xml
│    └── 📄 cache.build.gradle
├── 📄 gerar_cache_libs.sh     # Script interativo para alimentar os caches globais
└── 📄 testar_aluno.sh         # Script principal de execução da Sandbox
```

---

## ⚡ 1. Montagem do Cache (Executar uma única vez)

Para evitar que o ambiente baixe o ecossistema do Spring Boot da internet para cada aluno, você pode pré-carregar as principais dependências (`Spring Boot`, `Security/Auth`, `Swagger UI`, `H2` e `Lombok`).

1. Abra o `Git Bash` na raiz do projeto.
2. Execute o script de cache:
   `./gerar_cache_libs.sh`

3. O script aguardará 10 segundos para o Maven e 10 segundos para o Gradle. Caso queira baixar, digite 's' durante a contagem. O padrão é não baixar (`'n'`).

---

## 🎯 2. Como Testar o Projeto de um Aluno

O script `testar_aluno.sh` é inteligente: ele detecta a ferramenta de build (Maven/Gradle), a versão do Java (17/21/25), gerencia o ciclo de vida do Git e aplica limites severos de segurança no container do aluno.

### 🌐 Cenário A: Baixando direto do GitHub do Aluno
O script clona o repositório automaticamente para dentro da pasta `apps/`:

```sh
./testar_aluno.sh https://github.com/usuario/projeto-aluno.git
```

Se rodar o comando novamente para o mesmo aluno: Ele perguntará interativamente se você deseja atualizar o código. Se disser que sim, ele faz um `git fetch` e `git reset --hard` instantâneo (muito rápido). Se disser que não, ele mantém o código local atual e prossegue para rodar o projeto existente.

### 📂 Cenário B: Copiando os arquivos manualmente

Se você já tem a pasta do aluno no seu computador:

1. Execute o comando passando o nome do aluno:
   `./testar_aluno.sh nome_do_aluno`

2. O script detectará que a pasta não existe, criará a estrutura em `apps/nome_do_aluno/codigos/` e pedirá para você extrair os arquivos lá dentro.
3. Cole o código do aluno e pressione ENTER no terminal para continuar.

---

## ⚙️ Opções Avançadas

Você pode passar chaves extras para customizar o comportamento do hardware e o fluxo do terminal:

| Flag | Descrição                                                                            | Exemplo de Uso                   |
| ---- | ------------------------------------------------------------------------------------ | -------------------------------- |
| -f   | Force: Pula todas as perguntas de Git/Substituição e força o build completo do zero. | ./testar_aluno.sh aluno1 -f      |
| -mem | Customiza o limite de memória RAM do container (Padrão: 2g).                         | ./testar_aluno.sh aluno1 -mem 4g |
| -cpu | Customiza a quantidade de núcleos de CPU alocados (Padrão: 4).                       | ./testar_aluno.sh aluno1 -cpu 2  |



Exemplo combinando tudo:

`./testar_aluno.sh https://github.com/aluno/projeto.git -f -mem 1g -cpu 2`

---

## 🌍 Acessando a Aplicação Rodando

Assim que o container subir com sucesso, os atalhos de rede serão exibidos na tela:

* 💻 Aplicação Base: http://localhost:8080
* 📑 Documentação Swagger UI: http://localhost:8080/swagger-ui/index.html

Para encerrar o teste e liberar a porta 8080 para o próximo aluno, basta pressionar `CTRL + C` na janela do Git Bash.

---

## 🔒 Camada de Segurança Aplicada (Sandbox)

O container do aluno é executado sob as seguintes restrições em ambiente isolado:
* Não-Root: Roda sob o usuário comum `sandboxuser`.
* Read-Only File System: O container não pode alterar arquivos internos do sistema (exceto a pasta `/tmp` que é limpa ao fechar).
* Cap drop: Remoção de todas as permissões administrativas do Kernel (`--cap-drop=ALL`).
* Isolamento de Imagem: A imagem Docker gerada usa o nome da pasta atual onde os scripts estão (ex: `sandbox-20261_prog1`). Um aluno sobrescreve o outro na execução padrão para proteger o espaço em disco do seu computador.