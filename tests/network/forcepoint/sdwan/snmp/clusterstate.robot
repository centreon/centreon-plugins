*** Settings ***
Documentation       Forcepoint SD-WAN Mode ClusterState

Resource            ${CURDIR}${/}../..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Test Timeout        120s


*** Variables ***
${CMD}                                          ${CENTREON_PLUGINS} --plugin=network::forcepoint::sdwan::snmp::plugin

*** Test Cases ***
ClusterState ${tc}
    [Tags]    network    forcepoint    sdwan     snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=cluster-state
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/forcepoint/sdwan/snmp/forcepoint
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                           expected_result    --
            ...      1     ${EMPTY}                                                OK: Node status is 'standby' [Member id: 2]
            ...      2     --warning-status='\\\%{node_status} =~ /standby/i'      WARNING: Node status is 'standby' [Member id: 2]
            ...      3     --critical-status='\\\%{node_status} =~ /standby/i'     CRITICAL: Node status is 'standby' [Member id: 2]
            ...      4     --unknown-status='\\\%{node_status} =~ /standby/i'      UNKNOWN: Node status is 'standby' [Member id: 2]
