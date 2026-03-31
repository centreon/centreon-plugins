*** Settings ***
Documentation       Check processcount table

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=os::linux::snmp::plugin


*** Test Cases ***
processcount ${tc}
    [Tags]    os    linux
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=processcount
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=os/linux/snmp/linux
    ...    --snmp-timeout=1
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                       expected_result    --
            ...      1     --critical-cpu-total                                OK: Number of current processes running: 84 | 'nbproc'=84;;;0;
            ...      2     --top                                               OK: Number of current processes running: 84 | 'nbproc'=84;;;0; 'top_gorgone-proxy'=324349952B;;;0; 'top_Anonymized 068'=298323968B;;;0; 'top_Anonymized 148'=127754240B;;;0; 'top_Anonymized 054'=79663104B;;;0; 'top_gorgone-autodis'=72368128B;;;0;
            ...      3     --top-num                                           OK: Number of current processes running: 84 | 'nbproc'=84;;;0;
            ...      4     --top-size                                          OK: Number of current processes running: 84 | 'nbproc'=84;;;0;
            ...      5     --process-status='running|runnable|unHandle'                                     OK: Number of current processes running: 86 | 'nbproc'=86;;;0;
            ...      6     --process-status='unHandled#-2' --process-name='Anonymized 228' --verbose        OK: Number of current processes running: 1 | 'nbproc'=1;;;0; Process '3534' [status: unHandled#-2] [name: Anonymized 228]
