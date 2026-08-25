*** Settings ***
Documentation       Check Windows operating systems in SNMP.

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}                  ${CENTREON_PLUGINS}
${CGS_COLLECTIONS}      ${CURDIR}${/}..${/}..${/}..${/}..${/}rust-plugins${/}rs-collections${/}rust-snmp


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

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    --critical-cpu-total
    ...    OK: Number of current processes running: 317 | 'nbproc'=317;;;0;
    ...    2
    ...    --top
    ...    OK: Number of current processes running: 317 | 'nbproc'=317;;;0; 'top_Anonymized 073'=132067328B;;;0; 'top_Anonymized 023'=122327040B;;;0; 'top_Anonymized 079'=109248512B;;;0; 'top_Anonymized 137'=108720128B;;;0; 'top_Anonymized 072'=93343744B;;;0;
    ...    3
    ...    --top-num
    ...    OK: Number of current processes running: 317 | 'nbproc'=317;;;0;
    ...    4
    ...    --top-size
    ...    OK: Number of current processes running: 317 | 'nbproc'=317;;;0;

cgs-processcount ${tc}
    [Tags]    os    windows    centreon-plugin-rust-snmp
    ${command}    Catenate
    ...    ${CENTREON_PLUGIN_RUST_SNMP}
    ...    -j ${CGS_COLLECTIONS}${/}processcount.json
    ...    --hostname=${HOSTNAME}
    ...    --port=${SNMPPORT}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-community=os/windows/snmp/processcount
    ...    ${extra_options}

    Ctn Run Command Without Connector And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    --filter-in 'Anonymized 187'
    ...    All processes are OK | 'Anonymized 187#process.memory.bytes'=19980288B;;;0; 'Anonymized 187#process.cpu.percent'=51%;;;0;100
    ...    2
    ...    --filter-in 'Anonymized 187' --warning-process-memory=0.1
    ...    WARNING: 'Anonymized 187#process.memory.bytes' is 19980288B | 'Anonymized 187#process.memory.bytes'=19980288B;0.1;;0; 'Anonymized 187#process.cpu.percent'=51%;;;0;100
    ...    3
    ...    --filter-in 'Anonymized 187' --critical-process-memory=0.1
    ...    CRITICAL: 'Anonymized 187#process.memory.bytes' is 19980288B | 'Anonymized 187#process.memory.bytes'=19980288B;;0.1;0; 'Anonymized 187#process.cpu.percent'=51%;;;0;100
    ...    4
    ...    --filter-in 'Anonymized 187' --warning-process-cpu=0.1
    ...    WARNING: 'Anonymized 187#process.cpu.percent' is 51% | 'Anonymized 187#process.memory.bytes'=19980288B;;;0; 'Anonymized 187#process.cpu.percent'=51%;0.1;;0;100
    ...    5
    ...    --filter-in 'Anonymized 187' --critical-process-cpu=0.1
    ...    CRITICAL: 'Anonymized 187#process.cpu.percent' is 51% | 'Anonymized 187#process.memory.bytes'=19980288B;;;0; 'Anonymized 187#process.cpu.percent'=51%;;0.1;0;100
    ...    6
    ...    --filter-in 'not foundable' --critical-process-cpu=0.1
    ...    UNKNOWN: Process not found
    ...    7
    ...    --filter-in 'not foundable' --critical-process-cpu=0.1 --no-data-status=CRITICAL
    ...    CRITICAL: Process not found
