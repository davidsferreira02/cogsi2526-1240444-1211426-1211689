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

## Issue #50 — Use Ansible to configure PAM to enforce a complex password policy

Para atribuir ao ***Ansible*** a responsabilidade de configurar uma política de *passwords* segura foi criado um ficheiro *.yml* extra para esta função. Desta maneira, este é possível ser reaproveitado para possíveis novas instâncias e possíveis alterações não afetarão os módulos principais para o provisionamento das máquinas. Posto isto, foram criados os seguintes métodos para:

1. Instalar a biblioteca ***libpam-pwqualioty*** para a definição de políticas de *password*

          name: Install libpam-pwquality
          package:
            name: "libpam-pwquality"
            state: present

2. Configurar os requisitos da *password*, através da alteração dos ficheiros ***common-password***, ***common-auth*** e ***pwquality.conf***. O último é necessário ser editado dado que a máquina utilizada é *Ubuntu*.


        name: Ensure pam_pwhistory.so enforces password history (no reuse of last 5)
        lineinfile:
          path: "{{ common_password }}"
          insertafter: '^password\s+\[success=1.*pam_unix\.so'
          regexp: '^password\s+(required|requisite)\s+pam_pwhistory\.so'
          line: 'password requisite pam_pwhistory.so remember=5 use_authtok enforce_for_root'
          state: present
          backup: yes
        when: common_password is defined

        name: Ensure pam_pwquality enforces password complexity rules
        lineinfile:
          path: "{{ common_password }}"
          regexp: '^password\s+requisite\s+pam_pwquality\.so'
          line: 'password requisite pam_pwquality.so minlen=12 minclass=3 dictcheck=1 usercheck=1 retry=3 enforce_for_root'
          state: present
          backup: yes
        when: common_password is defined

        name: Ensure pwquality enforces username check (Ubuntu requirement)
        lineinfile:
          path: "{{ password_quality }}"
          regexp: '^usercheck'
          line: 'usercheck = 1'
          create: yes
          backup: yes

        name: Ensure faillock configuration exists in common-auth
        blockinfile:
          path: "{{ common_auth }}"
          insertbefore: '^auth\s+\[success=1'
          marker: "# {mark} ANSIBLE MANAGED BLOCK - faillock"
          block: |
            auth required pam_faillock.so preauth silent deny=5 unlock_time=600
            auth [default=die] pam_faillock.so authfail deny=5 unlock_time=600
            account required pam_faillock.so
          backup: yes
        when: common_auth is defined

