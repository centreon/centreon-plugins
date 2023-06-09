*** Settings ***
Documentation       AWS CloudTrail plugin

Library             OperatingSystem
Library             String


*** Variables ***
${CENTREON_PLUGINS}             ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}src${/}centreon_plugins.pl
${MOCKOON_JSONS_DIR}            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources${/}mockoon${/}

${CMD}                          perl ${CENTREON_PLUGINS} --plugin=cloud::aws::cloudtrail::plugin --custommode=paws --region=eu-west --aws-secret-key=secret --aws-access-key=key

${mockoonfile}                  cloud-aws-cloudtrail.json
&{checktrailstatus_value1}
...    trailstatus=true
...    trailname=TrailName
...    result=OK: Trail is logging: 1 | 'trail_is_logging'=1;;;0;
&{checktrailstatus_value2}
...    trailstatus=false
...    trailname=TrailName
...    result=CRITICAL: Trail is logging: 0 | 'trail_is_logging'=0;;;0;
@{checktrailstatus_values}      &{checktrailstatus_value1}    &{checktrailstatus_value2}


*** Test Cases ***
AWS CloudTrail check trail status
    [Documentation]    Chek AWS CloudTrail trail status
    [Tags]    cloud    aws    cloudtrail
    Run    mockoon-cli start --data ${MOCKOON_JSONS_DIR}${mockoonfile} --port 3000
    FOR    ${checktrailstatus_value}    IN    @{checktrailstatus_values}
        ${output} =    Run
        ...    ${CMD} --mode=checktrailstatus --endpoint=http://localhost:3000/cloudtrail/gettrailstatus/${checktrailstatus_value.trailstatus} --trail-name=${checktrailstatus_value.trailname}
        Should Be Equal    ${output}    ${checktrailstatus_value.result}
    END
