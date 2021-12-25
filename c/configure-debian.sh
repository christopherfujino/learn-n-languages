#!/usr/bin/env bash

apt-get update
apt-get upgrade -y
apt-get install --no-install-recommends -y \
  build-essential \
  clang
