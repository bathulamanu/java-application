# Stage 1: Base Java runtime (no JDK needed, just JRE to run the JAR)
FROM eclipse-temurin:17-jre-alpine

# Working directory inside container
WORKDIR /app

# Copy the fat JAR Maven produced
COPY target/my-java-app.jar app.jar

# Expose port 8080 (Spring Boot default)
EXPOSE 8080

# Run the app
ENTRYPOINT ["java", "-jar", "app.jar"]
