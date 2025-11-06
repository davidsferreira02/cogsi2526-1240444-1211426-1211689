# CA4 - Ansible-based provisioning (two VMs)

## Issue #48 — Evolve Part 2 of CA3 to use Ansible as a provisioner in both VMs

Este issue evolui o Part 2 do CA3 para utilizar Ansible como provisioner em ambas as VMs:

- VM app (host1): faz o deploy e configura a aplicação "Building REST services with Spring".
- VM db (host2): instala e configura a base de dados H2 em modo servidor (TCP).

Resumo técnico:

- Passagem de shell scripts para Ansible usando `ansible_local` no `Vagrantfile`, evitando dependências na máquina host.
- Dois playbooks (app.yml e db.yml) que aplicam os roles `spring_app` e `h2_db` respetivamente.
- Role `spring_app`: instala Java/Gradle, ajusta `application.properties` para apontar ao H2 (TCP), compila com `bootJar` e cria um serviço systemd (`ca4-app.service`).
- Role `h2_db`: instala Java + UFW(Uncomplicated Firewall) do Ubuntu, descarrega o JAR do H2, inicializa a BD em `/data/h2`, abre apenas a porta 9092 para a VM app e cria um serviço systemd (`h2.service`).

Resultado: aprovisionamento idempotente, serviços geridos por systemd, e separação clara entre responsabilidades de app e db com Ansible.

## Como foi alcançado (Evolve Part 2 of CA3 to use Ansible in both VMs)

Objetivo: usar Ansible como provisioner nas duas VMs para

- host1 (app): deploy e configuração da aplicação "Building REST services with Spring"
- host2 (db): deploy e configuração do H2 em modo servidor (TCP)

### Estrutura criada

- `Vagrantfile`
  - Define duas VMs Ubuntu 22.04: `app` e `db` com rede privada
  - Monta o workspace do repositório em `/workspace` nas VMs
  - Usa `ansible_local` para executar Ansible dentro de cada VM
  - Passa variáveis úteis (IPs, caminho do projeto, flags de build/start)

- Playbooks Ansible
  - `ansible/app.yml` (host1): aplica o role `spring_app`
  - `ansible/db.yml` (host2): aplica o role `h2_db`

- Roles
  - `ansible/roles/spring_app`
    - `tasks/main.yml`: instala Java/Gradle/Maven, atualiza `application.properties` com a URL do H2, compila (`./gradlew bootJar`), escolhe o JAR gerado, instala e ativa o serviço systemd da app
    - `templates/ca4-app.service.j2`: template do serviço systemd que arranca o JAR com Java 17 e reinício automático em falha
  - `ansible/roles/h2_db`
    - `tasks/main.yml`: instala Java e UFW, faz download do JAR do H2 para `/opt/h2`, inicializa a base em `/data/h2`, configura UFW para expor 9092 apenas para o IP da VM `app`, instala e ativa o serviço systemd do H2
    - `templates/h2.service.j2`: template do serviço systemd do H2 em modo servidor TCP

### Variáveis suportadas (podem ser passadas ao `vagrant up`)

- Rede: `APP_IP` (default `192.168.244.172`), `DB_IP` (default `192.168.244.171`)
- DB: `H2_VERSION` (default `2.3.232`), `START_DB` (default `true`)
- App: `APP_PROJECT_DIR` (default `/workspace/CA2/Part2`), `BUILD_APP` (default `true`), `START_APP` (default `true`)

Exemplo:

```bash
APP_IP=192.168.56.12 DB_IP=192.168.56.11 APP_PROJECT_DIR=/workspace/CA2/Part2 vagrant up
```

### Verificação rápida

- VM DB (host2):

```bash
vagrant ssh db
```

- VM App (host1):

```bash
vagrant ssh app
```

## Issue #53 — Health-check dos serviços

Para garantir que cada serviço está corretamente a correr após o aprovisionamento, foram adicionadas tarefas de health-check nos playbooks Ansible:

### O que foi implementado

- Host1 (app) — `ansible/app.yml`
  - Nova variável `app_port` com default `8080`.
  - `post_tasks` que:
    - Esperam que a porta TCP `{{ app_port }}` esteja a ouvir (`wait_for`, `state: started`).
    - Efetuam um pedido HTTP a `http://localhost:{{ app_port }}/` com o módulo `uri`, validando resposta `200 OK` com retries e backoff.
    - Mostram um excerto da resposta (útil para diagnóstico rápido) via `debug`.

- Host2 (db) — `ansible/db.yml`
  - `post_tasks` que:
    - Esperam que a porta TCP `9092` (H2 Server) esteja a ouvir (`wait_for`, `state: started`).
    - Confirmam via `debug` que a porta está aberta.

Estas verificações falham o playbook se a aplicação web não responder com `200` ou se o socket da BD não abrir, permitindo detetar problemas cedo.



