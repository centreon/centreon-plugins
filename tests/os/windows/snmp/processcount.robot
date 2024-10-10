*** Settings ***
Documentation       Linux Local Systemd-sc-status

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}

*** Test Cases ***
processcount ${tc}
    [Tags]    os    linux
    ${command}    Catenate
    ...    ${CMD}
    ...    --plugin=os::windows::snmp::plugin
    ...    --mode=processcount
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=os/windows/snmp/windows_anon
    ...    --snmp-timeout=1
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                   expected_result    --
            ...      1     --critical-cpu-total            OK: Number of current processes running: 0 | 'nbproc'=0;;;0;
            ...      2     --top                           OK: Number of current processes running: 0 | 'nbproc'=0;;;0;
            ...      3     --top-num                       OK: Number of current processes running: 0 | 'nbproc'=0;;;0; 
            ...      4     --top-size                      OK: Number of current processes running: 0 | 'nbproc'=0;;;0;