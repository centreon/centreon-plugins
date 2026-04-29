*** Settings ***
Documentation       Cloud Linux Libvirt VM Memory

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Test Timeout        120s


*** Variables ***
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=cloud::linux::libvirt::local::plugin
...                 --custommode=virshcli
...                 --virsh-path=${CURDIR}${/}virsh_bin
...                 --mode=vm-memory


*** Test Cases ***
VM Memory ${tc}
    [Documentation]    Check VM memory usage
    [Tags]    cloud    linux    libvirt    vm-memory

    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:    tc    extra_options                                       expected_result    --
        ...      1     ${EMPTY}                                            OK: All VMs memory usage are ok | 'vm1#vm.memory.usage.bytes'=2147483648B;;;0;4294967296 'vm1#vm.memory.usage.percentage'=50.00%;;;0;100 'vm1#vm.memory.rss.bytes'=3221225472B;;;0; 'vm2#vm.memory.usage.bytes'=1610612736B;;;0;2147483648 'vm2#vm.memory.usage.percentage'=75.00%;;;0;100 'vm2#vm.memory.rss.bytes'=1610612736B;;;0;
        ...      2     --vm-name=vm1                                       OK: VM 'vm1' memory used: 2.00 GB / 4.00 GB (50.00 %), memory used: 50.00 %, RSS: 3.00 GB | 'vm1#vm.memory.usage.bytes'=2147483648B;;;0;4294967296 'vm1#vm.memory.usage.percentage'=50.00%;;;0;100 'vm1#vm.memory.rss.bytes'=3221225472B;;;0;
        ...      3     --vm-name=vm2                                       OK: VM 'vm2' memory used: 1.50 GB / 2.00 GB (75.00 %), memory used: 75.00 %, RSS: 1.50 GB | 'vm2#vm.memory.usage.bytes'=1610612736B;;;0;2147483648 'vm2#vm.memory.usage.percentage'=75.00%;;;0;100 'vm2#vm.memory.rss.bytes'=1610612736B;;;0;
        ...      4     --vm-name=vm2 --warning-memory-usage=1000000000     WARNING: VM 'vm2' memory used: 1.50 GB / 2.00 GB (75.00 %) | 'vm2#vm.memory.usage.bytes'=1610612736B;0:1000000000;;0;2147483648 'vm2#vm.memory.usage.percentage'=75.00%;;;0;100 'vm2#vm.memory.rss.bytes'=1610612736B;;;0;
        ...      5     --vm-name=vm2 --critical-memory-usage=1000000000    CRITICAL: VM 'vm2' memory used: 1.50 GB / 2.00 GB (75.00 %) | 'vm2#vm.memory.usage.bytes'=1610612736B;;0:1000000000;0;2147483648 'vm2#vm.memory.usage.percentage'=75.00%;;;0;100 'vm2#vm.memory.rss.bytes'=1610612736B;;;0;
        ...      6     --vm-name=vm2 --warning-memory-usage-prct=60        WARNING: VM 'vm2' memory used: 75.00 % | 'vm2#vm.memory.usage.bytes'=1610612736B;;;0;2147483648 'vm2#vm.memory.usage.percentage'=75.00%;0:60;;0;100 'vm2#vm.memory.rss.bytes'=1610612736B;;;0;
        ...      7     --vm-name=vm2 --critical-memory-usage-prct=70       CRITICAL: VM 'vm2' memory used: 75.00 % | 'vm2#vm.memory.usage.bytes'=1610612736B;;;0;2147483648 'vm2#vm.memory.usage.percentage'=75.00%;;0:70;0;100 'vm2#vm.memory.rss.bytes'=1610612736B;;;0;
        ...      8     --vm-name=vm2 --warning-memory-rss=1000000000       WARNING: VM 'vm2' RSS: 1.50 GB | 'vm2#vm.memory.usage.bytes'=1610612736B;;;0;2147483648 'vm2#vm.memory.usage.percentage'=75.00%;;;0;100 'vm2#vm.memory.rss.bytes'=1610612736B;0:1000000000;;0;
        ...      9     --vm-name=vm2 --critical-memory-rss=1000000000      CRITICAL: VM 'vm2' RSS: 1.50 GB | 'vm2#vm.memory.usage.bytes'=1610612736B;;;0;2147483648 'vm2#vm.memory.usage.percentage'=75.00%;;;0;100 'vm2#vm.memory.rss.bytes'=1610612736B;;0:1000000000;0;
