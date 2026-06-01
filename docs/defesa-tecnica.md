# Defesa Técnica - Projeto Korp

## Objetivo

Este projeto foi desenvolvido para atender ao desafio prático DevOps da Korp, demonstrando conhecimentos em Golang, Docker, Docker Compose, NGINX, Prometheus, Grafana e Ansible.

A proposta foi criar uma solução simples, funcional, automatizada e reproduzível em uma VM Ubuntu 24.04 limpa.

## Arquitetura

A arquitetura utiliza quatro containers principais:

- http-server-projeto-korp: aplicação HTTP em Golang.
- nginx-projeto-korp: proxy reverso exposto na porta 80.
- prometheus-projeto-korp: coleta métricas da aplicação.
- grafana-projeto-korp: visualização das métricas coletadas.

Fluxo principal:

Usuário/Navegador
        |
        v
NGINX :80
        |
        v
http-server-projeto-korp :8080
        |
        v
/metrics <- Prometheus <- Grafana

## Decisões técnicas

### Golang

Foi utilizado Golang por ser uma linguagem leve, performática e adequada para criação de serviços HTTP simples.

### Docker

A aplicação foi empacotada em container para garantir portabilidade, isolamento e padronização da execução.

### Docker Compose

O Docker Compose foi utilizado para orquestrar localmente os containers da aplicação, NGINX, Prometheus e Grafana.

### NGINX

O NGINX foi utilizado como proxy reverso, expondo apenas a porta 80 no host e encaminhando as requisições para o serviço Go internamente.

### Rede Docker bridge

Foi criada uma rede Docker bridge dedicada para permitir comunicação entre containers sem expor diretamente a porta da aplicação Go no host.

### Prometheus

O Prometheus coleta métricas no endpoint /metrics, permitindo acompanhar disponibilidade e volume de requisições.

### Grafana

O Grafana foi provisionado com datasource e dashboard para visualização das métricas do serviço.

### Ansible

O Ansible automatiza a preparação do ambiente, instalação de dependências, instalação do Docker, criação da rede, build da imagem, subida dos containers e validação dos endpoints.

## Validação

A solução foi validada em uma VM Ubuntu 24.04 limpa e também a partir de um clone limpo do repositório GitHub.

Resultado esperado do playbook:

failed=0
skipped=0

Endpoints principais:

curl http://localhost:80/projeto-korp
curl http://localhost:80/metrics

Validação dos containers:

cd /opt/http-server-projeto-korp
docker compose ps

## Observações operacionais

Caso o usuário local ainda não tenha permissão para acessar o Docker diretamente, é possível validar com:

sudo docker compose ps

Ou adicionar o usuário ao grupo docker:

sudo usermod -aG docker $USER
newgrp docker

## Melhorias futuras

- Adicionar pipeline CI/CD.
- Adicionar testes automatizados para o serviço Go.
- Implementar alertas com Alertmanager.
- Executar a solução em Kubernetes.
- Adicionar hardening de segurança no NGINX e Grafana.
- Melhorar logs estruturados da aplicação.
