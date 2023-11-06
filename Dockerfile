FROM openjdk 
LABEL maintainer="akashzakde123@gmail.com"
EXPOSE 8080
COPY target/spring-petclinic-3.1.0-SNAPSHOT.jar /home/spring-petclinic-3.1.0-SNAPSHOT.jar
CMD ["java","-jar","/home/spring-petclinic-3.1.0-SNAPSHOT.jar"]
