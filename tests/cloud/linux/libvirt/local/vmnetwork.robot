*** Settings ***
Documentation       Cloud Linux Libvirt VM Network

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Test Timeout        120s


*** Variables ***
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=cloud::linux::libvirt::local::plugin
...                 --custommode=virshcli
...                 --virsh-path=${CURDIR}${/}virsh_bin
...                 --mode=vm-network


*** Test Cases ***
VM Network ${tc}
    [Documentation]    Check VM network interface statistics - odd tc creates statefile cache, even tc reads it (delta=0)
    [Tags]    cloud    linux    libvirt    vm-network

    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Regexp    ${command}    ${expected_result}

    Examples:    tc    extra_options                                        expected_result    --
        ...      1     ${EMPTY}                                             ^OK:
        ...      2     ${EMPTY}                                             ^OK: All VM network interfaces are ok \|.*vm1_vnet0.*vm2_vnet1.*vm\.network\.traffic\.in\.bitspersecond.*0\.00
        ...      3     --vm-name=vm1                                        ^OK:
        ...      4     --vm-name=vm1                                        ^OK: Interface 'vm1/vnet0'.*traffic in: 0\.00 b/s.*\|.*vm\.network\.traffic\.in\.bitspersecond.*0\.00
        ...      5     --include-interface=vnet0                            ^OK:
        ...      6     --include-interface=vnet0                            ^OK: Interface 'vm1/vnet0'.*traffic in: 0\.00 b/s.*\|.*vm\.network\.traffic\.in\.bitspersecond.*0\.00
        ...      7     --vm-name=vm1 --interface-name=vnet0                 ^OK:
        ...      8     --vm-name=vm1 --interface-name=vnet0                 ^OK: Interface 'vm1/vnet0'.*traffic in: 0\.00 b/s.*\|.*vm\.network\.traffic\.in\.bitspersecond.*0\.00
        ...      9     --vm-name=vm1 --warning-traffic-in=@0:1000           ^WARNING: Interface 'vm1/vnet0' traffic in: 0\.00 b/s.*\|.*vm\.network\.traffic\.in\.bitspersecond.*@0:1000
        ...      10    --vm-name=vm1 --critical-traffic-out=@0:1000         ^CRITICAL: Interface 'vm1/vnet0' traffic out: 0\.00 b/s.*\|.*vm\.network\.traffic\.out\.bitspersecond.*@0:1000
        ...      11    --vm-name=vm1 --warning-packets-in=@0:100            ^WARNING: Interface 'vm1/vnet0' packets in: 0\.00/s.*\|.*vm\.network\.packets\.in\.count.*@0:100
        ...      12    --vm-name=vm1 --critical-packets-out=@0:100          ^CRITICAL: Interface 'vm1/vnet0' packets out: 0\.00/s.*\|.*vm\.network\.packets\.out\.count.*@0:100
        ...      13    --vm-name=vm1 --warning-errors-in=@0:10              ^WARNING: Interface 'vm1/vnet0' errors in: 0\.00/s.*\|.*vm\.network\.errors\.in\.count.*@0:10
        ...      14    --vm-name=vm1 --critical-errors-out=@0:10            ^CRITICAL: Interface 'vm1/vnet0' errors out: 0\.00/s.*\|.*vm\.network\.errors\.out\.count.*@0:10
