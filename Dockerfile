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

# Remove the problematic standalone dependency copy from the POM
RUN sed -i '/<execution>/,/<\/execution>/{ /<id>copy-standalone-complete<\/id>/,/<\/execution>/d; }' dss-demo-webapp/pom.xml \
    && mvn package -pl dss-demo-webapp -P quick -DskipTests

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
