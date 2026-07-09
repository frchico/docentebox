#!/bin/bash

if [ "$EXECUTAR_LIMPEZA" = "sim" ]; then
    echo "========================================="
    echo "🧹 INICIANDO LIMPEZA DO J-BUNKER"
    echo "========================================="
    
    # ---------------------------------------------------
    # 1. LIMPEZA VIRTUAL (IMAGENS DOCKER)
    # ---------------------------------------------------
    echo "🔍 Buscando imagens antigas do J-Bunker (sandbox-)..."
    IMAGENS_SANDBOX=$(docker images --format "{{.Repository}}" | grep '^sandbox-' | sort | uniq)
    
    if [ -z "$IMAGENS_SANDBOX" ]; then
        echo "✨ Nenhuma imagem do Docker encontrada."
    else
        APAGAR_TODAS_IMAGENS="nao"
        
        if [ "$FORCAR_SUBSTITUICAO" = "sim" ]; then
            APAGAR_TODAS_IMAGENS="sim"
            echo "⚡ Flag --force detectada. Apagando imagens sem confirmação..."
        fi

        for IMAGEM in $IMAGENS_SANDBOX; do
            if [ "$APAGAR_TODAS_IMAGENS" = "sim" ]; then
                echo "🗑️ Apagando a imagem: $IMAGEM..."
                docker rmi -f "$IMAGEM" > /dev/null 2>&1
            else
                read -p "Deseja apagar a imagem '$IMAGEM'? (s/N/t para Todas): " CONFIRMACAO_IMG
                CONFIRMACAO_IMG=${CONFIRMACAO_IMG:-n}
                
                if [[ "$CONFIRMACAO_IMG" =~ ^[tT]$ ]]; then
                    APAGAR_TODAS_IMAGENS="sim"
                    echo "🗑️ Apagando '$IMAGEM' e todas as imagens restantes..."
                    docker rmi -f "$IMAGEM" > /dev/null 2>&1
                elif [[ "$CONFIRMACAO_IMG" =~ ^[sS]$ ]]; then
                    echo "🗑️ Apagando a imagem $IMAGEM..."
                    docker rmi -f "$IMAGEM" > /dev/null 2>&1
                else
                    echo "⏭️ Ignorando a imagem $IMAGEM..."
                fi
            fi
        done
        echo "✅ Limpeza do Docker concluída!"
    fi

    echo ""
    
    # ---------------------------------------------------
    # 2. LIMPEZA FÍSICA (PASTAS DOS ALUNOS)
    # ---------------------------------------------------
    echo "🔍 Verificando pastas físicas de alunos no diretório 'apps/'..."
    
    if [ ! -d "apps" ] || [ -z "$(ls -A apps/ 2>/dev/null)" ]; then
        echo "✨ Nenhuma pasta encontrada. Seu HD físico já está limpo!"
    else
        # Pega apenas os diretórios dentro de apps/
        PASTAS_ALUNOS=$(ls -d apps/*/ 2>/dev/null)
        
        if [ -z "$PASTAS_ALUNOS" ]; then
            echo "✨ Nenhuma subpasta de aluno encontrada em 'apps/'."
        else
            APAGAR_TODAS_PASTAS="nao"
            
            if [ "$FORCAR_SUBSTITUICAO" = "sim" ]; then
                APAGAR_TODAS_PASTAS="sim"
                echo "⚡ Flag --force detectada. Apagando todas as pastas sem confirmação..."
            fi

            for PASTA in $PASTAS_ALUNOS; do
                NOME_PASTA=$(basename "$PASTA")
                
                if [ "$APAGAR_TODAS_PASTAS" = "sim" ]; then
                    echo "🗑️ Apagando a pasta: $NOME_PASTA..."
                    rm -rf "$PASTA"
                else
                    read -p "Deseja apagar a pasta do aluno '$NOME_PASTA'? (s/N/t para Todas): " CONFIRMACAO_PASTA
                    CONFIRMACAO_PASTA=${CONFIRMACAO_PASTA:-n}
                    
                    if [[ "$CONFIRMACAO_PASTA" =~ ^[tT]$ ]]; then
                        APAGAR_TODAS_PASTAS="sim"
                        echo "🗑️ Apagando $NOME_PASTA e todas as pastas restantes..."
                        rm -rf "$PASTA"
                    elif [[ "$CONFIRMACAO_PASTA" =~ ^[sS]$ ]]; then
                        echo "🗑️ Apagando $NOME_PASTA..."
                        rm -rf "$PASTA"
                    else
                        echo "⏭️ Ignorando $NOME_PASTA..."
                    fi
                fi
            done
            echo "✅ Limpeza física das pastas concluída!"
        fi
    fi
    
    echo "========================================="
    echo "🎉 Processo de manutenção finalizado."
    echo "========================================="
    
    # Sai do script principal, pois a intenção era apenas fazer a manutenção
    exit 0
fi