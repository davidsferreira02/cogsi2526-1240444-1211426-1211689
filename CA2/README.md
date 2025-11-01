# Technical Report CA02

Technical report do CA02 no âmbito da UC de COGSI realizado por:

1. David Ferreira - 1240444
2. Rafael Gomes - 1211426
3. Nuno Cunha - 1211689

## Issue 24 - Add custom Gradle task runServer

Em primeiro lugar, é necessário compreender o que deve ser feito para colocar o módulo da app em execução. Para isso, é preciso fazer o *build* do projeto e executar o comando ***java -cp build/libs/basic_demo-0.1.0.jar basic_demo.ChatServerApp "server port"***, conforme indicado no ficheiro README.
Este comando serve para indicar qual o método main que deve ser executado e para definir os argumentos necessários ao seu funcionamento.

        nacunha@cogsi$ ./gradlew build
        > Task :compileJava UP-TO-DATE
        > Task :processResources UP-TO-DATE
        > Task :classes UP-TO-DATE
        > Task :jar UP-TO-DATE
        > Task :startScripts UP-TO-DATE
        > Task :distTar UP-TO-DATE
        > Task :distZip UP-TO-DATE
        > Task :assemble UP-TO-DATE
        > Task :compileTestJava NO-SOURCE
        > Task :processTestResources NO-SOURCE
        > Task :testClasses UP-TO-DATE
        > Task :test NO-SOURCE
        > Task :check UP-TO-DATE
        > Task :build UP-TO-DATE

        BUILD SUCCESSFUL in 845ms
        6 actionable tasks: 6 up-to-date
        nacunha@cogsi$ java -cp build/libs/basic_demo-0.1.0.jar basic_demo.ChatServerApp 59001
        The chat server is running...

**NOTA**: o caminho para a pasta foi abreviado de forma a facilitar a leitura do *output*.

Posto isto, é agora necessário proceder à criação da *task* no ficheiro ***build.gradle***:

        task runServer(type:JavaExec){
            group = "COGSI"

            description = "Task that starts the Chat App"

            dependsOn build

            classpath = sourceSets.main.runtimeClasspath

            mainClass = 'basic_demo.ChatServerApp'

            args '59001'
        }

Analisando a mesma por linhas, podemos observar o seguinte:

1. A *task* criada é do tipo *JavaExec*, o que significa que a mesma irá executar uma aplicação *Java* num processo filho.
2. Foi criado um grupo de *tasks* com o nome COGSI, para fins organizacionais.
3. Dada uma descrição pertinente do objetivo da mesma.
4. Utilizando a ferramenta de ordenação de *tasks* ***dependsOn*** garantimos que a *task* criada irá ser executada caso o *build* do projeto seja bem sucedido.
5. A variável ***classpath*** serve para informar o *Gradle* sobre onde encontrar o código compilado, os recursos e as bibliotecas necessárias para executar o programa.
6. A variável ***mainClass*** indica ao *Gradle* qual a classe que contém o método *main* a ser executado sendo-lhes passados os parâmetros necessários, sendo neste caso apenas o porto onde deve ser executada a aplicação.

Tendo já sido criada a *task* resta testar o seu funcionamento utilizando o comando ***./gradlew runServer***.

        nacunha@cogsi$ ./gradlew runServer
        > Task :compileJava UP-TO-DATE
        > Task :processResources UP-TO-DATE
        > Task :classes UP-TO-DATE
        > Task :jar UP-TO-DATE
        > Task :startScripts UP-TO-DATE
        > Task :distTar UP-TO-DATE
        > Task :distZip UP-TO-DATE
        > Task :assemble UP-TO-DATE
        > Task :compileTestJava NO-SOURCE
        > Task :processTestResources NO-SOURCE
        > Task :testClasses UP-TO-DATE
        > Task :test NO-SOURCE
        > Task :check UP-TO-DATE
        > Task :build UP-TO-DATE
        
        > Task :runServer
        The chat server is running...
        
Como é possível observar no *output* anterior, o código foi totalmente compilado e está operacional, dado que o output foi igual ao obtido quando utilizados os comandos individuais de *build* e execução.

## Issue 25 - Add a unit test and enable Gradle test execution

Para implementar os testes, foi necessário criar uma pasta dedicada, com uma estrutura semelhante à da pasta que contém o código-fonte da aplicação. Posteriormente, foi criada uma classe de testes correspondente a cada classe do domínio. Neste caso, como o objetivo é apenas demonstrar a interligação entre uma *task* e a execução de testes, foi criada apenas uma classe de teste que valida uma funcionalidade simples.

        package basic_demo;

        import org.junit.jupiter.api.Test;
        import static org.junit.jupiter.api.Assertions.*;

        public class ChatClientTest {

            @Test
            void testChatClientCreation() {
                ChatClient client = new ChatClient("localhost", 59001);
                assertNotNull(client, "ChatClient Created with Success");
            }
        }

Tendo sido o teste criado é necessário, de seguida, editar o ficheiro *build.gradle* e criar-se a *task* que executará os testes, bem como, adicionar-se os módulos necessários às dependências do projeto.

Relativamente às dependências do projeto, foram adicionadas as últimas duas linhas do código abaixo. Estas tratam de adicionar às dependências todos os módulos relativos ao ***junit***, na versão 5.10.

        dependencies {
            // Use Apache Log4J for logging
            implementation group: 'org.apache.logging.log4j', name: 'log4j-api', version: '2.11.2'
            implementation group: 'org.apache.logging.log4j', name: 'log4j-core', version: '2.11.2'
            testImplementation 'org.junit.jupiter:junit-jupiter-api:5.10.0'
            testRuntimeOnly 'org.junit.jupiter:junit-jupiter-engine:5.10.0'
        }

Observando agora a *task* criada:

        task testChatClient(type: Test) {
            group = "COGSI"                          
            description = "Executa apenas o teste da classe ChatClient"
            dependsOn build                          

            useJUnitPlatform()                       

            testClassesDirs = sourceSets.test.output.classesDirs  
        
            classpath = sourceSets.test.runtimeClasspath          

            include '**/ChatClientTest.class'        
        }

Analisando linha a linha, pode-se afirmar o seguinte:

1. A task é do tipo Test, o que significa que será responsável pela execução dos testes, neste caso, utilizando o JUnit.
2. Tal como no *issue* anterior, é-lhe atribuído o grupo COGSI, uma descrição coerente com a sua função e definida uma dependência em relativamente ao sucesso do *build* do projeto.
3. Ao ser utilizado o método ***useJUnitPlatform()*** indica será utilizado a versão 5 do *junit*.
4. As três últimas linhas indicam o caminho das classes de teste, das dependências e, por fim, neste caso, filtra a execução apenas ao teste criado anteriormente.

Posto isto, para correr a *task* é necessário correr o comando ***./gradlew testChatClient***, é importante sublinhar que é necessário correr este teste numa máquina com ambiente gráfico, por isso, de forma excecional a task foi corrida numa máquina *Windows*.

        PS C:\Shared\cogsi2526-1240444-1211426-1211689\CA2\Part1\gradle_basic_demo-main> ./gradlew testChatClient
        > Task :compileJava UP-TO-DATE
        > Task :processResources UP-TO-DATE
        > Task :classes UP-TO-DATE
        > Task :compileTestJava UP-TO-DATE
        > Task :processTestResources NO-SOURCE
        > Task :testClasses UP-TO-DATE
        > Task :testChatClient UP-TO-DATE

        BUILD SUCCESSFUL in 1s
        4 actionable tasks: 4 up-to-date

Para além de conseguirmos ver que todo o build foi sucedido, podemos ainda verificar um ficheiro HTML criado automaticamente onde temos toda a informação relativa ao resultado dos testes, como revela a seguinte imagem.

![Resultado dos Testes](img\taskTest\taskTest.png)

## Issue 26 - Add Gradle task backup to copy src to backup/

Este *issue* descreve a adição de uma *task* Gradle que utiliza o tipo embutido `Copy` para criar uma cópia da pasta `src` para uma nova pasta `backup/` no diretório do projeto. O objetivo é fornecer uma forma rápida e reproduzível de criar uma cópia de segurança dos ficheiros fonte.

Explicação da tarefa:

1. Foi adicionada uma *task* chamada `backup` no ficheiro `build.gradle` com o tipo `Copy`.
2. A *task* copia todo o conteúdo da pasta `src` para uma pasta `backup` na raiz do projeto usando as propriedades `from` e `into`.
3. A task é intencionalmente simples e determinística: pode ser executada localmente sem dependências adicionais e pode ser encadeada noutras tasks (por exemplo `backupZip` no mesmo ficheiro) usando `dependsOn`.

Trecho relevante do `build.gradle` (implementação da *task*):

                task backup(type: Copy) {
                        group = "COGSI"
                        description = "Copies the src directory to a backup directory"

                        from 'src'
                        into 'backup'
                }

Partes mais importantes da implementação da task `backup`:

- `task backup(type: Copy)`: declara a task usando o tipo built-in `Copy`, que fornece comportamento padrão de cópia com suporte a estruturas de pastas, filtros e performance do Gradle.
- `group = "COGSI"`: organiza a task no grupo `COGSI` para facilitar a descoberta ao listar tasks (`./gradlew tasks`).
- `description = "Copies the src directory to a backup directory"`: fornece uma descrição legível que aparece nas listagens de tasks e ajuda na documentação.
- `from 'src'`: especifica a origem da cópia — toda a árvore de ficheiros em `src` será incluída.
- `into 'backup'`: define o destino da cópia; a pasta `backup/` será criada se não existir e a estrutura interna será preservada.

Como verificar (passos executados):

1. Mudar para o directório do projecto onde se encontra o `build.gradle`.

        ```bash
        cd /path/to/gradle_basic_demo-main
        ```

2. Executar a task `backup`:

        ```bash
        ./gradlew backup
        ```

3. Verificar que a pasta `backup/` foi criada e que contém uma cópia do conteúdo de `src` (p. ex. `src/main` aparece em `backup/main`):

        ```bash
        ls -la backup
        ```

Exemplo de output observado durante a verificação realizada neste trabalho:

        > Task :backup

        BUILD SUCCESSFUL in 11s
        1 actionable task: 1 executed

        total 12
        drwxr-xr-x 3 rafael rafael 4096 Oct 12 17:20 .
        drwxr-xr-x 7 rafael rafael 4096 Oct 12 18:49 ..
        drwxr-xr-x 4 rafael rafael 4096 Oct 12 17:20 main

## Issue 27 - Add zipBackup task of type Zip

Objetivo: Criar um ficheiro `backup.zip` contendo uma cópia da árvore de fontes (`src/`). Para garantir que o conteúdo está atualizado, a nova task deve depender da task `backup` (que copia `src` para a pasta `backup/`).

Implementação adicionada ao `build.gradle`:

    task backup(type: Copy) {
            from 'src'
            into 'backup'
    }

    task zipBackup(type: Zip) {
            group = "COGSI"
            description = "Creates a zip archive of the backup directory (depends on backup)"
            dependsOn backup
            from 'backup'
            archiveFileName = 'backup.zip'
            destinationDirectory = file('.')
    }

Explicação técnica:

1. `type: Copy` na task `backup` garante a duplicação simples dos ficheiros (mantendo estrutura relativa) antes da compressão.
2. `type: Zip` na task `zipBackup` usa o mecanismo interno do Gradle para agregação de ficheiros num artefacto `.zip`.
3. `dependsOn backup` cria uma aresta explícita no grafo de execução assegurando que a origem (`backup/`) está pronta.
4. `from 'backup'` define a raiz a arquivar; não usamos diretamente `src/` para manter a intencionalidade de uma cópia congelada.
5. `destinationDirectory = file('.')` coloca o artefacto no diretório do projeto (poderia ser `build/distributions` se quiséssemos isolar outputs).

Execução:
```
./gradlew zipBackup
```

Output observado:

```
> Task :backup UP-TO-DATE
> Task :zipBackup

BUILD SUCCESSFUL in 2s
2 actionable tasks: 1 executed, 1 up-to-date
```

Artefactos resultantes:
- Diretoria `backup/`
- Ficheiro `backup.zip`

Imagem de suporte (execução da task):

![Execução da task zipBackup](img/zip/Gradle/gradlew_backupZip.png)

## Issue 28 - Explain Gradle Wrapper and JDK Toolchain

Requisitos: Demonstrar como o *Gradle Wrapper* e a *Java Toolchain* asseguram versões consistentes (Gradle 8.9 + Java 17) sem necessidade de instalações manuais divergentes.

Configuração existente no `build.gradle`:

```gradle
java {
        toolchain {
                languageVersion = JavaLanguageVersion.of(17)
        }
}
```

Foi ainda criada uma task auxiliar para recolher informação de diagnóstico:

```gradle
tasks.register('javaToolchain') {
        group = "Help"
        description = "Prints information about the configured Java toolchain"
        doLast {
                println "Java Toolchain (languageVersion): ${java.toolchain.languageVersion.get()}"
                println "Current JVM version: ${System.getProperty('java.version')}"
                println "Gradle version: ${gradle.gradleVersion} (Wrapper governs this)"
                println "JAVA_HOME: ${System.getenv('JAVA_HOME')}"
        }
}
```

Execução:

```
./gradlew -q javaToolchain
```

Output:

![Gradle Wrapper & Toolchain (Parte 1)](img/gradle_wrapper&jdk_toolchain/Gradle/gradlewOutputPart1.png)
![Gradle Wrapper & Toolchain (Parte 2)](img/gradle_wrapper&jdk_toolchain/Gradle/gradlewOutputPart2.png)


Análise:

1. O Wrapper (`gradlew`) descarrega / utiliza a distribuição exata de Gradle definida em `gradle/wrapper/gradle-wrapper.properties`, evitando discrepâncias de versões entre máquinas.
2. A *toolchain* declara a versão alvo de Java (17). O Gradle tenta localizar internamente um JDK compatível; quando configurado com *provisioning*, pode mesmo descarregar (dependendo das features usadas).
3. A compilação fica isolada de *overrides* acidentais do `JAVA_HOME` ou de JDKs mais recentes/antigos disponíveis localmente.

Com o Wrapper e a Toolchain, o build fica igual em qualquer máquina, é mais rápido começar a trabalhar e há menos erros por diferenças de ambiente.

## Issue 30 & 31 - Initial Commit + Adding necessary dependencies

