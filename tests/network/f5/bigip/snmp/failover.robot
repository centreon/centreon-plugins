*** Settings ***

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}                                          ${CENTREON_PLUGINS} --plugin=network::f5::bigip::snmp::plugin

*** Test Cases ***
failover ${tc}
    [Tags]    network
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=failover
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/f5/bigip/snmp/slim-f5-bigip
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                           expected_result    --
            ...      1     ${EMPTY}                                                                OK: Sync status is 'inSync' - Failover status is 'active'
            ...      2     --filter-counters='.*'                                                  OK: Sync status is 'inSync' - Failover status is 'active'
            ...      3     --warning-sync-status='\\\%{syncstatus} eq "inSync"'                    WARNING: Sync status is 'inSync'
            ...      4     --critical-sync-status='\\\%{syncstatus} =~ /inSync/'                   CRITICAL: Sync status is 'inSync'
            ...      5     --warning-failover-status='\\\%{failoverstatus} eq "active"'            WARNING: Failover status is 'active'
            ...      6     --critical-failover-status='\\\%{failoverstatus} =~ /active/'           CRITICAL: Failover status is 'active'