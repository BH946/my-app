FROM openjdk:17-jdk
LABEL maintainer="test"
COPY secret-art-typing-gallery-0.0.1-SNAPSHOT.jar /app/secret-art-typing-gallery-0.0.1-SNAPSHOT.jar
WORKDIR /app
ENTRYPOINT ["java","-Dspring.profiles.active=default","-jar", "secret-art-typing-gallery-0.0.1-SNAPSHOT.jar"]
