*** Settings ***
Documentation       Check disk-usage space reservation on partitions with different reserved blocks

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=os::linux::snmp::plugin


*** Test Cases ***
disk-usage-reservation ${tc}
    [Tags]    os    linux
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=disk-usage
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=os/linux/snmp/disk-usage-reservation
    ...    --snmp-timeout=1
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    OK: All partitions are ok | 'count'=8;;;0; 'used_/'=187882291200B;;;0;247570337792 'free_/'=59688046592B;;;0;247570337792 'used_prct_/'=75.89%;;;0;100 'inodes_/'=18%;;;0;100 'used_/boot'=859500544B;;;0;1725022208 'free_/boot'=865521664B;;;0;1725022208 'used_prct_/boot'=49.83%;;;0;100 'inodes_/boot'=0%;;;0;100 'used_/boot/efi'=6451200B;;;0;535805952 'free_/boot/efi'=529354752B;;;0;535805952 'used_prct_/boot/efi'=1.20%;;;0;100 'inodes_/boot/efi'=0%;;;0;100 'used_/dev/shm'=8192B;;;0;16204361728 'free_/dev/shm'=16204353536B;;;0;16204361728 'used_prct_/dev/shm'=0.00%;;;0;100 'inodes_/dev/shm'=0%;;;0;100 'used_/run'=2621440B;;;0;3240873984 'free_/run'=3238252544B;;;0;3240873984 'used_prct_/run'=0.08%;;;0;100 'inodes_/run'=0%;;;0;100 'used_/run/lock'=20480B;;;0;5242880 'free_/run/lock'=5222400B;;;0;5242880 'used_prct_/run/lock'=0.39%;;;0;100 'inodes_/run/lock'=0%;;;0;100 'used_/run/qemu'=0B;;;0;16204361728 'free_/run/qemu'=16204361728B;;;0;16204361728 'used_prct_/run/qemu'=0.00%;;;0;100 'inodes_/run/qemu'=0%;;;0;100 'used_/run/user/1000'=307200B;;;0;3240869888 'free_/run/user/1000'=3240562688B;;;0;3240869888 'used_prct_/run/user/1000'=0.01%;;;0;100 'inodes_/run/user/1000'=0%;;;0;100
    ...    2
    ...    --space-reservation='auto'
    ...    OK: All partitions are ok | 'count'=8;;;0; 'used_/'=187882291200B;;;0;247570337792 'free_/'=47037607936B;;;0;247570337792 'used_prct_/'=79.98%;;;0;100 'inodes_/'=18%;;;0;100 'used_/boot'=859500544B;;;0;1725022208 'free_/boot'=759144448B;;;0;1725022208 'used_prct_/boot'=53.10%;;;0;100 'inodes_/boot'=0%;;;0;100 'used_/boot/efi'=6451200B;;;0;535805952 'free_/boot/efi'=529354752B;;;0;535805952 'used_prct_/boot/efi'=1.20%;;;0;100 'inodes_/boot/efi'=0%;;;0;100 'used_/dev/shm'=8192B;;;0;16204361728 'free_/dev/shm'=16204353536B;;;0;16204361728 'used_prct_/dev/shm'=0.00%;;;0;100 'inodes_/dev/shm'=0%;;;0;100 'used_/run'=2621440B;;;0;3240873984 'free_/run'=3238252544B;;;0;3240873984 'used_prct_/run'=0.08%;;;0;100 'inodes_/run'=0%;;;0;100 'used_/run/lock'=20480B;;;0;5242880 'free_/run/lock'=5222400B;;;0;5242880 'used_prct_/run/lock'=0.39%;;;0;100 'inodes_/run/lock'=0%;;;0;100 'used_/run/qemu'=0B;;;0;16204361728 'free_/run/qemu'=16204361728B;;;0;16204361728 'used_prct_/run/qemu'=0.00%;;;0;100 'inodes_/run/qemu'=0%;;;0;100 'used_/run/user/1000'=307200B;;;0;3240869888 'free_/run/user/1000'=3240562688B;;;0;3240869888 'used_prct_/run/user/1000'=0.01%;;;0;100 'inodes_/run/user/1000'=0%;;;0;100
    ...    3
    ...    --space-reservation='5'
    ...    OK: All partitions are ok | 'count'=8;;;0; 'used_/'=187882291200B;;;0;247570337792 'free_/'=47309529702B;;;0;247570337792 'used_prct_/'=79.88%;;;0;100 'inodes_/'=18%;;;0;100 'used_/boot'=859500544B;;;0;1725022208 'free_/boot'=779270553B;;;0;1725022208 'used_prct_/boot'=52.45%;;;0;100 'inodes_/boot'=0%;;;0;100 'used_/boot/efi'=6451200B;;;0;535805952 'free_/boot/efi'=502564454B;;;0;535805952 'used_prct_/boot/efi'=1.27%;;;0;100 'inodes_/boot/efi'=0%;;;0;100 'used_/dev/shm'=8192B;;;0;16204361728 'free_/dev/shm'=15394135449B;;;0;16204361728 'used_prct_/dev/shm'=0.00%;;;0;100 'inodes_/dev/shm'=0%;;;0;100 'used_/run'=2621440B;;;0;3240873984 'free_/run'=3076208844B;;;0;3240873984 'used_prct_/run'=0.09%;;;0;100 'inodes_/run'=0%;;;0;100 'used_/run/lock'=20480B;;;0;5242880 'free_/run/lock'=4960256B;;;0;5242880 'used_prct_/run/lock'=0.41%;;;0;100 'inodes_/run/lock'=0%;;;0;100 'used_/run/qemu'=0B;;;0;16204361728 'free_/run/qemu'=15394143641B;;;0;16204361728 'used_prct_/run/qemu'=0.00%;;;0;100 'inodes_/run/qemu'=0%;;;0;100 'used_/run/user/1000'=307200B;;;0;3240869888 'free_/run/user/1000'=3078519193B;;;0;3240869888 'used_prct_/run/user/1000'=0.01%;;;0;100 'inodes_/run/user/1000'=0%;;;0;100
    ...    4
    ...    --space-reservation='auto' --force-counters32
    ...    OK: All partitions are ok | 'count'=8;;;0; 'used_/'=187882291200B;;;0;247570337792 'free_/'=47037607936B;;;0;247570337792 'used_prct_/'=79.98%;;;0;100 'inodes_/'=18%;;;0;100 'used_/boot'=859500544B;;;0;1725022208 'free_/boot'=759144448B;;;0;1725022208 'used_prct_/boot'=53.10%;;;0;100 'inodes_/boot'=0%;;;0;100 'used_/boot/efi'=6451200B;;;0;535805952 'free_/boot/efi'=529354752B;;;0;535805952 'used_prct_/boot/efi'=1.20%;;;0;100 'inodes_/boot/efi'=0%;;;0;100 'used_/dev/shm'=8192B;;;0;16204361728 'free_/dev/shm'=16204353536B;;;0;16204361728 'used_prct_/dev/shm'=0.00%;;;0;100 'inodes_/dev/shm'=0%;;;0;100 'used_/run'=2621440B;;;0;3240873984 'free_/run'=3238252544B;;;0;3240873984 'used_prct_/run'=0.08%;;;0;100 'inodes_/run'=0%;;;0;100 'used_/run/lock'=20480B;;;0;5242880 'free_/run/lock'=5222400B;;;0;5242880 'used_prct_/run/lock'=0.39%;;;0;100 'inodes_/run/lock'=0%;;;0;100 'used_/run/qemu'=0B;;;0;16204361728 'free_/run/qemu'=16204361728B;;;0;16204361728 'used_prct_/run/qemu'=0.00%;;;0;100 'inodes_/run/qemu'=0%;;;0;100 'used_/run/user/1000'=307200B;;;0;3240869888 'free_/run/user/1000'=3240562688B;;;0;3240869888 'used_prct_/run/user/1000'=0.01%;;;0;100 'inodes_/run/user/1000'=0%;;;0;100
    ...    5
    ...    --space-reservation='auto' --filter-disk-path='^/boot$'
    ...    OK: Partition '/boot' usage total: 1.61 GB used: 819.68 MB (53.10%) free: 723.98 MB (46.90%), Inodes used: 0 % | 'count'=1;;;0; 'used'=859500544B;;;0;1725022208 'free'=759144448B;;;0;1725022208 'used_prct'=53.10%;;;0;100 'inodes'=0%;;;0;100
    ...    6
    ...    --space-reservation='5' --filter-disk-path='^/boot$'
    ...    OK: Partition '/boot' usage total: 1.61 GB used: 819.68 MB (52.45%) free: 743.17 MB (47.55%), Inodes used: 0 % | 'count'=1;;;0; 'used'=859500544B;;;0;1725022208 'free'=779270553B;;;0;1725022208 'used_prct'=52.45%;;;0;100 'inodes'=0%;;;0;100
    ...    7
    ...    --space-reservation='auto' --filter-disk-path='^/boot/efi$'
    ...    OK: Partition '/boot/efi' usage total: 510.98 MB used: 6.15 MB (1.20%) free: 504.83 MB (98.80%), Inodes used: 0 % | 'count'=1;;;0; 'used'=6451200B;;;0;535805952 'free'=529354752B;;;0;535805952 'used_prct'=1.20%;;;0;100 'inodes'=0%;;;0;100
    ...    8
    ...    --warning-usage-prct='79' --filter-disk-path='^/$'
    ...    OK: Partition '/' usage total: 230.57 GB used: 174.98 GB (75.89%) free: 55.59 GB (24.11%), Inodes used: 18 % | 'count'=1;;;0; 'used'=187882291200B;;;0;247570337792 'free'=59688046592B;;;0;247570337792 'used_prct'=75.89%;0:79;;0;100 'inodes'=18%;;;0;100
    ...    9
    ...    --space-reservation='auto' --warning-usage-prct='79' --filter-disk-path='^/$'
    ...    WARNING: Partition '/' used: 79.98 % | 'count'=1;;;0; 'used'=187882291200B;;;0;247570337792 'free'=47037607936B;;;0;247570337792 'used_prct'=79.98%;0:79;;0;100 'inodes'=18%;;;0;100
    ...    10
    ...    --space-reservation='5' --critical-usage-prct='53' --filter-disk-path='^/boot$'
    ...    OK: Partition '/boot' usage total: 1.61 GB used: 819.68 MB (52.45%) free: 743.17 MB (47.55%), Inodes used: 0 % | 'count'=1;;;0; 'used'=859500544B;;;0;1725022208 'free'=779270553B;;;0;1725022208 'used_prct'=52.45%;;0:53;0;100 'inodes'=0%;;;0;100
    ...    11
    ...    --space-reservation='auto' --critical-usage-prct='53' --filter-disk-path='^/boot$'
    ...    CRITICAL: Partition '/boot' used: 53.10 % | 'count'=1;;;0; 'used'=859500544B;;;0;1725022208 'free'=759144448B;;;0;1725022208 'used_prct'=53.10%;;0:53;0;100 'inodes'=0%;;;0;100
    ...    12
    ...    --critical-usage-free='50000000000:' --filter-disk-path='^/$'
    ...    OK: Partition '/' usage total: 230.57 GB used: 174.98 GB (75.89%) free: 55.59 GB (24.11%), Inodes used: 18 % | 'count'=1;;;0; 'used'=187882291200B;;;0;247570337792 'free'=59688046592B;;50000000000:;0;247570337792 'used_prct'=75.89%;;;0;100 'inodes'=18%;;;0;100
    ...    13
    ...    --space-reservation='auto' --critical-usage-free='50000000000:' --filter-disk-path='^/$'
    ...    CRITICAL: Partition '/' usage total: 230.57 GB used: 174.98 GB (79.98%) free: 43.81 GB (20.02%) | 'count'=1;;;0; 'used'=187882291200B;;;0;247570337792 'free'=47037607936B;;50000000000:;0;247570337792 'used_prct'=79.98%;;;0;100 'inodes'=18%;;;0;100
    ...    14
    ...    --space-reservation='auto' --warning-usage-prct='53' --critical-usage-prct='79'
    ...    CRITICAL: Partition '/' used: 79.98 % WARNING: Partition '/boot' used: 53.10 % | 'count'=8;;;0; 'used_/'=187882291200B;;;0;247570337792 'free_/'=47037607936B;;;0;247570337792 'used_prct_/'=79.98%;0:53;0:79;0;100 'inodes_/'=18%;;;0;100 'used_/boot'=859500544B;;;0;1725022208 'free_/boot'=759144448B;;;0;1725022208 'used_prct_/boot'=53.10%;0:53;0:79;0;100 'inodes_/boot'=0%;;;0;100 'used_/boot/efi'=6451200B;;;0;535805952 'free_/boot/efi'=529354752B;;;0;535805952 'used_prct_/boot/efi'=1.20%;0:53;0:79;0;100 'inodes_/boot/efi'=0%;;;0;100 'used_/dev/shm'=8192B;;;0;16204361728 'free_/dev/shm'=16204353536B;;;0;16204361728 'used_prct_/dev/shm'=0.00%;0:53;0:79;0;100 'inodes_/dev/shm'=0%;;;0;100 'used_/run'=2621440B;;;0;3240873984 'free_/run'=3238252544B;;;0;3240873984 'used_prct_/run'=0.08%;0:53;0:79;0;100 'inodes_/run'=0%;;;0;100 'used_/run/lock'=20480B;;;0;5242880 'free_/run/lock'=5222400B;;;0;5242880 'used_prct_/run/lock'=0.39%;0:53;0:79;0;100 'inodes_/run/lock'=0%;;;0;100 'used_/run/qemu'=0B;;;0;16204361728 'free_/run/qemu'=16204361728B;;;0;16204361728 'used_prct_/run/qemu'=0.00%;0:53;0:79;0;100 'inodes_/run/qemu'=0%;;;0;100 'used_/run/user/1000'=307200B;;;0;3240869888 'free_/run/user/1000'=3240562688B;;;0;3240869888 'used_prct_/run/user/1000'=0.01%;0:53;0:79;0;100 'inodes_/run/user/1000'=0%;;;0;100
    ...    15
    ...    --space-reservation='100' --filter-disk-path='^/boot$'
    ...    OK: Partition '/boot' usage total: 1.61 GB used: 819.68 MB (100.00%) free: 0.00 B (0.00%), Inodes used: 0 % | 'count'=1;;;0; 'used'=859500544B;;;0;1725022208 'free'=0B;;;0;1725022208 'used_prct'=100.00%;;;0;100 'inodes'=0%;;;0;100
