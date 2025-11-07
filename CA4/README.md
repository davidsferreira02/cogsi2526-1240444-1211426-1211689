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
## Issue #49 — Ensure that your playbooks are idempotent

A idempotência, em ***Ansible***, é alcançada através da remoção da necessidade de gastar recursos computacionais em operaçãos que são repetidas sempre que o *provision* das máquinas é realizado. Podemos alcançar o objetivo utilizando funções *built'in*, colocadas nos ficheiros *.yml* com todo o processo de *provision*.

Posto isto, as seguintes alterações foram feitas aos ficheiros *.xml*: 

1. **DB**

- Foi utilizada a função ***state: present*** para garantir que determinados pacotes não são instalados novamente:

      name: Update apt cache and install packages for H2
      apt:
        update_cache: yes
        name:
          - openjdk-17-jre-headless
          - ufw
          - curl
          - unzip
        state: present
  
- A função ***register*** foi usada também para guardar o resultado de uma determinada tarefa e depois utilizar o mesmo para validações. Juntamente com esta função foi utilizada a função ***until***. Esta serve para repetir uma tarefa até que a mesma seja bem sucedida.

      name: Download H2 jar
      get_url:
        url: "https://repo1.maven.org/maven2/com/h2database/h2/{{ h2_version }}/h2-{{ h2_version }}.jar"
        dest: "/opt/h2/h2-{{ h2_version }}.jar"
        mode: '0644'
      register: h2_jar_download
      until: h2_jar_download is succeeded
      retries: 3
      delay: 5

Como é possível observar no método mostrado anteriormente, foram ainda usadas as funções ***retries*** e ***delay***, que, respetivamente, limitam as tentativas da execução da tarefa, em caso de falha, e o tempo entre as mesmas.

É também usado a função ***when***, esta tem como objetivo realizar a tarefa definida apenas quando uma condição se validar. Na nossa solução, esta é amplamente utilizada em conjunto com a função ***register***, já descrita.

      name: Initialize H2 database files if missing
        command: >-
          /usr/bin/java -cp "/opt/h2/h2-{{ h2_version }}.jar" org.h2.tools.RunScript
          -url "jdbc:h2:/data/h2/payrolldb" -user sa -password password -script "/tmp/init_payrolldb.sql"
        become_user: vagrant
        when: not h2_db_mv.stat.exists and not h2_db_legacy.stat.exists

Neste ficheiro é ainda utilizada a função ***ufw***, na criação das regras de *firewall*. Esta cria as regras de *firewall* apenas se as mesmas não existam, de forma *built-in*.

      name: Allow app server access to H2 port
      ufw:
        rule: allow
        proto: tcp
        from_ip: "{{ app_ip }}"
        to_port: 9092
        comment: "Allow app to connect to H2"

Para validarmos se este acontece, basta colocar o código em execução duas vezes e ter em atenção a parte final do *output*, pois este irá revelar quantas tarefas foram executadas, sendo este número ser o mais reduzido possível.

1. **1.ª Execução**

- DB

      PLAY RECAP *********************************************************************
      db                         : ok=16   changed=12   unreachable=0    failed=0    skipped=1    rescued=0    ignored=0 

- APP 

      PLAY RECAP *********************************************************************
      app                        : ok=12   changed=4    unreachable=0    failed=0    skipped=2    rescued=0    ignored=0 

2. **2.ª Execução**

- DB

      PLAY RECAP *********************************************************************
      db                         : ok=14   changed=0    unreachable=0    failed=0    skipped=3    rescued=0    ignored=0

- APP 

      TASK [spring_app : Build Spring Boot application] ******************************
      changed: [app]

      PLAY RECAP *********************************************************************
      app                        : ok=12   changed=1    unreachable=0    failed=0    skipped=2    rescued=0    ignored=0 

Como podemos observar a idempotência é alcançada, pois apenas uma função é repetida entre execuções, a construção do *jar*.

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

