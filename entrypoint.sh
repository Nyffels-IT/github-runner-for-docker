#!/bin/bash

# Environment variables
ORG=$ORG
PAT=$PAT
NAME=$NAME
HOSTDOCKER=$HOSTDOCKER

# Script variables
ACTIONS_RUNNER_INPUT_REPLACE=true
RUNNER_ALLOW_RUNASROOT="1"
export ACTIONS_RUNNER_INPUT_REPLACE
export RUNNER_ALLOW_RUNASROOT

# Fetch the runner registration token with a personal access token
echo "Api URL: https://api.github.com/orgs/${ORG}/actions/runners/registration-token"
REG_TOKEN=$(curl -X POST -H "Authorization: Bearer ${PAT}" -H "Accept: application/vnd.github+json" https://api.github.com/orgs/${ORG}/actions/runners/registration-token | jq .token --raw-output)
echo "Registration token received: ${REG_TOKEN}"

# Run the script to create the runner
cd /actions-runner
./config.sh --unattended --url "https://github.com/${ORG}" --token $REG_TOKEN --name $NAME

# Remove the runner on container end-of-live
cleanup() {
echo "Removing runner..."
    ./config.sh remove --token $REG_TOKEN
}

trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM
trap 'cleanup' SIGTERM

# Start the docker service 
if [$HOSTDOCKER -eq "1"]
then
echo "Starting docker service..."
service docker start
fi

# Start the runner
echo "Starting runner..."
./run.sh & wait $!