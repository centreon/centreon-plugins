*** Settings ***
Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=os::aix::snmp::plugin


*** Test Cases ***
storage ${tc}
    [Tags]    os    aix
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=storage
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=os/aix/snmp/slim_os-aix
    ...    --snmp-timeout=5
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                    expected_result    --
            ...      1     ${EMPTY} --storage=2                             OK: Storage '/dev/hd2' Usage Total: 5.00 GB Used: 3.35 GB (66.97%) Free: 1.65 GB (33.03%) | 'count'=1;;;0; 'used'=3595264000B;;;0;5368709120
            ...      2     --warning-usage=45 --storage=1                   WARNING: Storage '/dev/hd4' Usage Total: 1.00 GB Used: 498.18 MB (48.65%) Free: 525.82 MB (51.35%) | 'count'=1;;;0; 'used'=522375168B;0:483183820;;0;1073741824
            ...      3     --critical-usage=40 --storage=1                  CRITICAL: Storage '/dev/hd4' Usage Total: 1.00 GB Used: 498.18 MB (48.65%) Free: 525.82 MB (51.35%) | 'count'=1;;;0; 'used'=522375168B;;0:429496729;0;1073741824
            ...      4     --free=51 --storage=1                            OK: Storage '/dev/hd4' Usage Total: 1.00 GB Used: 498.18 MB (48.65%) Free: 525.82 MB (51.35%) | 'count'=1;;;0; 'free'=551366656B;;;0;1073741824
            ...      5     --critical-access=readWrite                      OK: All storages are ok | 'count'=21;;;0; 'used_/dev/hd4'=522375168B;;;0;1073741824 'used_/dev/lv_logiciel'=30902849536B;;;0;212600881152 'used_/dev/lv_statsnmon'=499585024B;;;0;1073741824 'used_/dev/lv_exp0x00'=151797760B;;;0;536870912 'used_/dev/lv_oradiag'=383913984B;;;0;4294967296 'used_/dev/lvrubrik'=696320B;;;0;268435456 'used_/dev/lv_automx01'=8888320B;;;0;1073741824 'used_/dev/lvorar1DJET4'=3528171520B;;;0;4294967296 'used_/dev/lvorar2DJET4'=3528171520B;;;0;4294967296 'used_/dev/lvorafraDJET4'=152616960B;;;0;53687091200 'used_/dev/lvoradbDJET4'=331419025408B;;;0;429496729600 'used_/dev/hd2'=3595264000B;;;0;5368709120 'used_/dev/lvoradpDJET4'=458752B;;;0;805306368 'used_/dev/lv_automx02'=9052160B;;;0;2147483648 'used_/dev/hd9var'=722554880B;;;0;1140850688 'used_/dev/hd3'=538583040B;;;0;2147483648 'used_/dev/hd1'=122642432B;;;0;603979776 'used_/dev/hd11admin'=389120B;;;0;134217728 'used_/dev/hd10opt'=1821675520B;;;0;4966055936 'used_/dev/livedump'=376832B;;;0;268435456 'used_/dev/lv_automx00'=499712B;;;0;1073741824