# build frontend code
FROM node:14.15.4-alpine3.10 As frontend-builder
WORKDIR /app

# copy files to /app
COPY ./frontend/src src
COPY ./frontend/public public
COPY ./frontend/package.json .
COPY ./frontend/package-lock.json .
COPY ./frontend/tsconfig.json .
RUN npm install && npm run build

## copy jar file from previous stage and execute it
FROM maven:3.6.3-amazoncorretto-8 As maven-builder
WORKDIR /home

# copy files to /home
COPY springbootServer/src src
COPY springbootServer/pom.xml .

# copy build from previous stage to resources folder
COPY --from=frontend-builder /app/build/ /home/src/main/resources/static/

# compile java code with production profile
RUN mvn clean package -Pproduction

# rename *.jar to app.jar
RUN mv target/*.jar app.jar

### remaing app.jar only
FROM adoptopenjdk/openjdk8:alpine
WORKDIR /app
COPY --from=maven-builder /home/app.jar .

ENTRYPOINT ["java","-jar","./app.jar"]