# Use a minimal Python image
FROM python:3.7-slim

# Install Google Cloud SDK as described in
# https://cloud.google.com/sdk/docs/quickstart-debian-ubuntu
RUN apt-get update && apt-get install -y build-essential curl
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
RUN apt-get update && apt-get install -y google-cloud-sdk

# Copy the service directory to the image
COPY service /service
# Copy the run script to the image
COPY container/run.sh /run.sh

# Install Python dependencies specific to the predictive model
RUN pip install --upgrade --requirement /service/source/requirements.txt
# Install Python dependencies specific to the service
RUN pip install --upgrade --requirement /service/requirements.txt

# Set the working directory to be the service directory
WORKDIR /service

# Set the entry point to be the run script
ENTRYPOINT /run.sh
