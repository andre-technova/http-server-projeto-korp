#!/usr/bin/env bash
set -euo pipefail

log() { echo -e "\n==> $*"; }
fail() { echo -e "\n[ERRO] $*" >&2; exit 1; }

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${PROJECT_DIR}"

log "Projeto Korp - provisionamento local Ansible-first"
log "Diretório do projeto: ${PROJECT_DIR}"

BAD_PATTERN="client_""golang"
if grep -R "${BAD_PATTERN}" -n app Dockerfile 2>/dev/null; then
  fail "Pacote incorreto: ainda existe referencia ao pacote Prometheus removido. Use o pacote limpo mais recente."
fi

if ! command -v ansible-playbook >/dev/null 2>&1; then
  log "ansible-playbook não encontrado. Executando bootstrap da VM limpa..."
  chmod +x ./00-bootstrap-ubuntu24.sh
  ./00-bootstrap-ubuntu24.sh
else
  log "ansible-playbook encontrado. Bootstrap não é necessário."
fi

log "Executando provisionamento principal com Ansible..."
ansible-playbook -i ansible/inventory.ini ansible/playbook.yml
