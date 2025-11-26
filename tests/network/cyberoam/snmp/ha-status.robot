*** Settings ***
Documentation       Check Cyberoam equipments in SNMP.

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::cyberoam::snmp::plugin


*** Test Cases ***
ha-status ${tc}
    [Tags]    network    cyberoam
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=ha-status
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=${SNMPCOMMUNITY}
    ...    --snmp-timeout=1
    ...    ${extra_options}

    Ctn Verify Command Without Connector Output    ${command}    ${expected_result}

    Examples:        tc    extra_options                                           SNMPCOMMUNITY                                                            expected_result    --
            ...      1     ${EMPTY}                                                network/cyberoam/snmp/slim_sophos                                        OK: HA is 'enabled' - Current HA State: 'primary' - Peer HA State: 'auxiliary' - HA Port: 'Anonymized 007' - HA IP: '192.168.42.167' - Peer IP: '192.168.42.23'
            ...      2     --warning-status='\\\%{hastate} ne "down"'              network/cyberoam/snmp/slim_sophos                                        WARNING: HA is 'enabled' - Current HA State: 'primary' - Peer HA State: 'auxiliary' - HA Port: 'Anonymized 007' - HA IP: '192.168.42.167' - Peer IP: '192.168.42.23'
            ...      3     --critical-status='\\\%{hastatus} ne "down"'            network/cyberoam/snmp/slim_sophos                                        CRITICAL: HA is 'enabled' - Current HA State: 'primary' - Peer HA State: 'auxiliary' - HA Port: 'Anonymized 007' - HA IP: '192.168.42.167' - Peer IP: '192.168.42.23'
            ...      4     --no-ha-status='UNKNOWN'                                network/cyberoam/snmp/slim_sophos_no_ha                                  UNKNOWN: Looks like HA is not enabled, or not applicable ..
