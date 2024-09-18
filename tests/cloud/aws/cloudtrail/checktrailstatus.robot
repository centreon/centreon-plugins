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