3. Por fim, tal como ilustrado nos *slides*, foi criado um utilizador, a *password* deste foi gerado usando a biblioteca ***pwgen***, respeitando os requisitos previamente definidos. Para além disso, o utilizador criado foi adicionado a um grupo, um diretório e um ficheiro dentro deste, de forma a testar a criação do utilizador.

          name: Ensure group 'developers' exists
          group:
            name: developers
            state: present

          name: Create the user 'cogsi'
          user:
            name: cogsi
            shell: /bin/bash
            password: $6$VZ3OJaWEurd4oR1V$6x10uCP9xSfc84wP2N1hI3UE4HUApbX9T.D7UkYYwsSE8bVZPnm07l.5xV5WvgD5/VF1TtXrMds8/RImuYndR.CVAN`'.OTG3=
          register: user_created

          name: Assign 'cogsi' to the 'developers' group
          user:
            name: cogsi
            groups: developers
            append: yes

          name: Create a directory named 'engineering'
          file:
            path: /opt/engineering
            state: directory
            mode: 0750
            group: developers

          name: Create a file in the engineering directory
          file:
            path: "/opt/engineering/private.txt"
            state: touch
            mode: 0770
            group: developers

Passando às validações, em primeiro lugar foi testado o acesso ao ficheiro criado, através do utilizador *default* e com o utilizador criado.

    nacunha@cogsi:~/cogsi2526-1240444-1211426-1211689/CA4/ansible$ vagrant ssh db
    Welcome to Ubuntu 22.04.5 LTS (GNU/Linux 5.15.0-160-generic x86_64)

     * Documentation:  https://help.ubuntu.com
     * Management:     https://landscape.canonical.com
     * Support:        https://ubuntu.com/pro

     System information as of Thu Oct 23 10:31:57 PM UTC 2025

      System load:             1.19
      Usage of /:              21.3% of 30.34GB
      Memory usage:            7%
      Swap usage:              0%
      Processes:               159
      Users logged in:         0
      IPv4 address for enp0s3: 10.0.2.15
      IPv6 address for enp0s3: fd17:625c:f037:2:a00:27ff:fe16:ddef


    This system is built by the Bento project by Chef Software
    More information can be found at https://github.com/chef/bento

    Use of this system is acceptance of the OS vendor EULA and License Agreements.
    vagrant@ca4-db:~$ ls -la /opt/engineering
    ls: cannot open directory '/opt/engineering': Permission denied
    vagrant@ca4-db:~$ sudo -su cogsi
    cogsi@ca4-db:/home/vagrant$ ls -la /opt/engineering
    total 8
    drwxr-x--- 2 root developers 4096 Nov  8 17:08 .
    drwxr-xr-x 5 root root       4096 Nov  8 17:08 ..
    -rwxrwx--- 1 root developers    0 Nov  8 17:29 private.txt
    cogsi@ca4-db:/home/vagrant$ 

Como é possível observar, apenas o utilizar criado pode aceder ao ficheiro também criado.

    vagrant@ca4-app:~$ sudo passwd cogsi
    New password: 
    Retype new password: 
    passwd: password updated successfully
    vagrant@ca4-app:~$ 
    vagrant@ca4-app:~$ 
    vagrant@ca4-app:~$ 
    vagrant@ca4-app:~$ sudo passwd cogsi
    New password: 
    Retype new password: 
    Password has been already used. Choose another.
    passwd: Have exhausted maximum number of retries for service
    passwd: password unchanged
    vagrant@ca4-app:~$ 

Como é possível observar a troca de uma palavra passe já utilizada também não é permitida.

## Issue 51 — Provide hosts.ini (static or the Vagrant auto-inventory path) and show ansible-inventory --list output
<<<<<<< HEAD
=======

Objetivo: disponibilizar um ficheiro de inventário (p.ex. `hosts.ini` estático ou apontar para o inventário gerado automaticamente pelo Vagrant) e mostrar a saída do comando `ansible-inventory --list` para validar o inventário usado pelo Ansible.

O que foi feito para resolver:

- Configurado o provider de ambas as VMs para utilizar o provedor remoto `ansible` em vez de `ansible_local`, de forma a gerir as VMs remotamente via uma instância do Ansible a correr do lado do host.
- Removidas as linhas de configuração dos ficheiros `ansible/app.yml` e `ansible/db.yml` que forçavam a ligação local (local connection), garantindo que o playbook pode ser executado contra um inventário remoto/automaticamente gerado.
- Executado o comando abaixo para inspecionar o inventário gerado pelo Vagrant e confirmar o conteúdo:

```
ansible-inventory -i ".vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory" --list
```

Resultados observados:

- Saída do comando `ansible-inventory --list`:

```
{
    "_meta": {
        "hostvars": {
            "app": {
                "ansible_host": "172.21.208.1",
                "ansible_port": 2200,
                "ansible_ssh_private_key_file": "/mnt/c/Users/rafae/OneDrive/Documentos/Mestrado/2ano/COGSI/CA4/.vagrant/machines/app/virtualbox/private_key",
                "ansible_user": "vagrant"
            },
            "db": {
                "ansible_host": "172.21.208.1",
                "ansible_port": 2222,
                "ansible_ssh_private_key_file": "/mnt/c/Users/rafae/OneDrive/Documentos/Mestrado/2ano/COGSI/CA4/.vagrant/machines/db/virtualbox/private_key",
                "ansible_user": "vagrant"
            }
        },
        "profile": "inventory_legacy"
    },
    "all": {
        "children": [
            "ungrouped"
        ]
    },
    "ungrouped": {
        "hosts": [
            "app",
            "db"
        ]
    }
}
```

- Conteúdo gerado pelo Vagrant (ficheiro `./.vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory`):

```
# Generated by Vagrant

