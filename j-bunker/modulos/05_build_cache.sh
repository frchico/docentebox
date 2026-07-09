#!/bin/bash
export PASTA_APP_LOCAL="$PASTA_ALUNO_RAIZ/app"

if [ "$COMPILAR_NOVAMENTE" = "sim" ]; then
    echo "📦 Compilando o código..."
    rm -rf "$PASTA_APP_LOCAL" && mkdir -p "$PASTA_APP_LOCAL"
    mkdir -p "$DIRETORIOBASE/.cache_m2" "$DIRETORIOBASE/.cache_gradle"

    if [ "$BUILD_TOOL" = "maven" ]; then
        MSYS_NO_PATHCONV=1 docker run --rm \
          -v "$PASTA_CODIGOS_LOCAL":/usr/src/app -v "$DIRETORIOBASE/.cache_m2":/root/.m2 -w /usr/src/app \
          maven:3.9-eclipse-temurin-"$JAVA_VERSION" mvn clean package -DskipTests
    else
        MSYS_NO_PATHCONV=1 docker run --rm \
          -v "$PASTA_CODIGOS_LOCAL":/home/gradle/project -v "$DIRETORIOBASE/.cache_gradle":/home/gradle/.gradle -w /home/gradle/project \
          gradle:8-jdk"$JAVA_VERSION" gradle bootJar --no-daemon
    fi

    JAR_GERADO=$(find "$PASTA_CODIGOS_LOCAL" -name "*.jar" ! -name "*-sources.jar" | head -n 1)
    if [ -z "$JAR_GERADO" ]; then echo "❌ Arquivo JAR não encontrado!"; exit 1; fi

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
fi