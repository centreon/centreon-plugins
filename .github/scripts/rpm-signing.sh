#!/bin/bash

set -ex
export GPG_TTY=$(tty)
rpmsign --addsign /src/*.rpm
