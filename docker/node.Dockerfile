FROM node:lts

# Install Apache Ant
RUN apt-get update && \
    apt-get install -y ant && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app
