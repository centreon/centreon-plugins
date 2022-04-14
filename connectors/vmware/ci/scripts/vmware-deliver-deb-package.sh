#!/bin/bash
set -ex

VERSION="$3"
BULLSEYEPACKAGES=`echo *.deb`

for i in $BULLSEYEPACKAGES
do
  echo "Sending $i"
  curl -u \'$1':'$2'\ -H "Content-Type: multipart/form-data" --data-binary \"@/$i\" "https://apt.centreon.com/repository/22.04"
done
