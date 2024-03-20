*** Settings ***
Documentation       AWS CloudTrail plugin

Library             OperatingSystem
Library             Process
Library             String

Suite Setup         Start Mockoon
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${CENTREON_PLUGINS}             ${CURDIR}${/}..${/}..${/}..${/}src${/}centreon_plugins.pl
${MOCKOON_JSON}                 ${CURDIR}${/}..${/}..${/}resources${/}mockoon${/}cloud-aws-cloudtrail.json

${CMD}                          perl ${CENTREON_PLUGINS} --plugin=cloud::aws::cloudtrail::plugin --custommode=paws --region=eu-west --aws-secret-key=secret --aws-access-key=key

&{checktrailstatus_value1}
...                             trailstatus=true
...                             trailname=TrailName
...                             result=OK: Trail is logging: 1 | 'trail_is_logging'=1;;;0;
&{checktrailstatus_value2}
...                             trailstatus=false
...                             trailname=TrailName
...                             result=CRITICAL: Trail is logging: 0 | 'trail_is_logging'=0;;;0;
@{checktrailstatus_values}      &{checktrailstatus_value1}    &{checktrailstatus_value2}

&{countevents_value1}
...                             AwsApiCall=4
...                             AwsServiceEvent=2
...                             AwsConsoleAction=1
...                             AwsConsoleSignIn=3
...                             NextToken=false
...                             eventtype=
...                             delta=
...                             errormessage=
...                             warningcount=
...                             criticalcount=
...                             result=OK: Number of events: 10.00 | 'events_count'=10.00;;;0;
&{countevents_value2}
...                             AwsApiCall=4
...                             AwsServiceEvent=2
...                             AwsConsoleAction=1
...                             AwsConsoleSignIn=3
...                             NextToken=true
...                             eventtype=
...                             delta=
...                             errormessage=
...                             warningcount=
...                             criticalcount=
...                             result=OK: Number of events: 20.00 | 'events_count'=20.00;;;0;
&{countevents_value3}
...                             AwsApiCall=4
...                             AwsServiceEvent=2
...                             AwsConsoleAction=1
...                             AwsConsoleSignIn=3
...                             NextToken=false
...                             eventtype=AwsApiCall
...                             delta=
...                             errormessage=
...                             warningcount=
...                             criticalcount=
...                             result=OK: Number of events: 4.00 | 'events_count'=4.00;;;0;
&{countevents_value4}
...                             AwsApiCall=4
...                             AwsServiceEvent=2
...                             AwsConsoleAction=1
...                             AwsConsoleSignIn=3
...                             NextToken=true
...                             eventtype=AwsServiceEvent
...                             delta=
...                             errormessage=
...                             warningcount=
...                             criticalcount=
...                             result=OK: Number of events: 4.00 | 'events_count'=4.00;;;0;
&{countevents_value5}
...                             AwsApiCall=4
...                             AwsServiceEvent=2
...                             AwsConsoleAction=1
...                             AwsConsoleSignIn=3
...                             NextToken=false
...                             eventtype=AwsApiCall
...                             delta=10
...                             errormessage=
...                             warningcount=
...                             criticalcount=
...                             result=OK: Number of events: 4.00 | 'events_count'=4.00;;;0;
&{countevents_value6}
...                             AwsApiCall=4
...                             AwsServiceEvent=2
...                             AwsConsoleAction=1
...                             AwsConsoleSignIn=3
...                             NextToken=false
...                             eventtype=
...                             delta=
...                             errormessage='Login error'
...                             warningcount=
...                             criticalcount=
...                             result=OK: Number of events: 3.00 | 'events_count'=3.00;;;0;
&{countevents_value7}
...                             AwsApiCall=4
...                             AwsServiceEvent=2
...                             AwsConsoleAction=1
...                             AwsConsoleSignIn=3
...                             NextToken=false
...                             eventtype=
...                             delta=
...                             errormessage='.*error'
...                             warningcount=
...                             criticalcount=
...                             result=OK: Number of events: 4.00 | 'events_count'=4.00;;;0;
&{countevents_value8}
...                             AwsApiCall=4
...                             AwsServiceEvent=2
...                             AwsConsoleAction=1
...                             AwsConsoleSignIn=3
...                             NextToken=false
...                             eventtype=
...                             delta=
...                             errormessage=
...                             warningcount=3
...                             criticalcount=
...                             result=WARNING: Number of events: 10.00 | 'events_count'=10.00;;;0;
&{countevents_value9}
...                             AwsApiCall=4
...                             AwsServiceEvent=2
...                             AwsConsoleAction=1
...                             AwsConsoleSignIn=3
...                             NextToken=false
...                             eventtype=
...                             delta=
...                             errormessage=
...                             warningcount=
...                             criticalcount=5
...                             result=CRITICAL: Number of events: 10.00 | 'events_count'=10.00;;;0;
@{countevents_values}
...                             &{countevents_value1}
...                             &{countevents_value2}
...                             &{countevents_value3}
...                             &{countevents_value4}
...                             &{countevents_value5}
...                             &{countevents_value6}
...                             &{countevents_value7}
...                             &{countevents_value8}
...                             &{countevents_value9}


