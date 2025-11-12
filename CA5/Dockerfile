

######################################################################
# Version 1: Build inside Docker — support clone-in-container mode     #
######################################################################

# Optional: repo clone stage (only built if referenced via --target)
FROM eclipse-temurin:17-jdk AS repo
WORKDIR /src
RUN apt-get update \
	&& apt-get install -y --no-install-recommends git ca-certificates \
	&& rm -rf /var/lib/apt/lists/*

# Use BuildKit SSH for private repos (recommended) or make repo public
# Build with: DOCKER_BUILDKIT=1 docker build --ssh default -f CA5/Dockerfile --target spring-runtime-clone -t spring-payroll:clone .
ARG REPO_URL=https://github.com/davidsferreira02/cogsi2526-1240444-1211426-1211689.git
RUN --mount=type=ssh git clone --depth=1 "$REPO_URL" /src/repo


# 1) Build Spring REST app (CA2/Part2/app) using Gradle wrapper inside container
FROM eclipse-temurin:17-jdk AS spring-build
WORKDIR /build

# Bring in only the needed sub-tree from the build context for better cache reuse
COPY CA2/Part2 /build/CA2/Part2

WORKDIR /build/CA2/Part2
RUN chmod +x ./gradlew \
	&& ./gradlew --no-daemon --version > /dev/null || true \
	&& ./gradlew --no-daemon :app:clean :app:bootJar -x test

# Collect the generated Boot fat-jar
RUN set -e; \
	ls -l app/build/libs; \
	cp "$(ls -1t app/build/libs/*.jar | grep -v -- '-plain' | head -n1)" /app.jar

# Alternative builder that consumes the cloned repo (for clone-in-container mode)
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


# 2) Build Chat server (CA2/Part1/gradle_basic_demo-main)
FROM eclipse-temurin:17-jdk AS chat-build
WORKDIR /build

COPY CA2/Part1/gradle_basic_demo-main /build/chat
WORKDIR /build/chat
RUN chmod +x ./gradlew \
	&& ./gradlew --no-daemon --version > /dev/null || true \
	&& ./gradlew --no-daemon clean jar

# Collect chat jar for optional runtime image
RUN ls -l build/libs && cp build/libs/*.jar /chat.jar


# 3a) Runtime image for Chat server (optional target)
FROM eclipse-temurin:17-jre AS chat-runtime
WORKDIR /app
ENV CHAT_PORT=59001
RUN useradd -m appuser
USER appuser
COPY --from=chat-build /chat.jar /app/chat.jar
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

# Default final image (non-clone path)
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

# Non-root user for runtime
RUN useradd -m appuser
USER appuser

# Copy only the built application jar from the builder stage
COPY --from=spring-build /app.jar /app/app.jar

EXPOSE 8080
ENTRYPOINT ["sh", "-c", "exec java -jar /app/app.jar --server.port=${SERVER_PORT:-8080}"]
