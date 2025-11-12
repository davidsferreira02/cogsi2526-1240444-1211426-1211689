

# Version 1: Build inside Docker — support clone-in-container mode     


#repo clone stage 
FROM eclipse-temurin:17-jdk AS repo
WORKDIR /src
RUN apt-get update \
	&& apt-get install -y --no-install-recommends git ca-certificates \
	&& rm -rf /var/lib/apt/lists/*


ARG REPO_URL=https://github.com/davidsferreira02/cogsi2526-1240444-1211426-1211689.git
RUN --mount=type=ssh git clone --depth=1 "$REPO_URL" /src/repo


FROM eclipse-temurin:17-jdk AS spring-build-clone
WORKDIR /build
COPY --from=repo /src/repo/CA2/Part2 /build/CA2/Part2
WORKDIR /build/CA2/Part2
RUN chmod +x ./gradlew \
	&& ./gradlew --no-daemon --version > /dev/null || true \
	&& ./gradlew --no-daemon :app:clean :app:bootJar -x test
RUN set -e; \
	ls -l app/build/libs; \
	cp "$(ls -1t app/build/libs/*.jar | grep -v -- '-plain' | head -n1)" /app.jar


# 2) Build Chat server (CA2/Part1/gradle_basic_demo-main) from cloned sources
FROM eclipse-temurin:17-jdk AS chat-build-clone
WORKDIR /build
COPY --from=repo /src/repo/CA2/Part1/gradle_basic_demo-main /build/chat
WORKDIR /build/chat
RUN chmod +x ./gradlew \
	&& ./gradlew --no-daemon clean jar
RUN ls -l build/libs && cp build/libs/*.jar /chat.jar


# 3a) Runtime image for Chat server (optional target)
FROM eclipse-temurin:17-jre AS chat-runtime
WORKDIR /app
ENV CHAT_PORT=59001
RUN useradd -m appuser
USER appuser
COPY --from=chat-build-clone /chat.jar /app/chat.jar
EXPOSE 59001
ENTRYPOINT ["sh", "-c", "exec java -cp /app/chat.jar basic_demo.ChatServerApp ${CHAT_PORT:-59001}"]


# 3b) Runtime image for Spring Boot app (default final image)
FROM eclipse-temurin:17-jre AS spring-runtime-clone
WORKDIR /app
ENV SERVER_PORT=8080
ENV SPRING_DATASOURCE_URL=jdbc:h2:mem:payrolldb;DB_CLOSE_DELAY=-1;MODE=LEGACY
ENV SPRING_DATASOURCE_DRIVER_CLASS_NAME=org.h2.Driver
ENV SPRING_DATASOURCE_USERNAME=sa
ENV SPRING_DATASOURCE_PASSWORD=password
ENV SPRING_JPA_HIBERNATE_DDL_AUTO=update
RUN useradd -m appuser
USER appuser
COPY --from=spring-build-clone /app.jar /app/app.jar
EXPOSE 8080
ENTRYPOINT ["sh", "-c", "exec java -jar /app/app.jar --server.port=${SERVER_PORT:-8080}"]

# 4) Version 2 (copy-only): build on host, then copy JARs into runtime images
# Chat runtime that expects a host-built JAR at CA2/Part1/gradle_basic_demo-main/build/libs/
FROM eclipse-temurin:17-jre AS chat-runtime-copy
WORKDIR /app
ENV CHAT_PORT=59001
RUN useradd -m appuser
# Copy any built jar(s) from host and symlink the newest to /app/chat.jar (run as root)
COPY CA2/Part1/gradle_basic_demo-main/build/libs/*.jar /app/
RUN set -e; \
	jar="$(ls -1t /app/*.jar | head -n1)"; \
	if [ "$jar" != "/app/chat.jar" ]; then ln -sf "$jar" /app/chat.jar; fi; \
	chown -R appuser:appuser /app
USER appuser
EXPOSE 59001
ENTRYPOINT ["sh", "-c", "exec java -cp /app/chat.jar basic_demo.ChatServerApp ${CHAT_PORT:-59001}"]

# Spring runtime that expects a host-built JAR at CA2/Part2/app/build/libs/
FROM eclipse-temurin:17-jre AS spring-runtime-copy
WORKDIR /app
ENV SERVER_PORT=8080
ENV SPRING_DATASOURCE_URL=jdbc:h2:mem:payrolldb;DB_CLOSE_DELAY=-1;MODE=LEGACY
ENV SPRING_DATASOURCE_DRIVER_CLASS_NAME=org.h2.Driver
ENV SPRING_DATASOURCE_USERNAME=sa
ENV SPRING_DATASOURCE_PASSWORD=password
ENV SPRING_JPA_HIBERNATE_DDL_AUTO=update
RUN useradd -m appuser
COPY CA2/Part2/app/build/libs/*.jar /app/
RUN set -e; \
	jar="$(ls -1t /app/*.jar | grep -v -- '-plain' | head -n1)"; \
	if [ "$jar" != "/app/app.jar" ]; then ln -sf "$jar" /app/app.jar; fi; \
	chown -R appuser:appuser /app
USER appuser
EXPOSE 8080
ENTRYPOINT ["sh", "-c", "exec java -jar /app/app.jar --server.port=${SERVER_PORT:-8080}"]

# (Removed non-clone default; Version 1 uses spring-build-clone)
