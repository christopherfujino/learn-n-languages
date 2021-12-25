#!/usr/bin/env bash

apt-get update
apt-get upgrade -y
# xz-utils to decompress tarballs
apt-get install --no-install-recommends -y \
  curl \
  xz-utils

ZIG_VERSION='0.9.0'

curl -lO "https://ziglang.org/download/$ZIG_VERSION/zig-linux-x86_64-$ZIG_VERSION.tar.xz"

# add zig binary to PATH
export PATH="$PWD/zig-linux-x86_64-$ZIG_VERSION:$PATH"
