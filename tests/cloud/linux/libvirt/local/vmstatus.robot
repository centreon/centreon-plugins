*** Settings ***
Documentation       Cloud Linux Libvirt VM Status

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Test Timeout        120s


*** Variables ***
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=cloud::linux::libvirt::local::plugin
...                 --custommode=virshcli
...                 --virsh-path=${CURDIR}${/}virsh_bin
...                 --mode=vm-status


*** Test Cases ***
VM Status ${tc}
    [Documentation]    Check VM status
    [Tags]    cloud    linux    libvirt    vm-status

    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:    tc    extra_options                                                                        expected_result    --
        ...      1     ${EMPTY}                                                                            CRITICAL: VM 'vm3' state is 'shut_off'
        ...      2     --vm-name=vm1                                                                       OK: VM 'vm1' state is 'running'
        ...      3     --vm-name=vm3                                                                       CRITICAL: VM 'vm3' state is 'shut_off'
        ...      4     --include-name='vm[12]'                                                             OK: All VMs status are ok
        ...      5     --vm-name=vm3 --critical-status='' --warning-status='\\\%{state} =~ /shut_off/'     WARNING: VM 'vm3' state is 'shut_off'
