#!/bin/bash
if [ ! -f "$PASTA_CODIGOS_LOCAL/pom.xml" ] && [ ! -f "$PASTA_CODIGOS_LOCAL/build.gradle" ]; then
    echo "❌ Erro: Nenhum arquivo de compilação encontrado."
    exit 1
fi

export JAVA_VERSION="17"
export BUILD_TOOL="maven"

if [ -f "$PASTA_CODIGOS_LOCAL/pom.xml" ]; then
    VERSOES_DETECTADAS=$(grep -oP '(?<=<java.version>)[0-9]+' "$PASTA_CODIGOS_LOCAL/pom.xml" | head -n 1)
    if [ -n "$VERSOES_DETECTADAS" ]; then JAVA_VERSION=$VERSOES_DETECTADAS; fi
else
    BUILD_TOOL="gradle"
    VERSOES_DETECTADAS=$(grep -oE "compatibility.*[0-9]+|languageVersion.*[0-9]+" "$PASTA_CODIGOS_LOCAL/build.gradle"* 2>/dev/null | grep -oE "[0-9]+" | head -n 1)
    if [ -n "$VERSOES_DETECTADAS" ]; then JAVA_VERSION=$VERSOES_DETECTADAS; fi
fi

echo "🔍 Detectado: Java $JAVA_VERSION usando $BUILD_TOOL"

export PORTA_APP=""
ARQUIVO_PROPERTIES="$PASTA_CODIGOS_LOCAL/src/main/resources/application.properties"
ARQUIVO_YML="$PASTA_CODIGOS_LOCAL/src/main/resources/application.yml"

if [ -f "$ARQUIVO_PROPERTIES" ]; then
    PORTA_DETECTADA=$(grep -E '^\s*server\.port\s*=' "$ARQUIVO_PROPERTIES" | cut -d'=' -f2 | tr -d '[:space:]' | tr -d '\r')
    if [[ "$PORTA_DETECTADA" =~ ^[0-9]+$ ]]; then export PORTA_APP="$PORTA_DETECTADA"; fi
elif [ -f "$ARQUIVO_YML" ]; then
    PORTA_DETECTADA=$(grep -E '^\s*port\s*:\s*[0-9]+' "$ARQUIVO_YML" | head -n 1 | cut -d':' -f2 | tr -d '[:space:]' | tr -d '\r')
    if [[ "$PORTA_DETECTADA" =~ ^[0-9]+$ ]]; then export PORTA_APP="$PORTA_DETECTADA"; fi
fi

if [ -z "$PORTA_APP" ]; then
    export PORTA_APP="8080"
    if [ "$FORCAR_SUBSTITUICAO" != "sim" ]; then
        echo "⚠️  Não foi possível detectar a porta."
        read -t 15 -r -p "Digite a porta [Padrão: 8080]: " RESP_PORTA
        if [[ "$RESP_PORTA" =~ ^[0-9]+$ ]]; then export PORTA_APP="$RESP_PORTA"; fi
    fi
fi
echo "🚀 A aplicação será exposta na porta: $PORTA_APP"