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
