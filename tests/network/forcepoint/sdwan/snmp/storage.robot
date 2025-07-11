*** Settings ***
Documentation       Forcepoint SD-WAN Mode Storage

Resource            ${CURDIR}${/}../..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Test Timeout        120s


*** Variables ***
${CMD}                                          ${CENTREON_PLUGINS} --plugin=network::forcepoint::sdwan::snmp::plugin


*** Test Cases ***
storage ${tc}
    [Tags]    network    forcepoint    sdwan     snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=storage
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/forcepoint/sdwan/snmp/forcepoint-storage
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                       expected_result    --
            ...      1     --filter-duplicate=''               OK: All storages are ok | 'count'=4;;;0; 'used_/'=0B;;;0;1994637312 'used_/xxxx/diagnostics'=242581504B;;;0;2027601920 'used_/xxxX/dump/user_space_cores'=416538624B;;;0;3365871616 'used_/tmp/run/snmpd'=1839104B;;;0;1994637312
            ...      2     --filter-storage-type=''            OK: All storages are ok | 'count'=19;;;0; 'used_Physical memory'=3620208640B;;;0;3989274624 'used_Swap space'=95158272B;;;0;1006628864 'used_Virtual memory'=3715366912B;;;0;4995903488 'used_/'=0B;;;0;1994637312 'used_/xxxx/diagnostics'=242581504B;;;0;2027601920 'used_/xxxx/config/snmp'=242581504B;;;0;2027601920 'used_/xxxX/dump/user_space_cores'=416538624B;;;0;3365871616 'used_/tmp/run/snmpd'=1839104B;;;0;1994637312 'used_/tmp/run/dmidata'=1839104B;;;0;1994637312 'used_/tmp/run/stonegate'=1839104B;;;0;1994637312 'used_/tmp/run/smonitd'=1839104B;;;0;1994637312 'used_/etc/passwd'=242581504B;;;0;2027601920 'used_/tmp/run/agentx'=1839104B;;;0;1994637312 'used_/tmp/hwmond-socket'=1839104B;;;0;1994637312 'used_Memory buffers'=99962880B;;;0;3989274624 'used_/tmp/r2d2-sensor-cmdif'=1839104B;;;0;1994637312 'used_/usr/sbin/snmpd_refresh_config'=1839104B;;;0;1994637312 'used_Cached memory'=1153867776B;;;0;1153867776 'used_Shared memory'=829284352B;;;0;829284352
            ...      3     --display-transform-dst='run'       OK: All storages are ok | 'count'=13;;;0; 'used_/'=0B;;;0;1994637312 'used_/xxxx/diagnostics'=242581504B;;;0;2027601920 'used_/xxxx/config/snmp'=242581504B;;;0;2027601920 'used_/xxxX/dump/user_space_cores'=416538624B;;;0;3365871616 'used_/tmp/run/snmpd'=1839104B;;;0;1994637312 'used_/tmp/run/dmidata'=1839104B;;;0;1994637312 'used_/tmp/run/stonegate'=1839104B;;;0;1994637312 'used_/tmp/run/smonitd'=1839104B;;;0;1994637312 'used_/etc/passwd'=242581504B;;;0;2027601920 'used_/tmp/run/agentx'=1839104B;;;0;1994637312 'used_/tmp/hwmond-socket'=1839104B;;;0;1994637312 'used_/tmp/r2d2-sensor-cmdif'=1839104B;;;0;1994637312 'used_/usr/sbin/snmpd_refresh_config'=1839104B;;;0;1994637312
            ...      4     --filter-duplicate                  OK: All storages are ok | 'count'=4;;;0; 'used_/'=0B;;;0;1994637312 'used_/xxxx/diagnostics'=242581504B;;;0;2027601920 'used_/xxxX/dump/user_space_cores'=416538624B;;;0;3365871616 'used_/tmp/run/snmpd'=1839104B;;;0;1994637312
            ...      5     --filter-storage-type               OK: All storages are ok | 'count'=19;;;0; 'used_Physical memory'=3620208640B;;;0;3989274624 'used_Swap space'=95158272B;;;0;1006628864 'used_Virtual memory'=3715366912B;;;0;4995903488 'used_/'=0B;;;0;1994637312 'used_/xxxx/diagnostics'=242581504B;;;0;2027601920 'used_/xxxx/config/snmp'=242581504B;;;0;2027601920 'used_/xxxX/dump/user_space_cores'=416538624B;;;0;3365871616 'used_/tmp/run/snmpd'=1839104B;;;0;1994637312 'used_/tmp/run/dmidata'=1839104B;;;0;1994637312 'used_/tmp/run/stonegate'=1839104B;;;0;1994637312 'used_/tmp/run/smonitd'=1839104B;;;0;1994637312 'used_/etc/passwd'=242581504B;;;0;2027601920 'used_/tmp/run/agentx'=1839104B;;;0;1994637312 'used_/tmp/hwmond-socket'=1839104B;;;0;1994637312 'used_Memory buffers'=99962880B;;;0;3989274624 'used_/tmp/r2d2-sensor-cmdif'=1839104B;;;0;1994637312 'used_/usr/sbin/snmpd_refresh_config'=1839104B;;;0;1994637312 'used_Cached memory'=1153867776B;;;0;1153867776 'used_Shared memory'=829284352B;;;0;829284352
