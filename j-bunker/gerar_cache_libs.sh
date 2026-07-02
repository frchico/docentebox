#!/bin/bash

# === VERIFICAÇÃO: O DOCKER ESTÁ RODANDO? ===
echo "🐳 Verificando se o Docker Desktop está ativo..."
docker info >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "--------------------------------------------------------"
    echo "❌ ERRO: O Docker Desktop não está rodando!"
    echo "👉 Por favor, abra o aplicativo Docker Desktop no Windows."
    echo "--------------------------------------------------------"
    exit 1
fi

DIRETORIOBASE=$(pwd -W 2>/dev/null || pwd)

# Garante que as pastas de cache ocultas existam na raiz
mkdir -p ./.cache_m2 ./.cache_gradle

# Verifica se a pasta auxiliar com as configurações existe
if [ ! -d "./gerar_cache" ]; then
    echo "❌ Erro: A pasta './gerar_cache' contendo os arquivos de configuração não foi encontrada!"
    echo "Certifique-se de que a pasta existe e contém o 'cache.pom.xml' ou 'cache.build.gradle'."
    exit 1
fi

echo "========================================================"
echo "⚡ Painel de Aquecimento dos Caches Globais do Java ⚡"
echo "========================================================"
echo ""

# === INTERATIVIDADE: CACHE DO MAVEN ===
BAIXAR_MAVEN="nao" # Padrão alterado para 'nao'
if [ -f "./gerar_cache/cache.pom.xml" ]; then
    echo "--------------------------------------------------------"
    echo "📦 [MAVEN] Arquivo 'cache.pom.xml' detectado."
    echo "⏱️  Aguardando 10 segundos. Pressione 's' para BAIXAR ou ENTER para pular."
    echo "--------------------------------------------------------"
    
    if read -t 10 -r -p "Deseja gerar o cache do Maven? (s/n) [Padrão: n]: " RESP_M2; then
        RESP_M2=$(echo "$RESP_M2" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z')
        if [[ "$RESP_M2" == "s" || "$RESP_M2" == "sim" ]]; then
            BAIXAR_MAVEN="sim"
        fi
    fi

    if [ "$BAIXAR_MAVEN" = "sim" ]; then
        echo "📥 Baixando dependências do Maven (Spring Boot, Auth, Swagger, H2, Lombok)..."
        MSYS_NO_PATHCONV=1 docker run --rm \
          -v "$DIRETORIOBASE/gerar_cache":/usr/src/app \
          -v "$DIRETORIOBASE/.cache_m2":/root/.m2 \
          -w /usr/src/app \
          maven:3.9-eclipse-temurin-25 \
          mvn dependency:go-offline -f cache.pom.xml

        if [ $? -eq 0 ]; then
            echo "✅ Cache do Maven (.cache_m2) atualizado com sucesso!"
        else
            echo "⚠️  Houve um problema ao baixar as dependências do Maven."
        fi
    else
        echo "⏭️  Cache do Maven pulado (padrão ou escolha do usuário)."
    fi
else
    echo "⏭️  Arquivo 'cache.pom.xml' não encontrado. Pulando etapa do Maven."
fi

echo ""

# === INTERATIVIDADE: CACHE DO GRADLE ===
BAIXAR_GRADLE="nao" # Padrão alterado para 'nao'
if [ -f "./gerar_cache/cache.build.gradle" ]; then
    echo "--------------------------------------------------------"
    echo "📦 [GRADLE] Arquivo 'cache.build.gradle' detectado."
    echo "⏱️  Aguardando 10 segundos. Pressione 's' para BAIXAR ou ENTER para pular."
    echo "--------------------------------------------------------"
    
    if read -t 10 -r -p "Deseja gerar o cache do Gradle? (s/n) [Padrão: n]: " RESP_GRADLE; then
        RESP_GRADLE=$(echo "$RESP_GRADLE" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z')
        if [[ "$RESP_GRADLE" == "s" || "$RESP_GRADLE" == "sim" ]]; then
            BAIXAR_GRADLE="sim"
        fi
    fi

    if [ "$BAIXAR_GRADLE" = "sim" ]; then
        echo "📥 Baixando dependências do Gradle (Spring Boot, Auth, Swagger, H2, Lombok)..."
        MSYS_NO_PATHCONV=1 docker run --rm \
          -v "$DIRETORIOBASE/gerar_cache":/home/gradle/project \
          -v "$DIRETORIOBASE/.cache_gradle":/home/gradle/.gradle \
          -w /home/gradle/project \
          gradle:8-jdk21 \
          gradle build --no-daemon -x test -b cache.build.gradle

        if [ $? -eq 0 ]; then
            echo "✅ Cache do Gradle (.cache_gradle) atualizado com sucesso!"
        else
            echo "⚠️  Houve um problema ao baixar as dependências do Gradle."
        fi
    else
        echo "⏭️  Cache do Gradle pulado (padrão ou escolha do usuário)."
    fi
else
    echo "⏭️  Arquivo 'cache.build.gradle' não encontrado. Pulando etapa do Gradle."
fi

echo ""
echo "========================================================"
echo "🎉 Processo de gerenciamento de cache concluído!"
echo "========================================================"