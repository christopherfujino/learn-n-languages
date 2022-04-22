#!/usr/bin/env bash

set -ev

# //zig/
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

echo "$DIR/main.zig"
zig test "$DIR/main.zig"
