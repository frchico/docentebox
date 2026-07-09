#!/bin/bash
mkdir -p "$DIRETORIOBASE/apps"

if [[ "$PARAMETRO" =~ ^https://github.com/.* ]]; then
    echo "🌐 Detectado: Entrada via URL do GitHub."
    if [ -n "$ARG_OPCIONAL" ]; then export ALUNO="$ARG_OPCIONAL"
    else export ALUNO=$(basename "$PARAMETRO" .git); fi
    
    export PASTA_ALUNO_RAIZ="$DIRETORIOBASE/apps/$ALUNO"
    export PASTA_CODIGOS_LOCAL="$PASTA_ALUNO_RAIZ/codigos"
    
    if [ -d "$PASTA_CODIGOS_LOCAL/.git" ]; then
        if [ "$FORCAR_SUBSTITUICAO" = "nao" ]; then
            echo "⚠️  O repositório de '$ALUNO' já existe."
            read -r -p "Deseja atualizar do GitHub? (s/n): " RESP_GIT
            RESP_GIT=$(echo "$RESP_GIT" | tr '[:upper:]' '[:lower:]')
            if [[ "$RESP_GIT" == "s" || "$RESP_GIT" == "sim" ]]; then
                echo "🔄 Atualizando repositório via Git Fetch & Reset..."
                cd "$PASTA_CODIGOS_LOCAL" && git fetch --all
                BRANCH_PADRAO=$(git remote show origin | grep 'HEAD branch' | cut -d' ' -f5)
                git reset --hard "origin/$BRANCH_PADRAO"
                cd "$DIRETORIOBASE"
            fi
        else
            echo "🔄 Flag -f detectada! Forçando atualização..."
            cd "$PASTA_CODIGOS_LOCAL" && git fetch --all
            BRANCH_PADRAO=$(git remote show origin | grep 'HEAD branch' | cut -d' ' -f5)
            git reset --hard "origin/$BRANCH_PADRAO"
            cd "$DIRETORIOBASE"
        fi
    else
        rm -rf "$PASTA_ALUNO_RAIZ" && mkdir -p "$PASTA_CODIGOS_LOCAL"
        echo "📥 Clonando repositório do aluno..."
        git clone "$PARAMETRO" "$PASTA_CODIGOS_LOCAL" || { echo "❌ Erro ao clonar!"; exit 1; }
    fi
else
    export ALUNO="$PARAMETRO"
    export PASTA_ALUNO_RAIZ="$DIRETORIOBASE/apps/$ALUNO"
    export PASTA_CODIGOS_LOCAL="$PASTA_ALUNO_RAIZ/codigos"
    
    if [ ! -d "$PASTA_CODIGOS_LOCAL" ]; then
        mkdir -p "$PASTA_CODIGOS_LOCAL"
        echo "⚠️ AÇÃO REQUERIDA: Extraia os arquivos do aluno em: apps/$ALUNO/codigos/"
        read -p "Pressione [ENTER] quando terminar..."
    elif [ -f "$PASTA_ALUNO_RAIZ/app/app-aluno.jar" ] && [ "$FORCAR_SUBSTITUICAO" != "sim" ]; then
        read -r -p "Já existe uma compilação. Gerar novo JAR? (s/n): " RESPOSTA
        RESPOSTA=$(echo "$RESPOSTA" | tr '[:upper:]' '[:lower:]')
        if [[ "$RESPOSTA" != "s" && "$RESPOSTA" != "sim" ]]; then
            export COMPILAR_NOVAMENTE="nao"
        fi
    fi
fi