# syntax=docker/dockerfile:1

# Multi-stage build for DSS application
# Stage 1: Build the DSS demo webapp
FROM maven:3.9.11-eclipse-temurin-21 AS build

# Create a user for building
RUN useradd -ms /bin/bash demouser
USER demouser

# Set working directory
WORKDIR /home/demouser

# Clone and build DSS demonstrations
RUN git clone https://github.com/esig/dss-demonstrations.git
WORKDIR /home/demouser/dss-demonstrations

# Build the demo webapp
RUN mvn clean package -P quick -pl dss-demo-webapp -am -DskipTests

# Stage 2: Runtime container
FROM tomcat:11.0.9-jdk21

# Remove default webapps
RUN rm -rf /usr/local/tomcat/webapps/*

# Copy the built WAR from build stage
COPY --from=build /home/demouser/dss-demonstrations/dss-demo-webapp/target/dss-demo-webapp.war /usr/local/tomcat/webapps/ROOT.war

# Optional configuration overrides can be dropped into the local config/ directory.
# They will be copied into the container at build time.
COPY config/ /opt/dss/config/

# Provide sane defaults for JVM sizing; adjust in Railway if workloads increase.
ENV JAVA_OPTS="-Xms512m -Xmx1024m"
ENV CATALINA_OPTS="$JAVA_OPTS"

# Expose the default DSS HTTP port.
EXPOSE 8080

# Start Tomcat
CMD ["catalina.sh", "run"]
