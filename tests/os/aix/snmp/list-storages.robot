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
    ...    --snmp-community=os/aix/snmp/aix
    ...    --snmp-timeout=1
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                         expected_result    --
            ...      1     --storage='/dev/hd4' --name           List storage: '/dev/hd4' [size = 1073741824B] [id = 1]
            ...      2     --storage='/dev/hd' --name --regexp   List storage: '/dev/hd4' [size = 1073741824B] [id = 1] '/dev/hd2' [size = 5368709120B] [id = 2] Skipping storage '/dev/hd6': no type or no matching filter type '/dev/hd9var' [size = 1140850688B] [id = 3] '/dev/hd3' [size = 2147483648B] [id = 4] '/dev/hd1' [size = 603979776B] [id = 5] '/dev/hd11admin' [size = 134217728B] [id = 6] '/dev/hd10opt' [size = 4966055936B] [id = 7]
