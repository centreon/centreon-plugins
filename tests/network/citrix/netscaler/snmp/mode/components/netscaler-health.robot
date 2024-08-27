*** Settings ***
Documentation       Network citrix netscaler health

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::citrix::netscaler::snmp::plugin


*** Test Cases ***
check psu components ${tc}/2
    [Documentation]    mib don't seem set on the meaning of .1.3.6.1.4.1.5951.4.1.1.41.7.1.2, some client report 0 = normal and other 0 = not supported.
    [Tags]    network    citrix    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=health
    ...    --hostname=${HOSTNAME}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community='network/citrix/netscaler/snmp/mode/components/${community}'
    ...    --component=psu
    ...    --alternative-status-mapping='${alternative_status_mapping}'

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    alternative_status_mapping    community    expected_result    --
            ...      1     true        psu-citrix-v13    OK: All 4 components are ok [4/4 psus]. | 'count_psu'=4;;;;
            ...      2     ${EMPTY}    psu-citrix-v13    UNKNOWN: Power supply '1' status is 'not supported' - Power supply '2' status is 'not supported' - Power supply '3' status is 'not supported' - Power supply '4' status is 'not supported' | 'count_psu'=4;;;;
