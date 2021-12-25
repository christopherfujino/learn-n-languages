#!/usr/bin/env bash

# should be run with working directory being this script's container dir
# This script must be run as a user with permissions to access the docker
# daemon.

docker build --tag learn-n-languages/c/tax-rate-schedules .
