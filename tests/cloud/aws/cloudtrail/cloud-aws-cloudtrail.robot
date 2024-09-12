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
AWS CloudTrail check trail status
    [Documentation]    Check AWS CloudTrail trail status
    [Tags]    cloud    aws    cloudtrail
    
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=checktrailstatus
    ...    --endpoint=http://${HOSTNAME}:${APIPORT}/cloudtrail/gettrailstatus/${trailstatus}
    ...    --trail-name=trailname
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}
        
    Examples:         tc    trailstatus     expected_result    --
    ...               1     true            OK: Trail is logging: 1 | 'trail_is_logging'=1;;;0;
    ...               2     false           CRITICAL: Trail is logging: 0 | 'trail_is_logging'=0;;;0;

AWS CloudTrail count events
    [Documentation]    Check AWS CloudTrail count events
    [Tags]    cloud    aws    cloudtrail

    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=countevents
    ...    --endpoint=http://localhost:3000/cloudtrail/events/AwsApiCall/${AwsApiCall}/AwsServiceEvent/${AwsServiceEvent}/AwsConsoleAction/${AwsConsoleAction}/AwsConsoleSignIn/${AwsConsoleSignIn}/NextToken/${NextToken}
    ...    --event-type='${eventtype}'
    ...    --delta=${delta}
    ...    --error-message='${errormessage}'
    ...    --warning-count=${warningcount}
    ...    --critical-count=${criticalcount}
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:         tc    AwsApiCall    AwsServiceEvent    AwsConsoleAction    AwsConsoleSignIn    NextToken    eventtype          delta       errormessage     warningcount    criticalcount    expected_result    --
    ...               1     4             2                 1                    3                   false        ${EMPTY}           ${EMPTY}    ${EMPTY}         ${EMPTY}        ${EMPTY}         OK: Number of events: 10.00 | 'events_count'=10.00;;;0;
    ...               2     4             2                 1                    3                   true         ${EMPTY}           ${EMPTY}    ${EMPTY}         ${EMPTY}        ${EMPTY}         OK: Number of events: 20.00 | 'events_count'=20.00;;;0;
    ...               3     4             2                 1                    3                   false        AwsApiCall         ${EMPTY}    ${EMPTY}         ${EMPTY}        ${EMPTY}         OK: Number of events: 4.00 | 'events_count'=4.00;;;0;
    ...               4     4             2                 1                    3                   false        AwsServiceEvent    ${EMPTY}    ${EMPTY}         ${EMPTY}        ${EMPTY}         OK: Number of events: 2.00 | 'events_count'=2.00;;;0;
    ...               5     4             2                 1                    3                   false        ${EMPTY}           10          ${EMPTY}         ${EMPTY}        ${EMPTY}         OK: Number of events: 10.00 | 'events_count'=10.00;;;0;
    ...               6     4             2                 1                    3                   false        ${EMPTY}           ${EMPTY}    Login error      ${EMPTY}        ${EMPTY}         OK: Number of events: 3.00 | 'events_count'=3.00;;;0;
    ...               7     4             2                 1                    3                   false        ${EMPTY}           ${EMPTY}    .*error          ${EMPTY}        ${EMPTY}         WARNING: Number of events:4.00 | 'events_count'=4.00;;;0;
    ...               8     4             2                 1                    3                   false        ${EMPTY}           ${EMPTY}    ${EMPTY}         3               ${EMPTY}         WARNING: Number of events: 10.00 | 'events_count'=10.00;;;0;
    ...               9     4             2                 1                    3                   false        ${EMPTY}           ${EMPTY}    ${EMPTY}         ${EMPTY}        5                CRITICAL: Number of events: 10.00 | 'events_count'=10.00;;;0;
