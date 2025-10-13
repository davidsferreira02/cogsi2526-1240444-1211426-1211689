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

![Resultado dos Testes](img\taskTest.png)

