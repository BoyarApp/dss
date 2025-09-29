# syntax=docker/dockerfile:1.4

# Multi-stage build using the official dss-demonstrations repository
FROM maven:3.9.11-eclipse-temurin-21 AS build

# Create a user for building
RUN useradd -ms /bin/bash demouser
USER demouser

# Set working directory
WORKDIR /home/demouser

# Clone and build DSS demonstrations
RUN git clone https://github.com/esig/dss-demonstrations.git
WORKDIR /home/demouser/dss-demonstrations

# Build just the webapp without profiles or extra dependencies
RUN mvn clean compile war:war -pl dss-demo-webapp -DskipTests -Dmaven.test.skip=true

# Runtime stage
FROM tomcat:11.0.9-jdk21

# Remove default webapps
RUN rm -rf /usr/local/tomcat/webapps/*

# Copy the built WAR from build stage
COPY --from=build /home/demouser/dss-demonstrations/dss-demo-webapp/target/dss-demo-webapp.war /usr/local/tomcat/webapps/ROOT.war

# Optional configuration overrides
COPY config/ /opt/dss/config/

# Environment variables
ENV JAVA_OPTS="-Xms512m -Xmx1024m"
ENV CATALINA_OPTS="$JAVA_OPTS"

# Expose port 8080
EXPOSE 8080

# Start Tomcat
CMD ["catalina.sh", "run"]
