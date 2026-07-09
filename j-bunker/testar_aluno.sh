#!/bin/bash

export DIRETORIOBASE=$(pwd -W 2>/dev/null || pwd)
export COMPILAR_NOVAMENTE="sim"

echo "=== 🚀 Iniciando Sistema de Testes ==="

# INVERTEMOS A ORDEM AQUI:
source "$DIRETORIOBASE/modulos/00_parametros.sh" "$@"
source "$DIRETORIOBASE/modulos/01_docker.sh"
source "$DIRETORIOBASE/modulos/02_1_limpeza.sh"
source "$DIRETORIOBASE/modulos/02_5_aquecimento.sh"
source "$DIRETORIOBASE/modulos/03_git_local.sh"
source "$DIRETORIOBASE/modulos/04_analise.sh"
source "$DIRETORIOBASE/modulos/05_build_cache.sh"
source "$DIRETORIOBASE/modulos/06_executar.sh"
source "$DIRETORIOBASE/modulos/07_encerramento.sh"