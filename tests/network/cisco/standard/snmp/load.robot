*** Settings ***
Documentation       Network citrix netscaler health

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::cisco::standard::snmp::plugin


*** Test Cases ***
load ${tc}
    [Tags]    network    citrix    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=load
    ...    --hostname=${HOSTNAME}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/cisco/standard/snmp/cisco
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                         expected_result    --
            ...      1     --warning-core-load-1m --critical-core-load-1m                        OK:
            ...      2     --warning-core-load-5m --critical-core-load-5m                        OK:
            ...      3     --warning-core-load-15m=5 --critical-core-load-15m=1                  OK:
            ...      4     --debug                                                               OK: .1.3.6.1.4.1.9.9.109.1.1.1.1.2.1 = 1001
