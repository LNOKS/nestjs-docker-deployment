## CI/CD Pipeline Configuration

This CI/CD (Continuous Integration/Continuous Deployment) pipeline is designed for automating the deployment process to a remote server via GitHub Actions. The pipeline triggers on every push to the `master` branch, ensuring that the latest version of the code is always deployed.

### Workflow Overview

- **Trigger**: The pipeline is triggered on every push to the `master` branch.
- **Environment**: The pipeline runs on an Ubuntu latest environment.

### Jobs and Steps

#### Build

1. **Checkout Code**: Checks out the code for the current commit.
2. **Docker Login**: Logs into Docker using credentials stored in GitHub secrets. This step is essential for pushing the built Docker image to a Docker registry.
3. **Build and Push Docker Image**: Builds a Docker image from the `Dockerfile.prod` file and pushes it to a Docker registry. The image is tagged as `api-latest` and includes several build arguments fetched from GitHub secrets, such as environment variables and database configuration.
4. **SSH into Server**: Uses SSH to connect to the remote server where the deployment will occur. It performs the following operations:
   - Stops all running Docker containers.
   - Pulls the latest Docker image tagged as `api-latest`.
   - Runs the new Docker container on the specified port (8080).

### Secrets

The pipeline uses GitHub secrets for sensitive information, such as Docker credentials, server SSH key, and other environment-specific variables. This approach enhances security by not hard-coding sensitive information within the workflow file.

### Deployment Flow

Upon triggering, the workflow goes through the build job, which encompasses steps for code checkout, Docker login, image building and pushing, and finally deploying the application via SSH into the server. This automated process ensures a smooth and consistent deployment pipeline, minimizing human errors and speeding up the deployment process.

## Dockerfile Explanation

This Dockerfile outlines the process for building a Docker image for a Node.js application, optimized for production environments. It uses a multi-stage build process, leveraging `node:16-alpine` as the base image for a lightweight and efficient final image.

### Base Image

