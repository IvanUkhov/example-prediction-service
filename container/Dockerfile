FROM gcr.io/cloud-datalab/datalab:cloud_datalab_release_20190616_1912_RC00

COPY service /service
COPY container/run.sh /run.sh

RUN source activate py3env && pip install --upgrade --requirement /service/requirements.txt
RUN source activate py3env && pip install --upgrade --requirement /service/source/requirements.txt

WORKDIR /service

ENTRYPOINT ["/run.sh"]
