*** Settings ***
Documentation       Cloud Linux Libvirt VM Disk I/O

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Test Timeout        120s


*** Variables ***
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=cloud::linux::libvirt::local::plugin
...                 --custommode=virshcli
...                 --virsh-path=${CURDIR}${/}virsh_bin
...                 --mode=vm-disk-io


*** Test Cases ***
VM Disk IO Cache ${tc}
    [Documentation]    First run - creates statefile cache (no perfdata yet)
    [Tags]    cloud    linux    libvirt    vm-disk-io

    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:    tc    extra_options                      expected_result                --
        ...      1     ${EMPTY}                           OK: All VM disk I/O are ok
        ...      2     --vm-name=vm1                      OK: Disk 'vm1/vda'
        ...      3     --include-disk=vda                 OK: All VM disk I/O are ok
        ...      4     --vm-name=vm1 --disk-name=vda      OK: Disk 'vm1/vda'

VM Disk IO ${tc}
    [Documentation]    Second run - reads statefile cache (delta=0)
    [Tags]    cloud    linux    libvirt    vm-disk-io

    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Regexp    ${command}    ${expected_result}

    Examples:    tc    extra_options                                        expected_result    --
        ...      1     ${EMPTY}                                             ^OK: All VM disk I/O are ok \|.*vm1_vda.*vm2_vda.*vm\.disk\.io\.read\.usage\.bytespersecond.*0
        ...      2     --vm-name=vm1                                        ^OK: Disk 'vm1/vda'.*read: 0\.00 B/s.*\|.*vm\.disk\.io\.read\.usage\.bytespersecond.*0
        ...      3     --include-disk=vda                                   ^OK: All VM disk I/O are ok \|.*vm1_vda.*vm2_vda.*vm\.disk\.io\.read\.usage\.bytespersecond.*0
        ...      4     --vm-name=vm1 --disk-name=vda                        ^OK: Disk 'vm1/vda'.*read: 0\.00 B/s.*\|.*vm\.disk\.io\.read\.usage\.bytespersecond.*0
        ...      5     --vm-name=vm1 --warning-read-usage=@0:1000           ^WARNING: Disk 'vm1/vda' read: 0\.00 B/s.*\|.*vm\.disk\.io\.read\.usage\.bytespersecond.*@0:1000
        ...      6     --vm-name=vm1 --critical-write-usage=@0:1000         ^CRITICAL: Disk 'vm1/vda' write: 0\.00 B/s.*\|.*vm\.disk\.io\.write\.usage\.bytespersecond.*@0:1000
        ...      7     --vm-name=vm1 --warning-read-iops=@0:100             ^WARNING: Disk 'vm1/vda' read IOPS: 0\.00/s.*\|.*vm\.disk\.io\.read\.iops.*@0:100
        ...      8     --vm-name=vm1 --critical-write-iops=@0:100           ^CRITICAL: Disk 'vm1/vda' write IOPS: 0\.00/s.*\|.*vm\.disk\.io\.write\.iops.*@0:100
