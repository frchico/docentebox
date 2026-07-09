#!/bin/bash

# === VERIFICAÇÃO: O DOCKER ESTÁ RODANDO? ===
echo "🐳 Verificando se o Docker Desktop está ativo..."
docker info >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "--------------------------------------------------------"
    echo "❌ ERRO: O Docker Desktop não está rodando!"
    echo "👉 Por favor, abra o aplicativo Docker Desktop no Windows."
    echo "👉 Aguarde o ícone no canto inferior esquerdo ficar VERDE (Running)."
    echo "--------------------------------------------------------"
    exit 1
fi

# === VALORES PADRÕES DE HARDWARE ===
MEMORIA_CONTAINER="2g"
CPUS_CONTAINER="4"

# === PROCESSAMENTO DE ARGUMENTOS AVANÇADO ===
FORCAR_SUBSTITUICAO="nao"
PARAMETRO=""
ARG_OPCIONAL=""

while [ "$#" -gt 0 ]; do
    case "$1" in
        -f)
            FORCAR_SUBSTITUICAO="sim"
            shift
            ;;
        -mem)
            if [ -n "$2" ]; then
                MEMORIA_CONTAINER="$2"
                shift 2
            else
                echo "❌ Erro: O parâmetro -mem exige um valor (Ex: -mem 4g)"
                exit 1
            fi
            ;;
        -cpu)
            if [ -n "$2" ]; then
                CPUS_CONTAINER="$2"
                shift 2
            else
                echo "❌ Erro: O parâmetro -cpu exige um valor (Ex: -cpu 2)"
                exit 1
            fi
            ;;
        *)
            if [ -z "$PARAMETRO" ]; then
                PARAMETRO="$1"
            else
                ARG_OPCIONAL="$1"
            fi
            shift
            ;;
    esac
done

if [ -z "$PARAMETRO" ]; then
    echo "Uso:"
    echo "  Por pasta local: ./testar_aluno.sh <nome_da_pasta_do_aluno> [opções]"
    echo "  Por GitHub:      ./testar_aluno.sh <URL_do_GitHub_do_Aluno> [nome_da_pasta_opcional] [opções]"
    echo ""
    echo "Opções:"
    echo "  -f               Força a atualização e compilação completa sem fazer perguntas."
    echo "  -mem <valor>     Define a memória do container (Padrão: 2g. Ex: -mem 4g)"
    echo "  -cpu <valor>     Define a quantidade de CPUs do container (Padrão: 4. Ex: -cpu 2)"
    echo ""
    echo "Exemplos:"
    echo "  ./testar_aluno.sh aluno1 -mem 4g -cpu 2"
    echo "  ./testar_aluno.sh https://github.com/aluno/projeto.git -f"
    exit 1
fi

DIRETORIOBASE=$(pwd -W 2>/dev/null || pwd)
COMPILAR_NOVAMENTE="sim"

# Garantir que a pasta centralizadora 'apps' existe na raiz
mkdir -p ./apps

