*** Settings ***

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource
Suite Setup         Ctn Generic Suite Setup
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::cisco::standard::snmp::plugin


*** Test Cases ***
configuration ${tc}
    [Tags]    network    configuration    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=configuration
    ...    --hostname=${HOSTNAME}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/cisco/standard/snmp/cisco
    ...    ${extra_options}

    Ctn Run Command Without Connector And Check Result As Strings    ${tc}    ${command}    ${expected_result}

    Examples:        tc    extra_options                                     expected_result    --
            ...      1     ${EMPTY}                                          OK: running config is ahead of startup config since -1y 3M 1w 4d 18h 40m 35s. changes will be lost in case of a reboot | 'configuration.running.ahead.since.seconds'=-40463790.78s;;;0;
            ...      2     --warning-config-running-ahead=0                  WARNING: running config is ahead of startup config since -1y 3M 1w 4d 18h 40m 35s. changes will be lost in case of a reboot | 'configuration.running.ahead.since.seconds'=-40463790.78s;0:0;;0;
            ...      3     --critical-config-running-ahead=10                CRITICAL: running config is ahead of startup config since -1y 3M 1w 4d 18h 40m 35s. changes will be lost in case of a reboot | 'configuration.running.ahead.since.seconds'=-40463790.78s;;0:10;0;