*** Settings ***
Documentation       Check list-diskspath table

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Stop Connector
Test Timeout        120s


*** Variables ***
${CMD}      /usr/lib/centreon/plugins/centreon_linux_snmp.pl --plugin=os::linux::snmp::plugin


*** Test Cases ***
list-diskspath-connector ${tc}
    [Tags]    os    linux
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=list-diskspath
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=os/linux/snmp/linux
    ...    ${extra_options}

    Ctn Run Command With Connector And Check Multiline Result    ${command}    ${expected_result}    ${tc}

    Examples:        tc    extra_options                           expected_result    --
            ...      1     --skip-total-size-zero=''               List disk path: '/run/user/0' [id = 25] '/run' [id = 5] '/' [id = 6] '/dev/shm' [id = 8] '/run/lock' [id = 9]
            ...      2     --regexp-insensitive='/run/user/0'      List disk path: '/run/user/0' [id = 25] '/run' [id = 5] '/' [id = 6] '/dev/shm' [id = 8] '/run/lock' [id = 9]
            ...      3     --display-transform-src='dev'           List disk path: '/run/user/0' [id = 25] '/run' [id = 5] '/' [id = 6] '//shm' [id = 8] '/run/lock' [id = 9]
            ...      4     --display-transform-dst='run'           List disk path: '/run/user/0' [id = 25] '/run' [id = 5] '/' [id = 6] '/dev/shm' [id = 8] '/run/lock' [id = 9] 
            ...      5     --skip-total-size-zero                  List disk path: '/run/user/0' [id = 25] '/run' [id = 5] '/' [id = 6] '/dev/shm' [id = 8] '/run/lock' [id = 9]
            ...      6     --regexp-insensitive                    List disk path: '/run/user/0' [id = 25] '/run' [id = 5] '/' [id = 6] '/dev/shm' [id = 8] '/run/lock' [id = 9] 
            ...      7     --regexp                                List disk path: '/run/user/0' [id = 25] '/run' [id = 5] '/' [id = 6] '/dev/shm' [id = 8] '/run/lock' [id = 9]
