#!/bin/bash

current_dir="$( cd  "$(dirname "$0")/../../../../.." >/dev/null 2>&1 || exit ; pwd -P )"
cmd="perl $current_dir/src/centreon_plugins.pl --plugin=cloud::aws::cloudtrail::plugin --custommode=paws --region=eu-west --aws-secret-key=secret --aws-access-key=key"

nb_tests=0
nb_tests_ok=0

endpoint_url="http://localhost:3000/cloudtrail/events/AwsApiCall/4/AwsServiceEvent/2/AwsConsoleAction/1/AwsConsoleSignIn/3/NextToken/t"

test_ok=$($cmd --mode=countevents --endpoint=$endpoint_url)
((nb_tests++))
if [[ $test_ok = "OK: Number of events: 10.00 | 'events_count'=10.00;;;0;" ]]
then
  ((nb_tests_ok++))
else
  echo "test_ok ko"
  echo $test_ok
fi

test_oknexttoken=$($cmd --mode=countevents --endpoint=$endpoint_url"rue")
((nb_tests++))
if [[ $test_oknexttoken = "OK: Number of events: 20.00 | 'events_count'=20.00;;;0;" ]]
then
  ((nb_tests_ok++))
else
  echo "test_oknexttoken ko"
  echo $test_oknexttoken
fi

test_okeventtype=$($cmd --mode=countevents --endpoint=$endpoint_url --event-type=AwsApiCall)
((nb_tests++))
if [[ $test_okeventtype = "OK: Number of events: 4.00 | 'events_count'=4.00;;;0;" ]]
then
  ((nb_tests_ok++))
else
  echo "test_okeventtype ko"
  echo $test_okeventtype
fi

test_okeventtypenexttoken=$($cmd --mode=countevents --endpoint=$endpoint_url"rue" --event-type=AwsServiceEvent)
((nb_tests++))
if [[ $test_okeventtypenexttoken = "OK: Number of events: 4.00 | 'events_count'=4.00;;;0;" ]]
then
  ((nb_tests_ok++))
else
  echo "test_okeventtypenexttoken ko"
  echo $test_okeventtypenexttoken
fi

test_okdelta=$($cmd --mode=countevents --endpoint=$endpoint_url --event-type=AwsApiCall --delta=10)
((nb_tests++))
if [[ $test_okdelta = "OK: Number of events: 4.00 | 'events_count'=4.00;;;0;" ]]
then
  ((nb_tests_ok++))
else
  echo "test_okdelta ko"
  echo $test_okdelta
fi

test_okerrormessage=$($cmd --mode=countevents --endpoint=$endpoint_url --error-message='Login error')
((nb_tests++))
if [[ $test_okerrormessage = "OK: Number of events: 3.00 | 'events_count'=3.00;;;0;" ]]
then
  ((nb_tests_ok++))
else
  echo "test_okerrormessage ko"
  echo $test_okerrormessage
fi

test_okerrormessagepartial=$($cmd --mode=countevents --endpoint=$endpoint_url --error-message='.*error')
((nb_tests++))
if [[ $test_okerrormessagepartial = "OK: Number of events: 4.00 | 'events_count'=4.00;;;0;" ]]
then
  ((nb_tests_ok++))
else
  echo "test_okerrormessagepartial ko"
  echo $test_okerrormessagepartial
fi

test_warning=$($cmd --mode=countevents --endpoint=$endpoint_url --warning-count=3)
((nb_tests++))
if [[ $test_warning = "WARNING: Number of events: 10.00 | 'events_count'=10.00;;;0;" ]]
then
  ((nb_tests_ok++))
else
  echo "test_warning ko"
  echo $test_warning
fi

test_critical=$($cmd --mode=countevents --endpoint=$endpoint_url --critical-count=5)
((nb_tests++))
if [[ $test_critical = "CRITICAL: Number of events: 10.00 | 'events_count'=10.00;;;0;" ]]
then
  ((nb_tests_ok++))
else
  echo "test_critical ko"
  echo $test_critical
fi

if [[ $nb_tests_ok = $nb_tests ]]
then
  echo "OK: "$nb_tests_ok"/"$nb_tests" tests OK"
else
  echo "NOK: "$nb_tests_ok"/"$nb_tests" tests OK"
fi
