*** Settings ***
Documentation       Check list-processes table

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=os::linux::snmp::plugin


*** Test Cases ***
list-processes ${tc}
    [Tags]    os    linux
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=list-processes
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=os/linux/snmp/linux
    ...    --snmp-timeout=1
    ...    ${extra_options}

    Ctn Run Command Without Connector And Check Result As Regexp    ${command}    ${expected_result}

    Examples:        tc    extra_options                       expected_result    --
            ...      1     --filter-name='gorgone-dbclean'     name = gorgone-dbclean
            ...      2     --filter-name='centreontrapd'       name = centreontrapd
            ...      3     --filter-name='systemd-udevd'       name = systemd-udevd
            ...      4     --filter-name='kdevtmpfs'           name = kdevtmpfs
