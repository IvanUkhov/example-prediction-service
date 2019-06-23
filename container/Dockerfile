# Use a Datalab image
FROM gcr.io/cloud-datalab/datalab:cloud_datalab_release_20190616_1912_RC00

# Copy the service directory to the image
COPY service /service
# Copy the run script to the image
COPY container/run.sh /run.sh

# Install Python dependencies specific to the predictive model
RUN source activate py3env && pip install --upgrade --requirement /service/source/requirements.txt
# Install Python dependencies specific to the service
RUN source activate py3env && pip install --upgrade --requirement /service/requirements.txt

# Set the working directory to be the service directory
WORKDIR /service

# Set the entry point to be the run script
ENTRYPOINT ["/run.sh"]
