
FROM eclipse-temurin:17-jdk AS build
WORKDIR /src/spring
COPY CA2/Part2/ ./
RUN chmod +x ./gradlew \
    && ./gradlew --no-daemon :app:clean :app:bootJar -x test

# Stage 2: Runtime (JRE only)
FROM eclipse-temurin:17-jre AS runtime
WORKDIR /app
ENV SERVER_PORT=8080 \
    SPRING_DATASOURCE_URL=jdbc:h2:mem:payrolldb;DB_CLOSE_DELAY=-1;MODE=LEGACY \
    SPRING_DATASOURCE_DRIVER_CLASS_NAME=org.h2.Driver \
    SPRING_DATASOURCE_USERNAME=sa \
    SPRING_JPA_HIBERNATE_DDL_AUTO=update
COPY --from=build /src/spring/app/build/libs/* /app/
EXPOSE 8080
CMD ["sh", "-c", "exec java -jar $(ls -1 /app/*.jar | grep -v -- '-plain' | tail -n1) --server.port=${SERVER_PORT:-8080}"]
