#!/usr/bin/env bash

set -e # exit if test fails

cd "$(dirname "${BASH_SOURCE[0]}")"

make run
