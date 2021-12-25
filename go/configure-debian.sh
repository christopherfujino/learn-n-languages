#!/usr/bin/env bash

# //go/
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

apt-get update
apt-get upgrade -y
apt-get install --no-install-recommends -y \
  build-essential \
  golang-go
