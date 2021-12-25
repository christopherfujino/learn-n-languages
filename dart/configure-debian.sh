#!/usr/bin/env bash

set -ev

# //dart/
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

apt-get update
apt-get upgrade -y
# ca-certificates for curl-ing https
# apt-transport-https also?
apt-get install --no-install-recommends -y \
  build-essential \
  curl \
  ca-certificates \
  apt-transport-https

DART_VERSION='2.16.0-80.1.beta'
#DART_ARCHIVE="https://storage.googleapis.com/dart-archive/channels/beta/release/$DART_VERSION/sdk/dartsdk-linux-x64-release.zip"

REMOTE_DEB_PACKAGE="https://storage.googleapis.com/dart-archive/channels/beta/release/$DART_VERSION/linux_packages/$DART_VERSION-1_amd64.deb"

LOCAL_DEB_PACKAGE='dart.deb'

ls -alh "./$LOCAL_DEB_PACKAGE"
cat "./$LOCAL_DEB_PACKAGE"

curl -l -o "$LOCAL_DEB_PACKAGE" "$REMOTE_DEB_PACKAGE"

dpkg -i "./$LOCAL_DEB_PACKAGE"
