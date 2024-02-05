*** Settings ***
Documentation       AWS CloudTrail plugin

Library             Examples
Library             OperatingSystem
Library             Process
Library             String

Suite Setup         Start Mockoon
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${CENTREON_PLUGINS}     ${CURDIR}${/}..${/}..${/}..${/}src${/}centreon_plugins.pl
${MOCKOON_JSON}         ${CURDIR}${/}..${/}..${/}resources${/}mockoon${/}cloud-aws-cloudtrail.json

${CMD}                  perl ${CENTREON_PLUGINS} --plugin=cloud::aws::cloudtrail::plugin --custommode=paws --region=eu-west --aws-secret-key=secret --aws-access-key=key


*** Test Cases ***
AWS CloudTrail check trail status
    [Documentation]    Check AWS CloudTrail trail status
    [Tags]    cloud    aws    cloudtrail
    ${output}    Run
    ...    ${CMD} --mode=checktrailstatus --endpoint=http://localhost:3000/cloudtrail/gettrailstatus/${trailstatus} --trail-name=${trailname}
    Should Be Equal As Strings
    ...    ${output}
    ...    ${result}
    ...    Wrong output result for check trail status of ${trailname}.{\n}Command output:{\n}${output}

    Examples:    trailstatus      trailname     result   --
        ...      true             TrailName     OK: Trail is logging: 1 | 'trail_is_logging'=1;;;0;
        ...      false            TrailName     CRITICAL: Trail is logging: 0 | 'trail_is_logging'=0;;;0;

AWS CloudTrail count events
    [Documentation]    Check AWS CloudTrail count events
    [Tags]    cloud    aws    cloudtrail
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=countevents
    ...    --endpoint=http://localhost:3000/cloudtrail/events/AwsApiCall/${AwsApiCall}/AwsServiceEvent/${AwsServiceEvent}/AwsConsoleAction/${AwsConsoleAction}/AwsConsoleSignIn/${AwsConsoleSignIn}/NextToken/${NextToken}
    ${length}    Get Length    ${eventtype}
    IF    ${length} > 0
        ${command}    Catenate    ${command}    --event-type=${eventtype}
    END
    ${length}    Get Length    ${delta}
    IF    ${length} > 0
        ${command}    Catenate    ${command}    --delta=${delta}
    END
    ${length}    Get Length    ${errormessage}
    IF    ${length} > 0
        ${command}    Catenate    ${command}    --error-message=${errormessage}
    END
    ${length}    Get Length    ${warningcount}
    IF    ${length} > 0
        ${command}    Catenate    ${command}    --warning-count=${warningcount}
    END
    ${length}    Get Length    ${criticalcount}
    IF    ${length} > 0
        ${command}    Catenate    ${command}    --critical-count=${criticalcount}
    END
    ${output}    Run    ${command}
    Should Be Equal As Strings
    ...    ${output}
    ...    ${result}
    ...    Wrong output result for count events.{\n}Command output:{\n}${output}

    Examples:    AwsApiCall    AwsServiceEvent    AwsConsoleAction    AwsConsoleSignIn    NextToken    eventtype            delta    errormessage    warningcount    criticalcount    result    --
            ...  4             2                  1                   3                   false                                                                                       OK: Number of events: 10.00 | 'events_count'=10.00;;;0;
            ...  4             2                  1                   3                   true                                                                                        OK: Number of events: 20.00 | 'events_count'=20.00;;;0;
            ...  4             2                  1                   3                   false        AwsApiCall                                                                     OK: Number of events: 2.00 | 'events_count'=4.00;;;0;
            ...  4             2                  1                   3                   true         AwsServiceEvent                                                                OK: Number of events: 4.00 | 'events_count'=2.00;;;0;
            ...  4             2                  1                   3                   false        AwsApiCall           10                                                        OK: Number of events: 4.00 | 'events_count'=4.00;;;0;
            ...  4             2                  1                   3                   false                                      'Login error'                                    OK: Number of events: 3.00 | 'events_count'=3.00;;;0;
            ...  4             2                  1                   3                   false                                      '.*error'                                        OK: Number of events: 4.00 | 'events_count'=4.00;;;0;
            ...  4             2                  1                   3                   false                                                      3                                WARNING: Number of events: 10.00 | 'events_count'=10.00;;;0;
            ...  4             2                  1                   3                   false                                                                       5               CRITICAL: Number of events: 10.00 | 'events_count'=10.00;;;0;


*** Keywords ***
Start Mockoon
    ${process}    Start Process
    ...    mockoon-cli
    ...    start
    ...    --data
    ...    ${MOCKOON_JSON}
    ...    --port
    ...    3000
    ...    --pname
    ...    aws-cloudtrail
    Wait For Process    ${process}

Stop Mockoon
    ${process}    Start Process
    ...    mockoon-cli
    ...    stop
    ...    mockoon-aws-cloudtrail
    Wait For Process    ${process}
