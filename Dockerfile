# Define custom function directory
ARG FUNCTION_DIR="/function"
ARG LOCAL_DEV=false

# First stage: Build dependencies and function
FROM mcr.microsoft.com/playwright/python:v1.52.0-jammy AS build-image

# Install aws-lambda-cpp build dependencies
RUN apt-get update && \
    apt-get install -y \
    g++ \
    make \
    cmake \
    unzip \
    libcurl4-openssl-dev \
    software-properties-common \
    fonts-liberation \
    libappindicator3-1 \
    libasound2 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libcups2 \
    libdbus-1-3 \
    libgdk-pixbuf2.0-0 \
    libnspr4 \
    libnss3 \
    pciutils \
    xdg-utils

# Include global arg in this stage of the build
ARG FUNCTION_DIR

# Copy function code
RUN mkdir -p ${FUNCTION_DIR}
COPY . ${FUNCTION_DIR}

# Install Lambda runtime interface client
RUN pip install \
    --target ${FUNCTION_DIR} \
    awslambdaric

# Install function dependencies
COPY requirements.txt .
RUN pip install --target ${FUNCTION_DIR} -r requirements.txt

# Second stage: Clean Lambda container image
FROM mcr.microsoft.com/playwright/python:v1.52.0-jammy

# Include global arg
ARG FUNCTION_DIR
WORKDIR ${FUNCTION_DIR}

# Copy from build stage
COPY --from=build-image ${FUNCTION_DIR} ${FUNCTION_DIR}

# Only add aws-lambda-rie if LOCAL_DEV is true
RUN if [ "$LOCAL_DEV" = "true" ] ; then \
    curl -Lo /usr/local/bin/aws-lambda-rie https://github.com/aws/aws-lambda-runtime-interface-emulator/releases/latest/download/aws-lambda-rie && \
    chmod +x /usr/local/bin/aws-lambda-rie ; \
    fi
# Uncomment and use this for normal deployment
ENTRYPOINT [ "python", "-m", "awslambdaric" ]
# Use aws-lambda-rie to bootstrap awslambdaric on local dev only
# ENTRYPOINT ["/usr/local/bin/aws-lambda-rie", "python", "-m", "awslambdaric"]
CMD [ "main.handler" ]
