*** Settings ***
Documentation       Check list-diskspath table

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=os::linux::snmp::plugin


*** Test Cases ***
list-diskspath ${tc}
    [Tags]    os    linux
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=list-diskspath
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=os/linux/snmp/linux
    ...    --snmp-timeout=1
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                           expected_result    --
            ...      1     --skip-total-size-zero=''               List disk path: ${SPACE}'/run/user/0' [id = 25] ${SPACE} '/run' [id = 5] ${SPACE} '/' [id = 6] ${SPACE} '/dev/shm' [id = 8] ${SPACE} '/run/lock' [id = 9]
            ...      2     --regexp-insensitive='/run/user/0'      List disk path: ${SPACE}'/run/user/0' [id = 25] ${SPACE} '/run' [id = 5] ${SPACE} '/' [id = 6] ${SPACE} '/dev/shm' [id = 8] ${SPACE} '/run/lock' [id = 9]
            ...      3     --display-transform-src='dev'           List disk path: ${SPACE}'/run/user/0' [id = 25] ${SPACE}'/run' [id = 5] ${SPACE} '/' [id = 6] ${SPACE} '//shm' [id = 8] ${SPACE} '/run/lock' [id = 9]
            ...      4     --display-transform-dst='run'           List disk path: ${SPACE}'/run/user/0' [id = 25] ${SPACE} '/run' [id = 5] ${SPACE} '/' [id = 6] ${SPACE} '/dev/shm' [id = 8] ${SPACE} '/run/lock' [id = 9] 
            ...      5     --skip-total-size-zero                  List disk path: ${SPACE}'/run/user/0' [id = 25] ${SPACE} '/run' [id = 5] ${SPACE} '/' [id = 6] ${SPACE} '/dev/shm' [id = 8] ${SPACE} '/run/lock' [id = 9]
            ...      6     --regexp-insensitive                    List disk path: ${SPACE}'/run/user/0' [id = 25] ${SPACE} '/run' [id = 5] ${SPACE} '/' [id = 6] ${SPACE} '/dev/shm' [id = 8] ${SPACE} '/run/lock' [id = 9] 
            ...      7     --regexp                                List disk path: ${SPACE}'/run/user/0' [id = 25] ${SPACE} '/run' [id = 5] ${SPACE} '/' [id = 6] ${SPACE} '/dev/shm' [id = 8] ${SPACE} '/run/lock' [id = 9]
