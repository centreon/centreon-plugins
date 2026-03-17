*** Settings ***
Documentation       Cloud Linux Libvirt Volume Allocation

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Test Timeout        120s


*** Variables ***
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=cloud::linux::libvirt::local::plugin
...                 --custommode=virshcli
...                 --virsh-path=${CURDIR}${/}virsh_bin
...                 --mode=volume


*** Test Cases ***
Volume ${tc}
    [Documentation]    Check storage volume allocation
    [Tags]    cloud    linux    libvirt    volume

    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:    tc    extra_options                                                                      expected_result    --
        ...      1     ${EMPTY}                                                                           OK: All volumes are ok | 'default/vm1.qcow2#volume.allocation.bytes'=5905580032B;;;0;21474836480 'default/vm1.qcow2#volume.allocation.percentage'=27.50%;;;0;100 'default/vm2.qcow2#volume.allocation.bytes'=3221225472B;;;0;10737418240 'default/vm2.qcow2#volume.allocation.percentage'=30.00%;;;0;100 'pool1/data.img#volume.allocation.bytes'=26843545600B;;;0;53687091200 'pool1/data.img#volume.allocation.percentage'=50.00%;;;0;100
        ...      2     --pool-name=default --volume-name=vm1.qcow2                                        OK: Volume 'default/vm1.qcow2' allocated: 5.50 GB / capacity: 20.00 GB (27.50 %), allocated: 27.50 % | 'default/vm1.qcow2#volume.allocation.bytes'=5905580032B;;;0;21474836480 'default/vm1.qcow2#volume.allocation.percentage'=27.50%;;;0;100
        ...      3     --pool-name=pool1 --volume-name=data.img                                           OK: Volume 'pool1/data.img' allocated: 25.00 GB / capacity: 50.00 GB (50.00 %), allocated: 50.00 % | 'pool1/data.img#volume.allocation.bytes'=26843545600B;;;0;53687091200 'pool1/data.img#volume.allocation.percentage'=50.00%;;;0;100
        ...      4     --pool-name=default --volume-name=vm1.qcow2 --warning-allocation=5000000000        WARNING: Volume 'default/vm1.qcow2' allocated: 5.50 GB / capacity: 20.00 GB (27.50 %) | 'default/vm1.qcow2#volume.allocation.bytes'=5905580032B;0:5000000000;;0;21474836480 'default/vm1.qcow2#volume.allocation.percentage'=27.50%;;;0;100
        ...      5     --pool-name=default --volume-name=vm2.qcow2 --critical-allocation=2000000000       CRITICAL: Volume 'default/vm2.qcow2' allocated: 3.00 GB / capacity: 10.00 GB (30.00 %) | 'default/vm2.qcow2#volume.allocation.bytes'=3221225472B;;0:2000000000;0;10737418240 'default/vm2.qcow2#volume.allocation.percentage'=30.00%;;;0;100
        ...      6     --pool-name=default --volume-name=vm1.qcow2 --warning-allocation-prct=20           WARNING: Volume 'default/vm1.qcow2' allocated: 27.50 % | 'default/vm1.qcow2#volume.allocation.bytes'=5905580032B;;;0;21474836480 'default/vm1.qcow2#volume.allocation.percentage'=27.50%;0:20;;0;100
        ...      7     --pool-name=default --volume-name=vm2.qcow2 --critical-allocation-prct=25          CRITICAL: Volume 'default/vm2.qcow2' allocated: 30.00 % | 'default/vm2.qcow2#volume.allocation.bytes'=3221225472B;;;0;10737418240 'default/vm2.qcow2#volume.allocation.percentage'=30.00%;;0:25;0;100
