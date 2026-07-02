# 🧰 DocenteBox — Central de Ferramentas de Correção Educacional

O **DocenteBox** é um repositório desenvolvido para unificar scripts, utilitários, templates e automações voltadas à gestão de turmas, correção de avaliações e suporte à docência.

Em vez de espalhar pequenos utilitários por várias pastas no computador, o DocenteBox organiza cada ferramenta em submódulos isolados e fáceis de manter.

---

## 📂 Módulos e Ferramentas Disponíveis

Atualmente, o ecossistema é composto pelos seguintes módulos:

### 1. 🔒 J-Bunker (Java Sandbox Code Evaluator)
Localizado na pasta `/j-bunker`, é um ambiente automatizado e altamente seguro baseado em Docker para compilação, isolamento e execução de projetos Spring Boot (Java 17, 21 e 25). Ele permite baixar repositórios do GitHub de alunos ou analisar códigos locais sem expor o sistema anfitrião.

> 👉 *Para instruções detalhadas de uso e comandos, consulte o [README interno do J-Bunker](./j-bunker/README.md).*

### 2. 📄 Templates e Diretrizes Académicas 

Localizado na pasta `/templates-academicos`, este módulo centraliza as estruturas de documentos não oficiais, normas e templates de escrita utilizados nos cursos superiores do campus, divididos em:

* 🎓 **CBSI:** Modelos de artigos, relatórios técnicos, TCCs e a classe nativa `cbsi_ifs.cls`.
* 💻 **CADS (ADS):** Manuais de TCC, regulamentos, modelos de projetos de pesquisa, monografias e templates de slides para apresentações de bancas.

> Ele serve como repositório de consulta rápida e geração de documentos estruturados. Saiba mais [aqui](https://adsifs.github.io/TCC-CADS/).

---

## 📐 Estrutura Global do Repositório

```text
📂 DocenteBox/                 # Repositório Git Principal
│
├── 📄 README.md               # Este arquivo (Visão geral do ecossistema)
├── 📄 .gitignore              # Regras globais de exclusão do Git
│
└── 📂 j-bunker/               # 🚀 Módulo J-Bunker (Sandbox Java)
└── 📂 templates-academicos/   # 📄 Módulo de Documentos e Modelos
```