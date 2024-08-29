*** Settings ***
Documentation       Check list-storages table

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=os::linux::snmp::plugin


*** Test Cases ***
list-storages ${tc}
    [Tags]    os    linux
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=list-storages
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=os/linux/snmp/linux
    ...    --snmp-timeout=1
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                                                   expected_result    --
            ...      1     --display-transform-src='dev'                                                                   List storage: ${SPACE}Skipping storage 'Physical memory': no type or no matching filter type ${SPACE}Skipping storage 'Swap space': no type or no matching filter type ${SPACE}Skipping storage 'Available memory': no type or no matching filter type ${SPACE}Skipping storage 'Virtual memory': no type or no matching filter type ${SPACE}'/run' [size = 206262272B] [id = 35] ${SPACE} '/' [size = 105088212992B] [id = 36] ${SPACE} '//shm' [size = 1031299072B] [id = 38] ${SPACE} '/run/lock' [size = 5242880B] [id = 39] ${SPACE}'/run/user/0' [size = 206258176B] [id = 55] ${SPACE} Skipping storage 'Memory buffers': no type or no matching filter type ${SPACE} Skipping storage 'Cached memory': no type or no matching filter type ${SPACE} Skipping storage 'Shared memory': no type or no matching filter type
            ...      2     --display-transform-dst='run'                                                                   List storage: ${SPACE}Skipping storage 'Physical memory': no type or no matching filter type ${SPACE}Skipping storage 'Swap space': no type or no matching filter type ${SPACE}Skipping storage 'Available memory': no type or no matching filter type ${SPACE}Skipping storage 'Virtual memory': no type or no matching filter type ${SPACE}'/run' [size = 206262272B] [id = 35] ${SPACE}'/' [size = 105088212992B] [id = 36] ${SPACE}'/dev/shm' [size = 1031299072B] [id = 38] ${SPACE}'/run/lock' [size = 5242880B] [id = 39] ${SPACE}'/run/user/0' [size = 206258176B] [id = 55] ${SPACE}Skipping storage 'Memory buffers': no type or no matching filter type Skipping storage 'Cached memory': no type or no matching filter type ${SPACE}Skipping storage 'Shared memory': no type or no matching filter type 
            ...      3     --filter-storage-type=''                                                                        List storage: ${SPACE}'Physical memory' [size = 2062598144B] [id = 1] ${SPACE}'Swap space' [size = 0B] [id = 10] ${SPACE}'Available memory' [size = 1143980032B] [id = 11]${SPACE} 'Virtual memory' [size = 2062598144B] [id = 3] ${SPACE}'/run' [size = 206262272B] [id = 35] '/' [size = 105088212992B] [id = 36] ${SPACE}'/dev/shm' [size = 1031299072B] [id = 38] ${SPACE}'/run/lock' [size = 5242880B] [id = 39] ${SPACE}'/run/user/0' [size = 206258176B] [id = 55] ${SPACE}'Memory buffers' [size = 2062598144B] [id = 6] ${SPACE}'Cached memory' [size = 523030528B] [id = 7] ${SPACE}'Shared memory' [size = 30310400B] [id = 8]
            ...      4     --filter-storage-type='^(hrStorageFixedDisk|hrStorageNetworkDisk|hrFSBerkeleyFFS)$'             List storage: ${SPACE}Skipping storage 'Physical memory': no type or no matching filter type ${SPACE}Skipping storage 'Swap space': no type or no matching filter type ${SPACE}Skipping storage 'Available memory': no type or no matching filter type ${SPACE}Skipping storage 'Virtual memory': no type or no matching filter type ${SPACE}'/run' [size = 206262272B] [id = 35]${SPACE} '/' [size = 105088212992B] [id = 36] ${SPACE}'/dev/shm' [size = 1031299072B] [id = 38] ${SPACE}'/run/lock' [size = 5242880B] [id = 39] ${SPACE}'/run/user/0' [size = 206258176B] [id = 55] ${SPACE}Skipping storage 'Memory buffers': no type or no matching filter type ${SPACE}Skipping storage 'Cached memory': no type or no matching filter type ${SPACE}Skipping storage 'Shared memory': no type or no matching filter type