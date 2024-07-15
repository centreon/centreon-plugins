*** Settings ***
Documentation       Azure PolicyInsights PolicyStates plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}         ${CURDIR}${/}cloud-azure-policyinsights-policystates.json

${LOGIN_ENDPOINT}       http://localhost:3000/login
${CMD}                  ${CENTREON_PLUGINS} --plugin=cloud::azure::policyinsights::policystates::plugin --subscription=subscription --tenant=tenant --client-id=client_id --client-secret=secret --statefile-dir=/tmp/cache/ --login-endpoint=${LOGIN_ENDPOINT}

&{compliance_value1}
...                     endpoint=http://localhost:3000/ok
...                     policyname=
...                     resourcelocation=
...                     resourcetype=
...                     result=OK: Number of non compliant policies: 0 - All compliances states are ok | 'policies.non_compliant.count'=0;;;0;
&{compliance_value2}
...                     endpoint=http://localhost:3000/oknextlink
...                     policyname=9daedab3-fb2d-461e-b861-71790eead4f6
...                     resourcelocation=
...                     resourcetype=
...                     result=OK: Number of non compliant policies: 0 - All compliances states are ok | 'policies.non_compliant.count'=0;;;0;
&{compliance_value3}
...                     endpoint=http://localhost:3000/nok1
...                     policyname=9daedab3-fb2d-461e-b861-71790eead4f6
...                     resourcelocation=fr
...                     resourcetype=
...                     result=CRITICAL: Compliance state for policy '9daedab3-fb2d-461e-b861-71790eead4f6' on resource 'mypubip1' is 'NonCompliant' | 'policies.non_compliant.count'=1;;;0;
&{compliance_value4}
...                     endpoint=http://localhost:3000/nok2
...                     policyname=9daedab3-fb2d-461e-b861-71790eead4f6
...                     resourcelocation=fr
...                     resourcetype=ip
...                     result=CRITICAL: Compliance state for policy '9daedab3-fb2d-461e-b861-71790eead4f6' on resource 'mypubip1' is 'NonCompliant' - Compliance state for policy '9daedab3-fb2d-461e-b861-71790eead4f6' on resource 'mypubip2' is 'NonCompliant' | 'policies.non_compliant.count'=2;;;0;
@{compliance_values}    &{compliance_value1}    &{compliance_value2}    &{compliance_value3}    &{compliance_value4}


*** Test Cases ***
Azure PolicyInsights PolicyStates compliance
    [Documentation]    Check Azure PolicyInsights PolicyStates compliance
    [Tags]    cloud    azure    policyinsights policystates
    FOR    ${compliance_value}    IN    @{compliance_values}
        ${command}    Catenate
        ...    ${CMD}
        ...    --mode=compliance
        ...    --management-endpoint=${compliance_value.endpoint}
        ${length}    Get Length    ${compliance_value.policyname}
        IF    ${length} > 0
            ${command}    Catenate    ${command}    --policy-name=${compliance_value.policyname}
        END
        ${length}    Get Length    ${compliance_value.resourcelocation}
        IF    ${length} > 0
            ${command}    Catenate    ${command}    --resource-location=${compliance_value.resourcelocation}
        END
        ${length}    Get Length    ${compliance_value.resourcetype}
        IF    ${length} > 0
            ${command}    Catenate    ${command}    --resource-type=${compliance_value.resourcetype}
        END
        ${output}    Run    ${command}
        ${output}    Strip String    ${output}
        Should Be Equal As Strings
        ...    ${output}
        ...    ${compliance_value.result}
        ...    Wrong output result for compliance of ${compliance_value}.{\n}Command output:{\n}${output}
    END
