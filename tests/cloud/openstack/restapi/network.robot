*** Settings ***
Documentation       OpenStack Port

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}openstack.mockoon.json
${HOSTNAME}         127.0.0.1
${APIPORT}          3000
${CMD}              ${CENTREON_PLUGINS} 
...                 --plugin=cloud::openstack::restapi::plugin
...                 --mode=network
...                 --identity-url=http://${HOSTNAME}:${APIPORT}/v3
...                 --username=xxx
...                 --password=P@s$WoRdZ


*** Test Cases ***
Port ${tc}
    [Tags]    cloud     openstack     api
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command Without Connector And Check Result As Strings   ${command}    ${expected_string}

    Examples:        tc    extraoptions                                                                 expected_string    --
            ...      1     ${EMPTY}                                                                     OK: Network count: 2 - All networks are ok | 'network.count'=2;;;0;
            ...      2     --disco-format                                                               <?xml version="1.0" encoding="utf-8"?> <data> <element>id</element> <element>status</element> <element>name</element> <element>admin_state_up</element> <element>shared</element> <element>port_security_enabled</element> <element>router_external</element> <element>project_id</element> <element>mtu</element> </data>
            ...      3     --disco-show                                                                 <?xml version="1.0" encoding="utf-8"?> <data> <label admin_state_up="True" id="a1b2c3d4-5678-90ab-cdef-1234567890ab" mtu="1450" name="private-net" port_security_enabled="False" project_id="tenant-1111" router_external="False" shared="False" status="ACTIVE"/> <label admin_state_up="True" id="b2c3d4e5-6789-01ab-cdef-2345678901bc" mtu="1450" name="public-net" port_security_enabled="False" project_id="tenant-2222" router_external="True" shared="True" status="ACTIVE"/> </data>
            ...      4     --include-name='public-net'                                                  OK: Network count: 1 - Network public-net is in ACTIVE state, Id: b2c3d4e5-6789-01ab-cdef-2345678901bc, Admin-state-up: True, Shared: True, Port-security-enabled: False, Router-external: True, Project-id: tenant-2222, Mtu: 1450 | 'network.count'=1;;;0;
            ...      5     --include-status=ACTIVE                                                      OK: Network count: 2 - All networks are ok | 'network.count'=2;;;0;
            ...      6     --include-admin-state-up=True                                                OK: Network count: 2 - All networks are ok | 'network.count'=2;;;0;
            ...      7     --include-shared=True                                                        OK: Network count: 1 - Network public-net is in ACTIVE state, Id: b2c3d4e5-6789-01ab-cdef-2345678901bc, Admin-state-up: True, Shared: True, Port-security-enabled: False, Router-external: True, Project-id: tenant-2222, Mtu: 1450 | 'network.count'=1;;;0;
            ...      8     --include-port-security-enabled=True                                         OK: Network count: 0 | 'network.count'=0;;;0;
            ...      9     --include-router-external=True                                               OK: Network count: 1 - Network public-net is in ACTIVE state, Id: b2c3d4e5-6789-01ab-cdef-2345678901bc, Admin-state-up: True, Shared: True, Port-security-enabled: False, Router-external: True, Project-id: tenant-2222, Mtu: 1450 | 'network.count'=1;;;0;
            ...      10     --exclude-id='a1b2c3d4-5678-90ab-cdef-1234567890ab'                         OK: Network count: 1 - Network public-net is in ACTIVE state, Id: b2c3d4e5-6789-01ab-cdef-2345678901bc, Admin-state-up: True, Shared: True, Port-security-enabled: False, Router-external: True, Project-id: tenant-2222, Mtu: 1450 | 'network.count'=1;;;0;
            ...      11    --warning-count=:1                                                           WARNING: Network count: 2 | 'network.count'=2;0:1;;0;
            ...      12    --critical-status='%\\\{status\\\}=~/ACTIVE/'                                CRITICAL: Network private-net is in ACTIVE state - Network public-net is in ACTIVE state | 'network.count'=2;;;0;
            ...      13    --critical-admin-state-up='%\\\{admin_state_up\\\} =~/False/'                OK: Network count: 2 - All networks are ok | 'network.count'=2;;;0;
            ...      14    --warning-port-security-enabled='%\\\{port_security_enabled\\\}=~/False/'    WARNING: Port-security-enabled: False - Port-security-enabled: False | 'network.count'=2;;;0;
            ...      15    --warning-id='%\\\{id\\\}=~/b2c3d4e5-6789-01ab-cdef-2345678901bc/'           WARNING: Id: b2c3d4e5-6789-01ab-cdef-2345678901bc | 'network.count'=2;;;0;
            ...      16    --critical-shared='%\\\{shared\\\} =~/False/'                                CRITICAL: Shared: False | 'network.count'=2;;;0;
            ...      17    --include-mtu=1234                                                           OK: Network count: 0 | 'network.count'=0;;;0;
            ...      18    --critical-mtu='%\\\{mtu\\\}!~/1234/'                                        CRITICAL: Mtu: 1450 - Mtu: 1450 | 'network.count'=2;;;0;
            ...      19    --critical-router-external='%\\\{router_external\\\} =~/False/'              CRITICAL: Router-external: False | 'network.count'=2;;;0;
