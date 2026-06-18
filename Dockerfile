# --- STAGE 1: Build Environment ---
FROM maven:3.9.6-eclipse-temurin-17 AS build-stage
WORKDIR /app

# Copy the source code and build the artifact
COPY . .
RUN mvn clean install -DskipTests

# --- STAGE 2: Secure Runtime Environment ---
FROM tomcat:9.0-jre17-temurin-jammy
LABEL project="vprofile"
LABEL author="devsecops-lab"

# Remove default Tomcat webapps to harden the security posture
RUN rm -rf /usr/local/tomcat/webapps/*

# Copy the compiled .war file from the build stage into Tomcat's deployment directory
COPY --from=build-stage /app/target/*.war /usr/local/tomcat/webapps/ROOT.war

EXPOSE 8080
CMD ["catalina.sh", "run"]
