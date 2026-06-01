#!/usr/bin/env bash
set -euo pipefail

log() { echo -e "\n==> $*"; }
fail() { echo -e "\n[ERRO] $*" >&2; exit 1; }

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log "Projeto Korp - provisionamento local Ansible-first"
log "Diretório do projeto: ${PROJECT_DIR}"

cd "${PROJECT_DIR}"

if ! command -v ansible-playbook >/dev/null 2>&1; then
  log "ansible-playbook não encontrado. Executando bootstrap da VM limpa..."
  chmod +x ./00-bootstrap-ubuntu24.sh
  ./00-bootstrap-ubuntu24.sh
else
  log "ansible-playbook encontrado. Bootstrap não é necessário."
fi

if ! command -v ansible-playbook >/dev/null 2>&1; then
  fail "ansible-playbook ainda não foi encontrado após o bootstrap."
fi

ANSIBLE_CMD=(ansible-playbook -i ansible/inventory.ini ansible/playbook.yml)

if [[ "${EUID}" -ne 0 ]]; then
  log "Usuário comum detectado. O Ansible solicitará a senha do sudo."
  ANSIBLE_CMD+=(--ask-become-pass)
else
  log "Execução como root detectada. Senha sudo não será solicitada."
fi

log "Executando provisionamento principal com Ansible..."
"${ANSIBLE_CMD[@]}"
