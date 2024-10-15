*** Settings ***
Documentation       Network citrix netscaler health

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::cisco::standard::snmp::plugin


*** Test Cases ***
arp ${tc}
    [Tags]    network    citrix    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=arp
    ...    --hostname=${HOSTNAME}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-community=network/cisco/standard/snmp/cisco
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                         expected_result    --
            ...      1     --verbose                                                             OK: total entries 3 - duplicate mac address 0 - duplicate ip address 0 | 'arp.total.entries.count'=3;;;0; 'arp.duplicate.macaddr.count'=0;;;0; 'arp.duplicate.ipaddr.count'=0;;;0;
            ...      2     --warning-total-entries --critical-total-entries                      OK: total entries 3 - duplicate mac address 0 - duplicate ip address 0 | 'arp.total.entries.count'=3;;;0; 'arp.duplicate.macaddr.count'=0;;;0; 'arp.duplicate.ipaddr.count'=0;;;0;
            ...      3     --filter-macaddr=1                                                    OK: total entries 3 - duplicate mac address 0 - duplicate ip address 0 | 'arp.total.entries.count'=3;;;0; 'arp.duplicate.macaddr.count'=0;;;0; 'arp.duplicate.ipaddr.count'=0;;;0;
            ...      4     --filter-ipaddr=5                                                     OK: total entries 0 - duplicate mac address 0 - duplicate ip address 0 | 'arp.total.entries.count'=0;;;0; 'arp.duplicate.macaddr.count'=0;;;0; 'arp.duplicate.ipaddr.count'=0;;;0;
            ...      5     --warning-duplicate-macaddr=0:3 --critical-duplicate-macaddr=3:0      CRITICAL: duplicate mac address 0 | 'arp.total.entries.count'=3;;;0; 'arp.duplicate.macaddr.count'=0;0:3;3:0;0; 'arp.duplicate.ipaddr.count'=0;;;0;
            ...      6     --warning-duplicate-ipaddr=1:0 --critical-duplicate-ipaddr=1:0        CRITICAL: duplicate ip address 0 | 'arp.total.entries.count'=3;;;0; 'arp.duplicate.macaddr.count'=0;;;0; 'arp.duplicate.ipaddr.count'=0;1:0;1:0;0;
            ...      7     --warning-duplicate-ipaddr=0:2 --critical-total-entries=2:0           CRITICAL: total entries 3 | 'arp.total.entries.count'=3;;2:0;0; 'arp.duplicate.macaddr.count'=0;;;0; 'arp.duplicate.ipaddr.count'=0;0:2;;0;