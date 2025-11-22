# CA5 - Containers

## Issue #55 - Create Docker image for the Chat application

### Dockerfile.chat.v1

Esta Dockerfile constrói a imagem do servidor de Chat diretamente a partir dos fontes do projeto Gradle:

- **Imagem base:** eclipse-temurin:17-jdk
- **Copia o projeto:** `CA2/Part1/gradle_basic_demo-main/` para dentro da imagem
- **Compila o JAR:** Executa o Gradle dentro do container para compilar a aplicação
- **Expõe a porta:** 59001 (porta padrão do servidor de chat)
- **Entrypoint:** Executa `basic_demo.ChatServerApp` com o porto como argumento

**Como usar:**

```sh
docker build -f Dockerfile.chat.v1 -t chat-server .
docker run -p 59001:59001 chat-server
```

Pode ligar-se ao servidor de chat a partir da máquina host na porta 59001.

### Dockerfile.chat.v2

Esta versão requer que o JAR seja construído previamente na máquina host e só depois copiado para o container.

**Como usar:**

```sh
# Construir o JAR na máquina host
cd CA2/Part1/gradle_basic_demo-main
./gradlew clean jar

# Construir e correr a imagem Docker
docker build -f CA5/Dockerfile.chat.v2 -t chat-server .
docker run -p 59001:59001 chat-server
```

## Issue #56 - Create Docker image for “Building REST Services with Spring”

### Dockerfile.spring.v1

Esta Dockerfile permite construir e correr a aplicação REST (Spring) dentro de um container:

- **Imagem base:** eclipse-temurin:17-jdk
- **Copia o projeto:** `CA2/Part2/` para dentro da imagem
- **Compila o JAR:** Executa o Gradle dentro do container para gerar o ficheiro `bootJar` da aplicação
- **Expõe a porta:** 8080 (porta padrão do servidor Spring)
- **Entrypoint:** Executa o JAR gerado, permitindo definir a porta via variável de ambiente

**Como usar:**

```sh
docker build -f CA5/Dockerfile.spring.v1 -t spring-server .
docker run -p 8080:8080 spring-server
```

Pode aceder à API REST do servidor Spring a partir da máquina host na porta 8080.

### Dockerfile.spring.v2

Esta versão requer que o JAR seja construído previamente na máquina host e só depois copiado para o container.

**Como usar:**

```sh
# Construir o JAR na máquina host
cd CA2/Part2
./gradlew :app:clean :app:bootJar

# Construir e correr a imagem Docker
docker build -f CA5/Dockerfile.spring.v2 -t spring-server .
docker run -p 8080:8080 spring-server
```

## Issue #57 - Build the server inside the container

Nas versões `Dockerfile.chat.v1` e `Dockerfile.spring.v1`, o código fonte do projeto é copiado para o container e a aplicação é construída lá dentro usando Gradle. Alternativamente, pode-se criar uma imagem que clona o repositório diretamente (usando o comando `git clone`) e faz o build dentro do container.

**Vantagens:**

- Permite sempre obter a versão mais recente do código.
- Automatiza o processo de build sem depender de artefactos pré-compilados.

**Desvantagens:**

- A imagem final tende a ser maior, pois inclui dependências de build (JDK, Gradle, etc.).
- O tempo de build pode ser maior.

### Inspeção das camadas da imagem

Para analisar o tamanho e a composição das camadas da imagem, pode-se usar:

```sh
docker history <nome-da-imagem>
```

#### Exemplo

```sh
docker history chat-server
docker history spring-server
```

Isto mostra cada camada, o comando que a gerou, e o tamanho ocupado.

**Diferenças observadas:**

- Imagens que constroem a aplicação dentro do container (com JDK e Gradle) são maiores do que as que apenas copiam o JAR já construído.
- As camadas de build (RUN gradlew, instalação de dependências) ocupam mais espaço.
- Imagens baseadas em JRE (apenas para execução) são mais leves.

## Issue #58 - Build the server on the host and copy the JAR

Nas versões `Dockerfile.chat.v2` e `Dockerfile.spring.v2`, o JAR da aplicação é construído na máquina host e apenas o artefacto final é copiado para o container. A imagem usa uma base JRE, mais leve, e não inclui dependências de build.

**Vantagens:**

- Imagem final mais pequena e rápida de construir.
- Menos camadas e menos dependências no container.

**Desvantagens:**

- Requer que o build seja feito manualmente no host antes do docker build.
- Não automatiza o build do código fonte.

### Comparação de tamanhos e camadas

Para comparar as imagens, pode-se usar:

```sh
docker history chat-server
docker history spring-server
```

**Diferenças observadas:**

- Imagens que apenas copiam o JAR (base JRE) são significativamente menores.
- As camadas de build não existem, tornando a imagem mais simples e leve.
- Ideal para produção, onde só é necessário o artefacto final.

## Issue #59 - Implement multi-stage build

O objetivo deste issue foi otimizar o processo de criação das imagens Docker utilizando **multi-stage builds**. Esta técnica permite usar uma imagem mais completa (com JDK e ferramentas de build) para compilar a aplicação e uma imagem mais leve (apenas JRE) para a execução final, descartando tudo o que não é necessário para correr a app (código fonte, gradle caches, compiladores, etc.).

### Chat App (`Dockerfile.multistage`)

O Dockerfile para a aplicação de Chat foi dividido em dois estágios:

1. **Builder Stage (`builder`):**
    - Usa a imagem `eclipse-temurin:17-jdk`.
    - Copia o código fonte (`CA2/Part1/gradle_basic_demo-main/`).
    - Compila o projeto usando o Gradle Wrapper (`./gradlew clean jar`).
2. **Runtime Stage:**
    - Usa a imagem `eclipse-temurin:17-jre` (mais leve).
    - Copia apenas o JAR compilado (`chat.jar`) do estágio anterior.
    - Define o comando de execução.

