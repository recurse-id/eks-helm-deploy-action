FROM python:3.8-slim-buster

# Install the toolset.
RUN apt -y update && apt -y install curl \
    && pip install awscli \
    && curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
    
COPY deploy.sh /usr/local/bin/deploy

CMD deploy