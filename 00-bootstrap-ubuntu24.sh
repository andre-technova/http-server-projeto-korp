#!/usr/bin/env bash
set -euo pipefail

log() { echo -e "\n==> $*"; }
fail() { echo -e "\n[ERRO] $*" >&2; exit 1; }

if [[ "${EUID}" -ne 0 ]]; then
  if ! command -v sudo >/dev/null 2>&1; then
    fail "Execute como root ou instale sudo para o usuário atual."
  fi
  SUDO="sudo"
else
  SUDO=""
fi

run_as_root() {
  if [[ -n "${SUDO}" ]]; then
    sudo "$@"
  else
    "$@"
  fi
}

export DEBIAN_FRONTEND=noninteractive

if [[ -f /etc/os-release ]]; then
  # shellcheck disable=SC1091
  source /etc/os-release
  log "Sistema detectado: ${PRETTY_NAME:-Linux}"
else
  fail "Não foi possível identificar o sistema operacional."
fi

if ! command -v apt-get >/dev/null 2>&1; then
  fail "Este bootstrap foi feito para Ubuntu/Debian com APT."
fi

log "Atualizando cache de pacotes..."
run_as_root apt-get update

log "Instalando dependências base da VM limpa..."
run_as_root apt-get install -y \
  ca-certificates \
  curl \
  git \
  unzip \
  gnupg \
  lsb-release \
  python3 \
  python3-apt \
  openssh-server \
  ansible

log "Habilitando e iniciando SSH..."
run_as_root systemctl enable --now ssh

log "Validações iniciais..."
command -v ansible-playbook >/dev/null 2>&1 || fail "ansible-playbook não foi encontrado após a instalação."
ansible --version | head -n 1 || true
ansible-playbook --version | head -n 1 || true
curl --version | head -n 1 || true
git --version || true

log "Endereços IP detectados:"
ip -brief address show | awk '$1 != "lo" {print "Interface: "$1" | Estado: "$2" | IP: "$3}' || true

log "Status do SSH:"
run_as_root systemctl status ssh --no-pager --lines=5 || true

echo
echo "Bootstrap concluído com sucesso."
echo "Este script NÃO sobe a aplicação. Ele apenas prepara a VM para executar o Ansible."
echo
echo "Próximo comando esperado:"
echo "ansible-playbook -i ansible/inventory.ini ansible/playbook.yml"
echo
echo "Alternativa segura para VM zerada:"
echo "./01-provision-local.sh"
