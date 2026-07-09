#!/bin/bash
NOME_PASTA_PAI=$(basename "$DIRETORIOBASE")
NOME_PASTA_LIMPO=$(echo "$NOME_PASTA_PAI" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9_-')
IMAGEM_PADRAO="sandbox-$NOME_PASTA_LIMPO"
export IMAGEM_FINAL="$IMAGEM_PADRAO"

if [ "$COMPILAR_NOVAMENTE" = "sim" ]; then
    if [ "$(docker images -q "$IMAGEM_PADRAO" 2> /dev/null)" ] && [ "$FORCAR_SUBSTITUICAO" = "nao" ]; then
        echo "⚠️ A imagem já existe. Digite um sufixo para manter as duas ou aguarde para substituir."
        if read -t 15 -r -p "Sufixo (Ex: nota10): " SUFIXO_CUSTOM; then
            if [ -n "$SUFIXO_CUSTOM" ]; then
                SUFIXO_LIMPO=$(echo "$SUFIXO_CUSTOM" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9_-')
                export IMAGEM_FINAL="${IMAGEM_PADRAO}-${SUFIXO_LIMPO}"
            fi
        fi
    fi
    echo "🛠️ Construindo a imagem: $IMAGEM_FINAL"
    cd "$PASTA_APP_LOCAL" && docker build -t "$IMAGEM_FINAL" . && cd "$DIRETORIOBASE"
fi

CONTAINER_FINAL="executando-${IMAGEM_FINAL}"

echo "🔥 Preparando o container da aplicação..."
docker rm -f "$CONTAINER_FINAL" 2>/dev/null

# 1. INICIA O CONTAINER EM SEGUNDO PLANO (Flag -d adicionada)
docker run -d --rm \
  --name "$CONTAINER_FINAL" \
  -p "$PORTA_APP:$PORTA_APP" \
  -e SERVER_PORT="$PORTA_APP" \
  --memory="$MEMORIA_CONTAINER" \
  --cpus="$CPUS_CONTAINER" \
  --cap-drop=ALL \
  --read-only \
  --tmpfs //tmp \
  "$IMAGEM_FINAL" > /dev/null

echo "⏱️  Aguardando o Spring Boot iniciar na porta $PORTA_APP (Healthcheck)..."

# 2. LOOP DE ESPERA INTELIGENTE
MAX_TENTATIVAS=20
CONTADOR=0
APP_PRONTO="nao"

while [ $CONTADOR -lt $MAX_TENTATIVAS ]; do
    # O curl tenta acessar a porta. Se der 'connection refused', o Spring ainda não subiu.
    # Quando o Spring sobe, o curl retorna sucesso (mesmo que a página em si dê erro 404).
    if curl --output /dev/null --silent "http://localhost:$PORTA_APP"; then
        APP_PRONTO="sim"
        break
    fi
    sleep 2
    CONTADOR=$((CONTADOR+1))
done

# 3. RESULTADO DO HEALTHCHECK
if [ "$APP_PRONTO" = "sim" ]; then
    echo "--------------------------------------------------------"
    echo "✅ APLICAÇÃO ONLINE E PRONTA PARA USO!"
    echo "🚀 Recursos alocados: Memória: $MEMORIA_CONTAINER | CPUs: $CPUS_CONTAINER"
    echo ""
    echo "👉 Acesse a aplicação: http://localhost:$PORTA_APP"
    echo "👉 Documentação Swagger: http://localhost:$PORTA_APP/swagger-ui/index.html"
    echo ""
    echo "Para encerrar o teste, pressione CTRL+C nesta janela."
    echo "--------------------------------------------------------"
else
    echo "--------------------------------------------------------"
    echo "⚠️  Aviso: O tempo limite (40s) de espera foi atingido."
    echo "A aplicação pode estar demorando mais que o normal para subir ou ocorreu um erro fatal."
    echo "Exibindo os logs para análise:"
    echo "--------------------------------------------------------"
fi

# 4. ARMADILHA PARA O CTRL+C
# Intercepta o CTRL+C do usuário para parar e limpar o container que ficou em segundo plano
trap 'echo -e "\n🛑 Encerrando o container de forma segura..."; docker stop "$CONTAINER_FINAL" >/dev/null 2>&1; exit 0' INT

# 5. ATRELA O TERMINAL AOS LOGS
# Isso permite que você veja os logs do Spring Boot em tempo real, mantendo a experiência anterior.
docker logs -f "$CONTAINER_FINAL"