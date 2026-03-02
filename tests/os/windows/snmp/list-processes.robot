*** Settings ***
Documentation       Check Windows operating systems in SNMP.

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}


*** Test Cases ***
list-processes ${tc}
    [Tags]    os    windows
    ${command}    Catenate
    ...    ${CMD}
    ...    --plugin=os::windows::snmp::plugin
    ...    --mode=list-processes
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=os/windows/snmp/list-processes
    ...    ${extra_options}

    ${output}    Run    ${command}
    ${output}    Strip String    ${output}
    Should Contain
    ...    ${output}
    ...    ${expected_result}
    ...    Wrong output result for command:\n${command}\n\nObtained:\n${output}\n\nExpected:\n${expected_result}\n
    ...    values=False
    ...    collapse_spaces=True

    Examples:        tc    extra_options                                       expected_result    --
            ...      1     --filter-name='Anonymized 159'                      [name = Anonymized 159] [path = ] [parameters = Anonymized 087] [type = application] [pid = 3320] [status = running]
            ...      2     --add-stats='running'                               [name = Anonymized 165] [path = Anonymized 071] [parameters = Anonymized 245] [type = application] [pid = 3800] [status = running] [cpu = 3] [mem = 13992]
