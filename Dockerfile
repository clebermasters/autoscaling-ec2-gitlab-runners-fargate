FROM ubuntu:20.04
LABEL maintainer="contact@bitslovers.com"

# Install deps
RUN apt-get update && \
	apt-get install -y --no-install-recommends \
	ca-certificates \
	curl \
	git \
	# Install the ECR Credential Helper, this helps us to login on ECR and pull private images. It requires the config.json file. Also, make sure that your instance has the right Role attached on it.
	amazon-ecr-credential-helper \
	dumb-init && \
	# Decrease docker image size
	rm -rf /var/lib/apt/lists/* && \

	# Install Gitlab Runner
	curl -LJO "https://gitlab-runner-downloads.s3.amazonaws.com/latest/deb/gitlab-runner_amd64.deb" && \
	dpkg -i gitlab-runner_amd64.deb && \

	# Install Docker Machine
	curl -L https://gitlab-docker-machine-downloads.s3.amazonaws.com/v0.16.2-gitlab.11/docker-machine-Linux-x86_64 > /usr/local/bin/docker-machine && \
	chmod +x /usr/local/bin/docker-machine 

COPY ./entrypoint.sh ./entrypoint.sh

RUN mkdir -p /root/.docker/
COPY config.json /root/.docker/

ENV REGISTER_NON_INTERACTIVE=true

ENTRYPOINT ["/usr/bin/dumb-init", "--", "./entrypoint.sh" ]
