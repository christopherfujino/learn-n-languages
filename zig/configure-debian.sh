#!/usr/bin/env bash

set -euv

# //zig/
ZIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

apt-get update
apt-get upgrade -y
# xz-utils to decompress tarballs
apt-get install --no-install-recommends -y \
  curl \
  ca-certificates \
  xz-utils

ZIG_VERSION='0.9.0'

ZIG_ARCHIVE="zig-linux-x86_64-$ZIG_VERSION.tar.xz"
curl -l -o "$ZIG_DIR/$ZIG_ARCHIVE" "https://ziglang.org/download/$ZIG_VERSION/$ZIG_ARCHIVE"

ls -alh "$ZIG_DIR/$ZIG_ARCHIVE"

tar xvf "$ZIG_DIR/$ZIG_ARCHIVE"

ls -alh "$ZIG_DIR/zig-linux-x86_64-$ZIG_VERSION/zig"

# add zig binary to PATH
export PATH="$ZIG_DIR/zig-linux-x86_64-$ZIG_VERSION:$PATH"
