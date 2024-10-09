*** Settings ***
Documentation       memory mode

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${SNMPCOMMUNITY}    hardware/kvm/avocent/acs/8000/avocent8000


*** Test Cases ***
Memory
    [Tags]    hardware    kvm    avocent    memory    snmp
    ${output}    Run Avocent 8000 Plugin    "memory"    ""

    ${output}    Strip String    ${output}
    Should Be Equal As Strings
    ...    ${output}
    ...    OK: Ram Total: 1.92 GB Used (-buffers/cache): 626.18 MB (31.79%) Free: 1.31 GB (68.21%), Buffer: 2.04 MB, Cached: 723.54 MB, Shared: 26.09 MB | 'used'=656592896B;;;0;2065698816 'free'=1409105920B;;;0;2065698816 'used_prct'=31.79%;;;0;100 'buffer'=2134016B;;;0; 'cached'=758689792B;;;0; 'shared'=27357184B;;;0;
    ...    Wrong output result for command:{\n}${output}{\n}{\n}{\n}

*** Keywords ***
Run Avocent 8000 Plugin
    [Arguments]    ${mode}    ${extraoptions}
    ${command}    Catenate
    ...    ${CENTREON_PLUGINS}
    ...    --plugin=hardware::kvm::avocent::acs::8000::snmp::plugin
    ...    --mode=${mode}
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=${SNMPCOMMUNITY}
    ...    ${extraoptions}

    ${output}    Run    ${command}
    RETURN    ${output}