Para o *commit* inicial, da parte 2 do CA2, ser feito o que se fez foi criar uma pasta vazia e nesta correu-se o comando ***gradle init*** para que um projeto *gradle* fosse iniciado na mesma. De seguida foi pedida a nossa informação relativamente a alguns ponto necessários para a criação do projeto *gradle*:

nacunha@cogsi:/mnt/hgfs/Shared/cogsi2526-1240444-1211426-1211689/CA2/Part2$ gradle init

        Select type of build to generate:
          1: Application
          2: Library
          3: Gradle plugin
          4: Basic (build structure only)
        Enter selection (default: Application) [1..4] 1
        
        Select implementation language:
          1: Java
          2: Kotlin
          3: Groovy
          4: Scala
          5: C++
          6: Swift
        Enter selection (default: Java) [1..6] 1
        
        Enter target Java version (min: 7, default: 21): 21
        
        Project name (default: Part2): 
        
        Select application structure:
          1: Single application project
          2: Application and library project
        Enter selection (default: Single application project) [1..2] 1
        
        Select build script DSL:
          1: Kotlin
          2: Groovy
        Enter selection (default: Kotlin) [1..2] 2
        
        Select test framework:
          1: JUnit 4
          2: TestNG
          3: Spock
          4: JUnit Jupiter
        Enter selection (default: JUnit Jupiter) [1..4] 4
        
        Generate build using new APIs and behavior (some features may change in the next minor release)? (default: no) [yes, no] yes
        
        
        > Task :init
        Learn more about Gradle by exploring our Samples at https://docs.gradle.org/9.1.0/samples/sample_building_java_applications.html
        
        BUILD SUCCESSFUL in 16s
        1 actionable task: 1 executed
        nacunha@cogsi:/mnt/hgfs/Shared/cogsi2526-1240444-1211426-1211689/CA2/Part2$ 

Como é possível observar no *output* acima, foram escolhidas as seguintes opções:

1. ***Application*** - Usado quando o objetivo do projeto é desenvolver uma aplicação.
2. ***Java*** - Selecionado dado que a aplicação de teste é totalmente desenvolvida em *Java* e a *framework* usada é o *Spring Boot*.
3. ***Java Version*** - Fui selecionada a versão 21 por ser a mais recente.
4. **Estrutura** - Dado que o projeto de testes tem apenas um módulo aplicacional foi selecionada a primeira opção que é direcionada a essa situação.
5. **Linguagem dos *scripts DSL*** - Escolhido o **Groovy** para manter a uniformidade durante todo o CA2.
6. ***Framework* de testes** - Escolhido o *Junit Jupiter* por ser a versão mais recente.

Posto isto, obtivemos um projeto com a seguinte árvore de diretórios:

        Part2/
        ├── .gradle/
        ├── app/
        │ ├── build/
        │ ├── src/
        │ │ ├── main/
        │ │ │ ├── java/
        │ │ │ └── resources/
        │ │ └── test/
        │ │ ├── java/
        │ │ └── resources/
        │ └── build.gradle
        ├── build/
        │ └── reports/
        ├── gradle/
        ├── .gitattributes
        ├── .gitignore
        ├── gradle.properties
        ├── gradlew
        ├── gradlew.bat
        └── settings.gradle

Tendo a estrutura do projeto feita resta copiar o contéudo da pasta **links** da aplicação de teste para a pasta **src** do novo projeto dando assim por finalizando o *commit* inicial, assim, por consequência, podemos afirmar que o *Issue 30* está concluido.

Passando agora à injeção de dependências necessárias, começamos por observar o ficheiro ***build.gradle*** criado:

        /*
         * This file was generated by the Gradle 'init' task.
         *
         * This generated file contains a sample Java application project to get you started.
         * For more details on building Java & JVM projects, please refer to https://docs.gradle.org/9.1.0/userguide/building_java_projects.html in the Gradle documentation.
         * This project uses @Incubating APIs which are subject to change.
         */

        plugins {
            // Apply the application plugin to add support for building a CLI application in Java.
            id 'application'
        }

        repositories {
            // Use Maven Central for resolving dependencies.
            mavenCentral()
        }

        dependencies {
            // This dependency is used by the application.
            implementation libs.guava
        }

        testing {
            suites {
                // Configure the built-in test suite
                test {
                    // Use JUnit Jupiter test framework
                    useJUnitJupiter('5.12.1')
                }
            }
        }

        // Apply a specific Java toolchain to ease working on different environments.
        java {
            toolchain {
                languageVersion = JavaLanguageVersion.of(21)
            }
        }

        application {
            // Define the main class for the application.
            mainClass = 'org.example.AppTest'
        }

Posto isto, passou-se a observar os ficheiros ***pom.xml*** encontrados no projeto usado para testes. É importante sublinhar que no projeto usado como exemplo existem dois ficheiros *pom*, um global que afeta todos os módulos da aplicação e um ficheiro *pom* dentro de cada módulo. Poderia ter-se usado a mesma abordagem na Part2, contudo como a aplicação só têm um módulo decidiu-se alterar o ficheiro ***build.gradle*** apenas desse módulo. 

Ficheiro ***pom.xml*** global:

        <?xml version="1.0" encoding="UTF-8"?>
        <project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        		 xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
        	<modelVersion>4.0.0</modelVersion>

        	<parent>
        		<groupId>org.springframework.boot</groupId>
        		<artifactId>spring-boot-starter-parent</artifactId>
        		<version>3.2.5</version>
        	</parent>

        	<groupId>org.springframework.guides</groupId>
        	<artifactId>tut-rest</artifactId>
        	<version>0.0.1-SNAPSHOT</version>
        	<packaging>pom</packaging>

        	<properties>
        		<project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        		<java.version>17</java.version>
        	</properties>

        	<modules>
        		<module>nonrest</module>
        		<module>rest</module>
        		<module>evolution</module>
        		<module>links</module>
        	</modules>

        	<dependencies>
        		<dependency>
        			<groupId>org.springframework.boot</groupId>
        			<artifactId>spring-boot-starter-test</artifactId>
        			<scope>test</scope>
        		</dependency>
        	</dependencies>
        
        </project>

Deste ficheiro, podemos retirar o seguinte:

1. É necessário utilizar o *plugin* ***org.springframework.boot*** na versão 3.2.5.
2. A versão do *Java* é a 17.
3. Necessário injetar a dependència ***spring-boot-starter-test*** do *plugin* acima referido.

Ficheiro ***pom.xml*** do módulo aplicacional:

        <?xml version="1.0" encoding="UTF-8"?>
        <project xmlns="http://maven.apache.org/POM/4.0.0"
        		 xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        		 xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
        	<modelVersion>4.0.0</modelVersion>

        	<parent>
        		<groupId>org.springframework.guides</groupId>
        		<artifactId>tut-rest</artifactId>
        		<version>0.0.1-SNAPSHOT</version>
        	</parent>

        	<artifactId>links</artifactId>
        	<version>0.0.1-SNAPSHOT</version>

        	<dependencies>

        		<dependency>
        			<groupId>org.springframework.boot</groupId>
        			<artifactId>spring-boot-starter-web</artifactId>
        		</dependency>

        		<dependency>
        			<groupId>org.springframework.boot</groupId>
        			<artifactId>spring-boot-starter-data-jpa</artifactId>
        		</dependency>

        		<dependency>
        			<groupId>org.springframework.boot</groupId>
        			<artifactId>spring-boot-starter-hateoas</artifactId>
        		</dependency>

        		<dependency>
        			<groupId>com.h2database</groupId>
        			<artifactId>h2</artifactId>
        			<scope>runtime</scope>
        		</dependency>

        	</dependencies>

        	<build>
        		<plugins>
        			<plugin>
        				<groupId>org.springframework.boot</groupId>
        				<artifactId>spring-boot-maven-plugin</artifactId>
        			</plugin>
        		</plugins>
        	</build>

        </project>

Deste ficheiro retiramos que devemos injetar as seguintes dependências:

1. ***spring-boot-starter-web***
2. ***spring-boot-starter-data-jpa***
3. ***spring-boot-starter-hateoas***
4. ***h2***, esta da biblioteca *com.h2database*

Posto isto, o aspeto do ficheiro ***build.gradle*** ficou o seguinte:

        /*
         * This file was generated by the Gradle 'init' task.
         *
         * This generated file contains a sample Java application project to get you started.
         * For more details on building Java & JVM projects, please refer to https://docs.gradle.org/9.1.0/userguide/building_java_projects.html in the Gradle documentation.
         * This project uses @Incubating APIs which are subject to change.
         */

        plugins {
            // Apply the application plugin to add support for building a CLI application in Java.
            id 'application'
            id 'java'
            id 'org.springframework.boot' version '3.2.5'
        }

        apply plugin: 'io.spring.dependency-management'

        repositories {
            // Use Maven Central for resolving dependencies.
            mavenCentral()
        }

        dependencies {
            // This dependency is used by the application.
            implementation libs.guava
            implementation 'org.springframework.boot:spring-boot-starter-web'
            implementation 'org.springframework.boot:spring-boot-starter-data-jpa'
            implementation 'org.springframework.boot:spring-boot-starter-hateoas'
            runtimeOnly 'com.h2database:h2'
            testImplementation 'org.springframework.boot:spring-boot-starter-test'
        }

        testing {
            suites {
                // Configure the built-in test suite
                test {
                    // Use JUnit Jupiter test framework
                    useJUnitJupiter('5.12.1')
                }
            }
        }

        // Apply a specific Java toolchain to ease working on different environments.
        java {
            toolchain {
                languageVersion = JavaLanguageVersion.of(17)
            }
        }

        application {
            // Define the main class for the application.
            mainClass = 'payroll.PayrollApplication'
        }

Como é possível observar, foram adicionados os *plugins* ***java***, ***org.springframework.boot*** e o ***io.spring.dependency-management***, tal como é sugerido na documentação do *Spring Boot*. Posteriormente, foram adicionadas as dependências anteriormente detetadas e, por fim, alterada a função *main*. Posto isto, podemos colocar em execução o projeto e surgiu um erro e o *build* falhou.

        nacunha@cogsi:/mnt/hgfs/Shared/cogsi2526-1240444-1211426-1211689/CA2/Part2$ ./gradlew bootRun
        Calculating task graph as no cached configuration is available for tasks: bootRun

        1 problem was found storing the configuration cache.
        - Task `:app:compileJava` of type `org.gradle.api.tasks.compile.JavaCompile`: error writing value of type 'org.gradle.api.internal.artifacts.configurations.DefaultLegacyConfiguration'

        See the complete report at file:///mnt/hgfs/Shared/cogsi2526-1240444-1211426-1211689/CA2/Part2/build/reports/configuration-cache/52is54ud52k743z2w3ofxi0bw/1auasmoaxpqwawxdgqf8vxy7g/configuration-cache-report.html

        [Incubating] Problems report is available at: file:///mnt/hgfs/Shared/cogsi2526-1240444-1211426-1211689/CA2/Part2/build/reports/problems/problems-report.html

        FAILURE: Build failed with an exception.

        * What went wrong:
        Configuration cache state could not be cached: field `annotationProcessorPath` of `org.gradle.api.tasks.compile.CompileOptions_Decorated` bean found in field `capturedArgs` of `java.lang.invoke.SerializedLambda` bean found in field `spec` of `org.gradle.api.internal.tasks.execution.SelfDescribingSpec` bean found in task `:app:compileJava` of type `org.gradle.api.tasks.compile.JavaCompile`: error writing value of type 'org.gradle.api.internal.artifacts.configurations.DefaultLegacyConfiguration'
        > Failed to notify dependency resolution listener.
           > 'java.util.Set org.gradle.api.artifacts.LenientConfiguration.getArtifacts(org.gradle.api.specs.Spec)'

        * Try:
        > Run with --stacktrace option to get the stack trace.
        > Run with --info or --debug option to get more log output.
        > Run with --scan to generate a Build Scan (Powered by Develocity).
        > Get more help at https://help.gradle.org.

        BUILD FAILED in 1s
        Configuration cache entry discarded due to serialization error.

Este erro deve-se ao facto de o *Spring Boot* não ser compatível com o *Gradle 9.1.0*, sendo assim, basta alterar a versão do *Gradle*, no ficheiro ***gradle-wraper.properties***, para a versão 8.14.3, que é a atual da versão 8. 

        istributionBase=GRADLE_USER_HOME
        istributionPath=wrapper/dists
        istributionUrl=https\://services.gradle.org/distributions/gradle-8.14.3-bin.zip
        etworkTimeout=10000
        alidateDistributionUrl=true
        ipStoreBase=GRADLE_USER_HOME
        ipStorePath=wrapper/dists

Sendo este erro corrigido, é possível executar o projeto, como mostra o seguinte *output*:

