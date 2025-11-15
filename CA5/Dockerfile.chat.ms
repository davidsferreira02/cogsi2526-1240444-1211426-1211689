
FROM eclipse-temurin:17-jdk AS build
WORKDIR /src/chat
COPY CA2/Part1/gradle_basic_demo-main/ ./
RUN chmod +x ./gradlew \
    && ./gradlew --no-daemon clean jar


FROM eclipse-temurin:17-jre AS runtime
WORKDIR /app
ENV CHAT_PORT=59001
COPY --from=build /src/chat/build/libs/*.jar ./
EXPOSE 59001
CMD ["sh", "-c", "exec java -cp /app/* basic_demo.ChatServerApp ${CHAT_PORT:-59001}"]
