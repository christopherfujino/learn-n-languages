#!/usr/bin/env bash

set -euv

apt-get update
apt-get upgrade -y
# xz-utils to decompress tarballs
apt-get install --no-install-recommends -y \
  curl \
  ca-certificates \
  xz-utils

ZIG_VERSION='0.9.0'

ZIG_ARCHIVE="zig-linux-x86_64-$ZIG_VERSION.tar.xz"
curl -lO "https://ziglang.org/download/$ZIG_VERSION/$ZIG_ARCHIVE"

ls -alh "./$ZIG_ARCHIVE"
file "./$ZIG_ARCHIVE"

tar xvzf "./$ZIG_ARCHIVE"

file "$PWD/zig-linux-x86_64-$ZIG_VERSION/zig"

# add zig binary to PATH
export PATH="$PWD/zig-linux-x86_64-$ZIG_VERSION:$PATH"
