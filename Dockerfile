FROM maven:3.9.11-eclipse-temurin-21 as build

RUN useradd -m demouser -d /home/demouser
USER demouser

WORKDIR /home/demouser

RUN git clone https://github.com/esig/dss-demonstrations.git

WORKDIR /home/demouser/dss-demonstrations

RUN mvn package -pl dss-standalone-app,dss-standalone-app-package,dss-demo-webapp -P quick

FROM tomcat:11.0.9-jdk21-temurin

# Install Azure CLI and dependencies for Key Vault REST API integration
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    ca-certificates \
    lsb-release \
    gnupg \
    && curl -sL https://packages.microsoft.com/keys/microsoft.asc | \
       gpg --dearmor | tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null \
    && echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" | \
       tee /etc/apt/sources.list.d/azure-cli.list \
    && apt-get update \
    && apt-get install -y azure-cli \
    && rm -rf /var/lib/apt/lists/*

# Copy DSS configuration files
COPY config/ /opt/dss/config/

# Copy DSS webapp
COPY --from=build /home/demouser/dss-demonstrations/dss-demo-webapp/target/dss-demo-webapp-*.war /usr/local/tomcat/webapps/ROOT.war

# Set environment for configuration
ENV SPRING_CONFIG_LOCATION="file:/opt/dss/config/"
ENV JAVA_OPTS="-Xms512m -Xmx1024m -Dspring.profiles.active=production"

EXPOSE 8080