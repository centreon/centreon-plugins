*** Settings ***
Documentation       Cloud Linux Libvirt VM CPU

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Test Timeout        120s


*** Variables ***
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=cloud::linux::libvirt::local::plugin
...                 --custommode=virshcli
...                 --virsh-path=${CURDIR}${/}virsh_bin
...                 --mode=vm-cpu


*** Test Cases ***
VM Cpu Cache ${tc}
    [Documentation]    First run - creates statefile cache (no perfdata yet)
    [Tags]    cloud    linux    libvirt    vm-cpu

    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:    tc    extra_options              expected_result                    --
        ...      1     ${EMPTY}                   OK: All VMs CPU usage are ok
        ...      2     --vm-name=vm1              OK: VM 'vm1' All vCPUs are ok
        ...      3     --include-name=vm[12]      OK: All VMs CPU usage are ok
        ...      4     --exclude-name=vm1         OK: VM 'vm2' All vCPUs are ok

VM Cpu ${tc}
    [Documentation]    Second run - reads statefile cache (delta=0)
    [Tags]    cloud    linux    libvirt    vm-cpu

    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Regexp    ${command}    ${expected_result}

    Examples:    tc    extra_options                                           expected_result    --
        ...      1     ${EMPTY}                                                ^OK:.*vm1.*vm2.*\|.*vm\.cpu\.utilization\.percentage.*0\.00
        ...      2     --vm-name=vm1                                           ^OK:.*0\.00 %.*\|.*vm1#vm\.cpu\.utilization\.percentage.*0\.00
        ...      3     --include-name=vm[12]                                   ^OK:.*vm1.*vm2.*\|.*vm\.cpu\.utilization\.percentage.*0\.00
        ...      4     --exclude-name=vm1                                      ^OK:.*vm2.*\|.*vm2#vm\.cpu\.utilization\.percentage.*0\.00
        ...      5     --critical-cpu-utilization=@0:100                       ^CRITICAL:.*cpu usage: 0\.00 %.*\|.*vm\.cpu\.utilization\.percentage.*@0:100
        ...      6     --vm-name=vm1 --warning-cpu-utilization=@0:100          ^WARNING:.*cpu usage: 0\.00 %.*\|.*vm\.cpu\.utilization\.percentage.*@0:100
        ...      7     --vm-name=vm1 --critical-cpu-utilization-vcpu=@0:100    ^CRITICAL:.*cpu vCPU utilization: 0\.00 %.*\|.*vm\.cpu\.utilization\.vcpu\.percentage.*@0:100
        ...      8     --vm-name=vm1 --warning-vcpu-utilization=@0:100         ^WARNING:.*vCPU.*usage: 0\.00 %.*\|.*vm\.cpu\.vcpu\.utilization\.percentage.*@0:100
