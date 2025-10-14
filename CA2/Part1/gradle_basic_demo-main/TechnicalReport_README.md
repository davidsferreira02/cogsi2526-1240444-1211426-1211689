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

## Issue 27 - Adicionar task zipBackup (tipo Zip)

Objetivo: Criar um ficheiro `backup.zip` contendo uma cópia da árvore de fontes (`src/`). Para garantir que o conteúdo está atualizado, a nova task deve depender da task `backup` (que copia `src` para a pasta `backup/`).

Implementação adicionada ao `build.gradle`:

```gradle
task backup(type: Copy) {
        from 'src'
        into 'backup'
}

task zipBackup(type: Zip) {
        group = "DevOps"
        description = "Creates a zip archive of the backup directory (depends on backup)"
        dependsOn backup
        from 'backup'
        archiveFileName = 'backup.zip'
        destinationDirectory = file('.')
}
```

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
* Diretoria `backup/`
* Ficheiro `backup.zip`

Imagem de suporte (execução da task):

![Execução da task zipBackup](img/zip/gradlew_backupZip.png)

## Issue 28 - Explicar Gradle Wrapper e JDK Toolchain

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

Execução silenciosa:
```
./gradlew -q javaToolchain
```

Output recolhido (exemplo):
```
Java Toolchain (languageVersion): 17
Current JVM version: 17.0.14
Gradle version: 8.9 (Wrapper governs this)
JAVA_HOME: /Users/<user>/.sdkman/candidates/java/current
```

Análise:
1. O Wrapper (`gradlew`) descarrega / utiliza a distribuição exata de Gradle definida em `gradle/wrapper/gradle-wrapper.properties`, evitando discrepâncias de versões entre máquinas.
2. A *toolchain* declara a versão alvo de Java (17). O Gradle tenta localizar internamente um JDK compatível; quando configurado com *provisioning*, pode mesmo descarregar (dependendo das features usadas).
3. A compilação fica isolada de *overrides* acidentais do `JAVA_HOME` ou de JDKs mais recentes/antigos disponíveis localmente.
4. Em CI/CD basta chamar `./gradlew build`, reduzindo fricção operacional.

![Gradle Wrapper & Toolchain (Parte 1)](img/gradle_wrapper&jdk_toolchain/gradlewOutputPart1.png)
![Gradle Wrapper & Toolchain (Parte 2)](img/gradle_wrapper&jdk_toolchain/gradlewOutputPart2.png)

A combinação Wrapper + Toolchain aumenta reprodutibilidade, reduz *onboarding time* e minimiza falhas introduzidas por ambientes heterogéneos.

