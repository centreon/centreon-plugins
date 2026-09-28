*** Settings ***
Documentation       AWS CloudWatch list-metrics mode

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=cloud::aws::cloudwatch::plugin
...         --custommode=awscli --region=eu-west
...         --aws-secret-key=secret --aws-access-key=key


*** Test Cases ***
AWS CloudWatch get-alarms simple ${tc}
    [Tags]    cloud    aws    cloudwatch    listmetrics
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=get-alarms
    ...    --command=${CURDIR}${/}getalarms_bin${/}mock_aws_single
    ...    ${extraoptions}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:    tc    extraoptions                                                                 expected_result    --
        ...      1     ${EMPTY}                                                                     CRITICAL: 1 problem(s) detected | 'alerts'=1;;;0;
        ...      2     --warning-status='\\\%{state_value} =~ /ALARM/' --critical-status=''         WARNING: 1 problem(s) detected | 'alerts'=1;;;0;

AWS CloudWatch get-alarms multiple ${tc}
    [Tags]    cloud    aws    cloudwatch    listmetrics
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=get-alarms
    ...    --command=${CURDIR}${/}getalarms_bin${/}mock_aws_multiple
    ...    ${extraoptions}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:    tc    extraoptions                                                                 expected_result    --
        ...      1     ${EMPTY}                                                                     CRITICAL: 1 problem(s) detected | 'alerts'=1;;;0;
        ...      2     --warning-status='\\\%{state_value} =~ /ALARM/' --critical-status=''         WARNING: 1 problem(s) detected | 'alerts'=1;;;0;
        ...      3     --critical-status='1'                                                        CRITICAL: 3 problem(s) detected | 'alerts'=3;;;0;
