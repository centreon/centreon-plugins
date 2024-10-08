*** Settings ***
Documentation       Network citrix netscaler health

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::cisco::standard::snmp::plugin


*** Test Cases ***
interfaces ${tc}
    [Tags]    network    citrix    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=interfaces
    ...    --hostname=${HOSTNAME}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/cisco/standard/snmp/slim_cisco_fc_fe
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                         expected_result    --
            ...      1     --oid-display='ifName'                                                UNKNOWN: Can't construct cache...
            ...      2     --oid-extra-display='ifdesc'                                          UNKNOWN: Can't construct cache...
            ...      3     --verbose                                                             UNKNOWN: Can't construct cache...
            ...      4     --show-cache                                                          $VAR1 = {};
            ...      5     --display-transform-dst='ens'                                         UNKNOWN: Can't construct cache...
            ...      6     --display-transform-src='eth'                                         UNKNOWN: Can't construct cache...
