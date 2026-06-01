# http-server-projeto-korp

Projeto técnico desenvolvido para o desafio prático DevOps da Korp, utilizando **Golang, Docker, Docker Compose, NGINX, Prometheus, Grafana e Ansible**.

O objetivo principal é entregar uma solução simples, funcional, automatizada, observável e reproduzível em uma VM Ubuntu 24.04 limpa.

---

## Objetivo

Provisionar automaticamente um serviço HTTP em Golang chamado `http-server-projeto-korp`.

O serviço é executado em container Docker, acessado por meio de um proxy reverso NGINX e monitorado com Prometheus e Grafana.

O endpoint principal da aplicação é:

```bash
GET /projeto-korp
```

Exemplo de resposta:

```json
{
  "nome": "Projeto Korp",
  "horario": "2026-06-01T00:53:50Z"
}
```

O campo `horario` é gerado dinamicamente em UTC a cada requisição.

---

## Arquitetura

A solução é composta pelos seguintes componentes:

* `http-server-projeto-korp`: aplicação HTTP em Golang, escutando internamente na porta 8080.
* `nginx-projeto-korp`: proxy reverso, expondo a porta 80 no host.
* `prometheus-projeto-korp`: coleta métricas expostas pela aplicação no endpoint `/metrics`.
* `grafana-projeto-korp`: dashboard para visualização das métricas.
* `ansible`: automação do provisionamento local em Ubuntu 24.04.

Fluxo simplificado:

```text
Usuário / Navegador
        |
        v
NGINX :80
        |
        v
http-server-projeto-korp :8080
        |
        v
/metrics <- Prometheus <- Grafana
```

A aplicação Go não expõe porta diretamente no host. O acesso externo ocorre somente pelo NGINX.

---

## Estrutura do projeto

```text
http-server-projeto-korp/
├── ansible/
│   ├── group_vars/
│   │   └── all.yml
│   ├── inventory.ini
│   └── playbook.yml
├── app/
│   ├── go.mod
│   └── main.go
├── docs/
│   └── defesa-tecnica.md
├── grafana/
│   ├── dashboards/
│   │   └── http-server-projeto-korp-dashboard.json
│   └── provisioning/
│       ├── dashboards/
│       │   └── dashboards.yml
│       └── datasources/
│           └── datasource.yml
├── nginx/
│   └── conf.d/
│       └── http-server-projeto-korp.conf
├── prometheus/
│   └── prometheus.yml
├── 00-bootstrap-ubuntu24.sh
├── 01-provision-local.sh
├── Dockerfile
├── docker-compose.yml
└── README.md
```

---

## Pré-requisitos

A solução foi validada em **Ubuntu 24.04 LTS**.

O projeto considera que uma VM limpa pode não possuir previamente:

* Docker
* Docker Compose
* Ansible
* curl
* Git
* OpenSSH Server

Por isso, o script `00-bootstrap-ubuntu24.sh` prepara a base mínima da máquina, e o script `01-provision-local.sh` executa o fluxo completo de provisionamento.

---

## Execução em Ubuntu 24 limpo

Clone o repositório:

```bash
cd /home/technova
mkdir -p korp-devops
cd korp-devops
git clone https://github.com/andre-technova/http-server-projeto-korp.git
cd http-server-projeto-korp
```

Dê permissão de execução aos scripts:

```bash
chmod +x 00-bootstrap-ubuntu24.sh 01-provision-local.sh
```

Execute o provisionamento completo:

```bash
./01-provision-local.sh
```

Esse script verifica se o Ansible já está instalado.

Caso o Ansible não exista, ele executa automaticamente o bootstrap inicial. Depois disso, chama o playbook principal responsável por instalar dependências, preparar Docker, criar rede, buildar a imagem, subir os containers e validar os endpoints.

Se executado com um usuário comum, o script solicitará a senha de sudo:

```text
BECOME password:
```

---

## Execução direta do Ansible

Após o bootstrap inicial, o playbook também pode ser executado diretamente.

Com usuário comum com permissão de sudo:

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbook.yml --ask-become-pass
```

Como `root`:

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbook.yml
```

---

## Validação

Endpoint principal:

```bash
curl http://localhost:80/projeto-korp
```

Exemplo de resposta:

```json
{"nome":"Projeto Korp","horario":"2026-06-01T00:53:50Z"}
```

Endpoint de métricas:

```bash
curl http://localhost:80/metrics
```

Exemplo de métricas expostas:

