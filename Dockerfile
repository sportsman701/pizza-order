FROM debian:jessie AS buildStage
MAINTAINER digIT <digit@chalmers.it>

# Setup directories and user
RUN mkdir /app && mkdir /output && \
groupadd -r meteor && useradd -m -g meteor meteor
WORKDIR /app

# Install prerequisites
RUN apt-get update && apt-get install -y \
curl

# Copy Source files
COPY . .

# Change ownership and su unprevelegied user
RUN chown -R meteor:meteor /app && chown -R meteor /output
USER meteor:meteor

# Install meteor
RUN curl https://install.meteor.com/ | sh
USER root:root
RUN cp /home/meteor/.meteor/packages/meteor-tool/1.6.0/mt-os.linux.x86_64/scripts/admin/launch-meteor /usr/bin/meteor
USER meteor:meteor
#RUN meteor update --all-packages

# Build and extract app
RUN meteor npm install
RUN meteor build /output
WORKDIR /output
RUN tar -zxf app.tar.gz && rm app.tar.gz


##########################
#    PRODUCTION STAGE    #
##########################
FROM node:9.1.0 AS production
MAINTAINER digIT <digit@chalmers.it>

# Copy files from the build stage
COPY --from=buildStage /output /app

# Setup and su as unprevelegied user
RUN chown -R node:node /app
USER node:node

# Install the application
WORKDIR /app/bundle/programs/server
RUN npm install
ENV MONGO_URL mongodb://user:password@host:port/databasename
ENV ROOT_URL https://example.com
ENV MAIL_URL smtp://user:password@mailhost:port

# Provide default command and entrypoint
WORKDIR /app/bundle
CMD node main.js