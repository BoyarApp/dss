FROM maven:3.9.11-eclipse-temurin-21 as build

RUN useradd -m demouser -d /home/demouser
USER demouser

WORKDIR /home/demouser

RUN git clone https://github.com/esig/dss-demonstrations.git

WORKDIR /home/demouser/dss-demonstrations

RUN mvn package -pl dss-standalone-app,dss-standalone-app-package,dss-demo-webapp -P quick

FROM tomcat:11.0.9-jdk21-temurin

# Install dependencies for Azure Key Vault PKCS#11 provider
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Download and install Azure Key Vault PKCS#11 provider
RUN mkdir -p /opt/azurekv-pkcs11/lib \
    && curl -L -o /tmp/azure-kv-pkcs11.tar.gz \
       "https://github.com/Azure/azure-keyvault-pkcs11/releases/download/v1.0.0/azure-keyvault-pkcs11-1.0.0-linux-x64.tar.gz" \
    && tar -xzf /tmp/azure-kv-pkcs11.tar.gz -C /opt/azurekv-pkcs11/lib --strip-components=1 \
    && rm /tmp/azure-kv-pkcs11.tar.gz

# Copy DSS configuration files
COPY config/ /opt/dss/config/

# Copy DSS webapp
COPY --from=build /home/demouser/dss-demonstrations/dss-demo-webapp/target/dss-demo-webapp-*.war /usr/local/tomcat/webapps/ROOT.war

# Set environment for configuration
ENV SPRING_CONFIG_LOCATION="file:/opt/dss/config/"
ENV JAVA_OPTS="-Xms512m -Xmx1024m -Dspring.profiles.active=production"

EXPOSE 8080