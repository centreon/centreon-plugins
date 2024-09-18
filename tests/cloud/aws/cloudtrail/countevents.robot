*** Settings ***
Documentation       AWS CloudTrail plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}                 ${CURDIR}${/}cloud-aws-cloudtrail.json

${CMD}                          ${CENTREON_PLUGINS} --plugin=cloud::aws::cloudtrail::plugin --custommode=paws --region=eu-west --aws-secret-key=secret --aws-access-key=key


*** Test Cases ***
AWS CloudTrail count events
    [Documentation]    Check AWS CloudTrail count events
    [Tags]    cloud    aws    cloudtrail

    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=countevents
    ...    --endpoint=http://localhost:3000/cloudtrail/events/AwsApiCall/${AwsApiCall}/AwsServiceEvent/${AwsServiceEvent}/AwsConsoleAction/${AwsConsoleAction}/AwsConsoleSignIn/${AwsConsoleSignIn}/NextToken/${NextToken}
    ...    ${extraoptions}
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:         tc    AwsApiCall    AwsServiceEvent    AwsConsoleAction    AwsConsoleSignIn    NextToken    extraoptions                     expected_result    --
    ...               1     4             2                 1                    3                   false        ${EMPTY}                         OK: Number of events: 10.00 | 'events_count'=10.00;;;0;
    ...               2     4             2                 1                    3                   true         ${EMPTY}                         OK: Number of events: 20.00 | 'events_count'=20.00;;;0;
    ...               3     4             2                 1                    3                   false        --event-type=AwsApiCall          OK: Number of events: 4.00 | 'events_count'=4.00;;;0;
    ...               4     4             2                 1                    3                   false        --event-type=AwsServiceEvent     OK: Number of events: 2.00 | 'events_count'=2.00;;;0;
    ...               5     4             2                 1                    3                   false        --delta=10                       OK: Number of events: 10.00 | 'events_count'=10.00;;;0;
    ...               6     4             2                 1                    3                   false        --error-message='Login error'    OK: Number of events: 3.00 | 'events_count'=3.00;;;0;
    ...               7     4             2                 1                    3                   false        --error-message='.*error'        OK: Number of events: 4.00 | 'events_count'=4.00;;;0;
    ...               8     4             2                 1                    3                   false        --warning-count=3                WARNING: Number of events: 10.00 | 'events_count'=10.00;;;0;
    ...               9     4             2                 1                    3                   false        --critical-count=5               CRITICAL: Number of events: 10.00 | 'events_count'=10.00;;;0;
