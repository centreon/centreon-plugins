*** Settings ***
Documentation       Azure PolicyInsights PolicyStates plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}         ${CURDIR}${/}cloud-azure-policyinsights-policystates.json

${BASE_URL}             http://${HOSTNAME}:${APIPORT}
${LOGIN_ENDPOINT}       ${BASE_URL}/login
${CMD}                  ${CENTREON_PLUGINS} --plugin=cloud::azure::policyinsights::policystates::plugin --subscription=subscription --tenant=tenant --client-id=client_id --client-secret=secret --statefile-dir=/dev/shm/ --login-endpoint=${LOGIN_ENDPOINT}


*** Test Cases ***
Azure PolicyInsights PolicyStates compliance ${tc}
    [Documentation]    Check Azure PolicyInsights PolicyStates compliance
    [Tags]    cloud    azure    policyinsights policystates
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=compliance
    ...    --management-endpoint=${endpoint}
       
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:         tc  endpoint                     policyname                                resourcelocation    resourcetype    expected_result    --
            ...       1   ${BASE_URL}/ok               ${EMPTY}                                  ${EMPTY}            ${EMPTY}        OK: Number of non compliant policies: 0 - All compliances states are ok | 'policies.non_compliant.count'=0;;;0;
            ...       2   ${BASE_URL}/oknextlink       9daedab3-fb2d-461e-b861-71790eead4f6      ${EMPTY}            ${EMPTY}        OK: Number of non compliant policies: 0 - All compliances states are ok | 'policies.non_compliant.count'=0;;;0;
            ...       3   ${BASE_URL}/nok1             9daedab3-fb2d-461e-b861-71790eead4f6      fr                  ${EMPTY}        CRITICAL: Compliance state for policy '9daedab3-fb2d-461e-b861-71790eead4f6' on resource 'mypubip1' is 'NonCompliant' | 'policies.non_compliant.count'=1;;;0;
            ...       4   ${BASE_URL}/nok2             9daedab3-fb2d-461e-b861-71790eead4f6      fr                  ip              CRITICAL: Compliance state for policy '9daedab3-fb2d-461e-b861-71790eead4f6' on resource 'mypubip1' is 'NonCompliant' - Compliance state for policy '9daedab3-fb2d-461e-b861-71790eead4f6' on resource 'mypubip2' is 'NonCompliant' | 'policies.non_compliant.count'=2;;;0;