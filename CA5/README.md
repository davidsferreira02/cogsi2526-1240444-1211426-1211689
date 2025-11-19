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