app ansible_host=172.21.208.1 ansible_port=2200 ansible_user='vagrant' ansible_ssh_private_key_file='/mnt/c/Users/rafae/OneDrive/Documentos/Mestrado/2ano/COGSI/CA4/.vagrant/machines/app/virtualbox/private_key'
db ansible_host=172.21.208.1 ansible_port=2222 ansible_user='vagrant' ansible_ssh_private_key_file='/mnt/c/Users/rafae/OneDrive/Documentos/Mestrado/2ano/COGSI/CA4/.vagrant/machines/db/virtualbox/private_key'
```

Conclusão:

- O inventário auto-gerado pelo Vagrant está presente no caminho `./.vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory` e contém entradas para as VMs `app` e `db` com as variáveis de conexão necessárias (host/porta/user/key).
- Caso se prefira um arquivo estático `hosts.ini`, basta criar um ficheiro INI com entradas equivalentes e indicar o caminho para esse ficheiro ao executar o Ansible no Vagrantfile.
>>>>>>> 8701594c6b48c0b65b5f68537dd649a50f4572ab

Objetivo: disponibilizar um ficheiro de inventário (p.ex. `hosts.ini` estático ou apontar para o inventário gerado automaticamente pelo Vagrant) e mostrar a saída do comando `ansible-inventory --list` para validar o inventário usado pelo Ansible.

O que foi feito para resolver:

- Configurado o provider de ambas as VMs para utilizar o provedor remoto `ansible` em vez de `ansible_local`, de forma a gerir as VMs remotamente via uma instância do Ansible a correr do lado do host.
- Removidas as linhas de configuração dos ficheiros `ansible/app.yml` e `ansible/db.yml` que forçavam a ligação local (local connection), garantindo que o playbook pode ser executado contra um inventário remoto/automaticamente gerado.
- Executado o comando abaixo para inspecionar o inventário gerado pelo Vagrant e confirmar o conteúdo:

```
ansible-inventory -i ".vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory" --list
```

Resultados observados:

- Saída do comando `ansible-inventory --list`:

```
{
    "_meta": {
        "hostvars": {
            "app": {
                "ansible_host": "172.21.208.1",
                "ansible_port": 2200,
                "ansible_ssh_private_key_file": "/mnt/c/Users/rafae/OneDrive/Documentos/Mestrado/2ano/COGSI/CA4/.vagrant/machines/app/virtualbox/private_key",
                "ansible_user": "vagrant"
            },
            "db": {
                "ansible_host": "172.21.208.1",
                "ansible_port": 2222,
                "ansible_ssh_private_key_file": "/mnt/c/Users/rafae/OneDrive/Documentos/Mestrado/2ano/COGSI/CA4/.vagrant/machines/db/virtualbox/private_key",
                "ansible_user": "vagrant"
            }
        },
        "profile": "inventory_legacy"
    },
    "all": {
        "children": [
            "ungrouped"
        ]
    },
    "ungrouped": {
        "hosts": [
            "app",
            "db"
        ]
    }
}
```

- Conteúdo gerado pelo Vagrant (ficheiro `./.vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory`):

```
# Generated by Vagrant

