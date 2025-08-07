*** Settings ***
Documentation       Check storage usage.

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s
Test Setup          Ctn Generic Suite Setup

*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::cyberoam::snmp::plugin


*** Test Cases ***
storage ${tc}
    [Tags]    network    cyberoam
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=storage
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/cyberoam/snmp/slim_sophos
    ...    --snmp-timeout=1
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}    ${tc}

    Examples:        tc    extra_options                                                                                                       expected_result    --
            ...      1     --warning-usage=0                                                                                                   WARNING: Storage Usage Total: 86.97 GB Used: 20.87 GB (24.00%) Free: 66.10 GB (76.00%) | 'used'=22411676221.44B;0:0;;0;93381984256
            ...      2     --critical-usage=0                                                                                                  CRITICAL: Storage Usage Total: 86.97 GB Used: 20.87 GB (24.00%) Free: 66.10 GB (76.00%) | 'used'=22411676221.44B;;0:0;0;93381984256