#!/bin/bash

# Set error handling
set -euo pipefail

# Always unregister runner on exit
function gitlab-unregister {
    gitlab-runner unregister --all-runners
}

trap 'gitlab-unregister' EXIT SIGHUP SIGINT SIGTERM

# Define runner tags
if [ -n "${RUNNER_TAG_LIST:-}" ]
then
    RUNNER_TAG_LIST_OPT=("--tag-list" "$RUNNER_TAG_LIST")
else
    RUNNER_TAG_LIST_OPT=("--run-untagged=true")
fi

# Define adicional parameters
if [ -n "${ADDITIONAL_REGISTER_PARAMS:-}" ]
then
    IFS=' ' read -r -a ADDITIONAL_REGISTER_PARAMS_OPT <<< "$ADDITIONAL_REGISTER_PARAMS"
else
    IFS=' ' read -r -a ADDITIONAL_REGISTER_PARAMS_OPT <<< ""
fi

# Register
# All Variables are defined and provide by the Cloud Formation Template. And their values are store on the Fargate Task Definition once created.
gitlab-runner register --executor docker+machine \
--docker-tlsverify \
--docker-volumes '/var/run/docker.sock:/var/run/docker.sock' \
--docker-pull-policy="if-not-present" \
--run-untagged="true" \
--machine-machine-driver "amazonec2" \
--machine-machine-name "gitlab-%s" \
--request-concurrency "$RUNNER_REQUEST_CONCURRENCY" \
--machine-machine-options amazonec2-use-private-address \
--machine-machine-options amazonec2-security-group="$AWS_SECURITY_GROUP" \
--machine-machine-options amazonec2-subnet-id="$AWS_SUBNET_ID" \
--machine-machine-options amazonec2-zone="$AWS_SUBNET_ZONE" \
--machine-machine-options amazonec2-vpc-id="$AWS_VPC_ID" \
--machine-machine-options amazonec2-iam-instance-profile="$RUNNER_IAM_PROFILE" \
"${RUNNER_TAG_LIST_OPT[@]}" \
"${ADDITIONAL_REGISTER_PARAMS_OPT[@]}"

sed -i 's/concurrent.*/concurrent = 10/' /etc/gitlab-runner/config.toml

# Native env var seems to be broken for security group
echo "Print CONFIG file ----> "
cat /etc/gitlab-runner/config.toml

# Retrieve the Public IP to make it easier to check if the SG from Gitlab allows that IP.
echo "Public IP-->"
curl --silent -4 ifconfig.co

# Start Runner
gitlab-runner run
