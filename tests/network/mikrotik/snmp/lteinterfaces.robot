*** Settings ***

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s
Test Setup          Ctn Generic Suite Setup

*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::mikrotik::snmp::plugin


*** Test Cases ***
lteinterfaces ${tc}
    [Tags]    network    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=lte-interfaces
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/mikrotik/snmp/mikrotik-chateau-lte6
    ...    --snmp-timeout=1
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc     extra_options                                                 expected_result    --
            ...      1      ${EMPTY}                                                      OK: Interface 'lte1' [imei: 863359044096580] Status : up (admin: up), rsrp: -94 dBm, rsrq: -13 dB, rssi: -65 dBm, sinr: 0 dB | 'lte1~863359044096580#interface.signal.rsrp.dbm'=-94;;;0; 'lte1~863359044096580#interface.signal.rsrq.db'=-13;;;0; 'lte1~863359044096580#interface.signal.rssi.dbm'=-65;;;0; 'lte1~863359044096580#interface.signal.sinr.dbm'=0;;;0;
            ...      2      --add-status                                                  OK: Interface 'lte1' [imei: 863359044096580] Status : up (admin: up), rsrp: -94 dBm, rsrq: -13 dB, rssi: -65 dBm, sinr: 0 dB | 'lte1~863359044096580#interface.signal.rsrp.dbm'=-94;;;0; 'lte1~863359044096580#interface.signal.rsrq.db'=-13;;;0; 'lte1~863359044096580#interface.signal.rssi.dbm'=-65;;;0; 'lte1~863359044096580#interface.signal.sinr.dbm'=0;;;0;
            ...      3      --add-global                                                  OK: Total port : 1, AdminStatus Up : 1, AdminStatus Down : 0, OperStatus Up : 1, OperStatus Down : 0 - Interface 'lte1' [imei: 863359044096580] rsrp: -94 dBm, rsrq: -13 dB, rssi: -65 dBm, sinr: 0 dB | 'total.interfaces.count'=1;;;0;1 'total.interfaces.admin.up.count'=1;;;0;1 'total.interfaces.admin.down.count'=0;;;0;1 'total.interfaces.operational.up.count'=1;;;0;1 'total.interfaces.operational.down.count'=0;;;0;1 'lte1~863359044096580#interface.signal.rsrp.dbm'=-94;;;0; 'lte1~863359044096580#interface.signal.rsrq.db'=-13;;;0; 'lte1~863359044096580#interface.signal.rssi.dbm'=-65;;;0; 'lte1~863359044096580#interface.signal.sinr.dbm'=0;;;0;
            ...      4      --add-traffic                                                 OK: Interface 'lte1' [imei: 863359044096580] Traffic In : Buffer creation, Traffic Out : Buffer creation, rsrp: -94 dBm, rsrq: -13 dB, rssi: -65 dBm, sinr: 0 dB | 'lte1~863359044096580#interface.signal.rsrp.dbm'=-94;;;0; 'lte1~863359044096580#interface.signal.rsrq.db'=-13;;;0; 'lte1~863359044096580#interface.signal.rssi.dbm'=-65;;;0; 'lte1~863359044096580#interface.signal.sinr.dbm'=0;;;0;
            ...      5      --add-errors                                                  OK: Interface 'lte1' [imei: 863359044096580] Packets In Discard : Buffer creation, Packets In Error : Buffer creation, Packets Out Discard : Buffer creation, Packets Out Error : Buffer creation, rsrp: -94 dBm, rsrq: -13 dB, rssi: -65 dBm, sinr: 0 dB | 'lte1~863359044096580#interface.signal.rsrp.dbm'=-94;;;0; 'lte1~863359044096580#interface.signal.rsrq.db'=-13;;;0; 'lte1~863359044096580#interface.signal.rssi.dbm'=-65;;;0; 'lte1~863359044096580#interface.signal.sinr.dbm'=0;;;0;
            ...      6      --add-cast                                                    OK: Interface 'lte1' [imei: 863359044096580] rsrp: -94 dBm, rsrq: -13 dB, rssi: -65 dBm, sinr: 0 dB, In Ucast : Buffer creation, In Bcast : Buffer creation, In Mcast : Buffer creation, Out Ucast : Buffer creation, Out Bcast : Buffer creation, Out Mcast : Buffer creation | 'lte1~863359044096580#interface.signal.rsrp.dbm'=-94;;;0; 'lte1~863359044096580#interface.signal.rsrq.db'=-13;;;0; 'lte1~863359044096580#interface.signal.rssi.dbm'=-65;;;0; 'lte1~863359044096580#interface.signal.sinr.dbm'=0;;;0;    
            ...      7      --check-metrics='\\\%{opstatus} eq "up"'                      OK: Interface 'lte1' [imei: 863359044096580] Status : up (admin: up), rsrp: -94 dBm, rsrq: -13 dB, rssi: -65 dBm, sinr: 0 dB | 'lte1~863359044096580#interface.signal.rsrp.dbm'=-94;;;0; 'lte1~863359044096580#interface.signal.rsrq.db'=-13;;;0; 'lte1~863359044096580#interface.signal.rssi.dbm'=-65;;;0; 'lte1~863359044096580#interface.signal.sinr.dbm'=0;;;0;
            ...      8      --warning-status='\\\%{admstatus} eq "up"'                    WARNING: Interface 'lte1' [imei: 863359044096580] Status : up (admin: up) | 'lte1~863359044096580#interface.signal.rsrp.dbm'=-94;;;0; 'lte1~863359044096580#interface.signal.rsrq.db'=-13;;;0; 'lte1~863359044096580#interface.signal.rssi.dbm'=-65;;;0; 'lte1~863359044096580#interface.signal.sinr.dbm'=0;;;0;
            ...      9      --critical-status='\\\%{admstatus} eq "up"'                   CRITICAL: Interface 'lte1' [imei: 863359044096580] Status : up (admin: up) | 'lte1~863359044096580#interface.signal.rsrp.dbm'=-94;;;0; 'lte1~863359044096580#interface.signal.rsrq.db'=-13;;;0; 'lte1~863359044096580#interface.signal.rssi.dbm'=-65;;;0; 'lte1~863359044096580#interface.signal.sinr.dbm'=0;;;0;
            ...      10     --warning-rsrq='-10' --critical-rsrq='0'                      CRITICAL: Interface 'lte1' [imei: 863359044096580] rsrq: -13 dB | 'lte1~863359044096580#interface.signal.rsrp.dbm'=-94;;;0; 'lte1~863359044096580#interface.signal.rsrq.db'=-13;0:-10;0:0;0; 'lte1~863359044096580#interface.signal.rssi.dbm'=-65;;;0; 'lte1~863359044096580#interface.signal.sinr.dbm'=0;;;0;
            ...      11     --warning-sinr='-1' --critical-sinr='10'                      WARNING: Interface 'lte1' [imei: 863359044096580] sinr: 0 dB | 'lte1~863359044096580#interface.signal.rsrp.dbm'=-94;;;0; 'lte1~863359044096580#interface.signal.rsrq.db'=-13;;;0; 'lte1~863359044096580#interface.signal.rssi.dbm'=-65;;;0; 'lte1~863359044096580#interface.signal.sinr.dbm'=0;0:-1;0:10;0;
            ...      12     --units-traffic                                               OK: Interface 'lte1' [imei: 863359044096580] Status : up (admin: up), rsrp: -94 dBm, rsrq: -13 dB, rssi: -65 dBm, sinr: 0 dB | 'lte1~863359044096580#interface.signal.rsrp.dbm'=-94;;;0; 'lte1~863359044096580#interface.signal.rsrq.db'=-13;;;0; 'lte1~863359044096580#interface.signal.rssi.dbm'=-65;;;0; 'lte1~863359044096580#interface.signal.sinr.dbm'=0;;;0;    