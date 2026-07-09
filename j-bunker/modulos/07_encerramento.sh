#!/bin/bash

# Só entra no ciclo de monitoramento e encerramento interativo se o app subiu corretamente
if [ "$APP_PRONTO" = "sim" ]; then
    
    # FUNÇÃO DE ENCERRAMENTO SEGURO INTERATIVO (CTRL+C)
    funcao_encerrar() {
        echo -e "\n🛑 Encerrando o container de forma segura..."
        docker stop "$CONTAINER_FINAL" >/dev/null 2>&1
        
        # Verifica se o modo força está desativado para exibir o prompt interativo
        if [ "$FORCAR_SUBSTITUICAO" != "sim" ]; then
            echo ""
            read -p "🗑️  Deseja apagar a pasta local do aluno '$NOME_ALUNO'? (s/N): " CONFIRM_DEL
            CONFIRM_DEL=${CONFIRM_DEL:-n}
            if [[ "$CONFIRM_DEL" =~ ^[sS]$ ]]; then
                echo "🗑️  Removendo apps/$NOME_ALUNO..."
                rm -rf "$PASTA_ALUNO_LOCAL"
                echo "✅ Pasta de arquivos limpa com sucesso."
            else
                echo "⏭️  Mantendo os arquivos locais do aluno salvos."
            fi
        fi
        exit 0
    }
    
    # Armadilha para interceptar o CTRL+C
    trap 'funcao_encerrar' INT
    
    # Exibe os logs contínuos em tempo real. O script fica "preso" aqui até o CTRL+C
    docker logs -f "$CONTAINER_FINAL"
fi