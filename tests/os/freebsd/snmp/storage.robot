*** Settings ***
Documentation       Check storage table

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s
Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=os::freebsd::snmp::plugin


*** Test Cases ***
storage ${tc}
    [Tags]    os    freebsd
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=storage
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=os/freebsd/snmp/freebsd
    ...    --snmp-version=2c
    ...    --snmp-timeout=1
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                       expected_result    --
            ...      1     ${EMPTY}                            OK: All storages are ok | 'count'=3;;;0; 'used_/'=4534042624B;;;0;10352734208 'used_/dev'=0B;;;0;1024 'used_/boot/efi'=662528B;;;0;33550336
            ...      2     --verbose                           OK: All storages are ok | 'count'=3;;;0; 'used_/'=4534042624B;;;0;10352734208 'used_/dev'=0B;;;0;1024 'used_/boot/efi'=662528B;;;0;33550336 Storage '/' Usage Total: 9.64 GB Used: 4.22 GB (43.80%) Free: 5.42 GB (56.20%) Storage '/dev' Usage Total: 1.00 KB Used: 0.00 B (0.00%) Free: 1.00 KB (100.00%) Storage '/boot/efi' Usage Total: 32.00 MB Used: 647.00 KB (1.97%) Free: 31.36 MB (98.03%)
            ...      3     --warning-usage=30                  WARNING: Storage '/' Usage Total: 9.64 GB Used: 4.22 GB (43.80%) Free: 5.42 GB (56.20%) | 'count'=3;;;0; 'used_/'=4534042624B;0:3105820262;;0;10352734208 'used_/dev'=0B;0:307;;0;1024 'used_/boot/efi'=662528B;0:10065100;;0;33550336
            ...      4     --critical-usage=30                 CRITICAL: Storage '/' Usage Total: 9.64 GB Used: 4.22 GB (43.80%) Free: 5.42 GB (56.20%) | 'count'=3;;;0; 'used_/'=4534042624B;;0:3105820262;0;10352734208 'used_/dev'=0B;;0:307;0;1024 'used_/boot/efi'=662528B;;0:10065100;0;33550336
            ...      5     --name --storage='/'                OK: Storage '/' Usage Total: 9.64 GB Used: 4.22 GB (43.80%) Free: 5.42 GB (56.20%) | 'count'=1;;;0; 'used'=4534042624B;;;0;10352734208
