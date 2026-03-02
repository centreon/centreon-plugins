*** Settings ***
Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Setup          Ctn Cleanup Cache
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}mockoon.json

${CMD}              ${CENTREON_PLUGINS} --plugin=apps::vmware::vsphere8::vm::plugin
...                 --mode=vm-status
...                 --password=C3POR2P2
...                 --username=obi-wan
...                 --hostname=127.0.0.1
...                 --proto=http
...                 --port=3000


*** Test Cases ***
Vm-Status ${tc}
    [Tags]    apps    api    vmware    vsphere8    vm
    ${command}    Catenate    ${CMD} ${filter_vm} ${extraoptions}
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:    tc     filter_vm                               extraoptions                                                        expected_result   --
        ...      1      --vm-name=db-server-01                  ${EMPTY}                                                            OK: VM 'db-server-01', id: 'vm-7722': power state is POWERED_ON
        ...      2      --vm-name=web-server-01                 ${EMPTY}                                                            CRITICAL: VM 'web-server-01', id: 'vm-7657': power state is POWERED_OFF
        ...      3      --vm-name=vm3.acme.com                  ${EMPTY}                                                            UNKNOWN: No VM found with name: 'vm3.acme.com' and/or id ''.
        ...      4      --vm-id=vm-7722                         ${EMPTY}                                                            OK: VM 'db-server-01', id: 'vm-7722': power state is POWERED_ON
        ...      5      --vm-id=vm-7657                         ${EMPTY}                                                            CRITICAL: VM 'web-server-01', id: 'vm-7657': power state is POWERED_OFF
        ...      6      --vm-id=vm-3                            ${EMPTY}                                                            UNKNOWN: No VM found with name: '' and/or id 'vm-3'.
        ...      7      --vm-id=vm-3000000                      --warning-power-status='\\\%{power_state} =~ /^powered_on$/i'       UNKNOWN: No VM found with name: '' and/or id 'vm-3000000'.
        ...      8      --vm-id=vm-7722                         --critical-power-status='\\\%{power_state} =~ /^powered_on$/i'      CRITICAL: VM 'db-server-01', id: 'vm-7722': power state is POWERED_ON
        ...      9      --vm-id=vm-7657                         --critical-power-status='\\\%{power_state} =~ /^powered_on$/i'      OK: VM 'web-server-01', id: 'vm-7657': power state is POWERED_OFF
        ...     10      --vm-id=vm-7722                         --warning-power-status='\\\%{power_state} =~ /^powered_on$/i'       WARNING: VM 'db-server-01', id: 'vm-7722': power state is POWERED_ON
        ...     11      --vm-id=vm-7657                         --warning-power-status='\\\%{power_state} =~ /^powered_on$/i'       CRITICAL: VM 'web-server-01', id: 'vm-7657': power state is POWERED_OFF
        ...     12      --vm-id=vm-3 --vm-name=web-server-01    ${EMPTY}                                                            CRITICAL: VM 'web-server-01', id: 'vm-7657': power state is POWERED_OFF