### Spring App (`Dockerfile.multistage`)

De forma semelhante, a aplicação Spring Boot também utiliza dois estágios:

1. **Builder Stage (`builder`):**
    - Usa a imagem `eclipse-temurin:17-jdk`.
    - Copia o código fonte (`CA2/Part2/`).
    - Compila o projeto gerando um "fat jar" (`./gradlew clean bootJar`).
2. **Runtime Stage:**
    - Usa a imagem `eclipse-temurin:17-jre`.
    - Define as variáveis de ambiente necessárias (Base de dados H2, portas, etc.).
    - Copia o JAR (`app.jar`) do estágio de build.
    - Executa a aplicação.

### Como usar

**Construir as imagens:**

```sh
docker build -f CA5/chat_app/Dockerfile.multistage -t chat-server:multistage .
docker build -f CA5/spring_app/Dockerfile.multistage -t spring-server:multistage .
```

**Correr os contentores:**

```sh
docker run -p 59001:5900 chat-server:multistage
docker run -p 8080:8080 spring-server:multistage
```

### Comparação de Eficiência

A utilização de multi-stage builds resulta numa redução significativa do tamanho da imagem final, pois removemos o código fonte, o Gradle e o JDK completo da imagem de produção.

Para verificar os tamanhos e comparar com as versões anteriores, utilizamos o comando:

```sh
docker images
```

**Tabela de Comparação (Preencher com os valores obtidos):**

| Aplicação | Versão | Tag | Tamanho (MB) | Observações |
| :--- | :--- | :--- | :--- | :--- |
| Chat | Build no Docker (v1) | `chat-server:v1` | 579MB | Inclui JDK e código fonte |
| Chat | Build no Docker (v2) | `chat-server:v2` | 265MB | Apenas JRE e JAR compilado |
| Chat | Multi-stage (v3) | `chat-server:multistage` | 265MB | Apenas JRE e JAR compilado |
| Spring | Build no Docker (v1) | `spring-server:v1` | 792MB | Inclui JDK e código fonte |
| Spring | Build no Docker (v2) | `spring-server:v2` | 314MB | Apenas JRE e JAR compilado |
| Spring | Multi-stage (v3) | `spring-server:multistage` | 314MB | Apenas JRE e JAR compilado |

#### Conclusão

As imagens `multistage` resultam em imagens significativamente menores que as versões `v1`, tendo exatamente o mesmo tamanho das versões `v2`. Isto acontece porque as imagens `multistage`, tal como as versões `v2`, não incluem o código fonte, o Gradle e o JDK completo da imagem de produção, como as versões `v1`.
Para além disso, as imagens `multistage` são mais eficientes em termos de construção, já que o build é feito dentro do container, eliminando a necessidade de construir o artefacto manualmente no host.

## Issue #60 - Monitor resource usage

O objetivo deste issue foi monitorizar em tempo real a utilização de CPU, memória, rede e I/O de disco dos containers em execução e registar as observações obtidas.

### Como usar

```sh
# Iniciar os containers (assumindo que as imagens foram construídas previamente)
docker run --rm -p 5900:5900 --name chat-app chat-server:multistage
docker run --rm -p 8080:8080 --name spring-app spring-server:multistage

# Monitorizar o uso de recursos dos containers
docker stats
```

### Observações

Parte do output observado com `docker stats` (capturado enquanto ambos os containers estavam em execução):

```
CONTAINER ID   NAME         CPU %     MEM USAGE / LIMIT    MEM %     NET I/O          BLOCK I/O        PIDS
5bca1ad6e42d   chat-app     0.19%     49.44MiB / 7.44GiB   0.65%     1.15kB / 318B    4.98MB / 193kB   20
8069f1c63b23   spring-app   0.18%     367.5MiB / 7.44GiB   4.82%     9.31kB / 4.6kB   89.2MB / 352kB   51
```

### Análise de Recursos

A monitorização em tempo real revelou as seguintes características de utilização de recursos para cada aplicação:

-   **CPU**: A utilização de CPU variou pouco durante a observação.
    -   `chat-app`: ~0.15%–0.20% (picos ocasionais próximos de 0.25%).
    -   `spring-app`: ~0.20%–0.25%, com picos entre 2% e 3% quando a aplicação recebeu pedidos.
-   **Memória**: A `spring-app` apresentou uma utilização de memória significativamente superior à `chat-app` (ex.: 367.5MiB vs 49.44MiB no exemplo mostrado).
-   **Rede / I/O**: Os valores de rede e block I/O mantiveram-se baixos e estáveis. O `spring-app` registou maiores valores absolutos de block I/O no período observado.

### Conclusão

As medições foram efetuadas em tempo real via `docker stats` no terminal e não foram persistidas em ficheiro. A `spring-app` demonstrou ser mais intensiva em termos de memória e teve picos de CPU mais elevados sob carga, quando comparada com a `chat-app`, que manteve um consumo de recursos mais estável e baixo.

## Issue #61 - Tag and publish images

O objetivo deste issue foi taggar e publicar as imagens Docker criadas no repositório DockerHub.

### Chat App

```sh
docker tag chat-server-v1:v1 rafaelgomes03/chat-server-v1:v1
docker tag chat-server-v2:v2 rafaelgomes03/chat-server-v2:v2
docker tag chat-server-multistage:multistage rafaelgomes03/chat-server-multistage:multistage
docker push rafaelgomes03/chat-server-v1:v1
docker push rafaelgomes03/chat-server-v2:v2
docker push rafaelgomes03/chat-server-multistage:multistage
```

### Spring App

```sh
docker tag spring-server-v1:v1 rafaelgomes03/spring-server-v1:v1
docker tag spring-server-v2:v2 rafaelgomes03/spring-server-v2:v2
docker tag spring-server-multistage:multistage rafaelgomes03/spring-server-multistage:multistage
docker push rafaelgomes03/spring-server-v1:v1
docker push rafaelgomes03/spring-server-v2:v2
docker push rafaelgomes03/spring-server-multistage:multistage
```

