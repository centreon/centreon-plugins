*** Settings ***
Documentation       Check arp table

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=os::linux::snmp::plugin


*** Test Cases ***
memory ${tc}
    [Tags]    os    linux
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=memory
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=os/linux/snmp/linux
    ...    --snmp-timeout=1
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                   expected_result    --
            ...      1     --verbose                       OK: Ram Total: 1.92 GB Used (-buffers/cache): 702.20 MB (35.70%) Free: 1.24 GB (64.30%), Buffer: 35.86 MB, Cached: 498.80 MB, Shared: 28.91 MB | 'used'=736309248B;;;0;2062598144 'free'=1326288896B;;;0;2062598144 'used_prct'=35.70%;;;0;100 'buffer'=37601280B;;;0; 'cached'=523030528B;;;0; 'shared'=30310400B;;;0; 
            ...      2     --warning-usage='1'             WARNING: Ram Total: 1.92 GB Used (-buffers/cache): 702.20 MB (35.70%) Free: 1.24 GB (64.30%) | 'used'=736309248B;;;0;2062598144 'free'=1326288896B;;;0;2062598144 'used_prct'=35.70%;0:1;;0;100 'buffer'=37601280B;;;0; 'cached'=523030528B;;;0; 'shared'=30310400B;;;0;
            ...      3     --warning-usage-free='1'        WARNING: Ram Total: 1.92 GB Used (-buffers/cache): 702.20 MB (35.70%) Free: 1.24 GB (64.30%) | 'used'=736309248B;;;0;2062598144 'free'=1326288896B;0:1;;0;2062598144 'used_prct'=35.70%;;;0;100 'buffer'=37601280B;;;0; 'cached'=523030528B;;;0; 'shared'=30310400B;;;0;
            ...      4     --warning-usage-prct='1'        WARNING: Ram Total: 1.92 GB Used (-buffers/cache): 702.20 MB (35.70%) Free: 1.24 GB (64.30%) | 'used'=736309248B;;;0;2062598144 'free'=1326288896B;;;0;2062598144 'used_prct'=35.70%;0:1;;0;100 'buffer'=37601280B;;;0; 'cached'=523030528B;;;0; 'shared'=30310400B;;;0;
            ...      5     --warning-swap='1'              OK: Ram Total: 1.92 GB Used (-buffers/cache): 702.20 MB (35.70%) Free: 1.24 GB (64.30%), Buffer: 35.86 MB, Cached: 498.80 MB, Shared: 28.91 MB | 'used'=736309248B;;;0;2062598144 'free'=1326288896B;;;0;2062598144 'used_prct'=35.70%;;;0;100 'buffer'=37601280B;;;0; 'cached'=523030528B;;;0; 'shared'=30310400B;;;0;
            ...      6     --warning-swap-free='1'         OK: Ram Total: 1.92 GB Used (-buffers/cache): 702.20 MB (35.70%) Free: 1.24 GB (64.30%), Buffer: 35.86 MB, Cached: 498.80 MB, Shared: 28.91 MB | 'used'=736309248B;;;0;2062598144 'free'=1326288896B;;;0;2062598144 'used_prct'=35.70%;;;0;100 'buffer'=37601280B;;;0; 'cached'=523030528B;;;0; 'shared'=30310400B;;;0; 
            ...      7     --warning-swap-prct='0'         OK: Ram Total: 1.92 GB Used (-buffers/cache): 702.20 MB (35.70%) Free: 1.24 GB (64.30%), Buffer: 35.86 MB, Cached: 498.80 MB, Shared: 28.91 MB | 'used'=736309248B;;;0;2062598144 'free'=1326288896B;;;0;2062598144 'used_prct'=35.70%;;;0;100 'buffer'=37601280B;;;0; 'cached'=523030528B;;;0; 'shared'=30310400B;;;0; 
            ...      8     --warning-buffer='40'           WARNING: Buffer: 35.86 MB | 'used'=736309248B;;;0;2062598144 'free'=1326288896B;;;0;2062598144 'used_prct'=35.70%;;;0;100 'buffer'=37601280B;0:40;;0; 'cached'=523030528B;;;0; 'shared'=30310400B;;;0; 
            ...      9     --warning-cached='1'            WARNING: Cached: 498.80 MB | 'used'=736309248B;;;0;2062598144 'free'=1326288896B;;;0;2062598144 'used_prct'=35.70%;;;0;100 'buffer'=37601280B;;;0; 'cached'=523030528B;0:1;;0; 'shared'=30310400B;;;0;
            ...      10    --warning-shared='1'            WARNING: Shared: 28.91 MB | 'used'=736309248B;;;0;2062598144 'free'=1326288896B;;;0;2062598144 'used_prct'=35.70%;;;0;100 'buffer'=37601280B;;;0; 'cached'=523030528B;;;0; 'shared'=30310400B;0:1;;0;
            ...      11    --patch-redhat='1'              OK: Ram Total: 1.92 GB Used (-buffers/cache): 1.21 GB (62.88%) Free: 730.19 MB (37.12%), Buffer: 35.86 MB, Cached: 498.80 MB, Shared: 28.91 MB | 'used'=1296941056B;;;0;2062598144 'free'=765657088B;;;0;2062598144 'used_prct'=62.88%;;;0;100 'buffer'=37601280B;;;0; 'cached'=523030528B;;;0; 'shared'=30310400B;;;0;
            ...      12    --critical-usage='1'            CRITICAL: Ram Total: 1.92 GB Used (-buffers/cache): 702.20 MB (35.70%) Free: 1.24 GB (64.30%) | 'used'=736309248B;;;0;2062598144 'free'=1326288896B;;;0;2062598144 'used_prct'=35.70%;;0:1;0;100 'buffer'=37601280B;;;0; 'cached'=523030528B;;;0; 'shared'=30310400B;;;0;
            ...      13    --critical-usage-free='1'       CRITICAL: Ram Total: 1.92 GB Used (-buffers/cache): 702.20 MB (35.70%) Free: 1.24 GB (64.30%) | 'used'=736309248B;;;0;2062598144 'free'=1326288896B;;0:1;0;2062598144 'used_prct'=35.70%;;;0;100 'buffer'=37601280B;;;0; 'cached'=523030528B;;;0; 'shared'=30310400B;;;0;
            ...      14    --critical-usage-prct='1'       CRITICAL: Ram Total: 1.92 GB Used (-buffers/cache): 702.20 MB (35.70%) Free: 1.24 GB (64.30%) | 'used'=736309248B;;;0;2062598144 'free'=1326288896B;;;0;2062598144 'used_prct'=35.70%;;0:1;0;100 'buffer'=37601280B;;;0; 'cached'=523030528B;;;0; 'shared'=30310400B;;;0; 
            ...      15    --critical-swap='1'             OK: Ram Total: 1.92 GB Used (-buffers/cache): 702.20 MB (35.70%) Free: 1.24 GB (64.30%), Buffer: 35.86 MB, Cached: 498.80 MB, Shared: 28.91 MB | 'used'=736309248B;;;0;2062598144 'free'=1326288896B;;;0;2062598144 'used_prct'=35.70%;;;0;100 'buffer'=37601280B;;;0; 'cached'=523030528B;;;0; 'shared'=30310400B;;;0;
            ...      16    --critical-swap-free='1'        OK: Ram Total: 1.92 GB Used (-buffers/cache): 702.20 MB (35.70%) Free: 1.24 GB (64.30%), Buffer: 35.86 MB, Cached: 498.80 MB, Shared: 28.91 MB | 'used'=736309248B;;;0;2062598144 'free'=1326288896B;;;0;2062598144 'used_prct'=35.70%;;;0;100 'buffer'=37601280B;;;0; 'cached'=523030528B;;;0; 'shared'=30310400B;;;0; 
            ...      17    --critical-swap-prct='1'        OK: Ram Total: 1.92 GB Used (-buffers/cache): 702.20 MB (35.70%) Free: 1.24 GB (64.30%), Buffer: 35.86 MB, Cached: 498.80 MB, Shared: 28.91 MB | 'used'=736309248B;;;0;2062598144 'free'=1326288896B;;;0;2062598144 'used_prct'=35.70%;;;0;100 'buffer'=37601280B;;;0; 'cached'=523030528B;;;0; 'shared'=30310400B;;;0; 
            ...      18    --critical-buffer='1'           CRITICAL: Buffer: 35.86 MB | 'used'=736309248B;;;0;2062598144 'free'=1326288896B;;;0;2062598144 'used_prct'=35.70%;;;0;100 'buffer'=37601280B;;0:1;0; 'cached'=523030528B;;;0; 'shared'=30310400B;;;0; 
            ...      19    --critical-cached='1'           CRITICAL: Cached: 498.80 MB | 'used'=736309248B;;;0;2062598144 'free'=1326288896B;;;0;2062598144 'used_prct'=35.70%;;;0;100 'buffer'=37601280B;;;0; 'cached'=523030528B;;0:1;0; 'shared'=30310400B;;;0;
            ...      20    --critical-shared='1'           CRITICAL: Shared: 28.91 MB | 'used'=736309248B;;;0;2062598144 'free'=1326288896B;;;0;2062598144 'used_prct'=35.70%;;;0;100 'buffer'=37601280B;;;0; 'cached'=523030528B;;;0; 'shared'=30310400B;;0:1;0;
            ...      21    --patch-redhat='1'              OK: Ram Total: 1.92 GB Used (-buffers/cache): 1.21 GB (62.88%) Free: 730.19 MB (37.12%), Buffer: 35.86 MB, Cached: 498.80 MB, Shared: 28.91 MB | 'used'=1296941056B;;;0;2062598144 'free'=765657088B;;;0;2062598144 'used_prct'=62.88%;;;0;100 'buffer'=37601280B;;;0; 'cached'=523030528B;;;0; 'shared'=30310400B;;;0;