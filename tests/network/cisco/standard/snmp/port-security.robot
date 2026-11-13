*** Settings ***
Documentation       Cisco standard SNMP plugin, port-security mode (CISCO-PORT-SECURITY-MIB).
...                 The cases share a statefile (violations delta): they must run in this order.

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::cisco::standard::snmp::plugin


*** Test Cases ***
port-security ${tc}
    [Tags]    network    cisco    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=port-security
    ...    --hostname=${HOSTNAME}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/cisco/standard/snmp/${walk}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    walk                                    extra_options                                                                                                expected_result    --
            ...      1     cisco-catalyst-port-security            --include-interface='^Gi1/0/[1-4]$'                                                                          OK: All port security interfaces are ok | 'Gi1/0/1#interface.portsecurity.secure.mac.addresses.count'=0;;;0;1 'Gi1/0/2#interface.portsecurity.secure.mac.addresses.count'=1;;;0;1 'Gi1/0/3#interface.portsecurity.secure.mac.addresses.count'=0;;;0;1 'Gi1/0/4#interface.portsecurity.secure.mac.addresses.count'=1;;;0;2
            ...      2     cisco-catalyst-port-security-faults     --include-interface='^Gi1/0/[1-4]$'                                                                          WARNING: Interface 'Gi1/0/4' port security: enabled, status: shutdown, violation action: dropNotify | 'Gi1/0/1#interface.portsecurity.secure.mac.addresses.count'=0;;;0;1 'Gi1/0/1#interface.portsecurity.violations.count'=0;;;0; 'Gi1/0/2#interface.portsecurity.secure.mac.addresses.count'=1;;;0;1 'Gi1/0/2#interface.portsecurity.violations.count'=2;;;0; 'Gi1/0/3#interface.portsecurity.secure.mac.addresses.count'=0;;;0;1 'Gi1/0/3#interface.portsecurity.violations.count'=0;;;0; 'Gi1/0/4#interface.portsecurity.secure.mac.addresses.count'=1;;;0;2 'Gi1/0/4#interface.portsecurity.violations.count'=3;;;0;
            ...      3     cisco-catalyst-port-security            --include-interface='^Gi1/0/[1-4]$'                                                                          OK: All port security interfaces are ok | 'Gi1/0/1#interface.portsecurity.secure.mac.addresses.count'=0;;;0;1 'Gi1/0/1#interface.portsecurity.violations.count'=0;;;0; 'Gi1/0/2#interface.portsecurity.secure.mac.addresses.count'=1;;;0;1 'Gi1/0/2#interface.portsecurity.violations.count'=0;;;0; 'Gi1/0/3#interface.portsecurity.secure.mac.addresses.count'=0;;;0;1 'Gi1/0/3#interface.portsecurity.violations.count'=0;;;0; 'Gi1/0/4#interface.portsecurity.secure.mac.addresses.count'=1;;;0;2 'Gi1/0/4#interface.portsecurity.violations.count'=0;;;0;
            ...      4     cisco-catalyst-port-security-faults     --include-interface='^Gi1/0/[1-4]$' --critical-violations=2                                                  CRITICAL: Interface 'Gi1/0/4' port security: enabled, status: shutdown, violation action: dropNotify, violations: 3 | 'Gi1/0/1#interface.portsecurity.secure.mac.addresses.count'=0;;;0;1 'Gi1/0/1#interface.portsecurity.violations.count'=0;;0:2;0; 'Gi1/0/2#interface.portsecurity.secure.mac.addresses.count'=1;;;0;1 'Gi1/0/2#interface.portsecurity.violations.count'=2;;0:2;0; 'Gi1/0/3#interface.portsecurity.secure.mac.addresses.count'=0;;;0;1 'Gi1/0/3#interface.portsecurity.violations.count'=0;;0:2;0; 'Gi1/0/4#interface.portsecurity.secure.mac.addresses.count'=1;;;0;2 'Gi1/0/4#interface.portsecurity.violations.count'=3;;0:2;0;
            ...      5     cisco-catalyst-port-security            --include-interface='^Gi1/0/2$' --expected-port-security=enabled                                             OK: Interface 'Gi1/0/2' port security: enabled (expected: enabled), status: secureup, violation action: dropNotify, secure MAC addresses: 1/1, violations : Buffer creation | 'Gi1/0/2#interface.portsecurity.secure.mac.addresses.count'=1;;;0;1
            ...      6     cisco-catalyst-port-security-faults     --include-interface='^Gi1/0/9$' --expected-port-security=enabled                                             CRITICAL: Interface 'Gi1/0/9' port security: disabled (expected: enabled), status: securedown, violation action: dropNotify | 'Gi1/0/9#interface.portsecurity.secure.mac.addresses.count'=1;;;0;1
            ...      7     cisco-catalyst-port-security            --include-interface='^Gi1/0/9$' --expected-port-security=disabled                                            CRITICAL: Interface 'Gi1/0/9' port security: enabled (expected: disabled), status: securedown, violation action: dropNotify | 'Gi1/0/9#interface.portsecurity.secure.mac.addresses.count'=1;;;0;1 'Gi1/0/9#interface.portsecurity.violations.count'=0;;;0;
            ...      8     cisco-catalyst-port-security            --include-interface='^Gi1/0/9$' --critical-status='\\\%{admin_status} eq "up" and \\\%{oper_status} ne "up"'    CRITICAL: Interface 'Gi1/0/9' port security: enabled, status: securedown, violation action: dropNotify | 'Gi1/0/9#interface.portsecurity.secure.mac.addresses.count'=1;;;0;1 'Gi1/0/9#interface.portsecurity.violations.count'=0;;;0;
            ...      9     cisco-catalyst-port-security            --oid-display=ifDescr --include-interface='GigabitEthernet1/0/(2|4)$'                                        OK: All port security interfaces are ok | 'GigabitEthernet1/0/2#interface.portsecurity.secure.mac.addresses.count'=1;;;0;1 'GigabitEthernet1/0/4#interface.portsecurity.secure.mac.addresses.count'=1;;;0;2
            ...      10    cisco-catalyst-port-security            --include-interface='^Gi1/1/' --exclude-interface='^Gi1/1/[12]$'                                             OK: All port security interfaces are ok | 'Gi1/1/3#interface.portsecurity.secure.mac.addresses.count'=0;;;0;1 'Gi1/1/4#interface.portsecurity.secure.mac.addresses.count'=0;;;0;1
            ...      11    cisco-catalyst-port-security            --include-interface='^Gi1/0/4$' --critical-secure-mac-addresses=0                                            CRITICAL: Interface 'Gi1/0/4' secure MAC addresses: 1/2 | 'Gi1/0/4#interface.portsecurity.secure.mac.addresses.count'=1;;0:0;0;2
            ...      12    cisco-catalyst-port-security            --include-interface=nothing                                                                                  UNKNOWN: No interface with port security found.
            ...      13    cisco-catalyst-port-security            --expected-port-security=foo                                                                                 UNKNOWN: Option --expected-port-security must be 'enabled', 'disabled' or empty.