\`\`\`Dockerfile
FROM node:16-alpine AS build
\`\`\`
- **node:16-alpine**: A lightweight Node.js 16 image based on Alpine Linux. This image is used as the starting point for the build process.

### Working Directory

\`\`\`Dockerfile
WORKDIR /app
\`\`\`
- Sets the working directory inside the Docker image to \`/app\`. All subsequent commands will be run from this directory.

### Environment Variables

The Dockerfile defines several build arguments (\`ARG\`) and environment variables (\`ENV\`) to configure the application. These include:
- \`NODE_ENV\`: Specifies the Node.js environment (e.g., production, development).
- \`APP_NAME\`: The name of the application.
- \`APP_PORT\`: The port on which the application will run.
- \`API_PREFIX\`: The prefix for API routes.
- \`FRONTEND_DOMAIN\`: The domain name of the frontend.
- \`BACKEND_DOMAIN\`: The domain name of the backend.
- \`DATABASE_*\`: Various database configuration options, such as type, host, port, username, password, name, synchronization settings, maximum connections, SSL settings, and CA certificate information.

### Installing Dependencies

\`\`\`Dockerfile
COPY package*.json ./
RUN npm install
\`\`\`
- Copies \`package.json\` and \`package-lock.json\` (if present) to the working directory and installs the project dependencies.

### Installing NestJS CLI

\`\`\`Dockerfile
RUN npm i -g @nestjs/cli
\`\`\`
- Installs the NestJS CLI globally within the image to facilitate building the NestJS application.

### Copying Application Files

\`\`\`Dockerfile
COPY . .
\`\`\`
- Copies the application source code into the Docker image.

### Preparing Startup Script

\`\`\`Dockerfile
COPY ./startup.prod.sh /opt/startup.prod.sh
RUN sed -i 's/\r//g' /opt/startup.prod.sh
RUN chmod 775 /opt/startup.prod.sh
\`\`\`
- Copies a custom startup script to \`/opt/startup.prod.sh\`, removes carriage return characters to ensure Unix compatibility, and sets the script as executable.

### Building the Application

\`\`\`Dockerfile
RUN npm run build
\`\`\`
- Runs the build script defined in \`package.json\`, compiling the application for production.

### Exposing Port

\`\`\`Dockerfile
EXPOSE 8080
\`\`\`
- Informs Docker that the container listens on port 8080 at runtime.

### Entry Point

\`\`\`Dockerfile
ENTRYPOINT ["sh","/opt/startup.prod.sh"]
\`\`\`
- Sets the entry point to the custom startup script, which is executed when the container starts.

This Dockerfile is designed to create a Docker image tailored for production deployments, incorporating best practices for security, performance, and maintainability.

## Docker Compose Configuration Explanation

This Docker Compose file is designed to configure and run the `nestjs-api` service as part of a multi-container Docker application. It is based on Docker Compose file format version '3'.

### Services Definition

- **api**: The service name for the application.

### Service Configuration

- **image**: Specifies the name of the image to be used, `nestjs-api`, if it exists locally or in a registry.

- **build**: Defines the context and Dockerfile for building the image if it does not exist locally.
  - `context`: Sets the build context to the current directory (`.`).
  - `dockerfile`: Points to the `Dockerfile` used for building the image.

### Environment Variables

The service configuration includes environment variables passed to the container at runtime. These variables configure the application behavior and its connection to other services or databases. The variables include:
- `NODE_ENV`: Sets the environment in which the Node.js application will run.
- `APP_NAME`: Specifies the name of the application.
- `APP_PORT`: Defines the port on which the application will listen.
- `API_PREFIX`: Sets the prefix for all API routes.
- `FRONTEND_DOMAIN`: The domain name of the frontend application.
- `BACKEND_DOMAIN`: The domain name for the backend services.
- `DATABASE_TYPE`, `DATABASE_HOST`, `DATABASE_PORT`, `DATABASE_USERNAME`, `DATABASE_PASSWORD`, `DATABASE_NAME`, `DATABASE_SYNCHRONIZE`, `DATABASE_MAX_CONNECTIONS`, `DATABASE_SSL_ENABLED`, `DATABASE_REJECT_UNAUTHORIZED`: Configure the database connection details.

### Ports

- Maps the application port from the container to the host, allowing external access to the service on the specified port.

### Usage

To use this Docker Compose file, ensure Docker and Docker Compose are installed. Place this file in the root directory of your project. Run `docker-compose up` to build (if necessary) and start the services defined in this file. This command facilitates the deployment of your application in a consistent and repeatable manner.

This Docker Compose file streamlines the deployment of the `nestjs-api` application, encapsulating it within a container, and managing its environment and interactions with other services or databases.

## Startup Script Explanation

This script is intended for use as a startup command for a Node.js application running in a Docker container or a similar environment. It's designed to ensure that the application's database migrations and seed operations are executed before the application starts in production mode.

### Script Breakdown

```bash
#!/usr/bin/env bash
set -e
```
- Shebang line specifies that the script should be executed using Bash.
- `set -e`: Causes the script to exit immediately if any command exits with a non-zero status.

```bash
npm run migration:run
```
- Executes the database migration scripts defined in the application, ensuring that the database schema is up-to-date.

```bash
npm run seed:run
```
- Runs any seed operations that populate the database with initial data, necessary for the application to function correctly on startup.

```bash
npm run start:prod
```
- Starts the application in production mode.

### Usage

This script should be placed in a location accessible to the environment running the application, such as within the Docker image. It should be made executable and specified as the entry point or command in the Docker or deployment configuration.

To make the script executable, run:
```bash
chmod +x startup_script.sh
```

Then, it can be executed directly or through Docker's `CMD` or `ENTRYPOINT` instructions.

### Conclusion

This startup script automates the process of preparing the application's environment by handling database migrations and seeding before starting the application. It's an essential step for ensuring the application is fully configured and ready to serve requests upon startup.


## About us
### Ready to see what's beyond? Check out our website to discover more projects and learn how we're making a difference: [Discover More](https://lnoks.com).
<img src="https://api.lnoks.com/api/files/gpdni4nbyo5aj5b/ckzlbh3iiyt5n83/logo_purple_pure_hqhbjiEXbL.svg?token=" alt="drawing" width="200" height="100"/>
