# http-server-projeto-korp

Projeto técnico para desafio prático DevOps com Go, Docker, NGINX, Prometheus, Grafana e Ansible.

## Objetivo

Provisionar, de forma automatizada, um serviço HTTP em Golang chamado `http-server-projeto-korp`, executado em containers Docker, acessado via NGINX como proxy reverso e monitorado por Prometheus e Grafana.

## Arquitetura

- `http-server-projeto-korp`: aplicação Go na porta 8080, sem porta exposta diretamente no host.
- `nginx`: proxy reverso publicando a porta 80 do host.
- `prometheus`: coleta métricas do serviço Go em `/metrics`.
- `grafana`: visualização das métricas com datasource e dashboard provisionados.
- `ansible`: provisionamento local-first em Ubuntu 24.

## Execução em Ubuntu 24 limpo

O Ubuntu 24 pode não trazer Docker, Docker Compose, curl, Git, Ansible ou OpenSSH Server instalados por padrão. Por isso, o projeto possui um bootstrap mínimo e depois executa o provisionamento principal com Ansible.

```bash
cd /home/technova
mkdir -p /home/technova/korp-devops
mv /home/technova/http-server-projeto-korp.tar.gz /home/technova/korp-devops/ 2>/dev/null || true
cd /home/technova/korp-devops
tar -xzf http-server-projeto-korp.tar.gz
cd http-server-projeto-korp
chmod +x 00-bootstrap-ubuntu24.sh 01-provision-local.sh
./01-provision-local.sh
```

## Comando principal Ansible

Após o bootstrap, o provisionamento pode ser executado diretamente com:

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbook.yml
```

## Validação

```bash
curl http://localhost:80/projeto-korp
curl http://localhost:80/metrics
cd /opt/http-server-projeto-korp
docker compose ps
```

## Acessos

- Aplicação: http://localhost:80/projeto-korp
- Métricas: http://localhost:80/metrics
- Prometheus: http://localhost:9090
- Grafana: http://localhost:3000
- Login Grafana: `admin`
- Senha Grafana: `admin`

## Métricas

- `http_server_projeto_korp_up`: disponibilidade do serviço.
- `http_requests_total`: volume de requisições no endpoint `/projeto-korp`.
- `http_server_last_request_timestamp_seconds`: timestamp da última requisição.

## Decisões técnicas

- Execução local-first com `localhost` e `ansible_connection=local`, evitando dependência inicial de SSH.
- Bootstrap mínimo para preparar VM Ubuntu 24 limpa.
- Docker Compose moderno com `docker compose`.
- NGINX como único ponto publicado na porta 80.
- Métricas em formato Prometheus expostas diretamente pela aplicação Go.
- Dashboard do Grafana provisionado automaticamente.

## Melhorias futuras

- Pipeline CI/CD.
- Alertmanager.
- Testes automatizados em Go.
- Kubernetes.
- Hardening de containers e NGINX.