```text
# HELP http_server_projeto_korp_up Disponibilidade do servico http-server-projeto-korp.
# TYPE http_server_projeto_korp_up gauge
http_server_projeto_korp_up 1

# HELP http_requests_total Total de requisicoes recebidas no endpoint /projeto-korp.
# TYPE http_requests_total counter
http_requests_total{service="http-server-projeto-korp",endpoint="/projeto-korp"} 2

# HELP http_server_last_request_timestamp_seconds Timestamp Unix da ultima requisicao recebida no endpoint /projeto-korp.
# TYPE http_server_last_request_timestamp_seconds gauge
http_server_last_request_timestamp_seconds{service="http-server-projeto-korp"} 1780275230
```

Validar containers:

```bash
cd /opt/http-server-projeto-korp
docker compose ps
```

Containers esperados:

```text
grafana-projeto-korp
http-server-projeto-korp
nginx-projeto-korp
prometheus-projeto-korp
```

---

## Acessos

Aplicação:

```text
http://localhost:80/projeto-korp
```

Métricas:

```text
http://localhost:80/metrics
```

Prometheus:

```text
http://localhost:9090
```

Grafana:

```text
http://localhost:3000
```

Credenciais padrão do Grafana:

```text
Usuário: admin
Senha: admin
```

---

## Métricas implementadas

A aplicação expõe métricas em formato compatível com Prometheus:

| Métrica                                      | Tipo    | Descrição                                                  |
| -------------------------------------------- | ------- | ---------------------------------------------------------- |
| `http_server_projeto_korp_up`                | Gauge   | Indica disponibilidade do serviço                          |
| `http_requests_total`                        | Counter | Total de requisições recebidas no endpoint `/projeto-korp` |
| `http_server_last_request_timestamp_seconds` | Gauge   | Timestamp Unix da última requisição recebida               |

---

## Automação com Ansible

O playbook Ansible contempla:

* Validação do sistema operacional
* Atualização do cache APT
* Instalação de dependências
* Instalação do Docker
* Instalação do Docker Compose v2
* Habilitação do SSH
* Habilitação do serviço Docker
* Criação do diretório de deploy em `/opt/http-server-projeto-korp`
* Cópia dos arquivos do projeto
* Criação da rede Docker bridge
* Build da imagem da aplicação Go
* Execução dos containers com Docker Compose
* Validação do endpoint `/projeto-korp`
* Validação do endpoint `/metrics`
* Exibição da resposta da aplicação no console

Resultado esperado ao final:

```text
failed=0
skipped=0
```

---

## Decisões técnicas

### Golang

Golang foi utilizado por ser leve, performático e adequado para criação de serviços HTTP simples.

### Docker

A aplicação foi empacotada em container para garantir padronização, isolamento e portabilidade.

### Docker Compose

O Docker Compose foi utilizado para orquestrar localmente os containers da aplicação, NGINX, Prometheus e Grafana.

### NGINX

O NGINX atua como proxy reverso, expondo apenas a porta 80 do host e encaminhando as requisições para o serviço Go internamente.

### Rede Docker bridge

Foi criada uma rede Docker bridge dedicada para comunicação entre os containers, evitando exposição direta da porta 8080 no host.

### Prometheus

O Prometheus coleta métricas da aplicação por meio do endpoint `/metrics`.

### Grafana

O Grafana foi provisionado automaticamente com datasource e dashboard para visualização das métricas.

### Ansible

O Ansible foi utilizado para garantir provisionamento reproduzível, reduzindo dependência de configuração manual da VM.

---

## Observação sobre permissão Docker

Caso o usuário local ainda não tenha permissão para acessar o Docker diretamente, é possível validar os containers com:

```bash
sudo docker compose ps
```

Ou adicionar o usuário ao grupo `docker`:

```bash
sudo usermod -aG docker $USER
newgrp docker
```

Após isso, execute novamente:

```bash
cd /opt/http-server-projeto-korp
docker compose ps
```

---

## Validação realizada

A solução foi validada em uma VM Ubuntu 24.04 limpa e também a partir de um clone limpo do repositório GitHub.

Resumo da validação:

```text
PLAY RECAP
localhost : ok=20 changed=3 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0
```

Também foram validados:

* Resposta do endpoint `/projeto-korp`
* Exposição das métricas em `/metrics`
* Execução dos containers via Docker Compose
* Dashboard do Grafana
* Coleta de métricas pelo Prometheus

---

## Documentação complementar

A defesa técnica do projeto está disponível em:

```text
docs/defesa-tecnica.md
```

Esse documento resume a arquitetura, decisões técnicas, validação realizada e possíveis melhorias futuras.

---

## Melhorias futuras

Possíveis evoluções do projeto:

* Adicionar pipeline CI/CD
* Adicionar testes automatizados para o serviço Go
* Implementar Alertmanager
* Executar a solução em Kubernetes
* Aplicar hardening no NGINX e nos containers
* Adicionar logs estruturados
* Criar healthchecks mais detalhados
* Externalizar credenciais do Grafana via `.env`
