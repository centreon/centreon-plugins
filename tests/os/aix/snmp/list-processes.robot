*** Settings ***
Resource        ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup     Ctn Generic Suite Setup
Test Timeout    120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=os::aix::snmp::plugin


*** Test Cases ***
list-processes ${tc}
    [Tags]    os    aix
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=list-processes
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=os/aix/snmp/aix
    ...    --snmp-timeout=1
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    --filter-name='Anonymized 136'
    ...    List processes: [name = Anonymized 136] [path = Anonymized 008] [parameters = ] [type = deviceDriver] [pid = 5] [status = notRunnable]
    ...    2
    ...    --add-stats --filter-name='Anonymized 129'
    ...    List processes: [name = Anonymized 129] [path = /usr/lib/drivers/vdev_busdd] [parameters = ] [type = deviceDriver] [pid = 47] [status = notRunnable] [cpu = 0] [mem = 0]