*** Test Cases ***
AWS CloudTrail check trail status
    [Documentation]    Check AWS CloudTrail trail status
    [Tags]    cloud    aws    cloudtrail
    FOR    ${checktrailstatus_value}    IN    @{checktrailstatus_values}
        ${output}    Run
        ...    ${CMD} --mode=checktrailstatus --endpoint=http://localhost:3000/cloudtrail/gettrailstatus/${checktrailstatus_value.trailstatus} --trail-name=${checktrailstatus_value.trailname}
        ${output}    Strip String    ${output}
        Should Be Equal As Strings
        ...    ${output}
        ...    ${checktrailstatus_value.result}
        ...    Wrong output result for check trail status of ${checktrailstatus_value}.{\n}Command output:{\n}${output}
    END

AWS CloudTrail count events
    [Documentation]    Check AWS CloudTrail count events
    [Tags]    cloud    aws    cloudtrail
    FOR    ${countevents_value}    IN    @{countevents_values}
        ${command}    Catenate
        ...    ${CMD}
        ...    --mode=countevents
        ...    --endpoint=http://localhost:3000/cloudtrail/events/AwsApiCall/${countevents_value.AwsApiCall}/AwsServiceEvent/${countevents_value.AwsServiceEvent}/AwsConsoleAction/${countevents_value.AwsConsoleAction}/AwsConsoleSignIn/${countevents_value.AwsConsoleSignIn}/NextToken/${countevents_value.NextToken}
        ${length}    Get Length    ${countevents_value.eventtype}
        IF    ${length} > 0
            ${command}    Catenate    ${command}    --event-type=${countevents_value.eventtype}
        END
        ${length}    Get Length    ${countevents_value.delta}
        IF    ${length} > 0
            ${command}    Catenate    ${command}    --delta=${countevents_value.delta}
        END
        ${length}    Get Length    ${countevents_value.errormessage}
        IF    ${length} > 0
            ${command}    Catenate    ${command}    --error-message=${countevents_value.errormessage}
        END
        ${length}    Get Length    ${countevents_value.warningcount}
        IF    ${length} > 0
            ${command}    Catenate    ${command}    --warning-count=${countevents_value.warningcount}
        END
        ${length}    Get Length    ${countevents_value.criticalcount}
        IF    ${length} > 0
            ${command}    Catenate    ${command}    --critical-count=${countevents_value.criticalcount}
        END
        ${output}    Run    ${command}
        ${output}    Strip String    ${output}
        Should Be Equal As Strings
        ...    ${output}
        ...    ${countevents_value.result}
        ...    Wrong output result for count events of ${countevents_value}.{\n}Command output:{\n}${output}
    END


*** Keywords ***
Start Mockoon
    ${process}    Start Process
    ...    mockoon-cli
    ...    start
    ...    --data
    ...    ${MOCKOON_JSON}
    ...    --port
    ...    3000
    Sleep    5s

Stop Mockoon
    Terminate All Processes
