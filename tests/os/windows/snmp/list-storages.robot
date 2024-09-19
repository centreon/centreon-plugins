*** Settings ***
Documentation       Linux Local Systemd-sc-status

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}

*** Test Cases ***
list-storages ${tc}
    [Tags]    os    linux
    ${command}    Catenate
    ...    ${CMD}
    ...    --plugin=os::windows::snmp::plugin
    ...    --mode=list-storages
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=os/windows/snmp/windows
    ...    --snmp-timeout=1
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                                                   expected_result    --
            ...      1     --verbose                                                                                       List storage: ${SPACE}Skipping storage 'Physical memory': no type or no matching filter type ${SPACE}Skipping storage 'Swap space': no type or no matching filter type ${SPACE}Skipping storage 'Available memory': no type or no matching filter type ${SPACE}Skipping storage 'Virtual memory': no type or no matching filter type ${SPACE}'/dev/shm' [size = 2014359552B] [id = 35] ${SPACE}'/run' [size = 2014359552B] [id = 37] ${SPACE}'/sys/fs/cgroup' [size = 2014359552B] [id = 38] ${SPACE}'/' [size = 31989936128B] [id = 56] ${SPACE}Skipping storage 'Memory buffers': no type or no matching filter type${SPACE} '/boot' [size = 1063256064B] [id = 61]${SPACE} '/boot/efi' [size = 209489920B] [id = 62] ${SPACE}'/run/user/1000' [size = 402870272B] [id = 64] ${SPACE}Skipping storage 'Cached memory': no type or no matching filter type ${SPACE}Skipping storage 'Shared memory': no type or no matching filter type
            ...      2     --display-transform-src='dev'                                                                   List storage: ${SPACE}Skipping storage 'Physical memory': no type or no matching filter type ${SPACE}Skipping storage 'Swap space': no type or no matching filter type ${SPACE}Skipping storage 'Available memory': no type or no matching filter type ${SPACE}Skipping storage 'Virtual memory': no type or no matching filter type ${SPACE}'//shm' [size = 2014359552B] [id = 35]${SPACE} '/run' [size = 2014359552B] [id = 37] ${SPACE}'/sys/fs/cgroup' [size = 2014359552B] [id = 38]${SPACE} '/' [size = 31989936128B] [id = 56] ${SPACE}Skipping storage 'Memory buffers': no type or no matching filter type${SPACE} '/boot' [size = 1063256064B] [id = 61] ${SPACE}'/boot/efi' [size = 209489920B] [id = 62] ${SPACE}'/run/user/1000' [size = 402870272B] [id = 64] ${SPACE}Skipping storage 'Cached memory': no type or no matching filter type ${SPACE}Skipping storage 'Shared memory': no type or no matching filter type
            ...      3     --display-transform-dst='run'                                                                   List storage: ${SPACE}Skipping storage 'Physical memory': no type or no matching filter type ${SPACE}Skipping storage 'Swap space': no type or no matching filter type ${SPACE}Skipping storage 'Available memory': no type or no matching filter type ${SPACE}Skipping storage 'Virtual memory': no type or no matching filter type ${SPACE}'/dev/shm' [size = 2014359552B] [id = 35] ${SPACE}'/run' [size = 2014359552B] [id = 37] ${SPACE}'/sys/fs/cgroup' [size = 2014359552B] [id = 38] ${SPACE}'/' [size = 31989936128B] [id = 56] ${SPACE}Skipping storage 'Memory buffers': no type or no matching filter type ${SPACE}'/boot' [size = 1063256064B] [id = 61]${SPACE} '/boot/efi' [size = 209489920B] [id = 62] ${SPACE}'/run/user/1000' [size = 402870272B] [id = 64] ${SPACE}Skipping storage 'Cached memory': no type or no matching filter type ${SPACE}Skipping storage 'Shared memory': no type or no matching filter type
            ...      4     --filter-storage-type=''                                                                        List storage: ${SPACE}'Physical memory' [size = 4028719104B] [id = 1] ${SPACE}'Swap space' [size = 0B] [id = 10] ${SPACE}'Available memory' [size = 2259357696B] [id = 11]${SPACE} 'Virtual memory' [size = 4028719104B] [id = 3] ${SPACE}'/dev/shm' [size = 2014359552B] [id = 35] ${SPACE}'/run' [size = 2014359552B] [id = 37] ${SPACE}'/sys/fs/cgroup' [size = 2014359552B] [id = 38] ${SPACE}'/' [size = 31989936128B] [id = 56] ${SPACE}'Memory buffers' [size = 4028719104B] [id = 6] ${SPACE}'/boot' [size = 1063256064B] [id = 61] ${SPACE}'/boot/efi' [size = 209489920B] [id = 62] ${SPACE}'/run/user/1000' [size = 402870272B] [id = 64] ${SPACE}'Cached memory' [size = 555495424B] [id = 7] ${SPACE}'Shared memory' [size = 9228288B] [id = 8]
            ...      5     --filter-storage-type='^(hrStorageFixedDisk|hrStorageNetworkDisk|hrFSBerkeleyFFS)$'             List storage: ${SPACE}Skipping storage 'Physical memory': no type or no matching filter type ${SPACE}Skipping storage 'Swap space': no type or no matching filter type ${SPACE}Skipping storage 'Available memory': no type or no matching filter type ${SPACE}Skipping storage 'Virtual memory': no type or no matching filter type ${SPACE}'/dev/shm' [size = 2014359552B] [id = 35] ${SPACE}'/run' [size = 2014359552B] [id = 37] ${SPACE}'/sys/fs/cgroup' [size = 2014359552B] [id = 38] ${SPACE}'/' [size = 31989936128B] [id = 56] ${SPACE}Skipping storage 'Memory buffers': no type or no matching filter type ${SPACE}'/boot' [size = 1063256064B] [id = 61] ${SPACE}'/boot/efi' [size = 209489920B] [id = 62] ${SPACE}'/run/user/1000' [size = 402870272B] [id = 64]${SPACE} Skipping storage 'Cached memory': no type or no matching filter type ${SPACE}Skipping storage 'Shared memory': no type or no matching filter type
