
FROM eclipse-temurin:17-jdk AS build

WORKDIR /src

# Copy Gradle wrapper and settings from CA2/Part2 (used by CA3/Part2)
COPY ../CA2/Part2/gradlew ./
COPY ../CA2/Part2/gradlew.bat ./
COPY ../CA2/Part2/gradle ./gradle
COPY ../CA2/Part2/settings.gradle ./
COPY ../CA2/Part2/gradle.properties ./

# Ensure gradlew is executable
RUN chmod +x ./gradlew

# Pre-fetch dependencies (leverages caching)
RUN ./gradlew --no-daemon tasks > /dev/null || true

# Copy only the app subproject sources and build files
COPY ../CA2/Part2/app ./app

# Build Spring Boot fat jar (skip tests for faster docker builds)
RUN ./gradlew --no-daemon :app:clean :app:bootJar -x test

# Produce a deterministic jar name for the runtime stage
RUN ls -l app/build/libs && cp app/build/libs/*.jar /app.jar

# Runtime stage (slim JRE)
FROM eclipse-temurin:17-jre AS runtime

WORKDIR /app

# Default server port; Spring Boot respects SERVER_PORT env var
ENV SERVER_PORT=8080

# Sensible defaults to run without external H2 server; can be overridden at runtime
ENV SPRING_DATASOURCE_URL=jdbc:h2:mem:payrolldb;DB_CLOSE_DELAY=-1;MODE=LEGACY
ENV SPRING_DATASOURCE_DRIVERCLASSNAME=org.h2.Driver
ENV SPRING_DATASOURCE_USERNAME=sa
ENV SPRING_DATASOURCE_PASSWORD=password
ENV SPRING_JPA_HIBERNATE_DDL_AUTO=update

# Non-root user
RUN useradd -m appuser
USER appuser

# Copy jar from build stage
COPY --from=build /app.jar /app/app.jar

# Expose HTTP port
EXPOSE 8080

# Run Spring Boot app; env vars override application.properties
ENTRYPOINT ["sh", "-c", "exec java -jar /app/app.jar --server.port=${SERVER_PORT:-8080}"]
