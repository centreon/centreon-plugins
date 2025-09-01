*** Settings ***
Documentation       Forcepoint SD-WAN Mode ClusterLoad

Resource            ${CURDIR}${/}../..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}                                          ${CENTREON_PLUGINS} --plugin=network::forcepoint::sdwan::snmp::plugin

*** Test Cases ***
Cluster-Load ${tc}
    [Tags]    network    forcepoint    sdwan     snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=cluster-load
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/forcepoint/sdwan/snmp/forcepoint
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                           expected_result    --
            ...      1     ${EMPTY}                                                OK: cluster cpu load: 3.00% | 'cluster.cpu.load.percentage'=3.00%;;;0;100 
            ...      2     --warning-cpu-load=10:                                  WARNING: cluster cpu load: 3.00% | 'cluster.cpu.load.percentage'=3.00%;10:;;0;100
            ...      3     --critical-cpu-load=5:                                  CRITICAL: cluster cpu load: 3.00% | 'cluster.cpu.load.percentage'=3.00%;;5:;0;100
