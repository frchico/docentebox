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

echo "🔥 Rodando a aplicação em http://localhost:$PORTA_APP"
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