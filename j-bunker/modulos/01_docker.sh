#!/bin/bash
echo "🐳 Verificando se o Docker Desktop está ativo..."
docker info >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "--------------------------------------------------------"
    echo "❌ ERRO: O Docker Desktop não está rodando!"
    echo "👉 Por favor, abra o aplicativo Docker Desktop no Windows."
    echo "👉 Aguarde o ícone no canto inferior esquerdo ficar VERDE (Running)."
    echo "--------------------------------------------------------"
    exit 1
fi