### Explicação dos comandos

-   `docker tag`: Adiciona uma tag (nome) à imagem Docker. É necessário incluir o nome do repositório DockerHub no início do nome da tag para que a imagem seja publicada no repositório.
-   `docker push`: Envia a imagem Docker para o repositório DockerHub.

### Excerto do comando `docker images`

```sh
REPOSITORY                               TAG          IMAGE ID       CREATED             SIZE
chat-server-multistage                   multistage   4141d90c78fd   13 minutes ago      265MB
rafaelgomes03/chat-server-multistage     multistage   4141d90c78fd   13 minutes ago      265MB
chat-server-v1                           v1           7782bf4710ec   16 minutes ago      588MB
rafaelgomes03/chat-server-v1             v1           7782bf4710ec   16 minutes ago      588MB
chat-server-v2                           v2           5672a258323d   About an hour ago   265MB
rafaelgomes03/chat-server-v2             v2           5672a258323d   About an hour ago   265MB
spring-server-v2                         v2           2449f35bdab5   About an hour ago   314MB
rafaelgomes03/spring-server-v2           v2           2449f35bdab5   About an hour ago   314MB
spring-server-v1                         v1           04a691aa3d17   3 hours ago         792MB
rafaelgomes03/spring-server-v1           v1           04a691aa3d17   3 hours ago         792MB
rafaelgomes03/spring-server-multistage   multistage   9eb6e83e42b2   3 hours ago         314MB
spring-server-multistage                 multistage   9eb6e83e42b2   3 hours ago         314MB
```

### Exemplo do comando docker push

```sh
The push refers to repository [docker.io/rafaelgomes03/chat-server-v1]
89bba4cfd1e3: Pushed
5f70bf18a086: Mounted from oscarfonts/h2
5bb192cb7a8b: Pushed
cfe5fa2c84a9: Pushed
db1688142012: Mounted from library/eclipse-temurin
d03939930dac: Mounted from library/eclipse-temurin
35c0b8fb11b1: Mounted from library/eclipse-temurin
d7ef4463791e: Mounted from library/eclipse-temurin
e8bce0aabd68: Mounted from library/eclipse-temurin
v1: digest: sha256:ac0c6298f15faf1dec223899ba42b389ae0909414d458eafd6af26f0c80e0dca size: 2204
```

### Conteúdo do repositório DockerHub

```sh
docker search rafaelgomes03
                                      
NAME                                     DESCRIPTION   STARS     OFFICIAL
rafaelgomes03/spring-server                            0
rafaelgomes03/welcome-to-docker                        0
rafaelgomes03/chat-server                              0
rafaelgomes03/chat-server-v2                           0
rafaelgomes03/spring-server-multistage                 0
rafaelgomes03/spring-server-v1                         0
rafaelgomes03/chat-server-multistage                   0
rafaelgomes03/chat-server-v1                           0
rafaelgomes03/spring-server-v2                         0

```
## Issue #63 - Configure inter-container networking

Para ser possível implementar a comunicação entre *containers*, foram realizadas as seguintes alterações:

- Foi colocada a secção *networks* na definição de ambos os *containers*, no modo ***bridge***, assegurando algum isolamento do resto da rede.
- Foi definido, no final o nome da rede pretendida.
- Foi, também, definida uma condição para o *container* da *app* para apenas arrancar caso o *container* com a base de dados tenha sido levantado com sucesso, bem como, definidas condições para considerar que o mesmo arrancou com sucesso.

Posto, isto o ficheiro ficou com o seguinte aspeto:

services:
  db:
    image: thomseno/h2:2.2.224
    ports:
      - "9092:9092"
      - "8082:8082"
    healthcheck:
      test: ["CMD-SHELL", "curl http://localhost:8082 || exit 1"]
      interval: 5s
      timeout: 5s
      retries: 10
    networks:
      - spring-app

  web:
    build:
      context: ../..
      dockerfile: CA5/Part2/Dockerfile
    ports:
      - "8080:8080"
    depends_on:
      db:
        condition: service_healthy
    environment:
      - SPRING_DATASOURCE_URL=jdbc:h2:tcp://db:9092/./payrolldb
      - SPRING_DATASOURCE_USERNAME=sa
      - SPRING_DATASOURCE_PASSWORD=password
      - SPRING_JPA_HIBERNATE_DDL_AUTO=update
    networks:
      - spring-app

networks:
  spring-net:

De forma a validarmos se o que foi implementado executa do modo esperado foram tomadas as seguintes medidas:

1. Tradução DNS dos containers

Foram levantados os containers através do comando ***docker compose up*** e de seguida foi executado o seguinte comando, ***docker run --rm -it --network part2_spring-app busybox sh***. Este último, cria um *container* temporário, na mesma rede que os outros criados, e inicia uma sessão SSH para o mesmo. De seguida, foram feitos testes de conectividade com os outros *containers* através do *hostname*.

    / # ping db
    PING db (172.18.0.2): 56 data bytes
    64 bytes from 172.18.0.2: seq=0 ttl=64 time=0.281 ms
    64 bytes from 172.18.0.2: seq=1 ttl=64 time=0.103 ms
    64 bytes from 172.18.0.2: seq=2 ttl=64 time=0.085 ms
    64 bytes from 172.18.0.2: seq=3 ttl=64 time=0.089 ms
    64 bytes from 172.18.0.2: seq=4 ttl=64 time=0.126 ms
    ^C
    --- db ping statistics ---
    5 packets transmitted, 5 packets received, 0% packet loss
    round-trip min/avg/max = 0.085/0.136/0.281 ms
    / # ping web
    PING web (172.18.0.3): 56 data bytes
    64 bytes from 172.18.0.3: seq=0 ttl=64 time=0.455 ms
    64 bytes from 172.18.0.3: seq=1 ttl=64 time=0.083 ms
    64 bytes from 172.18.0.3: seq=2 ttl=64 time=0.079 ms
    64 bytes from 172.18.0.3: seq=3 ttl=64 time=0.076 ms
    64 bytes from 172.18.0.3: seq=4 ttl=64 time=0.083 ms
    64 bytes from 172.18.0.3: seq=5 ttl=64 time=0.083 ms
    ^C
    --- web ping statistics ---
    6 packets transmitted, 6 packets received, 0% packet loss

