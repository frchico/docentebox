#!/bin/bash
export MEMORIA_CONTAINER="2g"
export CPUS_CONTAINER="4"
export FORCAR_SUBSTITUICAO="nao"
export AQUECER_CACHE="nao"
export PARAMETRO=""
export ARG_OPCIONAL=""

while [ "$#" -gt 0 ]; do
    case "$1" in
        -f|--force) 
            FORCAR_SUBSTITUICAO="sim"
            shift 
            ;;
        --cache|/cache|-c) 
            AQUECER_CACHE="sim"
            shift 
            ;;
        -mem|--mem)
            if [ -n "$2" ]; then 
                MEMORIA_CONTAINER="$2"
                shift 2
            else 
                echo "❌ Erro: o parâmetro de memória exige um valor (Ex: --mem 4g)"
                exit 1
            fi 
            ;;
        -cpu|--cpu)
            if [ -n "$2" ]; then 
                CPUS_CONTAINER="$2"
                shift 2
            else 
                echo "❌ Erro: o parâmetro de cpu exige um valor (Ex: --cpu 2)"
                exit 1
            fi 
            ;;
        *)
            if [ -z "$PARAMETRO" ]; then 
                PARAMETRO="$1"
            else 
                ARG_OPCIONAL="$1"
            fi
            shift 
            ;;
    esac
done

# Se a flag de cache foi passada e não há parâmetros de aluno, 
# permite rodar apenas o aquecimento e sair sem erro.
if [ -z "$PARAMETRO" ] && [ "$AQUECER_CACHE" = "nao" ]; then
    echo "Uso:"
    echo "  Por pasta: ./testar_aluno.sh <nome_pasta> [opções]"
    echo "  Por GitHub: ./testar_aluno.sh <URL_GitHub> [nome_pasta] [opções]"
    echo ""
    echo "Opções:"
    echo "  -f, --force         Força a atualização e compilação completa sem fazer perguntas."
    echo "  --mem <valor>       Define a memória do container (Padrão: 2g. Ex: --mem 4g)"
    echo "  --cpu <valor>       Define a quantidade de CPUs do container (Padrão: 4. Ex: --cpu 2)"
    echo ""
    echo "Opções Especiais:"
    echo "  --cache ou /cache   Aquece os caches globais do Maven e Gradle."
    exit 1
fi