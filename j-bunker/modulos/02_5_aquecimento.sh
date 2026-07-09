#!/bin/bash

# Se a flag -cache não foi acionada, sai silenciosamente deste módulo
if [ "$AQUECER_CACHE" = "nao" ]; then
    return 0
fi

# Garante que as pastas de cache ocultas existam na raiz
mkdir -p "$DIRETORIOBASE/.cache_m2" "$DIRETORIOBASE/.cache_gradle"

# Verifica se a pasta auxiliar com as configurações existe
if [ ! -d "$DIRETORIOBASE/gerar_cache" ]; then
    echo "❌ Erro: A pasta './gerar_cache' contendo os arquivos de configuração não foi encontrada!"
    echo "Certifique-se de que a pasta existe e contém o 'cache.pom.xml' ou 'cache.build.gradle'."
    exit 1
fi

echo "========================================================"
echo "⚡ Painel de Aquecimento dos Caches Globais do Java ⚡"
echo "========================================================"
echo ""

# === INTERATIVIDADE: CACHE DO MAVEN ===
BAIXAR_MAVEN="nao"
if [ -f "$DIRETORIOBASE/gerar_cache/cache.pom.xml" ]; then
    # Inteligência de detecção do Java para o Maven
    JAVA_VER_MAVEN="17" # Padrão caso não encontre
    VERSAO_DETECTADA=$(grep -oP '(?<=<java.version>)[0-9]+|(?<=<maven.compiler.target>)[0-9]+|(?<=<maven.compiler.source>)[0-9]+' "$DIRETORIOBASE/gerar_cache/cache.pom.xml" | head -n 1)
    if [ -n "$VERSAO_DETECTADA" ]; then JAVA_VER_MAVEN=$VERSAO_DETECTADA; fi

    echo "--------------------------------------------------------"
    echo "📦 [MAVEN] Arquivo 'cache.pom.xml' detectado (Java $JAVA_VER_MAVEN)."
    echo "⏱️  Aguardando 10 segundos. Pressione 's' para BAIXAR ou ENTER para pular."
    echo "--------------------------------------------------------"
    
    if read -t 10 -r -p "Deseja gerar o cache do Maven? (s/n) [Padrão: n]: " RESP_M2; then
        RESP_M2=$(echo "$RESP_M2" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z')
        if [[ "$RESP_M2" == "s" || "$RESP_M2" == "sim" ]]; then
            BAIXAR_MAVEN="sim"
        fi
    fi

    if [ "$BAIXAR_MAVEN" = "sim" ]; then
        echo "📥 Baixando dependências do Maven usando Java $JAVA_VER_MAVEN..."
        MSYS_NO_PATHCONV=1 docker run --rm \
          -v "$DIRETORIOBASE/gerar_cache":/usr/src/app \
          -v "$DIRETORIOBASE/.cache_m2":/root/.m2 \
          -w /usr/src/app \
          maven:3.9-eclipse-temurin-"$JAVA_VER_MAVEN" \
          mvn dependency:go-offline -f cache.pom.xml

        if [ $? -eq 0 ]; then
            echo "✅ Cache do Maven atualizado com sucesso!"
        else
            echo "⚠️  Houve um problema ao baixar dependências do Maven."
        fi
    else
        echo "⏭️  Cache do Maven pulado."
    fi
else
    echo "⏭️  Arquivo 'cache.pom.xml' não encontrado."
fi

echo ""

# === INTERATIVIDADE: CACHE DO GRADLE ===
BAIXAR_GRADLE="nao"
if [ -f "$DIRETORIOBASE/gerar_cache/cache.build.gradle" ]; then
    # Inteligência de detecção do Java para o Gradle
    JAVA_VER_GRADLE="17" # Padrão caso não encontre
    VERSAO_DETECTADA=$(grep -oE "compatibility.*[0-9]+|languageVersion.*[0-9]+" "$DIRETORIOBASE/gerar_cache/cache.build.gradle" 2>/dev/null | grep -oE "[0-9]+" | head -n 1)
    if [ -n "$VERSAO_DETECTADA" ]; then JAVA_VER_GRADLE=$VERSAO_DETECTADA; fi

    echo "--------------------------------------------------------"
    echo "📦 [GRADLE] Arquivo 'cache.build.gradle' detectado (Java $JAVA_VER_GRADLE)."
    echo "⏱️  Aguardando 10 segundos. Pressione 's' para BAIXAR ou ENTER para pular."
    echo "--------------------------------------------------------"
    
    if read -t 10 -r -p "Deseja gerar o cache do Gradle? (s/n) [Padrão: n]: " RESP_GRADLE; then
        RESP_GRADLE=$(echo "$RESP_GRADLE" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z')
        if [[ "$RESP_GRADLE" == "s" || "$RESP_GRADLE" == "sim" ]]; then
            BAIXAR_GRADLE="sim"
        fi
    fi

    if [ "$BAIXAR_GRADLE" = "sim" ]; then
        echo "📥 Baixando dependências do Gradle usando Java $JAVA_VER_GRADLE..."
        MSYS_NO_PATHCONV=1 docker run --rm \
          -v "$DIRETORIOBASE/gerar_cache":/home/gradle/project \
          -v "$DIRETORIOBASE/.cache_gradle":/home/gradle/.gradle \
          -w /home/gradle/project \
          gradle:8-jdk"$JAVA_VER_GRADLE" \
          gradle build --no-daemon -x test -b cache.build.gradle

        if [ $? -eq 0 ]; then
            echo "✅ Cache do Gradle atualizado com sucesso!"
        else
            echo "⚠️  Houve um problema ao baixar dependências do Gradle."
        fi
    else
        echo "⏭️  Cache do Gradle pulado."
    fi
else
    echo "⏭️  Arquivo 'cache.build.gradle' não encontrado."
fi

echo ""
echo "🎉 Processo de gerenciamento de cache concluído!"
echo "========================================================"

# Se rodou apenas para aquecer o cache (sem informar aluno), encerra o script aqui.
if [ -z "$PARAMETRO" ]; then
    exit 0
fi