*** Settings ***
Documentation     AWS CloudWatch Logs get-logs mode

Resource          ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup       Start Mockoon    ${MOCKOON_JSON}
Suite Teardown    Stop Mockoon
Test Timeout      120s


*** Variables ***
${MOCKOON_JSON}    ${CURDIR}${/}cloud-aws-cloudwatchlogs.json

${CMD}             ${CENTREON_PLUGINS} --plugin=cloud::aws::cloudwatchlogs::plugin --mode=get-logs --region=eu-west-1 --aws-secret-key=secret --aws-access-key=key --group-name=/aws/lambda/demo-function --start-time-since=300
${PAWS}            --custommode=paws --endpoint=http://localhost:3000/logs/filter
${AWSCLI}          --custommode=awscli --command-path=${CURDIR}${/}bin


*** Test Cases ***
AWS CloudWatch Logs get-logs ${tc}
    [Documentation]    Check the log events with both custom modes.
    [Tags]    cloud    aws    cloudwatchlogs    getlogs

    ${command}    Catenate
    ...    ${CMD}
    ...    ${custommode}
    ...    ${extraoptions}
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    custommode
    ...    extraoptions
    ...    expected_result
    ...    --
    ...    1
    ...    ${PAWS}
    ...    ${EMPTY}
    ...    OK: 0 problem(s) detected | 'logs'=0;;;0;
    ...    2
    ...    ${AWSCLI}
    ...    ${EMPTY}
    ...    OK: 0 problem(s) detected | 'logs'=0;;;0;
    ...    3
    ...    ${PAWS}
    ...    --warning-status='\\\%{message} =~ /warn/i' --critical-status='\\\%{message} =~ /error|fatal/i'
    ...    CRITICAL: 2 problem(s) detected | 'logs'=2;;;0;
    ...    4
    ...    ${AWSCLI}
    ...    --warning-status='\\\%{message} =~ /warn/i' --critical-status='\\\%{message} =~ /error|fatal/i'
    ...    CRITICAL: 2 problem(s) detected | 'logs'=2;;;0;
    ...    5
    ...    ${PAWS}
    ...    --warning-status='\\\%{message} =~ /warn/i'
    ...    WARNING: 1 problem(s) detected | 'logs'=1;;;0;
    ...    6
    ...    ${AWSCLI}
    ...    --warning-status='\\\%{message} =~ /warn/i'
    ...    WARNING: 1 problem(s) detected | 'logs'=1;;;0;
    ...    7
    ...    ${PAWS}
    ...    --stream-name=app-stream-2 --critical-status='\\\%{message} =~ /error/i'
    ...    CRITICAL: 1 problem(s) detected | 'logs'=1;;;0;
    ...    8
    ...    ${AWSCLI}
    ...    --stream-name=app-stream-2 --critical-status='\\\%{message} =~ /error/i'
    ...    CRITICAL: 1 problem(s) detected | 'logs'=1;;;0;
    ...    9
    ...    ${PAWS}
    ...    --stream-name=app-stream-2 --warning-status='\\\%{stream_name} eq "app-stream-1"'
    ...    OK: 0 problem(s) detected | 'logs'=0;;;0;
    ...    10
    ...    ${AWSCLI}
    ...    --stream-name=app-stream-2 --warning-status='\\\%{stream_name} eq "app-stream-1"'
    ...    OK: 0 problem(s) detected | 'logs'=0;;;0;
    ...    11
    ...    ${PAWS}
    ...    --warning-status='\\\%{stream_name} eq "app-stream-1"'
    ...    WARNING: 2 problem(s) detected | 'logs'=2;;;0;
