#!/bin/bash

if [ "$EXECUTAR_LIMPEZA" = "sim" ]; then
    echo "🧹 Buscando imagens antigas do J-Bunker (sandbox-)..."
    IMAGENS_SANDBOX=$(docker images --format "{{.Repository}}" | grep '^sandbox-' | sort | uniq)
    
    if [ -z "$IMAGENS_SANDBOX" ]; then
        echo "✨ Nenhuma imagem do J-Bunker encontrada. Seu HD já está limpo!"
        exit 0
    fi

    echo "⚠️  As seguintes imagens foram encontradas e serão APAGADAS:"
    echo "$IMAGENS_SANDBOX"
    echo ""

    if [ "$FORCAR_SUBSTITUICAO" = "sim" ]; then
        CONFIRMACAO="s"
        echo "⚡ Flag --force detectada. Apagando sem confirmação..."
    else
        read -p "Deseja realmente apagar essas imagens? (s/N): " CONFIRMACAO
        CONFIRMACAO=${CONFIRMACAO:-n}
    fi

    if [[ "$CONFIRMACAO" =~ ^[sS]$ ]]; then
        echo "🗑️ Apagando imagens..."
        docker rmi -f $IMAGENS_SANDBOX > /dev/null 2>&1
        echo "✅ Limpeza concluída com sucesso! Espaço liberado."
    else
        echo "🛑 Operação cancelada. Nenhuma imagem foi apagada."
    fi
    
    # Sai do script principal, pois a intenção era apenas fazer a limpeza
    exit 0
fi