# 🧠 INTELIGÊNCIA DE NOME: Descobre o nome da pasta atual do script e limpa para o Docker
NOME_PASTA_PAI=$(basename "$(pwd)")
NOME_PASTA_LIMPO=$(echo "$NOME_PASTA_PAI" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9_-')

IMAGEM_FINAL="sandbox-$NOME_PASTA_LIMPO"

# 1. IDENTIFICA SE É URL DO GITHUB OU PASTA LOCAL
if [[ "$PARAMETRO" =~ ^https://github.com/.* ]]; then
    echo "🌐 Detectado: Entrada via URL do GitHub."
    
    if [ -n "$ARG_OPCIONAL" ]; then
        ALUNO=$ARG_OPCIONAL
    else
        ALUNO=$(basename "$PARAMETRO" .git)
    fi
    
    # Redirecionado para dentro da pasta 'apps'
    PASTA_ALUNO_RAIZ="./apps/$ALUNO"
    PASTA_CODIGOS_LOCAL="$PASTA_ALUNO_RAIZ/codigos"
    
    if [ -d "$PASTA_CODIGOS_LOCAL/.git" ]; then
        if [ "$FORCAR_SUBSTITUICAO" = "nao" ]; then
            echo "⚠️  O repositório do aluno '$ALUNO' já existe localmente em apps/."
            read -r -p "Deseja atualizar para a última versão do GitHub? (s/n): " RESP_GIT
            RESP_GIT=$(echo "$RESP_GIT" | tr '[:upper:]' '[:lower:]')
            if [[ "$RESP_GIT" == "s" || "$RESP_GIT" == "sim" ]]; then
                echo "🔄 Atualizando repositório existente via Git Fetch & Reset..."
                cd "$PASTA_CODIGOS_LOCAL"
                git fetch --all
                BRANCH_PADRAO=$(git remote show origin | grep 'HEAD branch' | cut -d' ' -f5)
                git reset --hard "origin/$BRANCH_PADRAO"
                cd "$DIRETORIOBASE"
            else
                echo "⏭️  Mantendo os arquivos locais atuais sem atualizar do GitHub..."
            fi
        else
            echo "🔄 Flag -f detectada! Forçando atualização do repositório..."
            cd "$PASTA_CODIGOS_LOCAL"
            git fetch --all
            BRANCH_PADRAO=$(git remote show origin | grep 'HEAD branch' | cut -d' ' -f5)
            git reset --hard "origin/$BRANCH_PADRAO"
            cd "$DIRETORIOBASE"
        fi
    else
        echo "🧹 Preparando ambiente para o download do Git em: $PASTA_ALUNO_RAIZ"
        rm -rf "$PASTA_ALUNO_RAIZ"
        mkdir -p "$PASTA_CODIGOS_LOCAL"
        
        echo "📥 Clonando repositório do aluno..."
        git clone "$PARAMETRO" "$PASTA_CODIGOS_LOCAL"
        
        if [ $? -ne 0 ]; then
            echo "❌ Erro ao clonar o repositório do GitHub!"
            exit 1
        fi
    fi
else
    # === CENÁRIO 2: PASTA LOCAL ===
    ALUNO=$PARAMETRO
    # Redirecionado para dentro da pasta 'apps'
    PASTA_ALUNO_RAIZ="./apps/$ALUNO"
    PASTA_CODIGOS_LOCAL="$PASTA_ALUNO_RAIZ/codigos"
    PASTA_APP_LOCAL="$PASTA_ALUNO_RAIZ/app"
    
    if [ ! -d "$PASTA_CODIGOS_LOCAL" ]; then
        echo "📂 A pasta do aluno '$ALUNO' não foi encontrada em apps/$ALUNO/codigos."
        echo "🛠️ Criando a estrutura necessária automaticamente..."
        mkdir -p "$PASTA_CODIGOS_LOCAL"
        
        echo "--------------------------------------------------------"
        echo "⚠️  AÇÃO REQUERIDA:"
        echo "Por favor, extraia os arquivos do aluno agora."
        echo "👉 O local correto é dentro de: apps/$ALUNO/codigos/"
        echo "👉 Lá deve ficar diretamente o arquivo pom.xml ou build.gradle do aluno."
        echo "--------------------------------------------------------"
        
        read -p "Pressione [ENTER] quando terminar de copiar os arquivos para continuar..."
        echo ""
    else
        if [ -f "$PASTA_APP_LOCAL/app-aluno.jar" ]; then
            if [ "$FORCAR_SUBSTITUICAO" = "sim" ]; then
                echo "🚀 Flag -f detectada! Forçando recompilação completa..."
            else
                echo "✨ Já existe uma compilação anterior para o aluno '$ALUNO'."
                read -r -p "Deseja substituir a compilação atual e gerar um novo JAR? (s/n): " RESPOSTA
                RESPOSTA=$(echo "$RESPOSTA" | tr '[:upper:]' '[:lower:]')
                
                if [[ "$RESPOSTA" != "s" && "$RESPOSTA" != "sim" ]]; then
                    COMPILAR_NOVAMENTE="nao"
                    echo "⏭️  Pulando a etapa de compilação. Usando o JAR existente..."
                fi
            fi
        fi
    fi
fi

if [ ! -f "$PASTA_CODIGOS_LOCAL/pom.xml" ] && [ ! -f "$PASTA_CODIGOS_LOCAL/build.gradle" ] && [ ! -f "$PASTA_CODIGOS_LOCAL/build.gradle.kts" ]; then
    echo "❌ Erro: Nenhum arquivo pom.xml ou build.gradle encontrado em $PASTA_CODIGOS_LOCAL"
    echo "Abortando execução."
    exit 1
fi

PASTA_APP_LOCAL="$PASTA_ALUNO_RAIZ/app"
# Ajuste do caminho absoluto completo para o volume (-v) do Docker entender no Windows
PASTA_CODIGOS_ABSOLUTA="$DIRETORIOBASE/apps/$ALUNO/codigos"

echo "=== 🚀 Iniciando processo para o aluno: $ALUNO ==="

# 2. DETECÇÃO AUTOMÁTICA EXTRAÇÃO EXATA DO JAVA
JAVA_VERSION="17" 
BUILD_TOOL="maven"

if [ -f "$PASTA_CODIGOS_LOCAL/pom.xml" ]; then
    BUILD_TOOL="maven"
    VERSOES_DETECTADAS=$(grep -oP '(?<=<java.version>)[0-9]+|(?<=<maven.compiler.target>)[0-9]+|(?<=<maven.compiler.source>)[0-9]+' "$PASTA_CODIGOS_LOCAL/pom.xml" | head -n 1)
    if [ -n "$VERSOES_DETECTADAS" ]; then
        JAVA_VERSION=$VERSOES_DETECTADAS
    fi
elif [ -f "$PASTA_CODIGOS_LOCAL/build.gradle" ] || [ -f "$PASTA_CODIGOS_LOCAL/build.gradle.kts" ]; then
    BUILD_TOOL="gradle"
    VERSOES_DETECTADAS=$(grep -oE "compatibility.*[0-9]+|languageVersion.*[0-9]+" "$PASTA_CODIGOS_LOCAL/build.gradle"* 2>/dev/null | grep -oE "[0-9]+" | head -n 1)
    if [ -n "$VERSOES_DETECTADAS" ]; then
        JAVA_VERSION=$VERSOES_DETECTADAS
    fi
fi

echo "🔍 Detectado: Ambiente Spring Boot rodando em Java $JAVA_VERSION usando $BUILD_TOOL"

# 2.5. DETECÇÃO DA PORTA DO APLICATIVO
PORTA_APP=""
ARQUIVO_PROPERTIES="$PASTA_CODIGOS_LOCAL/src/main/resources/application.properties"
ARQUIVO_YML="$PASTA_CODIGOS_LOCAL/src/main/resources/application.yml"

echo "🔍 Buscando configuração de porta no projeto..."

if [ -f "$ARQUIVO_PROPERTIES" ]; then
    PORTA_DETECTADA=$(grep -E '^\s*server\.port\s*=' "$ARQUIVO_PROPERTIES" | cut -d'=' -f2 | tr -d '[:space:]' | tr -d '\r')
    if [ -n "$PORTA_DETECTADA" ] && [[ "$PORTA_DETECTADA" =~ ^[0-9]+$ ]]; then
        PORTA_APP="$PORTA_DETECTADA"
        echo "✅ Porta encontrada no application.properties: $PORTA_APP"
    fi
elif [ -f "$ARQUIVO_YML" ]; then
    # Busca básica no YAML (caso o aluno use yaml ao invés de properties)
    PORTA_DETECTADA=$(grep -E '^\s*port\s*:\s*[0-9]+' "$ARQUIVO_YML" | head -n 1 | cut -d':' -f2 | tr -d '[:space:]' | tr -d '\r')
    if [ -n "$PORTA_DETECTADA" ] && [[ "$PORTA_DETECTADA" =~ ^[0-9]+$ ]]; then
        PORTA_APP="$PORTA_DETECTADA"
        echo "✅ Porta encontrada no application.yml: $PORTA_APP"
    fi
fi

# Fallback se não encontrou a porta
if [ -z "$PORTA_APP" ]; then
    PORTA_APP="8080" # Valor padrão
    if [ "$FORCAR_SUBSTITUICAO" = "sim" ]; then
        echo "ℹ️  Porta não detectada. Modo forçado (-f) ativo: usando porta $PORTA_APP."
    else
        echo "⚠️  Não foi possível detectar a porta (server.port) automaticamente."
        if read -t 15 -r -p "Digite a porta que o app usa (Ex: 8081) [Padrão: 8080]: " RESP_PORTA; then
            if [[ "$RESP_PORTA" =~ ^[0-9]+$ ]]; then
                PORTA_APP="$RESP_PORTA"
            fi
        fi
    fi
fi
echo "🚀 A aplicação será exposta na porta: $PORTA_APP"
echo ""

# 3. COMPILAÇÃO DINÂMICA
if [ "$COMPILAR_NOVAMENTE" = "sim" ]; then
    echo "📦 Compilando o código do aluno..."
    rm -rf "$PASTA_APP_LOCAL"
    mkdir -p "$PASTA_APP_LOCAL"
    
    mkdir -p ./.cache_m2 ./.cache_gradle
    CACHE_M2="$DIRETORIOBASE/.cache_m2"
    CACHE_GRADLE="$DIRETORIOBASE/.cache_gradle"

    if [ "$BUILD_TOOL" = "maven" ]; then
        MSYS_NO_PATHCONV=1 docker run --rm \
          -v "$PASTA_CODIGOS_ABSOLUTA":/usr/src/app \
          -v "$CACHE_M2":/root/.m2 \
          -w /usr/src/app \
          maven:3.9-eclipse-temurin-"$JAVA_VERSION" \
          mvn clean package -DskipTests
    else
        MSYS_NO_PATHCONV=1 docker run --rm \
          -v "$PASTA_CODIGOS_ABSOLUTA":/home/gradle/project \
          -v "$CACHE_GRADLE":/home/gradle/.gradle \
          -w /home/gradle/project \
          gradle:8-jdk"$JAVA_VERSION" \
          gradle bootJar --no-daemon
    fi

    if [ $? -ne 0 ]; then
        echo "❌ Erro na compilação do código do aluno!"
        exit 1
    fi

    # 4. ORGANIZAÇÃO DOS ARQUIVOS E CRIAÇÃO DO DOCKERFILE
    echo "🚚 Organizando o arquivo executável..."
    JAR_GERADO=$(find "$PASTA_CODIGOS_LOCAL" -name "*.jar" ! -name "*-sources.jar" ! -name "*-javadoc.jar" ! -name "*-plain.jar" | head -n 1)

    if [ -z "$JAR_GERADO" ]; then
        echo "❌ Arquivo JAR executável não encontrado!"
        exit 1
    fi

    cp "$JAR_GERADO" "$PASTA_APP_LOCAL/app-aluno.jar"

    cat <<EOF > "$PASTA_APP_LOCAL/Dockerfile"
FROM eclipse-temurin:${JAVA_VERSION}-jre-alpine
RUN addgroup -S sandboxgroup && adduser -S sandboxuser -G sandboxgroup
WORKDIR /app
COPY --chown=sandboxuser:sandboxgroup app-aluno.jar app.jar
USER sandboxuser
EXPOSE ${PORTA_APP}
CMD ["java", "-Djava.io.tmpdir=/tmp", "-jar", "app.jar"]
EOF

    # 5. GERENCIAMENTO DA IMAGEM COMPORTAMENTO INTERATIVO
    IMAGEM_PADRAO="sandbox-$NOME_PASTA_LIMPO"
    
    if [ "$(docker images -q "$IMAGEM_PADRAO" 2> /dev/null)" ] && [ "$FORCAR_SUBSTITUICAO" = "nao" ]; then
        echo "--------------------------------------------------------"
        echo "⚠️  A imagem '$IMAGEM_PADRAO' já existe no Docker."
        echo "👉 Digite um NOVO SUFIXO para salvar separada (Ex: 'nota10')."
        echo "⏱️  Ou aguarde 20 segundos (ou pressione ENTER) para SUBSTITUIR automaticamente."
        echo "--------------------------------------------------------"
        
        if read -t 20 -r -p "Sua escolha: " SUFIXO_CUSTOMIZADO; then
            if [ -n "$SUFIXO_CUSTOMIZADO" ]; then
                SUFIXO_LIMPO=$(echo "$SUFIXO_CUSTOMIZADO" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9_-')
                IMAGEM_FINAL="${IMAGEM_PADRAO}-${SUFIXO_LIMPO}"
            fi
        else
            echo ""
            echo "⏱️  Tempo esgotado! Prosseguindo com o nome padrão da imagem..."
        fi
    fi

    echo "🛠️  Construindo a imagem Docker com o nome final: $IMAGEM_FINAL"
    cd "$PASTA_APP_LOCAL"
    docker build -t "$IMAGEM_FINAL" .
    cd "$DIRETORIOBASE"
else
    IMAGEM_FINAL="sandbox-$NOME_PASTA_LIMPO"
fi

CONTAINER_FINAL="executando-${IMAGEM_FINAL}"

# 6. EXECUÇÃO DA SANDBOX SEGURA
echo "🔥 Rodando a aplicação do aluno na porta $PORTA_APP..."
echo "🚀 Recursos alocados: Memória: $MEMORIA_CONTAINER | CPUs: $CPUS_CONTAINER"
echo ""
echo "👉 Acesse a aplicação: http://localhost:$PORTA_APP"
echo "👉 Documentação Swagger: http://localhost:$PORTA_APP/swagger-ui/index.html"
echo ""
echo "Para encerrar o teste, pressione CTRL+C nesta janela."
echo "--------------------------------------------------------"

docker rm -f "$CONTAINER_FINAL" 2>/dev/null

docker run --rm \
  --name "$CONTAINER_FINAL" \
  -p "$PORTA_APP:$PORTA_APP" \
  -e SERVER_PORT="$PORTA_APP" \
  --memory="$MEMORIA_CONTAINER" \
  --cpus="$CPUS_CONTAINER" \
  --cap-drop=ALL \
  --read-only \
  --tmpfs //tmp \
  "$IMAGEM_FINAL"