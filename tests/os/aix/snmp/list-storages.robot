*** Settings ***
Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=os::aix::snmp::plugin


*** Test Cases ***
list-storages ${tc}
    [Tags]    os    aix
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=list-storages
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=os/aix/snmp/slim_os-aix
    ...    --snmp-timeout=1
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                                                     expected_result    --
            ...      1     --verbose --storage=1                                                                             List storage: '/dev/hd4' [size = 1073741824B] [id = 1]
            ...      2     --display-transform-src='Anonymized 205' --display-transform-dst='test'                           List storage: '/dev/hd4' [size = 1073741824B] [id = 1] '/dev/lv_logiciel' [size = 212600881152B] [id = 10] '/dev/lv_statsnmon' [size = 1073741824B] [id = 11] '/dev/lv_exp0x00' [size = 536870912B] [id = 12] '/dev/lv_oradiag' [size = 4294967296B] [id = 13] '/dev/lvrubrik' [size = 268435456B] [id = 14] '/dev/lv_automx01' [size = 1073741824B] [id = 15] '/dev/lvorar1DJET4' [size = 4294967296B] [id = 16] '/dev/lvorar2DJET4' [size = 4294967296B] [id = 17] '/dev/lvorafraDJET4' [size = 53687091200B] [id = 18] '/dev/lvoradbDJET4' [size = 429496729600B] [id = 19] '/dev/hd2' [size = 5368709120B] [id = 2] '/dev/lvoradpDJET4' [size = 805306368B] [id = 20] '/dev/lv_automx02' [size = 2147483648B] [id = 21] Skipping storage '/dev/hd6': no type or no matching filter type Skipping storage 'test': no type or no matching filter type '/dev/hd9var' [size = 1140850688B] [id = 3] '/dev/hd3' [size = 2147483648B] [id = 4] '/dev/hd1' [size = 603979776B] [id = 5] '/dev/hd11admin' [size = 134217728B] [id = 6] '/dev/hd10opt' [size = 4966055936B] [id = 7] '/dev/livedump' [size = 268435456B] [id = 8] '/dev/lv_automx00' [size = 1073741824B] [id = 9]