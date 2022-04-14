#!/bin/bash

VERSION="$1"
BULLSEYEPACKAGES=`echo *.deb`

for i in $BULLSEYEPACKAGES
do
  echo "Sending $i\n"
  curl -u \"$NEXUS_USERNAME:$NEXUS_PASSWORD\" -H "Content-Type: multipart/form-data" --data-binary \"@/$i\" "https://apt.centreon.com/repository/$VERSION"
done