Como podemos observar, os *pings* foram bem sucedidos.

2. Verificação da execução da base de dados em primeiro lugar

Para testar se a condição implementada está a executar de maneira corretas foram executados dois testes:

- Executado apenas o container da *app*:

        PS C:\Users\nunoc\Desktop\cogsi2526-1240444-1211426-1211689\CA5\Part2> docker compose up web
        [+] Running 3/3
         ✔ Network part2_spring-app  Created                                                                                                                                                                                                                                                                                                                             0.0s 
         ✔ Container part2-db-1      Created                                                                                                                                                                                                                                                                                                                             0.2s 
         ✔ Container part2-web-1     Created                                                                                                                                                                                                                                                                                                                             0.2s 
        Attaching to web-1
        web-1  |
        web-1  |   .   ____          _            __ _ _
        web-1  |  /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \                                                                                                                                                                                                                                                                                                                     
        web-1  | ( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \                                                                                                                                                                                                                                                                                                                    
        web-1  |  \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
        web-1  |   '  |____| .__|_| |_|_| |_\__, | / / / /                                                                                                                                                                                                                                                                                                                    
        web-1  |  =========|_|==============|___/=/_/_/_/                                                                                                                                                                                                                                                                                                                     
        web-1  |  :: Spring Boot ::                (v3.2.5)
        web-1  |                                                                                                                                                                                                                                                                                                                                                              
        web-1  | 2025-11-22T16:18:46.788Z  INFO 1 --- [           main] payroll.PayrollApplication               : Starting PayrollApplication using Java 17.0.17 with PID 1 (/app/app.jar started by root in /app)                                                                                                                                                           
        web-1  | 2025-11-22T16:18:46.792Z  INFO 1 --- [           main] payroll.PayrollApplication               : No active profile set, falling back to 1 default profile: "default"
        web-1  | 2025-11-22T16:18:47.809Z  INFO 1 --- [           main] .s.d.r.c.RepositoryConfigurationDelegate : Bootstrapping Spring Data JPA repositories in DEFAULT mode.                                                                                                                                                                                                
        web-1  | 2025-11-22T16:18:47.892Z  INFO 1 --- [           main] .s.d.r.c.RepositoryConfigurationDelegate : Finished Spring Data repository scanning in 70 ms. Found 2 JPA repository interfaces.
        web-1  | 2025-11-22T16:18:48.522Z  INFO 1 --- [           main] o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat initialized with port 8080 (http)
        web-1  | 2025-11-22T16:18:48.539Z  INFO 1 --- [           main] o.apache.catalina.core.StandardService   : Starting service [Tomcat]
        web-1  | 2025-11-22T16:18:48.539Z  INFO 1 --- [           main] o.apache.catalina.core.StandardEngine    : Starting Servlet engine: [Apache Tomcat/10.1.20]
        web-1  | 2025-11-22T16:18:48.646Z  INFO 1 --- [           main] o.a.c.c.C.[Tomcat].[localhost].[/]       : Initializing Spring embedded WebApplicationContext
        web-1  | 2025-11-22T16:18:48.647Z  INFO 1 --- [           main] w.s.c.ServletWebServerApplicationContext : Root WebApplicationContext: initialization completed in 1699 ms
        web-1  | 2025-11-22T16:18:48.735Z  INFO 1 --- [           main] com.zaxxer.hikari.HikariDataSource       : HikariPool-1 - Starting...
        web-1  | 2025-11-22T16:18:48.943Z  INFO 1 --- [           main] com.zaxxer.hikari.pool.HikariPool        : HikariPool-1 - Added connection conn0: url=jdbc:h2:tcp://db:9092/./payrolldb user=SA
        web-1  | 2025-11-22T16:18:48.946Z  INFO 1 --- [           main] com.zaxxer.hikari.HikariDataSource       : HikariPool-1 - Start completed.
        web-1  | 2025-11-22T16:18:48.957Z  INFO 1 --- [           main] o.s.b.a.h2.H2ConsoleAutoConfiguration    : H2 console available at '/h2-console'. Database available at 'jdbc:h2:tcp://db:9092/./payrolldb'                                                                                                                                                           
        web-1  | 2025-11-22T16:18:49.156Z  INFO 1 --- [           main] o.hibernate.jpa.internal.util.LogHelper  : HHH000204: Processing PersistenceUnitInfo [name: default]
        web-1  | 2025-11-22T16:18:49.317Z  INFO 1 --- [           main] org.hibernate.Version                    : HHH000412: Hibernate ORM core version 6.4.4.Final
        web-1  | 2025-11-22T16:18:49.368Z  INFO 1 --- [           main] o.h.c.internal.RegionFactoryInitiator    : HHH000026: Second-level cache disabled
        web-1  | 2025-11-22T16:18:49.674Z  INFO 1 --- [           main] o.s.o.j.p.SpringPersistenceUnitInfo      : No LoadTimeWeaver setup: ignoring JPA class transformer
        web-1  | 2025-11-22T16:18:49.698Z  WARN 1 --- [           main] org.hibernate.orm.connections.pooling    : HHH10001002: Using built-in connection pool (not intended for production use)
        web-1  | 2025-11-22T16:18:49.725Z  INFO 1 --- [           main] org.hibernate.orm.connections.pooling    : HHH10001005: Loaded JDBC driver class: org.h2.Driver
        web-1  | 2025-11-22T16:18:49.725Z  INFO 1 --- [           main] org.hibernate.orm.connections.pooling    : HHH10001012: Connecting with JDBC URL [jdbc:h2:tcp://db:9092/./payrolldb]
        web-1  | 2025-11-22T16:18:49.726Z  INFO 1 --- [           main] org.hibernate.orm.connections.pooling    : HHH10001001: Connection properties: {password=****, user=sa}                                                                                                                                                                                               
        web-1  | 2025-11-22T16:18:49.726Z  INFO 1 --- [           main] org.hibernate.orm.connections.pooling    : HHH10001003: Autocommit mode: false                                                                                                                                                                                                                        
        web-1  | 2025-11-22T16:18:49.729Z  INFO 1 --- [           main] org.hibernate.orm.connections.pooling    : HHH10001115: Connection pool size: 20 (min=1)
        web-1  | 2025-11-22T16:18:49.797Z  WARN 1 --- [           main] org.hibernate.orm.deprecation            : HHH90000025: H2Dialect does not need to be specified explicitly using 'hibernate.dialect' (remove the property setting and it will be selected by default)                                                                                                 
        web-1  | 2025-11-22T16:18:50.601Z  INFO 1 --- [           main] o.h.e.t.j.p.i.JtaPlatformInitiator       : HHH000489: No JTA platform available (set 'hibernate.transaction.jta.platform' to enable JTA platform integration)
        web-1  | 2025-11-22T16:18:50.616Z  INFO 1 --- [           main] org.hibernate.orm.connections.access     : HHH10001501: Connection obtained from JdbcConnectionAccess [org.hibernate.engine.jdbc.env.internal.JdbcEnvironmentInitiator$ConnectionProviderJdbcConnectionAccess@684a802a] for (non-JTA) DDL execution was not in auto-commit mode; the Connection 'local transaction' will be committed and the Connection will be set into auto-commit mode.                                                                                                                                                                                                                                                                                 
        web-1  | 2025-11-22T16:18:50.649Z  INFO 1 --- [           main] j.LocalContainerEntityManagerFactoryBean : Initialized JPA EntityManagerFactory for persistence unit 'default'
        web-1  | 2025-11-22T16:18:50.970Z  WARN 1 --- [           main] JpaBaseConfiguration$JpaWebConfiguration : spring.jpa.open-in-view is enabled by default. Therefore, database queries may be performed during view rendering. Explicitly configure spring.jpa.open-in-view to disable this warning
        web-1  | 2025-11-22T16:18:51.490Z  INFO 1 --- [           main] o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat started on port 8080 (http) with context path ''
        web-1  | 2025-11-22T16:18:51.515Z  INFO 1 --- [           main] payroll.PayrollApplication               : Started PayrollApplication in 5.317 seconds (process running for 5.95)
        web-1  | 2025-11-22T16:18:51.749Z  INFO 1 --- [           main] payroll.LoadDatabase                     : Preloaded Employee{id=1, firstName='Bilbo', lastName='Baggins', role='burglar'}
        web-1  | 2025-11-22T16:18:51.749Z  INFO 1 --- [           main] payroll.LoadDatabase                     : Preloaded Employee{id=2, firstName='Frodo', lastName='Baggins', role='thief'}
        web-1  | 2025-11-22T16:18:51.772Z  INFO 1 --- [           main] payroll.LoadDatabase                     : Preloaded Order{id=1, description='MacBook Pro', status=COMPLETED}                                                                                                                                                                                         
        web-1  | 2025-11-22T16:18:51.772Z  INFO 1 --- [           main] payroll.LoadDatabase                     : Preloaded Order{id=2, description='iPhone', status=IN_PROGRESS}

Com os *logs* acima mostrados, podemos ver que mesmo correndo apenas a parte *web* a base dados é executada antes.

- Apagado temporariamente o serviço da base de dados do ***compose.yaml*** e executados ambos os *containers*:

        PS C:\Users\nunoc\Desktop\cogsi2526-1240444-1211426-1211689\CA5\Part2> docker compose up    
        service "web" depends on undefined service "db": invalid compose project
        PS C:\Users\nunoc\Desktop\cogsi2526-1240444-1211426-1211689\CA5\Part2> 

Como podemos observar, a mesma não arranca pois a base de dados também não arrancou.

## Issue #64 - Add Docker volume for database persistence

Para obter-se persistência da base de dados, foi criado um volume da mesma, tendo sido feitas as seguintes alterações ao ficheiro ***compose.yaml***:

    services:
      db:
        image: thomseno/h2:2.2.224
        ports:
          - "9092:9092"
          - "8082:8082"
        volumes:
          - h2-data:/opt/h2-data
        healthcheck:
          test: ["CMD-SHELL", "curl http://localhost:8082 || exit 1"]
          interval: 5s
          timeout: 5s
          retries: 10
        networks:
          - spring-app

    volumes:
      h2-data:

    networks:
      spring-net:

**NOTA**: foi apenas colocado um excerto do ficheiro para facilitar a leitura.

Podemos validar a criação do volume com o comando ***docker volume ls***:

    PS C:\Users\nunoc\Desktop\cogsi2526-1240444-1211426-1211689\CA5\Part2> docker volume ls
    DRIVER    VOLUME NAME
    local     4b1706f550b816e315c1ed36c5bcb31853cd7fc4a9dbeed0606b6cadf424febb
    local     9bb79da43878f560eaed66e2a0ebf68045537c166a0a968e21bae615996920f2
    local     24b7bc718363b1e282c87fd503017814945347f78d450088548c519f2c7fac21
    local     aede490a0b6ae6970638e0764520ed3688842ee07e6ae23390a7300b45eddbe3
    local     b89fcd4b7656caa51a9c9fd007daef8421242161314df1cfd3586f1e21c18d71
    local     dcb5177ee9613bf10539aa6206a5a4c6af514b13740df9f3faaa9f4e5f370c54
    local     part2_h2-data

Como podemos observar, o volume com o nome definido anteriormente é criado.

Para além disto, podemos validar se o volume encontra-se no *container*, utilizando o seguinte comando, ***docker inspect part2-db-1 --format='{{json .Mounts}}'***:

    PS C:\Users\nunoc\Desktop\cogsi2526-1240444-1211426-1211689\CA5\Part2> docker inspect part2-db-1 --format='{{json .Mounts}}'
    [{"Type":"volume","Name":"part2_h2-data","Source":"/var/lib/docker/volumes/part2_h2-data/_data","Destination":"/opt/h2-data","Driver":"local","Mode":"rw","RW":true,"Propagation":""},{"Type":"volume","Name":"9bb79da43878f560eaed66e2a0ebf68045537c166a0a968e21bae615996920f2","Source":"/var/lib/docker/volumes/9bb79da43878f560eaed66e2a0ebf68045537c166a0a968e21bae615996920f2/_data","Destination":"/h2-data","Driver":"local","Mode":"","RW":true,"Propagation":""}]

No *output*, podemos ver, logo no início, que o volume consta no *container*.

## Issue #65 - Configure environment variables

Para serem implementadas variáveis de ambiente é necessário criar um ficheiro ***.env*** no diretório onde consta o ficheiro ***compose.yaml***.

    PS C:\Users\nunoc\Desktop\cogsi2526-1240444-1211426-1211689\CA5\Part2> dir  
    
    
        Directory: C:\Users\nunoc\Desktop\cogsi2526-1240444-1211426-1211689\CA5\Part2
    
    
    Mode                 LastWriteTime         Length Name
    ----                 -------------         ------ ----
    -a----        11/22/2025  12:02 PM            591 .env
    -a----        11/22/2025  12:02 PM           1005 compose.yaml
    -a----        11/22/2025  11:19 AM            526 Dockerfile

Observando o contéudo do mesmo:

    # Variável com porto para o módulo Web
    WEB_PORT=8080

    # Definição de varíaveis para execução do módulo DB
    DB_HOST=db
    DB_TCP_PORT=9092
    DB_CONSOLE_PORT=8082
    DB_NAME=payrolldb
    DB_USERNAME=sa
    DB_PASSWORD=password
    DB_HEALTHCHECK_INTERVAL=5s
    DB_HEALTHCHECK_TIMEOUT=5s
    DB_HEALTHCHECK_RETRIES=10

    # Variável para modo como JPA gere a DB
    SPRING_JPA_DDL_AUTO=update

    # Caminhos para pastas importantes
    WEB_BUILD_CONTEXT=../..
    WEB_DOCKERFILE_PATH=CA5/Part2/Dockerfile

    # Definição do nome do volume e rede dos Containers
    NETWORK_NAME=spring-app
    VOLUME_NAME=h2-data

Podemos verificar que todas as variáveis que constam no ***compose.yaml*** são aqui definidas e desta forma é possível invocar as mesmas neste e em qualquer outro ficheiro que necessite de as utilizar. De seguida é revelado o novo aspeto do ficheiro anteriormente mencionado, onde são invocadas as variáveis criadas:

    services:
      db:
        image: thomseno/h2:2.2.224
        ports:
          - "${DB_TCP_PORT}:9092"
          - "${DB_CONSOLE_PORT}:8082"
        volumes:
          - ${VOLUME_NAME}:/opt/h2-data
        healthcheck:
          test: ["CMD-SHELL", "curl http://localhost:${DB_CONSOLE_PORT} || exit 1"]
          interval: ${DB_HEALTHCHECK_INTERVAL}
          timeout: ${DB_HEALTHCHECK_TIMEOUT}
          retries: ${DB_HEALTHCHECK_RETRIES}
        networks:
          - ${NETWORK_NAME}

      web:
        build:
          context: ${WEB_BUILD_CONTEXT}
          dockerfile: ${WEB_DOCKERFILE_PATH}
        ports:
          - "${WEB_PORT}:8080"
        depends_on:
          db:
            condition: service_healthy
        environment:
          SPRING_DATASOURCE_URL: jdbc:h2:tcp://${DB_HOST}:${DB_TCP_PORT}/./${DB_NAME}
          SPRING_DATASOURCE_USERNAME: ${DB_USERNAME}
          SPRING_DATASOURCE_PASSWORD: ${DB_PASSWORD}
          SPRING_JPA_HIBERNATE_DDL_AUTO: ${SPRING_JPA_DDL_AUTO}
        networks:
          - ${NETWORK_NAME}

    volumes:
      h2-data:

    networks:
      spring-app:

Em jeito de validação, foi executado o comando ***docker compose up*** para levantar os *containers*:

    PS C:\Users\nunoc\Desktop\cogsi2526-1240444-1211426-1211689\CA5\Part2> docker compose up   
    [+] Running 3/3
     ✔ Network part2_spring-app  Created                                                                                                                                                                                                                                                                                                                                                                    0.0s 
     ✔ Container part2-db-1      Created                                                                                                                                                                                                                                                                                                                                                                    0.1s 
     ✔ Container part2-web-1     Created                                                                                                                                                                                                                                                                                                                                                                    0.1s 
    Attaching to db-1, web-1
    db-1  | VM settings:
    db-1  |     Max. Heap Size (Estimated): 1.90G
    db-1  |     Using VM: OpenJDK 64-Bit Server VM                                                                                                                                                                                                                                                                                                                                                               
    db-1  |                                                                                                                                                                                                                                                                                                                                                                                                      
    db-1  | TCP server running at tcp://172.18.0.2:9092 (others can connect)                                                                                                                                                                                                                                                                                                                                     
    db-1  | Web Console server running at http://172.18.0.2:8082 (others can connect)
    web-1  |                                                                                                                                                                                                                                                                                                                                                                                                     
    web-1  |   .   ____          _            __ _ _
    web-1  |  /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \                                                                                                                                                                                                                                                                                                                                                            
    web-1  | ( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \                                                                                                                                                                                                                                                                                                                                                           
    web-1  |  \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
    web-1  |   '  |____| .__|_| |_|_| |_\__, | / / / /                                                                                                                                                                                                                                                                                                                                                           
    web-1  |  =========|_|==============|___/=/_/_/_/                                                                                                                                                                                                                                                                                                                                                            
    web-1  |  :: Spring Boot ::                (v3.2.5)                                                                                                                                                                                                                                                                                                                                                          
    web-1  | 
    web-1  | 2025-11-22T12:09:20.112Z  INFO 1 --- [           main] payroll.PayrollApplication               : Starting PayrollApplication using Java 17.0.17 with PID 1 (/app/app.jar started by root in /app)                                                                                                                                                                                                  
    web-1  | 2025-11-22T12:09:20.122Z  INFO 1 --- [           main] payroll.PayrollApplication               : No active profile set, falling back to 1 default profile: "default"
    web-1  | 2025-11-22T12:09:21.226Z  INFO 1 --- [           main] .s.d.r.c.RepositoryConfigurationDelegate : Bootstrapping Spring Data JPA repositories in DEFAULT mode.
    web-1  | 2025-11-22T12:09:21.317Z  INFO 1 --- [           main] .s.d.r.c.RepositoryConfigurationDelegate : Finished Spring Data repository scanning in 72 ms. Found 2 JPA repository interfaces.
    web-1  | 2025-11-22T12:09:21.940Z  INFO 1 --- [           main] o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat initialized with port 8080 (http)
    web-1  | 2025-11-22T12:09:21.961Z  INFO 1 --- [           main] o.apache.catalina.core.StandardService   : Starting service [Tomcat]
    web-1  | 2025-11-22T12:09:21.961Z  INFO 1 --- [           main] o.apache.catalina.core.StandardEngine    : Starting Servlet engine: [Apache Tomcat/10.1.20]
    web-1  | 2025-11-22T12:09:22.029Z  INFO 1 --- [           main] o.a.c.c.C.[Tomcat].[localhost].[/]       : Initializing Spring embedded WebApplicationContext                                                                                                                                                                                                                                                
    web-1  | 2025-11-22T12:09:22.030Z  INFO 1 --- [           main] w.s.c.ServletWebServerApplicationContext : Root WebApplicationContext: initialization completed in 1768 ms
    web-1  | 2025-11-22T12:09:22.079Z  INFO 1 --- [           main] com.zaxxer.hikari.HikariDataSource       : HikariPool-1 - Starting...                                                                                                                                                                                                                                                                        
    web-1  | 2025-11-22T12:09:22.345Z  INFO 1 --- [           main] com.zaxxer.hikari.pool.HikariPool        : HikariPool-1 - Added connection conn0: url=jdbc:h2:tcp://db:9092/./payrolldb user=SA
    web-1  | 2025-11-22T12:09:22.348Z  INFO 1 --- [           main] com.zaxxer.hikari.HikariDataSource       : HikariPool-1 - Start completed.
    web-1  | 2025-11-22T12:09:22.364Z  INFO 1 --- [           main] o.s.b.a.h2.H2ConsoleAutoConfiguration    : H2 console available at '/h2-console'. Database available at 'jdbc:h2:tcp://db:9092/./payrolldb'                                                                                                                                                                                                  
    web-1  | 2025-11-22T12:09:22.605Z  INFO 1 --- [           main] o.hibernate.jpa.internal.util.LogHelper  : HHH000204: Processing PersistenceUnitInfo [name: default]
    web-1  | 2025-11-22T12:09:22.702Z  INFO 1 --- [           main] org.hibernate.Version                    : HHH000412: Hibernate ORM core version 6.4.4.Final
    web-1  | 2025-11-22T12:09:22.755Z  INFO 1 --- [           main] o.h.c.internal.RegionFactoryInitiator    : HHH000026: Second-level cache disabled
    web-1  | 2025-11-22T12:09:23.103Z  INFO 1 --- [           main] o.s.o.j.p.SpringPersistenceUnitInfo      : No LoadTimeWeaver setup: ignoring JPA class transformer
    web-1  | 2025-11-22T12:09:23.128Z  WARN 1 --- [           main] org.hibernate.orm.connections.pooling    : HHH10001002: Using built-in connection pool (not intended for production use)
    web-1  | 2025-11-22T12:09:23.162Z  INFO 1 --- [           main] org.hibernate.orm.connections.pooling    : HHH10001005: Loaded JDBC driver class: org.h2.Driver
    web-1  | 2025-11-22T12:09:23.162Z  INFO 1 --- [           main] org.hibernate.orm.connections.pooling    : HHH10001012: Connecting with JDBC URL [jdbc:h2:tcp://db:9092/./payrolldb]
    web-1  | 2025-11-22T12:09:23.162Z  INFO 1 --- [           main] org.hibernate.orm.connections.pooling    : HHH10001001: Connection properties: {password=****, user=sa}                                                                                                                                                                                                                                      
    web-1  | 2025-11-22T12:09:23.162Z  INFO 1 --- [           main] org.hibernate.orm.connections.pooling    : HHH10001003: Autocommit mode: false
    web-1  | 2025-11-22T12:09:23.166Z  INFO 1 --- [           main] org.hibernate.orm.connections.pooling    : HHH10001115: Connection pool size: 20 (min=1)                                                                                                                                                                                                                                                     
    web-1  | 2025-11-22T12:09:23.248Z  WARN 1 --- [           main] org.hibernate.orm.deprecation            : HHH90000025: H2Dialect does not need to be specified explicitly using 'hibernate.dialect' (remove the property setting and it will be selected by default)
    web-1  | 2025-11-22T12:09:24.123Z  INFO 1 --- [           main] o.h.e.t.j.p.i.JtaPlatformInitiator       : HHH000489: No JTA platform available (set 'hibernate.transaction.jta.platform' to enable JTA platform integration)
    web-1  | 2025-11-22T12:09:24.145Z  INFO 1 --- [           main] org.hibernate.orm.connections.access     : HHH10001501: Connection obtained from JdbcConnectionAccess [org.hibernate.engine.jdbc.env.internal.JdbcEnvironmentInitiator$ConnectionProviderJdbcConnectionAccess@684a802a] for (non-JTA) DDL execution was not in auto-commit mode; the Connection 'local transaction' will be committed and the Connection will be set into auto-commit mode.                                                                                                                                                                                                                                                                                                                                                               
    web-1  | 2025-11-22T12:09:24.176Z  INFO 1 --- [           main] j.LocalContainerEntityManagerFactoryBean : Initialized JPA EntityManagerFactory for persistence unit 'default'
    web-1  | 2025-11-22T12:09:24.518Z  WARN 1 --- [           main] JpaBaseConfiguration$JpaWebConfiguration : spring.jpa.open-in-view is enabled by default. Therefore, database queries may be performed during view rendering. Explicitly configure spring.jpa.open-in-view to disable this warning
    web-1  | 2025-11-22T12:09:25.117Z  INFO 1 --- [           main] o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat started on port 8080 (http) with context path ''
    web-1  | 2025-11-22T12:09:25.147Z  INFO 1 --- [           main] payroll.PayrollApplication               : Started PayrollApplication in 5.598 seconds (process running for 6.299)
    web-1  | 2025-11-22T12:09:25.412Z  INFO 1 --- [           main] payroll.LoadDatabase                     : Preloaded Employee{id=1, firstName='Bilbo', lastName='Baggins', role='burglar'}
    web-1  | 2025-11-22T12:09:25.412Z  INFO 1 --- [           main] payroll.LoadDatabase                     : Preloaded Employee{id=2, firstName='Frodo', lastName='Baggins', role='thief'}
    web-1  | 2025-11-22T12:09:25.434Z  INFO 1 --- [           main] payroll.LoadDatabase                     : Preloaded Order{id=1, description='MacBook Pro', status=COMPLETED}                                                                                                                                                                                                                                
    web-1  | 2025-11-22T12:09:25.435Z  INFO 1 --- [           main] payroll.LoadDatabase                     : Preloaded Order{id=2, description='iPhone', status=IN_PROGRESS}

Como podemos observar, os *containers* são levantados com sucesso.

## Issue #66 - Publish web and db images to Docker Hub

Para publicarmos os *containers* para o ***Docker Hub*** foram realizados os seguintes passos, depois de ser feito o *login*, neste caso através de uma página *web* aberta automaticamente pelo *CMD*:

1. Ambos os *containers* foram *taggados*, com o nome do utilizador do *Docker*.
2. Os *containers* foram de seguidas enviados para o repositório.

O resultado destes passos é revelado no seguinte *output*:

    PS C:\Users\nunoc\Desktop\cogsi2526-1240444-1211426-1211689\CA5\Part2> docker login
    Authenticating with existing credentials... [Username: nunocunha02]

    i Info → To login with a different account, run 'docker logout' followed by 'docker login'


    Login Succeeded
    PS C:\Users\nunoc\Desktop\cogsi2526-1240444-1211426-1211689\CA5\Part2> docker tag part2-web:latest nunocunha02/part2-web:v1
    PS C:\Users\nunoc\Desktop\cogsi2526-1240444-1211426-1211689\CA5\Part2> docker push nunocunha02/part2-web:v1
    The push refers to repository [docker.io/nunocunha02/part2-web]
    859ab389476a: Pushed
    b5e329fb7a0e: Pushed
    7e49dc6156b0: Pushed
    4e292c31f904: Pushed
    10a457c22d3e: Pushed
    31501e97c803: Pushed
    7e27b670a0f5: Pushed
    070c1638c21b: Pushed
    v1: digest: sha256:8a68b669e22c9426153994c52c9a5899eac6869c59ebd3e8e8f422179e53fb97 size: 856
    PS C:\Users\nunoc\Desktop\cogsi2526-1240444-1211426-1211689\CA5\Part2> docker tag thomseno/h2:2.2.224 nunocunha02/h2       
    PS C:\Users\nunoc\Desktop\cogsi2526-1240444-1211426-1211689\CA5\Part2> docker push nunocunha02/h2          
    Using default tag: latest
    The push refers to repository [docker.io/nunocunha02/h2]
    e2569d95ac3c: Mounted from thomseno/h2
    0474e363db68: Mounted from thomseno/h2
    99162d145ed1: Mounted from thomseno/h2
    a1a21c96bc16: Mounted from thomseno/h2
    ffa6ac410c03: Mounted from thomseno/h2
    9b650b1a0903: Mounted from thomseno/h2
    latest: digest: sha256:2ee33acace97f706e377d7d730eac0f8be6d492d8707e0dfbee673f6c5276329 size: 1437

    i Info → Not all multiplatform-content is present and only the available single-platform image was pushed
             sha256:ffe3779a4b2b129f6f409e8988fb630c51b0cc766f080d79c25b3e33909d1d9a -> sha256:2ee33acace97f706e377d7d730eac0f8be6d492d8707e0dfbee673f6c5276329

Por fim e em jeito de validação, podemos observar o conteúdo do repositório no seguinte URL: ***https://hub.docker.com/u/<*username*>***.

Neste caso no seguinte URL: https://hub.docker.com/u/nunocunha02

![Conteúdo do Docker Hub](img\dockerhub\docker_hub_content.png)