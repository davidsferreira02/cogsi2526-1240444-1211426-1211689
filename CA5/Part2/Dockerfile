# Multi-stage Dockerfile
# Stage 1: Build the application
FROM eclipse-temurin:17-jdk-jammy AS builder
WORKDIR /app

# Copy the gradle project files
COPY CA2/Part2 .

# Build the application
RUN ./gradlew :app:bootJar --no-daemon -x test

# Stage 2: Run the application
FROM eclipse-temurin:17-jre-jammy
WORKDIR /app

# Copy the jar from the builder stage
COPY --from=builder /app/app/build/libs/*.jar app.jar

# Expose the port
EXPOSE 8080

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]
