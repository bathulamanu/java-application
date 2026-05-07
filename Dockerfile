# BUILD STAGE
FROM maven:3.9.6-eclipse-temurin-21 AS builder

WORKDIR /app

# copy pom first
COPY pom.xml .

# download dependencies first (cached)
RUN mvn dependency:go-offline

# copy source
COPY src ./src

# build
RUN mvn clean package -DskipTests


# RUN STAGE
FROM eclipse-temurin:21-jdk

WORKDIR /app

COPY --from=builder /app/target/*.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java","-jar","app.jar"]
