*** Settings ***
Documentation       Check arp table

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      /usr/lib/centreon/plugins/centreon_linux_snmp.pl --plugin=os::linux::snmp::plugin


*** Test Cases ***
arp-connectors ${tc}
    [Tags]    os    linux
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=arp
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=os/linux/snmp/network-interfaces
    ...    --snmp-timeout=1
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                   expected_result    --
            ...      1     --filter-macaddr                OK: total entries 3 - duplicate mac address 0 - duplicate ip address 0 | 'arp.total.entries.count'=3;;;0; 'arp.duplicate.macaddr.count'=0;;;0; 'arp.duplicate.ipaddr.count'=0;;;0;
            ...      2     --filter-ipaddr                 OK: total entries 3 - duplicate mac address 0 - duplicate ip address 0 | 'arp.total.entries.count'=3;;;0; 'arp.duplicate.macaddr.count'=0;;;0; 'arp.duplicate.ipaddr.count'=0;;;0;
            ...      3     --warning-total-entries         OK: total entries 3 - duplicate mac address 0 - duplicate ip address 0 | 'arp.total.entries.count'=3;;;0; 'arp.duplicate.macaddr.count'=0;;;0; 'arp.duplicate.ipaddr.count'=0;;;0;
            ...      4     --critical-total-entries        OK: total entries 3 - duplicate mac address 0 - duplicate ip address 0 | 'arp.total.entries.count'=3;;;0; 'arp.duplicate.macaddr.count'=0;;;0; 'arp.duplicate.ipaddr.count'=0;;;0;
            ...      5     --critical-duplicate-ipaddr     OK: total entries 3 - duplicate mac address 0 - duplicate ip address 0 | 'arp.total.entries.count'=3;;;0; 'arp.duplicate.macaddr.count'=0;;;0; 'arp.duplicate.ipaddr.count'=0;;;0;
            ...      6     --critical-duplicate-macaddr    OK: total entries 3 - duplicate mac address 0 - duplicate ip address 0 | 'arp.total.entries.count'=3;;;0; 'arp.duplicate.macaddr.count'=0;;;0; 'arp.duplicate.ipaddr.count'=0;;;0;
            ...      7     --warning-duplicate-ipaddr      OK: total entries 3 - duplicate mac address 0 - duplicate ip address 0 | 'arp.total.entries.count'=3;;;0; 'arp.duplicate.macaddr.count'=0;;;0; 'arp.duplicate.ipaddr.count'=0;;;0;
            ...      8     --warning-duplicate-macaddr     OK: total entries 3 - duplicate mac address 0 - duplicate ip address 0 | 'arp.total.entries.count'=3;;;0; 'arp.duplicate.macaddr.count'=0;;;0; 'arp.duplicate.ipaddr.count'=0;;;0;
            ...      9     ${EMPTY}                        OK: total entries 3 - duplicate mac address 0 - duplicate ip address 0 | 'arp.total.entries.count'=3;;;0; 'arp.duplicate.macaddr.count'=0;;;0; 'arp.duplicate.ipaddr.count'=0;;;0;
