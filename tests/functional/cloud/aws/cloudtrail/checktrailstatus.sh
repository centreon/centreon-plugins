#!/bin/bash

current_dir="$( cd  "$(dirname "$0")/../../../../.." >/dev/null 2>&1 || exit ; pwd -P )"
cmd="perl $current_dir/src/centreon_plugins.pl --plugin=cloud::aws::cloudtrail::plugin --custommode=paws --region=eu-west --aws-secret-key=secret --aws-access-key=key"

nb_tests=0
nb_tests_ok=0

test_status_ok=$($cmd --mode=checktrailstatus --endpoint=http://localhost:3000/cloudtrail/gettrailstatus/true --trail-name=TrailName)
((nb_tests++))
if [[ $test_status_ok = "OK: Trail is logging: 1 | 'trail_is_logging'=1;;;0;" ]]
then
  ((nb_tests_ok++))
else
  echo "test_status_ok ko"
  echo $test_status_ok
fi

test_status_critical=$($cmd --mode=checktrailstatus --endpoint=http://localhost:3000/cloudtrail/gettrailstatus/false --trail-name=TrailName)
((nb_tests++))
if [[ $test_status_critical = "CRITICAL: Trail is logging: 0 | 'trail_is_logging'=0;;;0;" ]]
then
  ((nb_tests_ok++))
else
  echo "test_status_critical ko"
  echo $test_status_critical
fi

if [[ $nb_tests_ok = $nb_tests ]]
then
  echo "OK: "$nb_tests_ok"/"$nb_tests" tests OK"
else
  echo "NOK: "$nb_tests_ok"/"$nb_tests" tests OK"
fi
