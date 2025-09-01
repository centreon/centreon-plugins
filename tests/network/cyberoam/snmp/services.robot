*** Settings ***
Documentation       Check services.

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s
Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown

*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::cyberoam::snmp::plugin


*** Test Cases ***
services ${tc}
    [Tags]    network    cyberoam
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=services
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/cyberoam/snmp/slim_sophos
    ...    --snmp-timeout=1
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                          expected_result    --
            ...      1     --component='service'                                                  OK: All 21 components are ok [21/21 services]. | 'hardware.service.count'=21;;;;
            ...      2     --filter='toto'                                                        OK: All 21 components are ok [21/21 services]. | 'hardware.service.count'=21;;;;
            ...      3     --no-component='UNKNOWN'                                               OK: All 21 components are ok [21/21 services]. | 'hardware.service.count'=21;;;;
            ...      4     --threshold-overload='service,toto,OK,running'                         OK: All 21 components are ok [21/21 services]. | 'hardware.service.count'=21;;;;
