FROM maven:3.9.11-eclipse-temurin-21 as build

RUN useradd -m demouser -d /home/demouser
USER demouser

WORKDIR /home/demouser

RUN git clone https://github.com/esig/dss-demonstrations.git

WORKDIR /home/demouser/dss-demonstrations

RUN mvn package -pl dss-standalone-app,dss-standalone-app-package,dss-demo-webapp -P quick

FROM tomcat:11.0.9-jdk21-temurin

COPY --from=build /home/demouser/dss-demonstrations/dss-demo-webapp/target/dss-demo-webapp-*.war /usr/local/tomcat/webapps/ROOT.war

EXPOSE 8080