#!/bin/sh

echo "Creating centreon-as400 user ..."
useradd -m -r centreon-as400 2> /dev/null ||: