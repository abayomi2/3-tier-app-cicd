FROM eclipse-temurin:17-jdk-alpine
# Set the working directory in the container
WORKDIR /app
# Copy the application JAR file to the container
COPY app.jar /app/app.jar
# Expose the port your application listens on (adjust if needed)
EXPOSE 8080
# Command to run the JAR file
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
