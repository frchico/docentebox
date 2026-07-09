#!/bin/bash

# Verifica se o parâmetro é uma URL Git
if [[ "$PARAMETRO" =~ ^https:// || "$PARAMETRO" =~ ^git@ || "$PARAMETRO" =~ \.git$ ]]; then
    export CONFIG_ORIGEM="github"
    URL_GIT="$PARAMETRO"
    
    # Define o nome da pasta do aluno
    if [ -n "$ARG_OPCIONAL" ]; then
        export NOME_ALUNO="$ARG_OPCIONAL"
    else
        export NOME_ALUNO=$(basename "$URL_GIT" .git)
    fi
    
    export PASTA_ALUNO_LOCAL="$DIRETORIOBASE/apps/$NOME_ALUNO"
    export PASTA_CODIGOS_LOCAL="$PASTA_ALUNO_LOCAL/codigos"
    export PASTA_APP_LOCAL="$PASTA_ALUNO_LOCAL/app"
    
    # ---------------------------------------------------
    # DETECÇÃO DE REPOSITÓRIOS DIFERENTES NA MESMA PASTA
    # ---------------------------------------------------
    if [ -d "$PASTA_CODIGOS_LOCAL/.git" ]; then
        # Captura a URL remota configurada atualmente na pasta
        URL_REMOTA_ATUAL=$(cd "$PASTA_CODIGOS_LOCAL" && git config --get remote.origin.url 2>/dev/null)
        
        # Normaliza removendo quebras de linha ou espaços
        URL_REMOTA_ATUAL=$(echo "$URL_REMOTA_ATUAL" | tr -d '[:space:]')
        URL_GIT_NORMALIZADA=$(echo "$URL_GIT" | tr -d '[:space:]')
        
        if [ "$URL_REMOTA_ATUAL" != "$URL_GIT_NORMALIZADA" ] && [ -n "$URL_REMOTA_ATUAL" ]; then
            echo "⚠️  Aviso: A pasta '$NOME_ALUNO' já existe, mas aponta para OUTRO repositório!"
            echo "🔗 URL Atual da Pasta: $URL_REMOTA_ATUAL"
            echo "🔗 Nova URL Solicitada: $URL_GIT_NORMALIZADA"
            echo ""
            
            if [ "$FORCAR_SUBSTITUICAO" = "sim" ]; then
                CONFIRM_WIPE="s"
                echo "⚡ Flag --force detectada. Substituindo repositório automaticamente..."
            else
                read -r -p "Deseja APAGAR a pasta antiga para clonar este novo projeto? (s/N): " CONFIRM_WIPE
                CONFIRM_WIPE=${CONFIRM_WIPE:-n}
            fi
            
            if [[ "$CONFIRM_WIPE" =~ ^[sS]$ ]]; then
                echo "🗑️ Limpando diretório antigo 'apps/$NOME_ALUNO' para evitar conflito de histórico..."
                rm -rf "$PASTA_ALUNO_LOCAL"
                export COMPILAR_NOVAMENTE="sim"
            else
                echo "🛑 Operação cancelada para proteger o repositório local existente."
                exit 1
            fi
        fi
    fi
    # ---------------------------------------------------

    # Fluxo normal de verificação (caso as URLs sejam iguais ou a pasta tenha sido apagada acima)
    if [ -d "$PASTA_CODIGOS_LOCAL" ]; then
        echo "📂 A pasta do aluno '$NOME_ALUNO' já existe localmente."
        if [ "$FORCAR_SUBSTITUICAO" = "sim" ]; then
            ATUALIZAR="s"
        else
            read -r -p "Deseja verificar e atualizar o código do GitHub? (s/N): " ATUALIZAR
            ATUALIZAR=${ATUALIZAR:-n}
        fi
        
        if [[ "$ATUALIZAR" =~ ^[sS]$ ]]; then
            echo "🔄 Atualizando repositório Git existente..."
            cd "$PASTA_CODIGOS_LOCAL" && git fetch --all && git reset --hard origin/$(git remote show origin | grep 'HEAD branch' | cut -d' ' -f5) && cd "$DIRETORIOBASE"
            export COMPILAR_NOVAMENTE="sim"
        else
            echo "⏭️  Mantendo o código local atual sem atualizar do GitHub."
            export COMPILAR_NOVAMENTE="nao"
        fi
    else
        echo "📥 Clonando projeto do aluno para apps/$NOME_ALUNO/codigos/..."
        mkdir -p "$PASTA_CODIGOS_LOCAL"
        git clone "$URL_GIT" "$PASTA_CODIGOS_LOCAL"
        export COMPILAR_NOVAMENTE="sim"
    fi

else
    # Cenário B: Cópia Manual (Sem alteração)
    export CONFIG_ORIGEM="local"
    export NOME_ALUNO="$PARAMETRO"
    export PASTA_ALUNO_LOCAL="$DIRETORIOBASE/apps/$NOME_ALUNO"
    export PASTA_CODIGOS_LOCAL="$PASTA_ALUNO_LOCAL/codigos"
    export PASTA_APP_LOCAL="$PASTA_ALUNO_LOCAL/app"
    
    if [ ! -d "$PASTA_CODIGOS_LOCAL" ]; then
        echo "📁 Pasta 'apps/$NOME_ALUNO/codigos/' não encontrada."
        mkdir -p "$PASTA_CODIGOS_LOCAL"
        echo "👉 Por favor, extraia os arquivos do aluno dentro de: $PASTA_CODIGOS_LOCAL"
        read -r -p "Pressione [ENTER] quando os arquivos estiverem no lugar para continuar..."
        export COMPILAR_NOVAMENTE="sim"
    else
        if [ "$FORCAR_SUBSTITUICAO" = "sim" ]; then
            export COMPILAR_NOVAMENTE="sim"
        else
            read -r -p "A pasta já existe. Deseja recompilar o projeto atual? (S/n): " RECOMPILAR
            RECOMPILAR=${RECOMPILAR:-s}
            if [[ "$RECOMPILAR" =~ ^[sS]$ ]]; then
                export COMPILAR_NOVAMENTE="sim"
            else
                export COMPILAR_NOVAMENTE="nao"
            fi
        fi
    fi
fi

# =========================================================
# GARANTIA DE ESTRUTURA
# Impede que o Docker crie o volume 'app/' como root
# =========================================================
mkdir -p "$PASTA_APP_LOCAL"