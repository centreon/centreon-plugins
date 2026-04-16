*** Settings ***
Documentation       OpenStack Hypervisor

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
...                 --mode=hypervisor
...                 --identity-url=http://${HOSTNAME}:${APIPORT}/v3
...                 --username=xxx
...                 --password=P@s$WoRdZ


*** Test Cases ***
Hypervisor ${tc}
    [Tags]    cloud     openstack     api
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command Without Connector And Check Result As Strings   ${command}    ${expected_string}

    Examples:        tc    extraoptions                                                  expected_string    --
            ...      1     ${EMPTY}                                                      OK: Hypervisor count: 2 - All hypervisors are ok | 'hypervisor.count'=2;;;0;
            ...      2     --disco-format                                                <?xml version="1.0" encoding="utf-8"?> <data> <element>id</element> <element>status</element> <element>state</element> <element>hypervisor_hostname</element> <element>hypervisor_type</element> </data>
            ...      3     --disco-show                                                  <?xml version="1.0" encoding="utf-8"?> <data> <label hypervisor_hostname="compute-01" hypervisor_type="QEMU" id="1" state="up" status="enabled"/> <label hypervisor_hostname="compute-02" hypervisor_type="KVM" id="2" state="up" status="enabled"/> </data>
            ...      4     --include-hypervisor-hostname=compute-01                      OK: Hypervisor count: 1 - Hypervisor compute-01 is enabled and up, Id: 1, Hypervisor-hostname: compute-01, Hypervisor-type: QEMU | 'hypervisor.count'=1;;;0;
            ...      5     --exclude-status=enabled                                      OK: Hypervisor count: 0 | 'hypervisor.count'=0;;;0;
            ...      6     --exclude-state=up                                            OK: Hypervisor count: 0 | 'hypervisor.count'=0;;;0;
            ...      7     --include-id=2                                                OK: Hypervisor count: 1 - Hypervisor compute-02 is enabled and up, Id: 2, Hypervisor-hostname: compute-02, Hypervisor-type: KVM | 'hypervisor.count'=1;;;0;
            ...      8     --include-hypervisor-type=QEMU                                OK: Hypervisor count: 1 - Hypervisor compute-01 is enabled and up, Id: 1, Hypervisor-hostname: compute-01, Hypervisor-type: QEMU | 'hypervisor.count'=1;;;0;
            ...      9     --warning-status='%\\\{status\\\} =~ /enabled/'               WARNING: Hypervisor compute-01 is enabled and up - Hypervisor compute-02 is enabled and up | 'hypervisor.count'=2;;;0; 
            ...      10    --critical-id='%\\\{id\\\}=~/1/'                              CRITICAL: Id: 1 | 'hypervisor.count'=2;;;0;
            ...      11    --critical-hypervisor-type='%\\\{hypervisor_type}=~/QEMU/'    CRITICAL: Hypervisor-type: QEMU | 'hypervisor.count'=2;;;0;
