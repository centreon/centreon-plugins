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
            ...      1     --critical-cpu-total            OK: Number of current processes running: 86 | 'nbproc'=86;;;0;
            ...      2     --top                           OK: Number of current processes running: 86 | 'nbproc'=86;;;0; 'top_gorgone-proxy'=324349952B;;;0; 'top_mariadbd'=298323968B;;;0; 'top_apache2'=251240448B;;;0; 'top_telegraf'=127754240B;;;0; 'top_perl'=126619648B;;;0;
            ...      3     --top-num                       OK: Number of current processes running: 86 | 'nbproc'=86;;;0; 
            ...      4     --top-size                      OK: Number of current processes running: 86 | 'nbproc'=86;;;0;
            ...      5     --verbose --help                OK: 