nacunha@cogsi:/mnt/hgfs/Shared/cogsi2526-1240444-1211426-1211689/CA2/Part2$ ./gradlew bootRun
Calculating task graph as configuration cache cannot be reused because the file system entry 'app/build/classes/java/main' has been created.

        > Task :app:bootRun

          .   ____          _            __ _ _
         /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
        ( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
         \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
          '  |____| .__|_| |_|_| |_\__, | / / / /
         =========|_|==============|___/=/_/_/_/
         :: Spring Boot ::                (v3.2.5)

        2025-10-16T15:02:18.322Z  INFO 2906 --- [           main] payroll.PayrollApplication               : Starting PayrollApplication using Java 21.0.8 with PID 2906 (/mnt/hgfs/Shared/cogsi2526-1240444-1211426-1211689/CA2/Part2/app/build/classes/java/main started by nacunha in /mnt/hgfs/Shared/cogsi2526-1240444-1211426-1211689/CA2/Part2/app)
        2025-10-16T15:02:18.325Z  INFO 2906 --- [           main] payroll.PayrollApplication               : No active profile set, falling back to 1 default profile: "default"
        2025-10-16T15:02:19.074Z  INFO 2906 --- [           main] .s.d.r.c.RepositoryConfigurationDelegate : Bootstrapping Spring Data JPA repositories in DEFAULT mode.
        2025-10-16T15:02:19.127Z  INFO 2906 --- [           main] .s.d.r.c.RepositoryConfigurationDelegate : Finished Spring Data repository scanning in 46 ms. Found 2 JPA repository interfaces.
        2025-10-16T15:02:19.639Z  INFO 2906 --- [           main] o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat initialized with port 8080 (http)
        2025-10-16T15:02:19.652Z  INFO 2906 --- [           main] o.apache.catalina.core.StandardService   : Starting service [Tomcat]
        2025-10-16T15:02:19.652Z  INFO 2906 --- [           main] o.apache.catalina.core.StandardEngine    : Starting Servlet engine: [Apache Tomcat/10.1.20]
        2025-10-16T15:02:19.695Z  INFO 2906 --- [           main] o.a.c.c.C.[Tomcat].[localhost].[/]       : Initializing Spring embedded WebApplicationContext
        2025-10-16T15:02:19.696Z  INFO 2906 --- [           main] w.s.c.ServletWebServerApplicationContext : Root WebApplicationContext: initialization completed in 1336 ms
        2025-10-16T15:02:19.814Z  INFO 2906 --- [           main] com.zaxxer.hikari.HikariDataSource       : HikariPool-1 - Starting...
        2025-10-16T15:02:20.009Z  INFO 2906 --- [           main] com.zaxxer.hikari.pool.HikariPool        : HikariPool-1 - Added connection conn0: url=jdbc:h2:mem:15039a37-c397-4ef5-954a-1ee735bc186e user=SA
        2025-10-16T15:02:20.011Z  INFO 2906 --- [           main] com.zaxxer.hikari.HikariDataSource       : HikariPool-1 - Start completed.
        2025-10-16T15:02:20.046Z  INFO 2906 --- [           main] o.hibernate.jpa.internal.util.LogHelper  : HHH000204: Processing PersistenceUnitInfo [name: default]
        2025-10-16T15:02:20.105Z  INFO 2906 --- [           main] org.hibernate.Version                    : HHH000412: Hibernate ORM core version 6.4.4.Final
        2025-10-16T15:02:20.145Z  INFO 2906 --- [           main] o.h.c.internal.RegionFactoryInitiator    : HHH000026: Second-level cache disabled
        2025-10-16T15:02:20.420Z  INFO 2906 --- [           main] o.s.o.j.p.SpringPersistenceUnitInfo      : No LoadTimeWeaver setup: ignoring JPA class transformer
        2025-10-16T15:02:21.443Z  INFO 2906 --- [           main] o.h.e.t.j.p.i.JtaPlatformInitiator       : HHH000489: No JTA platform available (set 'hibernate.transaction.jta.platform' to enable JTA platform integration)
        2025-10-16T15:02:21.493Z  INFO 2906 --- [           main] j.LocalContainerEntityManagerFactoryBean : Initialized JPA EntityManagerFactory for persistence unit 'default'
        2025-10-16T15:02:21.752Z  WARN 2906 --- [           main] JpaBaseConfiguration$JpaWebConfiguration : spring.jpa.open-in-view is enabled by default. Therefore, database queries may be performed during view rendering. Explicitly configure spring.jpa.open-in-view to disable this warning
        2025-10-16T15:02:22.178Z  INFO 2906 --- [           main] o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat started on port 8080 (http) with context path ''
        2025-10-16T15:02:22.184Z  INFO 2906 --- [           main] payroll.PayrollApplication               : Started PayrollApplication in 4.265 seconds (process running for 4.651)
        2025-10-16T15:02:22.378Z  INFO 2906 --- [           main] payroll.LoadDatabase                     : Preloaded Employee{id=1, firstName='Bilbo', lastName='Baggins', role='burglar'}
        2025-10-16T15:02:22.378Z  INFO 2906 --- [           main] payroll.LoadDatabase                     : Preloaded Employee{id=2, firstName='Frodo', lastName='Baggins', role='thief'}
        2025-10-16T15:02:22.383Z  INFO 2906 --- [           main] payroll.LoadDatabase                     : Preloaded Order{id=1, description='MacBook Pro', status=COMPLETED}
        2025-10-16T15:02:22.383Z  INFO 2906 --- [           main] payroll.LoadDatabase                     : Preloaded Order{id=2, description='iPhone', status=IN_PROGRESS}
        <==========---> 80% EXECUTING [11s]
        > :app:bootRun

Para uma melhor validação podemos abrir o seguinte URL: http://<ip>:8080/employees e verificar se obtemos a informação dos empregados.

![Visualização WEB do projeto em execução](img\build_done\buildDone_Running.png)

## Issue 32 - Create a custom task named deployToDev

Objetivo: criar uma pipeline de deployment local (DEV) usando apenas tasks built-in do Gradle, com os seguintes passos em sequência:

- Delete: limpar a diretoria de deployment (`build/deployment/dev`).
- Copy: copiar o artefacto principal (JAR) para `build/deployment/dev`.
- Copy: copiar apenas as dependências de runtime (JARs) para `build/deployment/dev/lib`.
- Copy + ReplaceTokens: copiar ficheiros `src/main/resources/*.properties` para `build/deployment/dev`, aplicando substituição de tokens (`@projectVersion@` e `@buildTimestamp@`).

Comando executado e validação (aplica-se à Parte 2 — projeto `gradle_basic_demo-main`):

```bash
./gradlew -q deployToDev
ls -la build/deployment/dev
echo '--- lib ---'
ls -la build/deployment/dev/lib
```

Output observado:

![Output of ./gradlew -q deployToDev](img/deployToDev/outputGradlew.png)

Como podemos ver, temos:

- o artefacto da aplicação (payroll.jar) em `build/deployment/dev`;
- a pasta `lib` com todas as dependências de runtime (Spring Boot, Spring, Hibernate, Tomcat, H2, logging, etc.).

Isto comprova que a pipeline `deployToDev` limpou o destino, copiou o JAR e resolveu/copiou as dependências corretamente.

## Issue 33 - Create a custom task that depends on installDist and runs the generated distribution scripts

Objetivo: Criar uma *task* Gradle que dependa de `installDist` e que execute a aplicação usando os scripts gerados pela distribuição (`build/install/.../bin/<app>`), escolhendo o script executável correto consoante o sistema operativo (Unix-like vs Windows).

Explicação da tarefa:

1. A *task* foi implementada no ficheiro `app/build.gradle` como uma `Exec` task registada com o nome `runApp`. Esta *task* depende explicitamente de `installDist` para garantir que a distribuição (scripts + JARs) foi gerada antes da execução.
2. A *task* determina o sistema operativo em tempo de execução através de `System.getProperty('os.name').toLowerCase()` e escolhe o script apropriado (`app` no Linux/macOS, `app.bat` no Windows) a partir do diretório `build/install/app/bin/`.
3. Agrupar a tarefa no grupo `COGSI` e adicionar uma `description` torna-a fácil de descobrir com `./gradlew tasks`.

Implementação da tarefa:

        tasks.register('runApp', Exec) {
            group = 'COGSI'
            description = 'Runs the Chat Application'
            dependsOn tasks.named('installDist')
            
            def os = System.getProperty('os.name').toLowerCase()
            if (os.contains('win')) {
                commandLine "${buildDir}/install/app/bin/app.bat"
            } else {
                commandLine "${buildDir}/install/app/bin/app"
            }
    
        }

O que foi feito e porquê resolve o problema:

- Garantia de artefactos prontos: obrigando a dependência `installDist`, asseguramos que os ficheiros binários e JARs necessários existem antes de tentar executar a aplicação.
- Compatibilidade multi-SO: a deteção do SO e a seleção do script (`.bat` vs script Unix) tornam a tarefa portável entre máquinas Windows e Unix-like sem alterações manuais.
- Simplicidade de uso: para executar a aplicação empacotada basta correr `./gradlew runApp`. Alternativamente, os passos manuais equivalentes são: `./gradlew installDist` seguido de `build/install/app/bin/app` (ou `.../app.bat` no Windows).

Como verificar (passos executados):

1. No terminal, na raiz do módulo `app`, correr:

        ./gradlew runApp

2. A saída esperada é equivalente a executar a aplicação empacotada — o *terminal* deverá indicar que a aplicação iniciou.

### Output de ./gradlew runApp

```bash
./gradlew runApp
Calculating task graph as configuration cache cannot be reused because file 'app/build.gradle' has changed.

> Task :app:runApp

    .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
    '  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/
 :: Spring Boot ::                (v3.2.5)

2025-10-17T23:54:03.648+01:00  INFO 70245 --- [           main] payroll.PayrollApplication               : Starting PayrollApplication using Java 21.0.8 with PID 70245 (/home/rafael/mestrado/COGSI/.../app/build/install/app/lib/app-plain.jar started by rafael in /home/rafael/.../CA2/Part2/app)
2025-10-17T23:54:03.654+01:00  INFO 70245 --- [           main] payroll.PayrollApplication               : No active profile set, falling back to 1 default profile: "default"
2025-10-17T23:54:04.658+01:00  INFO 70245 --- [           main] .s.d.r.c.RepositoryConfigurationDelegate : Bootstrapping Spring Data JPA repositories in DEFAULT mode.
2025-10-17T23:54:04.785+01:00  INFO 70245 --- [           main] .s.d.r.c.RepositoryConfigurationDelegate : Finished Spring Data repository scanning in 112 ms. Found 2 JPA repository interfaces.
2025-10-17T23:54:05.647+01:00  INFO 70245 --- [           main] o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat initialized with port 8080 (http)
2025-10-17T23:54:05.672+01:00  INFO 70245 --- [           main] o.apache.catalina.core.StandardService   : Starting service [Tomcat]
2025-10-17T23:54:05.673+01:00  INFO 70245 --- [           main] o.apache.catalina.core.StandardEngine    : Starting Servlet engine: [Apache Tomcat/10.1.20]
2025-10-17T23:54:05.776+01:00  INFO 70245 --- [           main] o.a.c.c.C.[Tomcat].[localhost].[/]       : Initializing Spring embedded WebApplicationContext
2025-10-17T23:54:05.779+01:00  INFO 70245 --- [           main] w.s.c.ServletWebServerApplicationContext : Root WebApplicationContext: initialization completed in 2054 ms
2025-10-17T23:54:06.046+01:00  INFO 70245 --- [           main] com.zaxxer.hikari.HikariDataSource       : HikariPool-1 - Starting...
2025-10-17T23:54:06.260+01:00  INFO 70245 --- [           main] com.zaxxer.hikari.pool.HikariPool        : HikariPool-1 - Added connection conn0: url=jdbc:h2:mem:760a6935-8e4d-4614-a60a-f50c325b9914 user=SA
2025-10-17T23:54:06.262+01:00  INFO 70245 --- [           main] com.zaxxer.hikari.HikariDataSource       : HikariPool-1 - Start completed.
2025-10-17T23:54:06.319+01:00  INFO 70245 --- [           main] o.hibernate.jpa.internal.util.LogHelper  : HHH000204: Processing PersistenceUnitInfo [name: default]
2025-10-17T23:54:06.415+01:00  INFO 70245 --- [           main] org.hibernate.Version                    : HHH000412: Hibernate ORM core version 6.4.4.Final
2025-10-17T23:54:06.480+01:00  INFO 70245 --- [           main] o.h.c.internal.RegionFactoryInitiator    : HHH000026: Second-level cache disabled
2025-10-17T23:54:06.813+01:00  INFO 70245 --- [           main] o.s.o.j.p.SpringPersistenceUnitInfo      : No LoadTimeWeaver setup: ignoring JPA class transformer
2025-10-17T23:54:07.891+01:00  INFO 70245 --- [           main] o.h.e.t.j.p.i.JtaPlatformInitiator       : HHH000489: No JTA platform available (set 'hibernate.transaction.jta.platform' to enable JTA platform integration)
2025-10-17T23:54:07.935+01:00  INFO 70245 --- [           main] j.LocalContainerEntityManagerFactoryBean : Initialized JPA EntityManagerFactory for persistence unit 'default'
2025-10-17T23:54:08.357+01:00  WARN 70245 --- [           main] JpaBaseConfiguration$JpaWebConfiguration : spring.jpa.open-in-view is enabled by default. Therefore, database queries may be performed during view rendering. Explicitly configure spring.jpa.open-in-view to disable this warning
2025-10-17T23:54:09.075+01:00  INFO 70245 --- [           main] o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat started on port 8080 (http) with context path ''
2025-10-17T23:54:09.090+01:00  INFO 70245 --- [           main] payroll.PayrollApplication               : Started PayrollApplication in 5.926 seconds (process running for 6.516)
2025-10-17T23:54:09.280+01:00  INFO 70245 --- [           main] payroll.LoadDatabase                     : Preloaded Employee{id=1, firstName='Bilbo', lastName='Baggins', role='burglar'}
2025-10-17T23:54:09.280+01:00  INFO 70245 --- [           main] payroll.LoadDatabase                     : Preloaded Employee{id=2, firstName='Frodo', lastName='Baggins', role='thief'}
2025-10-17T23:54:09.292+01:00  INFO 70245 --- [           main] payroll.LoadDatabase                     : Preloaded Order{id=1, description='MacBook Pro', status=COMPLETED}
2025-10-17T23:54:09.292+01:00  INFO 70245 --- [           main] payroll.LoadDatabase                     : Preloaded Order{id=2, description='iPhone', status=IN_PROGRESS}
2025-10-17T23:54:13.120+01:00  INFO 70245 --- [nio-8080-exec-1] o.a.c.c.C.[Tomcat].[localhost].[/]       : Initializing Spring DispatcherServlet 'dispatcherServlet'
2025-10-17T23:54:13.120+01:00  INFO 70245 --- [nio-8080-exec-1] o.s.web.servlet.DispatcherServlet        : Initializing Servlet 'dispatcherServlet'
2025-10-17T23:54:13.123+01:00  INFO 70245 --- [nio-8080-exec-1] o.s.web.servlet.DispatcherServlet        : Completed initialization in 1 ms
<===========--> 85% EXECUTING [37s]
> :app:runApp
```

## Issue 34 - Create a custom task that depends on the javadoc task

Objetivo:

Criar uma *task* Gradle personalizada chamada `zipJavadoc` que dependa da *task* `javadoc`. A *task* deve gerar a documentação Javadoc do projeto e, em seguida, empacotar a documentação gerada numa arquivo ZIP, facilitando distribuição ou inclusão em artefactos de release.

```gradle
javadoc {
    group = 'Documentation'
    description = 'Generates Javadoc for the main source set.'
    source = sourceSets.main.allJava
    destinationDir = file("${buildDir}/docs/javadoc")
    classpath = configurations.compileClasspath

    options {
        // Includes classes with package-level visibility in the Javadoc, preventing only PayrollApplication from being documented.
        memberLevel = JavadocMemberLevel.PACKAGE
    }
}

tasks.register('zipJavadoc', Zip) {
    group = 'Distribution'
    description = 'Zips the generated Javadoc documentation.'

    dependsOn tasks.named('javadoc')

    from(tasks.named('javadoc').get().destinationDir)
    archiveFileName = "${project.name}-javadoc-${project.version}.zip"
    destinationDirectory = file("${buildDir}/docs")
}
```

Explicação da tarefa:

1. A *task* `javadoc` é a task padrão do Gradle que gera a documentação API do projecto em HTML. O output por defeito é colocado em `build/docs/javadoc`, salvo se configurado de outra forma.
2. A nova *task* `zipJavadoc` usa o tipo embutido `Zip` do Gradle para criar um ficheiro .zip com todo o conteúdo gerado pelo `javadoc`.
3. Para garantir ordem correta de execução, `zipJavadoc` declara `dependsOn tasks.named('javadoc')`. Desta forma, o Gradle garante que a documentação está atualizada antes de criar o zip, evitando arquivar conteúdo desactualizado ou inexistente.
4. A *task* referencia diretamente o `destinationDir` da task `javadoc` (`tasks.named('javadoc').get().destinationDir`) como origem do conteúdo a arquivar. Isso assegura que todos os ficheiros (HTML, CSS, imagens) são incluídos.

O que foi feito e porque resolve o problema:

1. Foi adicionada a *task* `zipJavadoc` ao ficheiro `app/build.gradle` do módulo aplicacional. A implementação faz `dependsOn tasks.named('javadoc')`, `from(tasks.named('javadoc').get().destinationDir)`, define `archiveFileName = "${project.name}-javadoc-${project.version}.zip"` e configura `destinationDirectory` para `file("${buildDir}/docs")`.
2. Esta abordagem separa responsabilidades: `javadoc` gera, `zipJavadoc` empacota. A dependência entre tasks usa o grafo do Gradle para ordenar execuções de forma robusta, o que é superior a executar comandos shell encadeados manualmente.
3. O artefacto zip resultante é facilmente localizável e pode ser integrado em pipelines de deployment ou publicado como parte de uma release. Ao apontar para o `destinationDir` do `javadoc`, evitamos problemas com paths hard-coded e tornamos a task resiliente a alterações na configuração do `javadoc`.

Como verificar:

1. Executar a task:

```
./gradlew zipJavadoc
```

2. Confirmar que o ficheiro ZIP foi criado em `app/build/docs/` com o nome `${project.name}-javadoc-${project.version}.zip`.
3. Extrair o ZIP e abrir `index.html` para garantir que a documentação HTML foi incluída corretamente.

Resultados observados:

ZIP criado:

```bash
$ ls app/build/docs
app-javadoc-unspecified.zip  javadoc
```
JavaDoc extraído:

![Javadoc gerado](img/zipJavadoc/generatedJavadoc.png)

## Issue 35 - Create a new source set for integration tests

O *Custom Source Set* foi implementado no ficheiro *build.gradle*, juntamente com todas as dependências necessárias e todos os mecanismos de ordenação de tarefas. Posto isto, foram adicionados os seguintes conteúdos ao ficheiro *build.gradle*:

        sourceSets {
            integrationTest {
                java {
                    srcDir 'src/integrationTest/java'
                }
                resources {
                    srcDir 'src/integrationTest/resources'
                }

                compileClasspath += sourceSets.main.output
                runtimeClasspath += sourceSets.main.output
            }
        }


        configurations {
            integrationTestImplementation.extendsFrom implementation
            integrationTestRuntimeOnly.extendsFrom runtimeOnly
        }

        dependencies {
            integrationTestImplementation 'org.springframework.boot:spring-boot-starter-test'
            integrationTestRuntimeOnly 'org.junit.platform:junit-platform-launcher'
            integrationTestRuntimeOnly 'com.h2database:h2'
        }

        task integrationTest (type: Test){
            description = 'Executa os testes de Integração'
            group = 'COGSI'
            testClassesDirs = sourceSets.integrationTest.output.classesDirs
            classpath = sourceSets.integrationTest.runtimeClasspath
            shouldRunAfter test
        }

        check.dependsOn integrationTest

Neste ficheiro foi criado o *source set* novo, onde são especificadas pastas de código e de recursos, além de adicionar ao classpath dos testes de integração o mesmo output do main, permitindo que estes utilizem as classes compiladas da aplicação principal. Adicionalmente, a secção de configurações faz com que o novo *source set* herde as dependências do projeto e de seguida são adicionadas as dependências necessárias para a execução dos testes. Por fim, é criada a tarefa que permite a execução dos testes, é de grande importância realçar que os testes de integração são executados após os testes unitários e que a execução da tarefa *check* depende do sucesso da execução dos testes de integração.
 
De forma a validarmos tudo o que foi implementado, foram realizados os seguintes passos:

1. Criados testes unitários para a classe ***Order*** e para a classe ***Employee***

        class OrderTest {

            @Test
            void constructorAndGetters_shouldReturnCorrectValues() {
                Order o = new Order("MacBook Pro", Status.IN_PROGRESS);

                assertThat(o.getId()).isNull();
                assertThat(o.getDescription()).isEqualTo("MacBook Pro");
                assertThat(o.getStatus()).isEqualTo(Status.IN_PROGRESS);
            }
        }

        class EmployeeTest {

            @Test
            void constructorAndGetters_shouldReturnCorrectValues() {
                Employee e = new Employee("Nuno", "Cunha", "Developer");

                assertThat(e.getFirstName()).isEqualTo("Nuno");
                assertThat(e.getLastName()).isEqualTo("Cunha");
                assertThat(e.getRole()).isEqualTo("Developer");
                assertThat(e.getName()).isEqualTo("Nuno Cunha");
            }
        }

Podemos observar o resultado dos mesmo através do *report* feito pelo *Gradle*.

![Testes Unitários](img/unitaryTestsDone/unitary_tests.png)

De seguida, foi adicionada uma pasta para os testes de integração, ficando a pasta *app* do projeto com o seguinte aspeto:

        app/
        ├── build/
        │   ├── reports/
        │   │   ├── configuration-cache/
        │   │   └── problems/
        │   └── ...
        ├── src/
        │   ├── main/
        │   │   ├── java/
        │   │   │   └── payroll/
        │   │   └── resources/
        │   ├── test/
        │   │   ├── java/
        │   │   │   └── payroll/
        │   │   └── resources/
        │   └── integrationTest/
        │       ├── java/
        │       │   └── payroll/
        │       └── resources/
        └── build.gradle

Dentro da pasta *integrationTest* foram criados testes de integração para os repositórios das classes *Order* e *Employee*:

        @DataJpaTest
        class OrderRepositoryIT {

            @Autowired
            private OrderRepository repo;

            @Test
            void shouldPersistAndRetrieveOrder() {
                Order order = new Order("Laptop", Status.IN_PROGRESS);
                repo.save(order);

                Optional<Order> found = repo.findById(order.getId());
                assertThat(found).isPresent();
                assertThat(found.get().getDescription()).isEqualTo("Laptop");
                assertThat(found.get().getStatus()).isEqualTo(Status.IN_PROGRESS);
            }
        }

        @DataJpaTest
        class EmployeeRepositoryIT {

            @Autowired
            private EmployeeRepository repo;

            @Test
            void shouldPersistAndLoadEmployee() {
                Employee e = new Employee("Nuno", "Cunha", "Developer");
                repo.save(e); // H2 in-memory

                Optional<Employee> found = repo.findById(e.getId());
                assertThat(found).isPresent();
                assertThat(found.get().getName()).isEqualTo("Nuno Cunha");
                assertThat(found.get().getRole()).isEqualTo("Developer");
            }
        }

Para a verificação dos resultados, é necessário executar a tarefa criada anteriormente. Os resultados são encontradas também num *report* criado pelo *Gradle*

![Testes Unitários](img/IntegrationTestsDone/IntegrationTests.png)

Tendo já verificado os resultados dos testes individualmente, podemos executar a a tarefa ***check*** com a *flag --info* de forma a validarmos a ordem de execução dos testes.

        > Task :app:test FROM-CACHE
        Build cache key for task ':app:test' is bfab188ce9fbcf894e457f055894108f
        Task ':app:test' is not up-to-date because:
          Output property 'binaryResultsDirectory' file /mnt/hgfs/Shared/cogsi2526-1240444-1211426-1211689/CA2/Part2/app/build/test-results/test/binary has been removed.
          Output property 'binaryResultsDirectory' file /mnt/hgfs/Shared/cogsi2526-1240444-1211426-1211689/CA2/Part2/app/build/test-results/test/binary/output.bin has been removed.
          Output property 'binaryResultsDirectory' file /mnt/hgfs/Shared/cogsi2526-1240444-1211426-1211689/CA2/Part2/app/build/test-results/test/binary/output.bin.idx has been removed.
          and more...
        Loaded cache entry for task ':app:test' with cache key bfab188ce9fbcf894e457f055894108f

        > Task :app:integrationTest FROM-CACHE
        Build cache key for task ':app:integrationTest' is dd51f1b7c5267c4c090cc45993455308
        Task ':app:integrationTest' is not up-to-date because:
          Output property 'binaryResultsDirectory' file /mnt/hgfs/Shared/cogsi2526-1240444-1211426-1211689/CA2/Part2/app/build/test-results/integrationTest/binary has been removed.
          Output property 'binaryResultsDirectory' file /mnt/hgfs/Shared/cogsi2526-1240444-1211426-1211689/CA2/Part2/app/build/test-results/integrationTest/binary/output.bin has been removed.
          Output property 'binaryResultsDirectory' file /mnt/hgfs/Shared/cogsi2526-1240444-1211426-1211689/CA2/Part2/app/build/test-results/integrationTest/binary/output.bin.idx has been removed.
          and more...
        Loaded cache entry for task ':app:integrationTest' with cache key dd51f1b7c5267c4c090cc45993455308
        Resolve mutations for :app:check (Thread[#1386,Execution worker,5,main]) started.
        :app:check (Thread[#1386,Execution worker,5,main]) started.

        > Task :app:check UP-TO-DATE
        Skipping task ':app:check' as it has no actions.

        BUILD SUCCESSFUL in 1s
        5 actionable tasks: 5 from cache
        Some of the file system contents retained in the virtual file system are on file systems that Gradle doesn't support watching. The relevant state was discarded to ensure changes to these locations are properly detected. You can override this by explicitly enabling file system watching.
        Configuration cache entry reused.

**NOTA**: O *output* foi abreviado para uma melhor apresentação dos resultados.

Como podemos observar o *build* do projeto é bem sucedido e a execução dos testes unitários é realizada antes da execução dos testes de integração.

## Ant

Esta secção foca-se nas diferenças e similaridades entre Gradle e Ant, seguida por um plano prático para replicar — com Ant — as tarefas que implementámos com Gradle neste projecto.

### 1. Gradle vs. Ant: Análise Comparativa

| Característica | Gradle | Apache Ant |
|---|---|---|
| Linguagem do Build Script | DSL (Groovy ou Kotlin). Concisa e declarativa. | XML. Verboso e imperativo. |
| Paradigma | Declarativo e por convenção: foca-se no "o quê" e assume estruturas padrão (ex: `src/main/java`). | Imperativo e por configuração: foca-se no "como" e exige passos explícitos. |
| Gestão de Dependências | Nativa e integrada (resolução transitiva via repositórios como Maven Central). | Não nativa: normalmente usa-se Apache Ivy (ficheiro `ivy.xml`) para resolução automática; sem Ivy a gestão é manual (JARs em `lib/`). |
| Ciclo de Vida e Grafos | Usa um DAG (grafo acíclico dirigido) para determinar ordem de execução e suporta builds incrementais/daemon. | Baseado em alvos/targets com dependências explícitas; menos sofisticado em otimizações de execução incremental. |
| Extensibilidade | Rico ecossistema de plugins (ex.: Spring Boot plugin que adiciona `bootRun`, etc.). | Extensível criando targets e macros; integração por bibliotecas (Ivy, tasks em Java) — mais manual. |
| Performance | Optimizações como Gradle Daemon e cache de configuração tornam-no normalmente mais rápido. | Mais lento por omissão; cada execução tende a iniciar um novo processo Java e reexecuta alvos não marcado como incremental. |

### 2. Similaridades Principais

- Automação de Build: ambos automatizam compilação, teste, empacotamento e deploy.
- Baseados na JVM: escritos em Java e executados sobre a JVM, logo multiplataforma.
- Unidade de trabalho: Gradle tem "tasks" e Ant tem "targets" — ambos representam ações encadeáveis.

### 3. Plano de Migração para Ant

Para replicar as tasks  usadas no `build.gradle` com Ant seguiremos estes passos gerais:

1. Estrutura do projeto e ficheiros iniciais

     - Criar um ficheiro `build.xml` na raiz do projecto.
     - Criar um ficheiro `ivy.xml` para declarar dependências do projecto.

2. Definir propriedades e classpath

     - No `build.xml` definir propriedades globais para diretórios (`src.dir`, `build.dir`, `dist.dir`, etc.) para facilitar manutenção.
     - Definir um path `classpath` que inclua os JARs descarregados pelo Ivy.

3. Configurar gestão de dependências com Ivy

     - Criar um alvo `resolve` ou `deps` que use Ivy para ler o `ivy.xml`, descarregar dependências para uma pasta (`lib/`) e disponibilizá-las para o `classpath`.

4. Criar alvos base do build

     - `clean`: apagar diretórios de build/saída.
     - `init`/`prepare`: criar diretórios necessários.
     - `compile`: compilar código-fonte Java com `<javac>` usando o `classpath` com dependências.
     - `jar`: empacotar classes compiladas num JAR, incluindo o atributo `Main-Class` no manifesto.

5. Implementar as tasks solicitadas

     - Definir alvos
     - Definir ordem de execução e dependências entre alvos com `depends`.
     - Usar `<copy>`, `<zip>`, `<java>` para replicar funcionalidades como deploy, backup, execução de aplicações.

Com este plano conseguimos traduzir a lógica declarativa do Gradle para passos explícitos e imperativos em Ant, mantendo a mesma funcionalidade.


### Pré‑requisitos

- Ant instalado (macOS via Homebrew: `brew install ant`).
- Java 17 disponível no PATH (o `build.xml` compila com `release="17"`).

### Configurar Ivy (uma vez)

O `build.xml` usa Ivy para resolver dependências. O jar do Ivy é esperado em `ant-lib/`.

                mkdir -p ant-lib
                curl -L -o ant-lib/ivy-2.5.2.jar \
                    https://repo1.maven.org/maven2/org/apache/ivy/ivy/2.5.2/ivy-2.5.2.jar

Alternativa via Homebrew (se instalou o pacote `ivy`):

    brew install ivy
    mkdir -p ant-lib
    ln -sf "$(ls $(brew --prefix ivy)/libexec/ivy-*.jar | tail -1)" ant-lib/

### Alvos principais (build.xml)

- `deps`: resolve e descarrega dependências com Ivy para `libs/`.
- `clean-build`: limpa e compila/empacota; gera jars em `ant-build/dist/`.
- `run-app`, `run-client`, `run-server`: executam os jars criados.
- `run`: atalho para `run-app` (alias adicionado).

Comandos de exemplo:

    ant deps
    ant clean-build
    ant run

## Issue 24 (Ant) - Adicionar tarefa para correr *Server*

Para ser possível executar o *server* da aplicação foi adicionado ao ficheiro de propriedades a classe *main* do servidor, presente na classe *java* *ChatServerApp*. 

    server.main=basic_demo.ChatServerApp

De seguida, foi criado um *JAR* para o servidor, a criação deste depende da tarefa de compilação.

    <target name="jar-server" depends="compile"><make-runnable-jar name="server" mainclass="${server.main}"/></target>

Por fim, é criada uma tarefa para correr a parte do servidor do projeto:

    <target name="run-server" depends="jar-server">
        <java jar="${dist.dir}/server.jar" fork="true" failonerror="true">
            <arg value="${server.port}"/>
        </java>
    </target>

De notar que é necessário passar o número do porto como paramêtro. Posto isto, resta validar se o mesmo executa como esperado.

    nacunha@cogsi:/mnt/hgfs/Shared/cogsi2526-1240444-1211426-1211689/CA2/Part1/gradle_basic_demo-main$ ant run-server
    Buildfile: /mnt/hgfs/Shared/cogsi2526-1240444-1211426-1211689/CA2/Part1/gradle_basic_demo-main/build.xml

    deps:
    [ivy:resolve] :: Apache Ivy 2.5.2 - 20230817170011 :: https://ant.apache.org/ivy/ ::
    [ivy:resolve] :: loading settings :: url = jar:file:/usr/share/ant/lib/ivy.jar!/org/apache/ivy/core/settings/ivysettings.xml
    [ivy:resolve] :: resolving dependencies :: me#gradle_basic_demo;working@cogsi
    [ivy:resolve]   confs: [compile, runtime]
    [ivy:resolve]   found org.apache.logging.log4j#log4j-api;2.24.1 in public
    [ivy:resolve]   found org.apache.logging.log4j#log4j-core;2.24.1 in public
    [ivy:resolve] :: resolution report :: resolve 113ms :: artifacts dl 3ms
            ---------------------------------------------------------------------
            |                  |            modules            ||   artifacts   |
            |       conf       | number| search|dwnlded|evicted|| number|dwnlded|
            ---------------------------------------------------------------------
            |      compile     |   1   |   0   |   0   |   0   ||   1   |   0   |
            |      runtime     |   2   |   0   |   0   |   0   ||   2   |   0   |
            ---------------------------------------------------------------------
    [ivy:retrieve] :: retrieving :: me#gradle_basic_demo [sync]
    [ivy:retrieve]  confs: [compile, runtime]
    [ivy:retrieve]  0 artifacts copied, 2 already retrieved (0kB/17ms)

    prepare:
        [mkdir] Created dir: /mnt/hgfs/Shared/cogsi2526-1240444-1211426-1211689/CA2/Part1/gradle_basic_demo-main/ant-build/classes
        [mkdir] Created dir: /mnt/hgfs/Shared/cogsi2526-1240444-1211426-1211689/CA2/Part1/gradle_basic_demo-main/ant-build/jar
        [mkdir] Created dir: /mnt/hgfs/Shared/cogsi2526-1240444-1211426-1211689/CA2/Part1/gradle_basic_demo-main/ant-build/dist

    resources:
         [copy] Copying 1 file to /mnt/hgfs/Shared/cogsi2526-1240444-1211426-1211689/CA2/Part1/gradle_basic_demo-main/ant-build/classes

    compile:
        [javac] Compiling 5 source files to /mnt/hgfs/Shared/cogsi2526-1240444-1211426-1211689/CA2/Part1/gradle_basic_demo-main/ant-build/classes
        [javac] Note: Annotation processing is enabled because one or more processors were found
        [javac]   on the class path. A future release of javac may disable annotation processing
        [javac]   unless at least one processor is specified by name (-processor), or a search
        [javac]   path is specified (--processor-path, --processor-module-path), or annotation
        [javac]   processing is enabled explicitly (-proc:only, -proc:full).
        [javac]   Use -Xlint:-options to suppress this message.
        [javac]   Use -proc:none to disable annotation processing.

    jar-server:
          [jar] Building jar: /mnt/hgfs/Shared/cogsi2526-1240444-1211426-1211689/CA2/Part1/gradle_basic_demo-main/ant-build/jar/server.jar
         [copy] Copying 1 file to /mnt/hgfs/Shared/cogsi2526-1240444-1211426-1211689/CA2/Part1/gradle_basic_demo-main/ant-build/dist
         [copy] Copying 2 files to /mnt/hgfs/Shared/cogsi2526-1240444-1211426-1211689/CA2/Part1/gradle_basic_demo-main/ant-build/dist/libs

    run-server:
         [java] The chat server is running...

Como podemos observar pelo *output*, mostrado acima, o servidor é executado como esperado.

### Issue 25 (Ant) — Permitir execução de testes

Para ser possível a execução dos testes foi necessário adicionar algumas variáveis ao ficheiro de propriedades:

    # ===== Tests =====
    test.src.dir=src/test/java
    test.resources.dir=src/test/resources
    test.classes.dir=${build.dir}/test-classes
    test.reports.dir=${build.dir}/test-reports
    test.includes=**/*Test.class
    test.excludes=

O contéudo adicionado serve para definir os caminhos para a pasta onde estão colocados os testas, a pasta para os recursos e para onde serão colocados os ficheiros com os testes já compilados. Para além disso, é definido o local onde são os *reports* dos testes, bem como duas expressões regulares que permitem definir os testes a correr e os testes a serem ignorados.

De seguida, foram adicionadas as dependências necessárias ao ficheiro ***ivy.xml***:

    <dependencies>
        <dependency org="org.apache.logging.log4j" name="log4j-api"  rev="2.24.1" conf="compile->default"/>
        <dependency org="org.apache.logging.log4j" name="log4j-core" rev="2.24.1" conf="runtime->default"/>
        <dependency org="org.junit.jupiter" name="junit-jupiter-api"    rev="5.10.0" conf="test->default"/>
        <dependency org="org.junit.jupiter" name="junit-jupiter-engine" rev="5.10.0" conf="test->default"/>
        <dependency org="org.junit.platform" name="junit-platform-launcher" rev="1.10.0" conf="test->default"/>
    </dependencies>


Definidas as variáveis e as dependências adicionadas, é necessário editar o ficheiro ***build.xml***. Neste foi adicionado o seguinte:

    <path id="test.compile.classpath">
        <pathelement location="${classes.dir}"/>
        <fileset dir="${lib.dir}" includes="**/*.jar" erroronmissingdir="false"/>
    </path>

    <path id="test.runtime.classpath">
        <pathelement location="${test.classes.dir}"/>
        <pathelement location="${classes.dir}"/>
        <fileset dir="${lib.dir}" includes="**/*.jar" erroronmissingdir="false"/>
    </path>

O primeiro bloco define e atribui um identificador ao classpath utilizado pelo ***Ant*** durante a compilação dos ficheiros de teste, garantindo que o compilador tenha acesso tanto às classes principais já compiladas como a todas as bibliotecas externas localizadas na pasta *libs/*.

O segundo bloco define o *classpath* utilizado pelo ***Ant*** durante a execução dos testes, incluindo no caminho as classes de teste compiladas, as classes principais do projeto e todas as dependências externas necessárias para que o ambiente de testes seja corretamente configurado em tempo de execução.

De seguida, foram criadas duas tarefas em Ant, designadas por *targets*, a primeira tem como objetivo preparar o ambiente de compilação dos testes, criando todas as pastas necessárias com base nas variáveis previamente definidas.
A segunda é responsável por compilar os ficheiros de teste, dependendo da execução bem-sucedida da primeira, de forma a garantir que a estrutura de diretórios necessária já se encontre criada antes da compilação.

    <target name="test-prepare" depends="compile">
        <mkdir dir="${test.classes.dir}"/>
        <mkdir dir="${test.reports.dir}"/>
        <copy todir="${test.classes.dir}">
            <fileset dir="${test.resources.dir}" erroronmissingdir="false"/>
        </copy>
    </target>       
    
    <target name="test-compile" depends="test-prepare" description="Compile test sources">
        <javac srcdir="${test.src.dir}" destdir="${test.classes.dir}" includeantruntime="false"
               release="${java.release}" encoding="${encoding}">
            <classpath refid="test.compile.classpath"/>
            <compilerarg value="-Xlint:deprecation"/>
            <compilerarg value="-Xlint:unchecked"/>
        </javac>
    </target>

Por fim, foi criada a *target* para a execução dos testes:

    <target name="test" depends="test-compile" description="Run unit tests (JUnit 5)">
        <junitlauncher haltonfailure="true">
            <classpath refid="test.runtime.classpath"/>
            <listener type="legacy-xml" sendSysOut="true" sendSysErr="true"/>
            <testclasses outputdir="${test.reports.dir}">
                <fileset dir="${test.classes.dir}">
                    <include name="${test.includes}"/>
                    <exclude name="${test.excludes}"/>
                </fileset>
            </testclasses>
        </junitlauncher>
    </target>

Analisando-a é de extrema importância sublinhar alguns detalhes:

1. Utilização do elemento ***<junitlauncher>***, responsável por executar os testes unitários utilizando o ***JUnit 5***.
2. Implementação do ***<listener>***, utilizado para gerar relatórios em formato XML, contendo informações detalhadas sobre a execução dos testes.

De notar, que, que tal como referido na solução em *Gradle* do mesmo *issue*, para a execução dos testes é necessário uma máquina com ambiente gráfico e por isso, excecionalmente, a validação do mesmo foi feita numa máquina *Windows*:

    C:\Shared\cogsi2526-1240444-1211426-1211689\CA2\Part1\gradle_basic_demo-main>ant test
    Buildfile: C:\Shared\cogsi2526-1240444-1211426-1211689\CA2\Part1\gradle_basic_demo-main\build.xml

    deps:
    [ivy:resolve] :: Apache Ivy 2.5.2 - 20230817170011 :: https://ant.apache.org/ivy/ ::
    [ivy:resolve] :: loading settings :: url = jar:file:/C:/Shared/cogsi2526-1240444-1211426-1211689/CA2/Part1/gradle_basic_demo-main/ant-lib/ivy-2.5.2.jar!/org/apache/ivy/core/settings/ivysettings.xml
    [ivy:resolve] :: resolving dependencies :: me#gradle_basic_demo;working@NunoCunha
    [ivy:resolve]   confs: [compile, runtime, test]
    [ivy:resolve]   found org.apache.logging.log4j#log4j-api;2.24.1 in public
    [ivy:resolve]   found org.apache.logging.log4j#log4j-core;2.24.1 in public
    [ivy:resolve]   found org.junit.jupiter#junit-jupiter-api;5.10.0 in public
    [ivy:resolve]   found org.opentest4j#opentest4j;1.3.0 in public
    [ivy:resolve]   found org.junit.platform#junit-platform-commons;1.10.0 in public
    [ivy:resolve]   found org.apiguardian#apiguardian-api;1.1.2 in public
    [ivy:resolve]   found org.junit.jupiter#junit-jupiter-engine;5.10.0 in public
    [ivy:resolve]   found org.junit.platform#junit-platform-engine;1.10.0 in public
    [ivy:resolve]   found org.junit.platform#junit-platform-launcher;1.10.0 in public
    [ivy:resolve] :: resolution report :: resolve 268ms :: artifacts dl 11ms
            ---------------------------------------------------------------------
            |                  |            modules            ||   artifacts   |
            |       conf       | number| search|dwnlded|evicted|| number|dwnlded|
            ---------------------------------------------------------------------
            |      compile     |   1   |   0   |   0   |   0   ||   1   |   0   |
            |      runtime     |   2   |   0   |   0   |   0   ||   2   |   0   |
            |       test       |   9   |   0   |   0   |   0   ||   9   |   0   |
            ---------------------------------------------------------------------
    [ivy:retrieve] :: retrieving :: me#gradle_basic_demo [sync]
    [ivy:retrieve]  confs: [compile, runtime, test]
    [ivy:retrieve]  0 artifacts copied, 9 already retrieved (0kB/10ms)

    prepare:
        [mkdir] Created dir: C:\Shared\cogsi2526-1240444-1211426-1211689\CA2\Part1\gradle_basic_demo-main\ant-build\classes
        [mkdir] Created dir: C:\Shared\cogsi2526-1240444-1211426-1211689\CA2\Part1\gradle_basic_demo-main\ant-build\jar
        [mkdir] Created dir: C:\Shared\cogsi2526-1240444-1211426-1211689\CA2\Part1\gradle_basic_demo-main\ant-build\dist

    resources:
         [copy] Copying 1 file to C:\Shared\cogsi2526-1240444-1211426-1211689\CA2\Part1\gradle_basic_demo-main\ant-build\classes

    compile:
        [javac] Compiling 5 source files to C:\Shared\cogsi2526-1240444-1211426-1211689\CA2\Part1\gradle_basic_demo-main\ant-build\classes
        [javac] Note: Annotation processing is enabled because one or more processors were found
        [javac]   on the class path. A future release of javac may disable annotation processing
        [javac]   unless at least one processor is specified by name (-processor), or a search
        [javac]   path is specified (--processor-path, --processor-module-path), or annotation
        [javac]   processing is enabled explicitly (-proc:only, -proc:full).
        [javac]   Use -Xlint:-options to suppress this message.
        [javac]   Use -proc:none to disable annotation processing.

    test-prepare:
        [mkdir] Created dir: C:\Shared\cogsi2526-1240444-1211426-1211689\CA2\Part1\gradle_basic_demo-main\ant-build\test-classes
        [mkdir] Created dir: C:\Shared\cogsi2526-1240444-1211426-1211689\CA2\Part1\gradle_basic_demo-main\ant-build\test-reports

    test-compile:
        [javac] Compiling 1 source file to C:\Shared\cogsi2526-1240444-1211426-1211689\CA2\Part1\gradle_basic_demo-main\ant-build\test-classes
        [javac] Note: Annotation processing is enabled because one or more processors were found
        [javac]   on the class path. A future release of javac may disable annotation processing
        [javac]   unless at least one processor is specified by name (-processor), or a search
        [javac]   path is specified (--processor-path, --processor-module-path), or annotation
        [javac]   processing is enabled explicitly (-proc:only, -proc:full).
        [javac]   Use -Xlint:-options to suppress this message.
        [javac]   Use -proc:none to disable annotation processing.

    test:
    [junitlauncher] Running basic_demo.ChatClientTest

    BUILD SUCCESSFUL
    Total time: 1 second

Como podemos ver, o *build* dos testes é bem sucedido, faltando apenas validar os resultados no *report* criado:

    <testsuite name="basic_demo.ChatClientTest" time="0.252" timestamp="2025-10-19T14:39:28" tests="1" failures="0" skipped="0" aborted="0">
        <properties>
        (*Output* abreviado)
        </properties>
        <testcase classname="basic_demo.ChatClientTest" name="testChatClientCreation()" time="0.191"/>
    </testsuite>

Como é possível ver tanto o *build* como o resultado dos testes é o esperado.

### Issue 27 (Ant) — Adicionar alvo zipBackup (depende de backup)

Objetivo: criar um ficheiro `backup.zip` a partir da pasta `backup/`, garantindo antes a cópia de `src/` para `backup/`.

Alterações no `build.xml` (adicionadas):

        <!-- Propriedade para a pasta de backup -->
        <property name="backup.dir" value="backup"/>

        <!-- Copia src/ para backup/ -->
        <target name="backup" description="Copy sources to backup/ folder">
            <mkdir dir="${backup.dir}"/>
            <copy todir="${backup.dir}">
                <fileset dir="src"/>
            </copy>
        </target>

        <!-- Cria backup.zip a partir de backup/ -->
        <target name="zipBackup" depends="backup" description="Create backup.zip from backup/ folder">
            <delete file="backup.zip" quiet="true"/>
            <zip destfile="backup.zip" basedir="${backup.dir}"/>
        </target>


Explicação:

- A propriedade `backup.dir` centraliza o caminho da diretoria de cópia de segurança, facilitando manutenção e reutilização noutros alvos.
- O alvo `backup` garante que a pasta de destino existe (`<mkdir>`) e copia recursivamente todo o conteúdo de `src/` para `${backup.dir}` com preservação da estrutura de diretórios (`<copy>` + `<fileset>`). Este passo cria uma “cópia congelada” dos fontes sobre a qual o ZIP será construído.
- O alvo `zipBackup` declara `depends="backup"`, assegurando a ordem correta: primeiro cria-se a cópia, depois arquiva-se. Antes de gerar o novo arquivo, `<delete quiet="true">` remove um `backup.zip` antigo para evitar artefactos obsoletos e assegurar reprodutibilidade.
- Por fim, `<zip destfile="backup.zip" basedir="${backup.dir}">` empacota todo o conteúdo da cópia (e não diretamente `src/`), espelhando a intenção de arquivar o snapshot produzido pelo alvo `backup`.

Execução :

![Execução da task zipBackup](img/zip/Ant/zipBackup.png)


Resultado esperado:

- Pasta `backup/` contendo cópia de `src/`.
- Artefacto `backup.zip` na raiz do projeto.

## Issue 28 (Ant) - Explain Gradle Wrapper and JDK Toolchain

Objetivo: explicar como reproduzimos, no Ant, a ideia do Gradle Wrapper (fixar a versão da ferramenta) e da Java Toolchain (garantir a versão de Java), para builds reprodutíveis entre máquinas.

O que foi feito no `build.xml` da Parte 1:

- "Toolchain" Java (versão-alvo 17)
    - Centralizámos a versão no ficheiro `build.properties` através de `java.release=17`.
    - O alvo `compile` usa `<javac ... release="${java.release}">`, garantindo que o bytecode é produzido para Java 17, independentemente da versão de JDK instalada (desde que o JDK em uso suporte `--release 17`).
    - Criámos um alvo utilitário `javaToolchain` que imprime ambiente e versões (JVM, Ant, `JAVA_HOME`, `javac -version`, `java -version`) para validar a configuração ativa.

    ```
    <target name="javaToolchain" description="Prints Java and Ant environment info">
        <echo>Java version (java.version): ${ant.java.version}</echo>
        <echo>JAVA_HOME: ${env.JAVA_HOME}</echo>
        <echo>javac -version:</echo>
        <exec executable="javac" failonerror="false">
            <arg value="-version"/>
        </exec>
        <echo>java -version:</echo>
        <exec executable="java" failonerror="false">
            <arg value="-version"/>
        </exec>
        <echo>Ant version: ${ant.version}</echo>
        <echo>java.home (runtime): ${java.home}</echo>
        <echo>user.home: ${user.home}</echo>
    </target>
    ```

- "Wrapper" de Ant (pinar a versão do Ant e re-executar o alvo)
    - Adicionámos propriedades para uma versão fixa de Ant (`wrapper.ant.version=1.10.15`) e URLs de download.
    - O alvo `wrapper-prepare` faz o download do Ant para `.ant/wrapper/` e extrai o ZIP localmente.
    - O alvo `wrapper-download-fallback` tenta um URL alternativo se o primário falhar.
    - O alvo `wrapper` re-executa o build atual com a versão de Ant descarregada, passando um alvo a executar via `-DwrappedTarget=<alvo>`.
    - Resultado: mesmo sem Ant instalado globalmente (ou com versões diferentes), conseguimos usar a versão definida pelo projeto.

- Dependências automáticas (Ivy)
    - No alvo `deps`, se o Ivy não existir é descarregado para `ant-lib/` e só depois é carregado.
    - Assim não precisamos instalar nada à mão e os JARs das bibliotecas vão sempre para `libs/` da mesma forma em qualquer máquina.

Como usar (exemplos rápidos):

```bash
# Ver o ambiente Java/Ant que está a ser usado
ant -q javaToolchain
```
  ![Saída do ant -q javaToolchain](img/gradle_wrapper&jdk_toolchain/Ant/javatoolchain.png)

- `-q` (quiet): reduz o output do Ant, mostrando apenas o essencial.

```bash
# Reexecutar o build com a versão de Ant "pinada" (wrapper)
ant wrapper -DwrappedTarget=clean-build

```
 ![Wrapper (parte 1)](img/gradle_wrapper&jdk_toolchain/Ant/antWrapper1.png)

    ![Wrapper (parte 2)](img/gradle_wrapper&jdk_toolchain/Ant/antWrapper2.png)

 `-DwrappedTarget=clean-build`: diz ao alvo `wrapper` qual o alvo do teu projeto a executar com a versão de Ant (a que o wrapper acabou de descarregar). O `wrapper` faz dois passos: (1) descarrega/ativa o Ant; (2) volta a invocar o Ant a apontar para o mesmo `build.xml` e corre exatamente o alvo indicado (neste caso, `clean-build`). 

Benefícios alcançados:

- Consistência: a versão do Ant e o nível de Java alvo (17) são controlados pelo projeto.
- Reprodutibilidade: qualquer membro da equipa obtém o mesmo resultado de build, sem passos manuais prévios.
- Portabilidade: o Ivy é descarregado automaticamente; não é preciso pré-instalar Ivy ou manter `ant-lib/` no repositório.

## Issue 32 (Ant) - Custom target deployToDev

Objetivo: replicar em Ant a pipeline local de deployment (DEV) com quatro passos encadeados:

- Delete: limpar a pasta de destino (`build/deployment/dev`).
- Copy: copiar o JAR principal da aplicação para `build/deployment/dev`.
- Copy: copiar as dependências de runtime (JARs) para `build/deployment/dev/lib`.
- Copy + ReplaceTokens: copiar ficheiros `*.properties` filtrando tokens (`@projectVersion@`, `@buildTimestamp@`).

Exemplo (trecho do `build.xml` — nomes de propriedades podem variar consoante o teu ficheiro):

        <!-- Diretórios de deployment -->
        <property name="deploy.env" value="dev"/>
        <property name="deploy.base" value="build/deployment"/>
        <property name="deploy.dir" value="${deploy.base}/${deploy.env}"/>
        <property name="deploy.lib.dir" value="${deploy.dir}/lib"/>

        <!-- Target de deployment para DEV -->
        <target name="deployToDev" depends="jar, resolve" description="Deploy local (DEV)">
            <!-- 1) Limpar destino -->
            <delete dir="${deploy.dir}" quiet="true"/>
            <mkdir dir="${deploy.lib.dir}"/>

            <!-- 2) Copiar JAR da aplicação -->
            <copy file="${dist.dir}/${app.jar.name}" tofile="${deploy.dir}/${app.jar.name}"/>

            <!-- 3) Copiar dependências de runtime para lib/ -->
            <copy todir="${deploy.lib.dir}">
                <fileset dir="${libs.dir}">
                    <include name="**/*.jar"/>
                </fileset>
            </copy>

            <!-- 4) Copiar configs com substituição de tokens -->
            <copy todir="${deploy.dir}">
                <fileset dir="${resources.dir}">
                    <include name="*.properties"/>
                </fileset>
                <filterchain>
                    <replacetokens beginToken="@" endToken="@">
                        <token key="projectVersion" value="${project.version}"/>
                        <token key="buildTimestamp" value="${timestamp}"/>
                    </replacetokens>
                </filterchain>
            </copy>
        </target>


Comando de Execução :

        ant deployToDev

Resultado esperado:

- o JAR da aplicação em `build/deployment/dev` (ex.: `payroll.jar`);
- a pasta `lib/` com os JARs de runtime (Spring Boot, Spring, Hibernate, Tomcat, H2, logging, etc.);
- se configurado, os `.properties` no destino sem tokens em claro (após substituição).

## Issue 33 (Ant) - Create a custom task that depends on installDist and runs the generated distribution scripts

Este *issue* tem como objetivo demonstrar que a execução completa (compilar + executar) pode ser feita com Ant e que o resultado funcional final é equivalente ao obtido com Gradle.

### Descrição da tarefa

- Criar um alvo `runApp` no `build.xml` que dependa dos alvos de compilação (`compile` / `jar`) e que utilize a task `<java>` para executar a classe principal da aplicação.
- Garantir que o classpath usado pela task `<java>` inclui as classes compiladas e as dependências resolvidas (via Ivy ou jars locais em `lib/`).

Código adicionado ao `build.xml`:

    <target name="compile" depends="init, resolve" description="--> Compiles the Java source code">
        <javac srcdir="${src.dir}"
            destdir="${build.classes.dir}"
            classpathref="compile.classpath"
            includeantruntime="false"
            source="${java.source.version}"
            target="${java.target.version}" />
        <!-- Copies resources (e.g., application.properties) to the classes folder -->
        <copy todir="${build.classes.dir}" failonerror="false">
            <fileset dir="${resources.dir}" erroronmissingdir="false" />
        </copy>
    </target>

    <!-- Target to run the application -->
    <target name="runApp" depends="jar" description="--> Executes the Spring Boot application">
        <java classname="${main.class}" fork="true">
            <classpath>
                <pathelement location="${jar.file}" />
                <path refid="compile.classpath" />
            </classpath>
        </java>
    </target>

### O que foi feito e porquê (resolução do problema)

1. Foi implementado o alvo `runApp` no `build.xml` para que a aplicação possa ser compilada e executada com Ant, sem depender do wrapper do Gradle.

2. A task `<java>` foi usada com `fork=true` para isolar o processo da VM de execução do Ant, garantindo comportamento semelhante ao do Gradle/JavaExec. O classpath foi explicitamente configurado para incluir as classes produzidas por `<javac>` e as bibliotecas em `lib/` (obtidas através da target `deps` que usa Ivy), garantindo que todas as dependências necessárias estão presentes em tempo de execução.

3. Esta solução replica por etapas a lógica do Gradle (`build` seguido de `runApp`) com alvos Ant: `deps` -> `compile` -> `runApp`. A ordenação explícita de dependências entre alvos assegura que a compilação e a resolução de dependências ocorrem antes da execução.

4. Validação: o output observado ao executar `ant runApp` foi equivalente ao obtido com `./gradlew runApp` do ponto de vista funcional, confirmando que a aplicação inicia corretamente e está operacional.

Conclusão: A implementação do alvo `runApp` em Ant fornece uma alternativa válida ao uso do Gradle para compilar e executar a aplicação. A abordagem é explícita (mais verbosa) mas reproduz o mesmo comportamento e output.

## Issue 34 (Ant) - Gerar Javadoc e compactar em ZIP (`javadoc` e `zipJavadoc`)

Esta secção documenta os alvos Ant responsáveis pela geração da documentação Javadoc e pela criação de um ficheiro ZIP contendo essa documentação. Os targets documentados no `build.xml` são `javadoc` e `zipJavadoc`.

### Descrição da tarefa

- `javadoc`: gera a documentação Javadoc a partir do código fonte Java (`app/src/main/java`) para a pasta `${build.dir}/docs/javadoc`.
- `zipJavadoc`: depende de `javadoc` e cria um ficheiro ZIP (`${build.dir}/docs/${app.name}-javadoc-${app.version}.zip`) com o conteúdo gerado.

Código adicionado ao `build.xml`:

    <!-- Target to generate Javadoc documentation -->
    <target name="javadoc" depends="compile" description="--> Generates Javadoc documentation">
        <javadoc destdir="${javadoc.dir}"
            author="true"
            version="true"
            use="true"
            windowtitle="${app.name} Javadoc"
            access="package"> <!-- Equivalent to JavadocMemberLevel.PACKAGE -->

            <sourcepath>
                <pathelement location="${src.dir}" />
            </sourcepath>
            <classpath refid="compile.classpath" />
        </javadoc>
    </target>

    <!-- Target to create a ZIP of the Javadoc documentation -->
    <target name="zipJavadoc" depends="javadoc"
        description="--> Compresses the Javadoc into a ZIP file">
        <zip destfile="${javadoc.zip.file}" basedir="${javadoc.dir}" />
        <echo message="Javadoc ZIP created at: ${javadoc.zip.file}" />
    </target>

### O que foi feito e porquê (resolução do problema)

1. O alvo `javadoc` foi adicionado para criar documentação API automaticamente a partir do código-fonte.

2. O `javadoc` usa explicitamente o `sourcepath` e o `classpath` (referência `compile.classpath`) para assegurar que as classes relacionadas e dependências estão acessíveis durante a geração da documentação.

3. O alvo `zipJavadoc` garante que a documentação gerada é empacotada num único artefacto ZIP colocável (`${javadoc.zip.file}`).

4. Validação: ao correr `ant zipJavadoc` (ou `ant javadoc` seguido de `ant zipJavadoc`) verificou-se que:

    - O directório `${build.dir}/docs/javadoc` foi criado e contém os ficheiros HTML da documentação.
    - O ficheiro ZIP foi criado em `${build.dir}/docs/${app.name}-javadoc-${app.version}.zip` e contém a árvore de documentação.

Comandos de verificação recomendados:

```bash
ant zipJavadoc
ls -la build/docs
unzip -l build/docs/${app.name}-javadoc-${app.version}.zip
```

Conclusão: Apesar de exigir maior configuração e verbosidade, os alvos `javadoc` e `zipJavadoc` proporcionam um fluxo simples e repetível para gerar e empacotar a documentação do projecto usando Ant.

## Issue 35 (Ant) - Criar *Source Set* para testes de integração

Neste caso, o ***Ant*** não têm nenhuma ferramenta nativa que seja equivalente ao *Source Set* que encontramos em *Gradle*. Contudo, a execução dos testes de integração é possível, utilizando ferramentas de ordenação de tarefas.

Antes da execução dos testes de integração foi necessário implementar um *target* que executasse os testes unitários, este processo foi bastante semelhante ao descrito no *Issue* 25. Posto isto, irá ser documentado apenas a implementação das ferramentas para executar e ordenar os testes de integração.

Para se executar os testes de implementação, tal como nos testes unitários, foi necessário acrescentar variáveis ao ficheiro de propriedades, dependências ao ficheiro ***ivy.xml*** e *targets* ao ficheiro ***build.xml***.

1. Variáveis adicionadas ao ficheiro de propriedades:

         ===== Integration Tests =====
        integrationTest.src.dir = app/src/integrationTest/java
        integrationTest.resources.dir = app/src/integrationTest/resources
        integrationTest.classes.dir = ${build.dir}/integrationTest-classes
        integrationTest.reports.dir = ${build.dir}/integrationTest-reports
        integrationTest.includes = **/*IT.class
        integrationTest.excludes =

2. Dependências adicionadas ao ficheiro ***ivy.xml***:

        <dependencies>
            <dependency org="org.springframework.boot" name="spring-boot-starter-web" rev="3.2.5"/>
            <dependency org="org.springframework.boot" name="spring-boot-starter-data-jpa" rev="3.2.5"/>
            <dependency org="org.springframework.boot" name="spring-boot-starter-hateoas" rev="3.2.5"/>
            <dependency org="com.google.guava" name="guava" rev="32.1.2-jre"/>
            <dependency org="com.h2database" name="h2" rev="2.2.224" conf="default->master,runtime"/>
            <dependency org="org.springframework.boot" name="spring-boot-starter-test" rev="3.2.5" conf="default->master,runtime"/>
            <dependency org="org.junit.platform" name="junit-platform-launcher" rev="1.10.0" conf="test->default"/>
        </dependencies>

3. *Targets* adicionados ao ficheiro ***build.xml***

        <path id="integrationTest.runtime.classpath">
            <pathelement location="${integrationTest.classes.dir}"/>
            <pathelement location="${classes.dir}"/>
            <path refid="compile.classpath"/>
        </path>

        -------------------------------------------------------------------------

        <target name="integrationTest-prepare" depends="compile">
            <mkdir dir="${integrationTest.classes.dir}"/>
            <mkdir dir="${integrationTest.reports.dir}"/>

            <copy todir="${integrationTest.classes.dir}" failonerror="false">
                <fileset dir="${integrationTest.resources.dir}" erroronmissingdir="false"/>
            </copy>
        </target>

        <target name="integrationTest-compile" depends="integrationTest-prepare" description="Compile test sources">
            <javac srcdir="${integrationTest.src.dir}"
                   destdir="${integrationTest.classes.dir}"
                   includeantruntime="false"
                   release="${java.source.version}"
                   encoding="${encoding}">
                <classpath refid="test.compile.classpath"/>
                <compilerarg value="-Xlint:deprecation"/>
                <compilerarg value="-Xlint:unchecked"/>
            </javac>
        </target>

        -------------------------------------------------------------------------

        <target name="integrationTest" depends="integrationTest-compile, test" description="Run unit tests (JUnit 5)">
            <mkdir dir="${integrationTest.reports.dir}"/>
            <junitlauncher haltonfailure="true">
                <classpath refid="integrationTest.runtime.classpath"/>
                <listener type="legacy-xml" sendSysOut="true" sendSysErr="true"/>
                <testclasses outputdir="${integrationTest.reports.dir}">
                    <fileset dir="${integrationTest.classes.dir}">
                        <include name="${integrationTest.includes}"/>
                        <exclude name="${integrationTest.excludes}"/>
                    </fileset>
                </testclasses>
            </junitlauncher>
        </target>
    
O primeiro bloco define o classpath dos testes de integração, incluindo as classes de teste, as classes da aplicação e as dependências externas.
O segundo prepara o ambiente, criando as pastas necessárias e compilando o código dos testes.
Por fim, o último *target* executa os testes de integração, gerando os relatórios de resultados.

Posto isto, resta validar se os testes são compilados corretamente, executados na ordem certa e se têm um resultado positivo.

            ---------------------------------------------------------------------
            |                  |            modules            ||   artifacts   |
            |       conf       | number| search|dwnlded|evicted|| number|dwnlded|
            ---------------------------------------------------------------------
            |      default     |  121  |   0   |   0   |   22  ||  107  |   0   |
            |       test       |  123  |   0   |   0   |   23  ||  108  |   0   |
            ---------------------------------------------------------------------
    [ivy:retrieve] :: retrieving :: com.example#payroll
    [ivy:retrieve]  confs: [default, test]
    [ivy:retrieve]  108 artifacts copied, 0 already retrieved (65429kB/979ms)

    compile:
        [javac] Compiling 15 source files to /mnt/hgfs/Shared/cogsi2526-1240444-1211426-1211689/CA2/Part2/build/classes
        [javac] warning: [options] system modules path not set in conjunction with -source 17
        [javac] 1 warning

    integrationTest-prepare:
        [mkdir] Created dir: /mnt/hgfs/Shared/cogsi2526-1240444-1211426-1211689/CA2/Part2/build/integrationTest-classes
        [mkdir] Created dir: /mnt/hgfs/Shared/cogsi2526-1240444-1211426-1211689/CA2/Part2/build/integrationTest-reports

    integrationTest-compile:
        [javac] Compiling 2 source files to /mnt/hgfs/Shared/cogsi2526-1240444-1211426-1211689/CA2/Part2/build/integrationTest-classes

    test-prepare:
        [mkdir] Created dir: /mnt/hgfs/Shared/cogsi2526-1240444-1211426-1211689/CA2/Part2/build/test-classes
        [mkdir] Created dir: /mnt/hgfs/Shared/cogsi2526-1240444-1211426-1211689/CA2/Part2/build/test-reports

    test-compile:
        [javac] Compiling 2 source files to /mnt/hgfs/Shared/cogsi2526-1240444-1211426-1211689/CA2/Part2/build/test-classes

    test:
    [junitlauncher] Running payroll.EmployeeTest
    [junitlauncher] Running payroll.OrderTest

    integrationTest:
    [junitlauncher] Running payroll.EmployeeRepositoryIT
    OpenJDK 64-Bit Server VM warning: Sharing is only supported for boot loader classes because bootstrap classpath has been appended
    [junitlauncher] Running payroll.OrderRepositoryIT

    BUILD SUCCESSFUL
    Total time: 21 seconds
    2025-10-19T17:56:15.344Z  INFO 31318 --- [ionShutdownHook] j.LocalContainerEntityManagerFactoryBean : Closing JPA EntityManagerFactory for persistence unit 'default'
    Hibernate: drop table if exists customer_order cascade 
    Hibernate: drop table if exists employee cascade 
    Hibernate: drop sequence if exists customer_order_seq
    Hibernate: drop sequence if exists employee_seq

Como podemos ver, os testes são compilados com sucesso e executam na ordem que é suposto. 

**NOTA**: Os avisos mostrados são apenas informativos: o primeiro indica que estamos a executar testes que iniciam uma aplicação *Spring Boot* dentro da JVM. O segundo informa que o contexto dos testes está a ser encerrado e que todos os recursos estão a ser limpos.

Verificando a compilação e ordenação dos testes resta apenas validar o seu resultado através dos reports gerados.

    <testsuite name="payroll.OrderRepositoryIT" time="0.034" timestamp="2025-10-19T17:56:13" tests="1" failures="0" skipped="0" aborted="0">

    <testsuite name="payroll.EmployeeRepositoryIT" time="6.456" timestamp="2025-10-19T17:56:10" tests="1" failures="0" skipped="0" aborted="0">

Como podemos, ver os testes obtiveram um resultado positivo, garantindo assim o objetivo do *issue*, apesar de em *Ant* não existir algo equivalente a *Source Sets*.



# Technical Report CA03

## Issue 37 - Create Vagrant VM and automate dependency installation using provisioning script

Para a implementação do *Vagrant* é necessário instalar o mesmo na máquina onde estará presente o *Hypervisor* que vai hospedar as VM's criadas. É de notar a importâncias dos seguintes factos:

1. O *Hypervisor* escolhido foi o *VMware*, dado que um elemento do grupo utiliza um *Macbook* cujo processador não é *Intel*.
2. A documentação criada para a solução do *Issue 37* foi feita com recurso ao *WSL*, dado que até ao momento foi utilizada uma máquina *Ubuntu Server* que não têm ambiente gráfico. Posto isto, apenas os comandos relacionados com *Vagrant* serão corridos via *PowerShell* dado que não existem diferenças entre *Windows* e *Ubuntu*.

Dado que irá ser utilizado o *VMware* foi também instalado o *plugin* do *VMware* através do comando ***vagrant plugin install vagrant-vmware-desktop***, bem como, o pacote com as ferramentas extra necessárias para o funcionamento do mesmo. Tendo o *vagrant* já instalado, foi criada uma pasta para a parte 1 do CA3 e na mesma executado o comando ***vagrant init***, criando assim um ***vagrantfile*** onde serão feitas as configurações. No código, mostrado a seguir, foram colocados as alterações feitas ao ficheiro *vagrant*:

    Vagrant.configure("2") do |config|
      config.vm.box = "bento/ubuntu-22.04"
      config.vm.synced_folder ".", "/vagrant"
      config.vm.provision "shell", path: "provision.sh"
    end
    
Podemos afirmar o seguinte:

1. A VM utiliza a *box* "*bento/ubuntu-22.04*".
2. A pasta partilhada de ambos, no host, será colocada no diretório onde o comando ***vagrant up*** for corrido.
3. O *provision* da máquina é feito através de um *script* com o mesmo nome colocado no diretório do ***vagrantfile***. Sendo assim, este fica mais limpo e legível e podemos editar o *script* conforme for necess+ario.

    #!/bin/bash
    
    #Install necessary packages and after show the version for validation
    sudo apt-get update -y
    sudo apt-get install -y git default-jdk maven gradle
    java -version
    javac -version
    mvn -v
    gradle -v

Posto isto, em jeito de validação, observou-se o output gerado pela criação da máquina, para validar se as ferramentas foram instaladas e utilizou-se o comando ***vagrant ssh*** para estabelecer uma ligação SSH à máquina para perceber se a mesma estava operacional.

Verificação da instalação dos programas:

    default: openjdk version "11.0.28" 2025-07-15
    default: OpenJDK Runtime Environment (build 11.0.28+6-post-Ubuntu-1ubuntu122.04.1)
    default: OpenJDK 64-Bit Server VM (build 11.0.28+6-post-Ubuntu-1ubuntu122.04.1, mixed mode, sharing)
    default: javac 11.0.28
    default: Apache Maven 3.6.3
    default: Maven home: /usr/share/maven
    default: Java version: 11.0.28, vendor: Ubuntu, runtime: /usr/lib/jvm/java-11-openjdk-amd64
    default: Default locale: en_US, platform encoding: UTF-8
    default: OS name: "linux", version: "5.15.0-160-generic", arch: "amd64", family: "unix"
    default: WARNING: An illegal reflective access operation has occurred
    default: WARNING: Illegal reflective access by org.codehaus.groovy.reflection.CachedClass (file:/usr/share/java/groovy-all.jar) to method java.lang.Object.finalize()
    default: WARNING: Please consider reporting this to the maintainers of org.codehaus.groovy.reflection.CachedClass
    default: WARNING: Use --illegal-access=warn to enable warnings of further illegal reflective access operations
    default: WARNING: All illegal access operations will be denied in a future release
    default:
    default: ------------------------------------------------------------
    default: Gradle 4.4.1
    default: ------------------------------------------------------------
    default:
    default: Build time:   2012-12-21 00:00:00 UTC
    default: Revision:     none
    default:
    default: Groovy:       2.4.21
    default: Ant:          Apache Ant(TM) version 1.10.12 compiled on January 17 1970
    default: JVM:          11.0.28 (Ubuntu 11.0.28+6-post-Ubuntu-1ubuntu122.04.1)
    default: OS:           Linux 5.15.0-160-generic amd64
    default:

Validação do acesso à máquina:

    PS C:\Shared\cogsi2526-1240444-1211426-1211689\CA3\Part1> vagrant ssh
    Welcome to Ubuntu 22.04.5 LTS (GNU/Linux 5.15.0-160-generic x86_64)

     * Documentation:  https://help.ubuntu.com
     * Management:     https://landscape.canonical.com
     * Support:        https://ubuntu.com/pro

     System information as of Wed Oct 29 02:02:02 AM UTC 2025

      System load:  0.19               Processes:             209
      Usage of /:   19.5% of 30.34GB   Users logged in:       0
      Memory usage: 10%                IPv4 address for eth0: 192.168.244.133
      Swap usage:   0%


    This system is built by the Bento project by Chef Software
    More information can be found at https://github.com/chef/bento

    Use of this system is acceptance of the OS vendor EULA and License Agreements.
    Last login: Wed Oct 29 01:52:53 2025 from 192.168.244.2
    vagrant@vagrant:~$

## Issue 38 - Clone Repository and Build Projects

Para se concretizar o objetivo deste *issue* começou-se por tratar da parte da clonagem do repositório. Para isso, foi necessário realizar um *workaround*, pois o ambiente onde foi criada a máquina virtual foi corrida é um ambiente *Windows* e por isso as clonagens de repositórios via SSH náo funcionam de forma totalmente correta. Posto isto, o repositório foi colocado público por breves momentos e o repositório foi clonado via HTTPS para a máquina criada através do ***Vagrant***. Exposta esta situação passa-se a explicar as alterações feitas ao ficheiro ***provision.sh*** para a clonagem do repositório:

    cd /vagrant
    if [ ! -d "cogsi2526-1240444-1211426-1211689" ]; then
      git clone https://github.com/davidsferreira02/cogsi2526-1240444-1211426-1211689.git cogsi2526-1240444-1211426-1211689
    else
      cd cogsi2526-1240444-1211426-1211689
      git pull
    fi

O *if statement* que foi adicionado ao ficheiro tem como objetivo, dentro do diretório *vagrant*, que é a pasta partilhada com o *host*, verificar se já existe um repositório com o nome do nosso. Caso não exista este vai fazer *clone* do projeto a primeira vez, caso já exista um projeto o *script* irá executar um *git pull* para obter a versáo mais atualizada do repositório.

Para validarmos este método, podemos observar o resultado do comando ***vagrant up***, especialmente a parte final, logo a seguir ao *print* das versões dos pacotes instalados.

        default: openjdk version "11.0.28" 2025-07-15
        default: OpenJDK Runtime Environment (build 11.0.28+6-post-Ubuntu-1ubuntu122.04.1)
        default: OpenJDK 64-Bit Server VM (build 11.0.28+6-post-Ubuntu-1ubuntu122.04.1, mixed mode, sharing)
        default: javac 11.0.28
        default: Apache Maven 3.6.3
        default: Maven home: /usr/share/maven
        default: Java version: 11.0.28, vendor: Ubuntu, runtime: /usr/lib/jvm/java-11-openjdk-amd64
        default: Default locale: en_US, platform encoding: UTF-8
        default: OS name: "linux", version: "5.15.0-160-generic", arch: "amd64", family: "unix"
        default: WARNING: An illegal reflective access operation has occurred
        default: WARNING: Illegal reflective access by org.codehaus.groovy.reflection.CachedClass (file:/usr/share/java/groovy-all.jar) to method java.lang.Object.finalize()
        default: WARNING: Please consider reporting this to the maintainers of org.codehaus.groovy.reflection.CachedClass
        default: WARNING: Use --illegal-access=warn to enable warnings of further illegal reflective access operations
        default: WARNING: All illegal access operations will be denied in a future release
        default:
        default: ------------------------------------------------------------
        default: Gradle 4.4.1
        default: ------------------------------------------------------------
        default:
        default: Build time:   2012-12-21 00:00:00 UTC
        default: Revision:     none
        default:
        default: Groovy:       2.4.21
        default: Ant:          Apache Ant(TM) version 1.10.12 compiled on January 17 1970
        default: JVM:          11.0.28 (Ubuntu 11.0.28+6-post-Ubuntu-1ubuntu122.04.1)
        default: OS:           Linux 5.15.0-160-generic amd64
        default:
        default: Cloning into 'cogsi2526-1240444-1211426-1211689'...
    Updating files: 100% (387/387), done.7/387)

**NOTA**: *output* abreviado de forma a focar o output pretendido.

Como podemos ver existe a clonagem do repositório, algo que também pode ser confirmado no interior da máquina virtual, usando o comando ***vagrant ssh*** e navengando na árvore de diretórios e verificarmos a pasta partilhada e validar se a pasta do projeto está presente na mesma, como mostra o seguinte *output*:

    vagrant@vagrant:~$ cd ..
    vagrant@vagrant:/home$ cd ..
    vagrant@vagrant:/$ ls
    bin   cdrom  etc   lib    lib64   lost+found  mnt  proc  run   snap  swap.img  tmp  vagrant
    boot  dev    home  lib32  libx32  media       opt  root  sbin  srv   sys       usr  var
    vagrant@vagrant:/$
    vagrant@vagrant:/$
    vagrant@vagrant:/$ cd vagrant/
    vagrant@vagrant:/vagrant$ ls
    cogsi2526-1240444-1211426-1211689  provision.sh  Vagrantfile
    vagrant@vagrant:/vagrant$ 

Posto isto, é validado também se o *git pull* executa caso o repositório já tenha sido clonado. Isto acontece, como podemos ver o *output* gerado pelo comando ***vagrant up --provision***, que executa novamente o *script* ***provision.sh***:

        default: git is already the newest version (1:2.34.1-1ubuntu1.15).
        default: 0 upgraded, 0 newly installed, 0 to remove and 13 not upgraded.
        default: openjdk version "11.0.28" 2025-07-15
        default: OpenJDK Runtime Environment (build 11.0.28+6-post-Ubuntu-1ubuntu122.04.1)
        default: OpenJDK 64-Bit Server VM (build 11.0.28+6-post-Ubuntu-1ubuntu122.04.1, mixed mode, sharing)
        default: javac 11.0.28
        default: Apache Maven 3.6.3
        default: Maven home: /usr/share/maven
        default: Java version: 11.0.28, vendor: Ubuntu, runtime: /usr/lib/jvm/java-11-openjdk-amd64
        default: Default locale: en_US, platform encoding: UTF-8
        default: OS name: "linux", version: "5.15.0-160-generic", arch: "amd64", family: "unix"
        default: WARNING: An illegal reflective access operation has occurred
        default: WARNING: Illegal reflective access by org.codehaus.groovy.reflection.CachedClass (file:/usr/share/java/groovy-all.jar) to method java.lang.Object.finalize()
        default: WARNING: Please consider reporting this to the maintainers of org.codehaus.groovy.reflection.CachedClass
        default: WARNING: Use --illegal-access=warn to enable warnings of further illegal reflective access operations
        default: WARNING: All illegal access operations will be denied in a future release
        default:
        default: ------------------------------------------------------------
        default: Gradle 4.4.1
        default: ------------------------------------------------------------
        default:
        default: Build time:   2012-12-21 00:00:00 UTC
        default: Revision:     none
        default:
        default: Groovy:       2.4.21
        default: Ant:          Apache Ant(TM) version 1.10.12 compiled on January 17 1970
        default: JVM:          11.0.28 (Ubuntu 11.0.28+6-post-Ubuntu-1ubuntu122.04.1)
        default: OS:           Linux 5.15.0-160-generic amd64
        default:
        default: Already up to date.

Como podemos ver o *git pull* é executado como podemos ver na última linha do *output* acima.

De seguida, foram adicionadas as seguintes linhas ao ficheiro ***provision.sh*** para fazer *build* aos projetos:

    sudo apt install -y xvfb
    git switch VagrantRepoInstall

    cd /vagrant/cogsi2526-1240444-1211426-1211689/CA2/Part1/gradle_basic_demo-main
    xvfb-run ./gradlew build

    cd /vagrant/cogsi2526-1240444-1211426-1211689/CA2/Part2
    ./gradlew bootJar

**NOTA**: O comando *git switch VagrantRepoInstall* foi usado, porque neste caso esse foi o *branch* onde solução foi desenvolida. Cada issue terá o seu nome neste comando.

A primeira linha é para instalar a ferramenta ***xvfb***, esta foi feita especificamente para ambientes *linux* e serve para executar operações gráficas em memória virtual permitindo, neste caso, executar os testes sem a necessidade de um ambiente gráfico. De notar ainda, que a *flag* ***-y*** serve para aceitar todos os *prompts* de autorização que possam aparecer durante a instalação do mesmo. De seguida, navegou-se pela árvore de diretórios até chegarmos ao ficheiro *build.gradle* de ambos os projetos e foi foram feitos os *builds* de ambos.

Para validarmos o resultado, fez-se o *commit* destas alterações e executou-se o comando ***vagrant up --provision***, este executa apenas o *script* construído de forma. Sendo o resultado o seguinte *output*:

    default: xvfb is already the newest version (2:21.1.4-2ubuntu1.7~22.04.16).
    default: 0 upgraded, 0 newly installed, 0 to remove and 13 not upgraded.
    default: Switched to a new branch 'VagrantRepoInstall'
    default: Branch 'VagrantRepoInstall' set up to track remote branch 'VagrantRepoInstall' from 'origin'.
    default: > Task :compileJava UP-TO-DATE
    default: > Task :processResources UP-TO-DATE
    default: > Task :classes UP-TO-DATE
    default: > Task :jar UP-TO-DATE
    default: > Task :startScripts UP-TO-DATE
    default: > Task :distTar UP-TO-DATE
    default: > Task :distZip UP-TO-DATE
    default: > Task :assemble UP-TO-DATE
    default: > Task :compileTestJava
    default: > Task :processTestResources NO-SOURCE
    default: > Task :testClasses
    default: > Task :test
    default: > Task :check
    default: > Task :build
    default:
    default: Deprecated Gradle features were used in this build, making it incompatible with Gradle 9.0.
    default:
    default: You can use '--warning-mode all' to show the individual deprecation warnings and determine if they come from your own scripts or plugins.
    default:
    default: For more on this, please refer to https://docs.gradle.org/8.9/userguide/command_line_interface.html#sec:command_line_warnings in the Gradle documentation.
    default:
    default: BUILD SUCCESSFUL in 2s
    default: 8 actionable tasks: 2 executed, 6 up-to-date
    default: Calculating task graph as configuration cache cannot be reused because the file system entry 'app/build/classes/java/main' has been created.
    default: > Task :app:processResources NO-SOURCE
    default: > Task :app:compileJava UP-TO-DATE
    default: > Task :app:classes UP-TO-DATE
    default: > Task :app:resolveMainClassName UP-TO-DATE
    default: > Task :app:bootJar UP-TO-DATE
    default:
    default: [Incubating] Problems report is available at: file:///vagrant/cogsi2526-1240444-1211426-1211689/CA2/Part2/build/reports/problems/problems-report.html
    default:
    default: Deprecated Gradle features were used in this build, making it incompatible with Gradle 9.0.
    default:
    default: You can use '--warning-mode all' to show the individual deprecation warnings and determine if they come from your own scripts or plugins.
    default:
    default: For more on this, please refer to https://docs.gradle.org/8.14.3/userguide/command_line_interface.html#sec:command_line_warnings in the Gradle documentation.
    default:
    default: BUILD SUCCESSFUL in 1s
    default: 3 actionable tasks: 3 up-to-date
    default: Configuration cache entry stored.

Como podemos observar, ambos os projetos concluem com sucesso o *build*.

## Issue 39 - Access Applications from Host Machine 

Para permitir a interação entre *host* e VM, é necessário alterar o ficheiro ***provision.sh*** para após o *build* colocar-se em execução, na VM, o módulo de servidor. Para isso, adicionaram-se as seguintes linhas ao final do ficheiro:

    cd /vagrant/cogsi2526-1240444-1211426-1211689/CA2/Part1/gradle_basic_demo-main
    ./gradlew runServer

Desta maneira, após os *builds* serem feitos, o módulo do servidor da *app* é colocado em execução.

Para se testar a comunicação entre VM e *host* é necessário colocar em execução, no *host*, o módulo de cliente apontando para o servidor criado na VM. Para isso, entrou-se via SSH na VM criada, através do comando ***vagrant ssh***, de forma a obter o IP da mesma, dado que este foi atribuído de forma dinâmica.

    PS C:\Shared\cogsi2526-1240444-1211426-1211689\CA3\Part1> vagrant ssh
    Welcome to Ubuntu 22.04.5 LTS (GNU/Linux 5.15.0-160-generic x86_64)

     * Documentation:  https://help.ubuntu.com
     * Management:     https://landscape.canonical.com
     * Support:        https://ubuntu.com/pro

     System information as of Sat Nov  1 01:08:23 AM UTC 2025

      System load:  0.31               Processes:             215
      Usage of /:   21.4% of 30.34GB   Users logged in:       0
      Memory usage: 47%                IPv4 address for eth0: 192.168.244.162
      Swap usage:   0%


    This system is built by the Bento project by Chef Software
    More information can be found at https://github.com/chef/bento

    Use of this system is acceptance of the OS vendor EULA and License Agreements.
    vagrant@vagrant:~$

 Como podemos ver no *banner* de *login* o IP da VM é o 192.168.244.162. Sendo assim, alterou-se a *task **runClient*** no ficheiro, ***build.gradle***, passando este IP como paramêtro como podemos ver de seguida:

    task runClient(type:JavaExec, dependsOn: classes){
        group = "DevOps"
        description = "Launches a chat client that connects to a server on localhost:59001 "
    
        classpath = sourceSets.main.runtimeClasspath

        mainClass = 'basic_demo.ChatClientApp'

        args '192.168.244.162', '59001'
    }

De seguida, foi colocado em execução o módulo do servidor na VM e de seguida o módulo do cliente no *host*:

    default: BUILD SUCCESSFUL in 1m 4s
    default: 4 actionable tasks: 4 executed
    default: Configuration cache entry stored.
    default: > Task :compileJava UP-TO-DATE
    default: > Task :processResources UP-TO-DATE
    default: > Task :classes UP-TO-DATE
    default: > Task :jar UP-TO-DATE
    default: > Task :startScripts UP-TO-DATE
    default: > Task :distTar UP-TO-DATE
    default: > Task :distZip UP-TO-DATE
    default: > Task :assemble UP-TO-DATE
    default: > Task :compileTestJava UP-TO-DATE
    default: > Task :processTestResources NO-SOURCE
    default: > Task :testClasses UP-TO-DATE
    default: > Task :test UP-TO-DATE
    default: > Task :check UP-TO-DATE
    default: > Task :build UP-TO-DATE
    default:
    default: > Task :runServer
    default: The chat server is running...
    default: 01:13:13.575 [pool-1-thread-3] INFO  basic_demo.ChatServer.Handler - A new user has joined: John Doe

Para além do *output* acima, que revela que existe uma conexão do utilizador *John Doe*, foi aberta uma janela *pop-up* onde foi pedido um nome como mostra a seguinte imagem:

![Janela Pop-Up com pedido de nome para ChatClient](img/chatclient/ChatClientNamePrompt.png)

Dados estas validações podemos afirmar que a conexão entre VM e *Host* ocorre com sucesso.
