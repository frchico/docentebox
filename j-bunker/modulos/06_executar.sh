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

# 1. INICIA O CONTAINER EM SEGUNDO PLANO
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

# 2. LOOP DE ESPERA INTELIGENTE COM DETECÇÃO DE CRASH
MAX_TENTATIVAS=20
CONTADOR=0
APP_PRONTO="nao"

while [ $CONTADOR -lt $MAX_TENTATIVAS ]; do
    # Verifica se a porta já está respondendo
    if curl --output /dev/null --silent "http://localhost:$PORTA_APP"; then
        APP_PRONTO="sim"
        break
    fi
    
    # Verifica se o container "morreu" (crashou logo após subir)
    STATUS_CONTAINER=$(docker inspect -f '{{.State.Running}}' "$CONTAINER_FINAL" 2>/dev/null)
    if [ "$STATUS_CONTAINER" = "false" ]; then
        echo -e "\n❌ Ops! O container foi encerrado inesperadamente."
        break
    fi

    sleep 2
    CONTADOR=$((CONTADOR+1))
done

# 3. RESULTADO E EXPORTAÇÃO DO LOG DE ERROS
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
    
    # Armadilha para limpar o container rodando em background
    trap 'echo -e "\n🛑 Encerrando o container de forma segura..."; docker stop "$CONTAINER_FINAL" >/dev/null 2>&1; exit 0' INT
    
    # Exibe os logs contínuos em caso de sucesso
    docker logs -f "$CONTAINER_FINAL"
else
    echo "--------------------------------------------------------"
    echo "⚠️  AVISO: Falha na inicialização da aplicação."
    
    # Salva o arquivo de log físico direto na pasta do app do aluno
    ARQUIVO_ERRO="$PASTA_APP_LOCAL/erro_execucao.txt"
    docker logs "$CONTAINER_FINAL" > "$ARQUIVO_ERRO" 2>&1
    
    echo "📄 Um arquivo com o log completo de falha foi exportado para o diretório local:"
    echo "   -> $ARQUIVO_ERRO"
    echo "--------------------------------------------------------"
    echo "🔍 Exibindo as últimas linhas do erro para análise rápida:"
    echo ""
    
    # Exibe só o final do erro no terminal (não polui a tela toda)
    docker logs --tail 20 "$CONTAINER_FINAL"
    echo ""
    echo "💡 O processo foi encerrado. Limpando a memória..."
    docker rm -f "$CONTAINER_FINAL" 2>/dev/null
fi