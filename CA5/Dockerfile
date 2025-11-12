

# Spring REST app (Building REST services) 


FROM eclipse-temurin:17-jdk AS spring-build

WORKDIR /src

# Copy Gradle wrapper and settings from CA2/Part2 (used by CA3/Part2)
COPY ../CA2/Part2/gradlew ./
COPY ../CA2/Part2/gradlew.bat ./
COPY ../CA2/Part2/gradle ./gradle
COPY ../CA2/Part2/settings.gradle ./
COPY ../CA2/Part2/gradle.properties ./

# Ensure gradlew is executable
RUN chmod +x ./gradlew


RUN ./gradlew --no-daemon tasks > /dev/null || true

# Copy only the app subproject sources and build files
COPY ../CA2/Part2/app ./app

RUN ./gradlew --no-daemon :app:clean :app:bootJar -x test

RUN set -e; \
	ls -l app/build/libs; \
	cp "$(ls -1t app/build/libs/*.jar | grep -v -- '-plain' | head -n1)" /app.jar


# Chat application (server)  #


FROM eclipse-temurin:17-jdk AS chat-build

WORKDIR /src


COPY ../CA2/Part1/gradle_basic_demo-main/gradlew ./
COPY ../CA2/Part1/gradle_basic_demo-main/gradlew.bat ./
COPY ../CA2/Part1/gradle_basic_demo-main/gradle ./gradle
COPY ../CA2/Part1/gradle_basic_demo-main/settings.gradle ./
COPY ../CA2/Part1/gradle_basic_demo-main/build.gradle ./


RUN chmod +x ./gradlew
RUN ./gradlew --no-daemon tasks > /dev/null || true


COPY ../CA2/Part1/gradle_basic_demo-main/src ./src
RUN ./gradlew --no-daemon clean jar


RUN ls -l build/libs && cp build/libs/*.jar /chat.jar

# Runtime stage (slim JRE)
# Runtime stage (Chat server)
FROM eclipse-temurin:17-jre AS chat-runtime

WORKDIR /app

# Default chat server port
ENV CHAT_PORT=59001

# Non-root user
RUN useradd -m appuser
USER appuser

# Copy jar from chat build stage
COPY --from=chat-build /chat.jar /app/chat.jar

# Expose chat port
EXPOSE 59001

# Run Chat server
ENTRYPOINT ["sh", "-c", "exec java -cp /app/chat.jar basic_demo.ChatServerApp ${CHAT_PORT:-59001}"]

# Runtime stage (Spring app)
FROM eclipse-temurin:17-jre AS spring-runtime

WORKDIR /app

# Default server port; Spring Boot respects SERVER_PORT env var
ENV SERVER_PORT=8080

# Sensible defaults to run without external H2 server; can be overridden at runtime
ENV SPRING_DATASOURCE_URL=jdbc:h2:mem:payrolldb;DB_CLOSE_DELAY=-1;MODE=LEGACY
ENV SPRING_DATASOURCE_DRIVER_CLASS_NAME=org.h2.Driver
ENV SPRING_DATASOURCE_USERNAME=sa
ENV SPRING_DATASOURCE_PASSWORD=password
ENV SPRING_JPA_HIBERNATE_DDL_AUTO=update

# Non-root user
RUN useradd -m appuser
USER appuser

# Copy jar from spring build stage
COPY --from=spring-build /app.jar /app/app.jar

# Expose HTTP port
EXPOSE 8080

# Run Spring Boot app; env vars override application.properties
ENTRYPOINT ["sh", "-c", "exec java -jar /app/app.jar --server.port=${SERVER_PORT:-8080}"]
