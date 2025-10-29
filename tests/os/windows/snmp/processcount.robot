*** Settings ***
Documentation       Check Windows operating systems in SNMP.

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}


*** Test Cases ***
processcount ${tc}
    [Tags]    os    windows
    ${command}    Catenate
    ...    ${CMD}
    ...    --plugin=os::windows::snmp::plugin
    ...    --mode=processcount
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=os/windows/snmp/processcount
    ...    --snmp-timeout=1
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                   expected_result    --
            ...      1     --critical-cpu-total            OK: Number of current processes running: 317 | 'nbproc'=317;;;0;
            ...      2     --top                           OK: Number of current processes running: 317 | 'nbproc'=317;;;0; 'top_Anonymized 073'=132067328B;;;0; 'top_Anonymized 023'=122327040B;;;0; 'top_Anonymized 079'=109248512B;;;0; 'top_Anonymized 137'=108720128B;;;0; 'top_Anonymized 072'=93343744B;;;0;
            ...      3     --top-num                       OK: Number of current processes running: 317 | 'nbproc'=317;;;0;
            ...      4     --top-size                      OK: Number of current processes running: 317 | 'nbproc'=317;;;0;