app ansible_host=172.21.208.1 ansible_port=2200 ansible_user='vagrant' ansible_ssh_private_key_file='/mnt/c/Users/rafae/OneDrive/Documentos/Mestrado/2ano/COGSI/CA4/.vagrant/machines/app/virtualbox/private_key'
db ansible_host=172.21.208.1 ansible_port=2222 ansible_user='vagrant' ansible_ssh_private_key_file='/mnt/c/Users/rafae/OneDrive/Documentos/Mestrado/2ano/COGSI/CA4/.vagrant/machines/db/virtualbox/private_key'
```

Conclusão:

- O inventário auto-gerado pelo Vagrant está presente no caminho `./.vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory` e contém entradas para as VMs `app` e `db` com as variáveis de conexão necessárias (host/porta/user/key).
- Caso se prefira um arquivo estático `hosts.ini`, basta criar um ficheiro INI com entradas equivalentes e indicar o caminho para esse ficheiro ao executar o Ansible no Vagrantfile.

## Issue #52 — Create developers group and devuser, restrict access to application and database

Para implementar controlo de acesso aos recursos da aplicação e base de dados, foi criado um grupo "developers" e um utilizador "devuser" em ambas as VMs. A aplicação Spring Boot foi colocada no host1 e a base de dados H2 no host2 num diretório acessível apenas aos membros do grupo developers.

### O que foi implementado

- **Ambas as VMs** — `ansible/roles/spring_app/tasks/main.yml` e `ansible/roles/h2_db/tasks/main.yml`
  - Criado o grupo "developers":

        name: Ensure developers group exists
        group:
          name: developers
          state: present

  - Criado o utilizador "devuser" com password e adicionado ao grupo developers:

        name: Create devuser and add to developers group
        user:
          name: devuser
          groups: developers
          append: yes
          shell: /bin/bash
          password: 6684282bf0c558ae99560ccd9eea5c3ba9d36767132a11a8298bdc6fcb0d368d623fd1305f2c6ac2782a5356d425fc664661c3f9503e7b37c9c2401a05d8130c

- **Host1 (app)** — `ansible/roles/spring_app/tasks/main.yml` e `templates/ca4-app.service.j2`
  - Criado o diretório `/opt/developers` com permissões restritas (owner: root, group: developers, mode: 0750):

        name: Create /opt/developers directory with restricted access
        file:
          path: /opt/developers
          state: directory
          owner: root
          group: developers
          mode: '0750'

  - Copiado o JAR da aplicação Spring Boot para `/opt/developers/spring-app.jar` com permissões 0640:

        name: Copy Spring Boot JAR to restricted directory
        copy:
          src: "{{ app_jar }}"
          dest: /opt/developers/spring-app.jar
          owner: root
          group: developers
          mode: '0640'
          remote_src: yes

  - Atualizado o serviço systemd para executar como utilizador "devuser" e usar os novos caminhos:

        [Service]
        User=devuser
        WorkingDirectory=/opt/developers
        ExecStart=/usr/bin/java -jar /opt/developers/spring-app.jar

- **Host2 (db)** — `ansible/roles/h2_db/tasks/main.yml` e `templates/h2.service.j2`
  - Criado o diretório `/opt/developers` com permissões restritas.
  - Movida a base de dados H2 de `/data/h2` para `/opt/developers/h2-db` com permissões 0770 (para permitir escrita pelo serviço):

        name: Move H2 database to restricted directory
        command: mv /data/h2 /opt/developers/h2-db
        args:
          creates: /opt/developers/h2-db

        name: Set ownership and permissions for H2 database directory
        file:
          path: /opt/developers/h2-db
          owner: root
          group: developers
          mode: '0770'
          recurse: yes

  - Atualizado o serviço systemd para executar como utilizador "devuser" e usar o novo baseDir:

        [Service]
        User=devuser
        ExecStart=/usr/bin/java -cp /opt/h2/h2-{{ h2_version }}.jar org.h2.tools.Server -tcp -tcpAllowOthers -tcpPort 9092 -baseDir /opt/developers/h2-db

### Verificação dos testes realizados

Foram realizados testes para verificar a criação do grupo e utilizador, bem como as permissões de acesso aos diretórios restritos:

- **Verificação da criação do grupo e utilizador**:

  - **VM App (ca4-app)**:

        vagrant@ca4-app:~$ getent group developers
        developers:x:1001:devuser

  - **VM DB (ca4-db)**:

        vagrant@ca4-db:$ getent group developers
        developers:x:1001:devuser

- **Testes de acesso negado com utilizador `vagrant`**:

  - **VM App (ca4-app)**:

        vagrant@ca4-app:~$ ls -la /opt/developers
        ls: cannot open directory '/opt/developers': Permission denied

  - **VM DB (ca4-db)**:

        vagrant@ca4-db:$ ls -la /opt/developers/h2-db
        ls: cannot access '/opt/developers/h2-db': Permission denied
        vagrant@ca4-db:$ cat /opt/developers/h2-db/payrolldb
        cat: /opt/developers/h2-db/payrolldb: Permission denied

- **Testes de acesso permitido com utilizador `devuser` (membro do grupo `developers`)**:

  - **VM App (ca4-app)**:

        vagrant@ca4-app:~$ sudo -su devuser
        devuser@ca4-app:/home/vagrant$ ls -la /opt/developers
        total 50060
        drwxr-x--- 2 root developers     4096 Nov  8 23:17 .
        drwxr-xr-x 4 root root           4096 Nov  8 23:06 ..
        -rw-r----- 1 root developers 51250153 Nov  8 20:48 spring-app.jar
        devuser@ca4-app:/home/vagrant$ exit

  - **VM DB (ca4-db)**:

        vagrant@ca4-db:/$  sudo -su devuser
        devuser@ca4-db:/$ ls -la  /opt/developers/h2-db
        total 32
        drwxrwx--- 2 root developers  4096 Nov  8 22:51 .
        drwxr-x--- 3 root developers  4096 Nov  8 22:51 ..
        -rwxrwx--- 1 root developers 24576 Nov  8 23:17 payrolldb.mv.db
        devuser@ca4-db:/$ exit

Estes testes confirmam que o grupo `developers` e o utilizador `devuser` foram criados corretamente, e que apenas membros do grupo conseguem aceder aos diretórios e ficheiros restritos, garantindo a segurança implementada.

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

## Additional Tech

Para tecnologia adicional foi escolhido o ***Chef***, de seguida é apresentada uma breve tabela com as diferenças mais importante entre as duas tecnologias:

| **Aspeto** | **Ansible** | **Chef** |
|-------------|-------------|-----------|
| **Linguagem de configuração** | YAML (*playbooks*) | Ruby (*recipes*) |
| **Arquitetura** | *Agentless* (usa SSH para conectar aos nós) | Requer agente (*Chef Client*) instalado nas máquinas geridas |
| **Modo de execução** | *Push-based* (o controlo é feito pelo *Ansible Controller*) | *Pull-based* (os nós puxam configurações do servidor *Chef*) |
| **Facilidade de uso** | Mais simples, sintaxe declarativa e intuitiva | Mais complexo, requer conhecimentos de Ruby |
| **Gestão de dependências** | Baseia-se em módulos e coleções | Usa *cookbooks* e *Berksfile* para dependências |
| **Idempotência** | Alta — executa apenas o necessário | Alta — também garante estado desejado |

Posto isto, para o *setup* inicial do projeto foi criada a seguinte árvore de diretórios:

    CA4
    ├── Ansible_Solution/
    ├── Chef_Solution/
    │   ├── cookbooks/
    │   │   └── ca_stack/
    │   │       ├── attributes/
    │   │       │   └── default.rb
    │   │       ├── recipes/
    │   │       │   ├── app.rb
    │   │       │   ├── h2.rb
    │   │       │   └── pam_policy.rb
    │   │       ├── templates/
    │   │       │   ├── ca4-app.service.erb
    │   │       │   └── h2.service.erb
    │   │       ├── Berksfile
    │   │       └── metadata.rb
    │   └── Vagrantfile


2. ***attributes/default.rb***  
   - Define variáveis globais (IPs, diretórios, versão do H2, portas e flags de execução).  

3. ***recipes/pam_policy.rb***  
   - Aplica regras de segurança PAM (passwords fortes, bloqueios de autenticação).  
   - Cria o grupo *developers* e o utilizador cogsi.  

4. ***recipes/h2.rb***  
   - Ficheiro responsável pela configuração da base de dados.

5. ***recipes/app.rb***  
   - Ficheiro responsável pela configuração do módulo da *app*.

4. **templates/h2.service.erb**  
   - Define como o serviço da base de dados é iniciado.

5. **templates/ca4-app.service.erb**  
   - Define o serviço do ***Spring Boot App***

6. **metadata.rb**  
   - Define variáveis associadas ao *cookbook*.

7. **Berksfile**  
   - Lista *cookbooks* externos ou dependências a instalar.

### Idempotência

Observando o ficheiro ***pam_policy.rb***:

    pwquality_path = node['ca']['pwquality'] || '/etc/security/pwquality.conf'
    common_pass    = node['ca']['pam_common_password'] || '/etc/pam.d/common-password'
    common_auth    = node['ca']['pam_common_auth'] || '/etc/pam.d/common-auth'
    dev_dir        = node['ca']['dev_dir'] || '/opt/dev'
    group_name     = node['ca']['group'] || 'developers'
    user_name      = node['ca']['user'] || 'cogsi'

    # --- Ensure PAM pwquality package is installed ---
    package 'libpam-pwquality'

    # --- Ensure pam_pwhistory rule exists ---
    ruby_block 'ensure pam_pwhistory rule' do
      block do
        next unless File.exist?(common_pass)
        text = File.read(common_pass)
        line = 'password requisite pam_pwhistory.so remember=5 use_authtok enforce_for_root'
        unless text.include?(line)
          text.sub!(/^password\s+\[success=1.*pam_unix\.so.*$/) { |m| "#{m}\n#{line}" }
          File.write(common_pass, text)
        end
      end
    end

    # --- Ensure pam_pwquality rule exists ---
    ruby_block 'ensure pam_pwquality rule' do
      block do
        next unless File.exist?(common_pass)
        txt  = File.read(common_pass)
        rule = 'password requisite pam_pwquality.so minlen=12 minclass=3 dictcheck=1 usercheck=1 retry=3 enforce_for_root'
        if txt =~ /^password\s+requisite\s+pam_pwquality\.so/
          txt.gsub!(/^password\s+requisite\s+pam_pwquality\.so.*$/, rule)
        else
          txt << "\n#{rule}\n"
        end
        File.write(common_pass, txt)
      end
    end

    # --- Update pwquality.conf ---
    file pwquality_path do
      content "usercheck = 1\n"
      mode '0644'
      owner 'root'
      group 'root'
    end

    # --- Insert faillock configuration ---
    ruby_block 'insert faillock block in common-auth' do
      block do
        next unless File.exist?(common_auth)
        content = File.read(common_auth)
        blocktxt = <<~EOT
          # BEGIN CHEF MANAGED BLOCK - faillock
          auth required pam_faillock.so preauth silent deny=5 unlock_time=600
          auth [default=die] pam_faillock.so authfail deny=5 unlock_time=600
          account required pam_faillock.so
          # END CHEF MANAGED BLOCK - faillock
        EOT
        unless content.include?('CHEF MANAGED BLOCK - faillock')
          content.sub!(/^auth\s+\[success=1/m, blocktxt + "\n\\0")
          File.write(common_auth, content)
        end
      end
    end

    # --- Create development group and user ---
    group group_name do
      action :create
    end

    user user_name do
      manage_home true
      shell '/bin/bash'
      password '$6$exampleSalt$D7zE2LD2uQ/nS.NekDYh9o0kZ02puDYRdtT2x4nUoeX7tuH1Gf1cAc4t1G2GvDtx2Th/qg.9s.ZCCnF9b44vG/'
      action :create
    end

    # --- Add user to group ---
    group group_name do
      members [user_name]
      append true
      action :modify
    end

    # --- Create dev directory ---
    directory dev_dir do
      owner 'root'
      group group_name
      mode '0750'
      recursive true
      action :create
    end

Podemos observar que foram implementadas medidas de idempotência, podendo mencionar as seguintes:

1. **Funções *built-in Chef***
   - Usa funções *built'int* como *package*, *file+, *group*, *user* e *directory*, que apenas executam ações caso estas ainda não tenham sido executadas.

2. **Funções condicionais**
   - Verificações como *next unless File.exist?* e comparações de conteúdo como *unless text.include?* evitam alterações redundantes.

3. **Edição controlada de ficheiros**
   - Linhas são adicionadas com *sub!* ou *gsub!* prevenindo duplicação de regras PAM.

Posto isto, podemos ver que um certo grau de idempotência é alcançado correndo o programa 2 vezes seguidas:

1. 1.ª Execução

        ==> db: Running handlers:
        ==> db: [2025-11-09T22:51:01+00:00] INFO: Running report handlers
        ==> db: Running handlers complete
        ==> db: [2025-11-09T22:51:01+00:00] INFO: Report handlers complete
        ==> db: Infra Phase complete, 26/31 resources updated in 56 seconds


        ==> app: Running handlers:
        ==> app: [2025-11-09T22:58:32+00:00] INFO: Running report handlers
        ==> app: Running handlers complete
        ==> app: [2025-11-09T22:58:32+00:00] INFO: Report handlers complete
        ==> app: Infra Phase complete, 23/28 resources updated in 03 minutes 25 seconds

2. 2.ª Execução

        ==> db: Running handlers:
        ==> db: [2025-11-09T23:28:17+00:00] INFO: Running report handlers
        ==> db: Running handlers complete
        ==> db: [2025-11-09T23:28:17+00:00] INFO: Report handlers complete
        ==> db: Infra Phase complete, 11/30 resources updated in 12 seconds


        ==> app: Running handlers:
        ==> app: [2025-11-09T23:29:00+00:00] INFO: Running report handlers
        ==> app: Running handlers complete
        ==> app: [2025-11-09T23:29:00+00:00] INFO: Report handlers complete
        ==> app: Infra Phase complete, 11/27 resources updated in 24 seconds

Como é possível observar, apesar de o número não ser táo reduzido quanto aquele obtido em ***Ansible***, podemo verificar que o número de tarefas executadas entre execuções reduziu bastante.

### *Password Policy*

Para a implementação de uma política de segurança de *passwords* foram implementados os seguintes métodos no ficheiro ***pam?policy.rb***:

    # --- Ensure PAM pwquality package is installed ---
    package 'libpam-pwquality'

    # --- Ensure pam_pwhistory rule exists ---
    ruby_block 'ensure pam_pwhistory rule' do
      block do
        next unless File.exist?(common_pass)
        text = File.read(common_pass)
        line = 'password requisite pam_pwhistory.so remember=5 use_authtok enforce_for_root'
        unless text.include?(line)
          text.sub!(/^password\s+\[success=1.*pam_unix\.so.*$/) { |m| "#{m}\n#{line}" }
          File.write(common_pass, text)
        end
      end
    end

    # --- Ensure pam_pwquality rule exists ---
    ruby_block 'ensure pam_pwquality rule' do
      block do
        next unless File.exist?(common_pass)
        txt  = File.read(common_pass)
        rule = 'password requisite pam_pwquality.so minlen=12 minclass=3 dictcheck=1 usercheck=1 retry=3 enforce_for_root'
        if txt =~ /^password\s+requisite\s+pam_pwquality\.so/
          txt.gsub!(/^password\s+requisite\s+pam_pwquality\.so.*$/, rule)
        else
          txt << "\n#{rule}\n"
        end
        File.write(common_pass, txt)
      end
    end

    # --- Update pwquality.conf ---
    file pwquality_path do
      content "usercheck = 1\n"
      mode '0644'
      owner 'root'
      group 'root'
    end

    # --- Insert faillock configuration ---
    ruby_block 'insert faillock block in common-auth' do
      block do
        next unless File.exist?(common_auth)
        content = File.read(common_auth)
        blocktxt = <<~EOT
          # BEGIN CHEF MANAGED BLOCK - faillock
          auth required pam_faillock.so preauth silent deny=5 unlock_time=600
          auth [default=die] pam_faillock.so authfail deny=5 unlock_time=600
          account required pam_faillock.so
          # END CHEF MANAGED BLOCK - faillock
        EOT
        unless content.include?('CHEF MANAGED BLOCK - faillock')
          content.sub!(/^auth\s+\[success=1/m, blocktxt + "\n\\0")
          File.write(common_auth, content)
        end
      end
    end

Podemos afirmar o seguinte sobre os mesmos:

1. ***package 'libpam-pwquality'***
   - Garante a instalação do módulo *pam_pwquality*.

2. ***ruby_block 'ensure pam_pwhistory rule'***
   - Obriga o sistema a guardar as últimas 5 *passwords* usadas por cada utilizador.
   - Impede reutilização imediata de palavras-passe antigas.

3. ***ruby_block 'ensure pam_pwquality rule'***
   - Exige que a password tenha:
     - Mínimo de 12 caracteres.  
     - Pelo menos 3 classes (maiúsculas, minúsculas, dígitos, símbolos). 
     - Verificação contra dicionários e nome do utilizador.  
     - Aplicação obrigatória mesmo para *root*.

5. ***ruby_block 'insert faillock block in common-auth'***
   - Implementa política de bloqueio de utilizadores no caso de 5 tentativas de autenticação falhadas.

Para a validação desta implementação foi utilizada a mesma estratégia encontrada no ***Ansible***, que consiste na criação de um utilizador, um grupo e um ficheiro dentro de um diretório apenas acessível a esse grupo.

    vagrant@ca4-db:/opt$ cd dev/
    -bash: cd: dev/: Permission denied
    vagrant@ca4-db:/opt$ sudo -iu cogsi
    cogsi@ca4-db:/$ cd opt/dev/
    cogsi@ca4-db:/opt/dev$ ls
    h2-db
    cogsi@ca4-db:/opt/dev$ 

Como é possível ver, no que toca ao acesso foi bem sucedido.

### Create developers group and devuser, restrict access to application and database

Para replicar a implementação do Issue #52 utilizando Chef em vez de Ansible, foi criado um cookbook `ca_stack` que implementa as mesmas funcionalidades de controlo de acesso aos recursos da aplicação e base de dados. O grupo "developers" e o utilizador "devuser" foram criados em ambas as VMs, com a aplicação Spring Boot no host1 e a base de dados H2 no host2 colocadas num diretório acessível apenas aos membros do grupo developers.

### O que foi implementado

- **Ambas as VMs** — `Chef_Solution/cookbooks/ca_stack/recipes/app.rb` e `Chef_Solution/cookbooks/ca_stack/recipes/h2.rb`
  - Criado o grupo "developers":

        # Ensure developers group exists
        group 'developers' do
          action :create
        end

  - Criado o utilizador "devuser" com password e adicionado ao grupo developers:

        # Create devuser and add to developers group
        user 'devuser' do
          group 'developers'
          shell '/bin/bash'
          password '6684282bf0c558ae99560ccd9eea5c3ba9d36767132a11a8298bdc6fcb0d368d623fd1305f2c6ac2782a5356d425fc664661c3f9503e7b37c9c2401a05d8130c'
          action :create
        end

- **Host1 (app)** — `Chef_Solution/cookbooks/ca_stack/recipes/app.rb` e `Chef_Solution/cookbooks/ca_stack/templates/ca4-app.service.erb`
  - Criado o diretório `/opt/developers` com permissões restritas (owner: root, group: developers, mode: 0750):

        # Create /opt/developers directory with restricted access
        directory node['ca']['dev_dir'] do
          owner 'root'
          group 'developers'
          mode '0750'
          recursive true
          action :create
        end

  - Copiado o JAR da aplicação Spring Boot para `/opt/developers/spring-app.jar` com permissões 0640:

        # Copy JAR to /opt/developers
        bash 'copy_jar' do
          code <<~BASH
            JAR=$(ls -t #{node['ca']['app_project_dir']}/app/build/libs/*.jar | grep -v plain | head -n1)
            cp "$JAR" #{node['ca']['dev_dir']}/spring-app.jar
            chown root:developers #{node['ca']['dev_dir']}/spring-app.jar
            chmod 0640 #{node['ca']['dev_dir']}/spring-app.jar
          BASH
        end

  - Atualizado o serviço systemd para executar como utilizador "devuser" e usar os novos caminhos:

        [Service]
        User=devuser
        Group=developers
        ExecStart=/usr/bin/java -jar /opt/developers/spring-app.jar --server.port=<%= @app_port %>
        Restart=always
        RestartSec=5
        Environment=JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64

- **Host2 (db)** — `Chef_Solution/cookbooks/ca_stack/recipes/h2.rb` e `Chef_Solution/cookbooks/ca_stack/templates/h2.service.erb`
  - Criado o diretório `/opt/developers` com permissões restritas.
  - Movida a base de dados H2 de `/data/h2` para `/opt/developers/h2-db` com permissões 0770 (para permitir escrita pelo serviço):

        # --- Initialize database (only once) ---
        bash 'init_h2_db' do
          code <<~BASH
            echo "CREATE TABLE IF NOT EXISTS payroll_init (id INT PRIMARY KEY, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP());" > /tmp/init.sql
            /usr/bin/java -cp "/opt/h2/h2-#{node['ca']['h2_version']}.jar" org.h2.tools.RunScript \
              -url "jdbc:h2:/data/h2/payrolldb" -user sa -password password -script /tmp/init.sql
            rm -f /tmp/init.sql
            mv /data/h2 #{node['ca']['dev_dir']}/h2-db
            chown root:developers #{node['ca']['dev_dir']}/h2-db
            chmod 0770 #{node['ca']['dev_dir']}/h2-db
          BASH
          creates "#{node['ca']['dev_dir']}/h2-db"
        end

  - Atualizado o serviço systemd para executar como utilizador "devuser" e usar o novo baseDir:

        [Service]
        User=devuser
        Group=developers
        ExecStart=/usr/bin/java -cp /opt/h2/h2-<%= @h2_version %>.jar org.h2.tools.Server -tcp -tcpAllowOthers -tcpPort 9092 -baseDir /opt/developers/h2-db
        Restart=always
        RestartSec=5

### Verificação dos testes realizados

Foram realizados testes para verificar a criação do grupo e utilizador, bem como as permissões de acesso aos diretórios restritos:

- **Verificação da criação do grupo e utilizador**:

  - **VM App (ca4-app)**:

        vagrant@ca4-app:~$ getent group developers
        developers:x:1001:devuser

  - **VM DB (ca4-db)**:

        vagrant@ca4-db:$ getent group developers
        developers:x:1001:devuser

- **Testes de acesso negado com utilizador `vagrant`**:

  - **VM App (ca4-app)**:

        vagrant@ca4-app:~$ ls -la /opt/developers
        ls: cannot open directory '/opt/developers': Permission denied

  - **VM DB (ca4-db)**:

        vagrant@ca4-db:$ ls -la /opt/developers/h2-db
        ls: cannot access '/opt/developers/h2-db': Permission denied
        vagrant@ca4-db:$ cat /opt/developers/h2-db/payrolldb
        cat: /opt/developers/h2-db/payrolldb: Permission denied

- **Testes de acesso permitido com utilizador `devuser` (membro do grupo `developers`)**:

  - **VM App (ca4-app)**:

        vagrant@ca4-app:~$ sudo -su devuser
        devuser@ca4-app:/home/vagrant$ ls -la /opt/developers
        total 50060
        drwxr-x--- 2 root developers     4096 Nov  8 23:17 .
        drwxr-xr-x 4 root root           4096 Nov  8 23:06 ..
        -rw-r----- 1 root developers 51250153 Nov  8 20:48 spring-app.jar
        devuser@ca4-app:/home/vagrant$ exit

  - **VM DB (ca4-db)**:

        vagrant@ca4-db:/$  sudo -su devuser
        devuser@ca4-db:/$ ls -la  /opt/developers/h2-db
        total 32
        drwxrwx--- 2 root developers  4096 Nov  8 22:51 .
        drwxr-x--- 3 root developers  4096 Nov  8 22:51 ..
        -rwxrwx--- 1 root developers 24576 Nov  8 23:17 payrolldb.mv.db
        devuser@ca4-db:/$ exit

Estes testes confirmam que o grupo `developers` e o utilizador `devuser` foram criados corretamente, e que apenas membros do grupo conseguem aceder aos diretórios e ficheiros restritos, garantindo a segurança implementada.