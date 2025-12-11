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
...                 --mode=port
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
            ...      1     ${EMPTY}                                                                     CRITICAL: Port port-2 is in DOWN state | 'port.count'=2;;;0;
            ...      2     --disco-format                                                               <?xml version="1.0" encoding="utf-8"?> <data> <element>id</element> <element>status</element> <element>name</element> <element>description</element> <element>admin_state_up</element> <element>port_security_enabled</element> <element>project_id</element> <element>admin_state_up</element> <element>port_security_enabled</element> </data>
            ...      3     --disco-show                                                                 <?xml version="1.0" encoding="utf-8"?> <data> <label admin_state_up="True" description="test" id="a1b2c3d4-5678-90ab-cdef-1234567890ab" name="port-1" port_security_enabled="False" project_id="tenant-1111" status="ACTIVE"/> <label admin_state_up="True" description="test2" id="b2c3d4e5-6789-01ab-cdef-2345678901bc" name="port-2" port_security_enabled="False" project_id="tenant-1111" status="DOWN"/> </data>
            ...      4     --include-name='port-1'                                                      OK: Port count: 1 - Port port-1 is in ACTIVE state, Id: a1b2c3d4-5678-90ab-cdef-1234567890ab, Description: test, Admin-state-up: True, Port-security-enabled: False, Project-id: tenant-1111, Admin-state-up: True, Port-security-enabled: False | 'port.count'=1;;;0;
            ...      5     --include-status=ACTIVE                                                      OK: Port count: 1 - Port port-1 is in ACTIVE state, Id: a1b2c3d4-5678-90ab-cdef-1234567890ab, Description: test, Admin-state-up: True, Port-security-enabled: False, Project-id: tenant-1111, Admin-state-up: True, Port-security-enabled: False | 'port.count'=1;;;0;
            ...      6     --exclude-description='test 1'                                               CRITICAL: Port port-2 is in DOWN state | 'port.count'=2;;;0;
            ...      7     --include-admin-state-up=True                                                CRITICAL: Port port-2 is in DOWN state | 'port.count'=2;;;0;
            ...      8     --include-port-security-enabled=True                                         OK: Port count: 0 | 'port.count'=0;;;0;
            ...      9     --exclude-id='a1b2c3d4-5678-90ab-cdef-1234567890ab'                          CRITICAL: Port port-2 is in DOWN state | 'port.count'=1;;;0;
            ...      10    --warning-count=:1                                                           CRITICAL: Port port-2 is in DOWN state WARNING: Port count: 2 | 'port.count'=2;0:1;;0;
            ...      11    --critical-status='%\\\{status\\\}=~/DOWN/'                                  CRITICAL: Port port-2 is in DOWN state | 'port.count'=2;;;0;
            ...      12    --critical-description='%\\\{description\\\}=~/test2/'                       CRITICAL: Port port-2 is in DOWN state, Description: test2 | 'port.count'=2;;;0;
            ...      13    --critical-admin-state-up='%\\\{admin_state_up\\\} =~/False/'                CRITICAL: Port port-2 is in DOWN state | 'port.count'=2;;;0;
            ...      14    --warning-port-security-enabled='%\\\{port_security_enabled\\\}=~/False/'    CRITICAL: Port port-2 is in DOWN state, Port-security-enabled: False, Port-security-enabled: False WARNING: Port-security-enabled: False, Port-security-enabled: False | 'port.count'=2;;;0;
            ...      15    --warning-id='%\\\{id\\\}=~/b2c3d4e5-6789-01ab-cdef-2345678901bc/'           CRITICAL: Port port-2 is in DOWN state, Id: b2c3d4e5-6789-01ab-cdef-2345678901bc | 'port.count'=2;;;0;

