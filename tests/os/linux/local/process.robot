*** Settings ***
Documentation       Linux Local list-systemdservices

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s
Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=os::linux::local::plugin
${COND}     ${PERCENT}\{sub\} =~ /exited/ && ${PERCENT}{display} =~ /network/'


*** Test Cases ***
Process ${tc}
    [Tags]    os    linux    local
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=process
    ...    --command-options='${CURDIR}${/}process_bin${/}${ps_output}'
    ...    --command=cat
    ...    --warning-total='${warning}'
    ...    --critical-total='${critical}'
    ...    --filter-command='${filter_command}'

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc   ps_output               filter_command    warning    critical    expected_result    --
            ...      1    ps-centreon.output      cs.sapC4P_C00     ${EMPTY}    ${EMPTY}   OK: Number of current processes: 0 | 'processes.total.count'=0;;;0;
            ...      2    ps-centreon.output      cs.sapC4P_C00     1:1         ${EMPTY}   WARNING: Number of current processes: 0 | 'processes.total.count'=0;1:1;;0;
            ...      3    ps-centreon.output      cs.sapC4P_C00     1:1         1:1        CRITICAL: Number of current processes: 0 | 'processes.total.count'=0;1:1;1:1;0;
            ...      4    ps-centreon.output      cs.sapC4P_C00     0:0         0:0        OK: Number of current processes: 0 | 'processes.total.count'=0;0:0;0:0;0;
            ...      5    ps-centreon.output      gorgone-proxy     ${EMPTY}    ${EMPTY}   OK: Number of current processes: 5 | 'processes.total.count'=5;;;0;
            ...      6    ps-centreon.output      gorgone-proxy     1:1         ${EMPTY}   WARNING: Number of current processes: 5 | 'processes.total.count'=5;1:1;;0;
            ...      7    ps-centreon.output      gorgone-proxy     1:1         1:1        CRITICAL: Number of current processes: 5 | 'processes.total.count'=5;1:1;1:1;0;
            ...      8    ps-centreon.output      gorgone-proxy     5:5         5:5        OK: Number of current processes: 5 | 'processes.total.count'=5;5:5;5:5;0;
            ...      9    ps-sap.output           cs.sapC4P_C00     ${EMPTY}    ${EMPTY}   OK: Process: [command => cs.sapC4P_C00] [arg => cs.sapC4P_C00 pf=/usr/sap/C4P/SYS/profile/C4P_C00_lunisapcsprd2] [state => S] duration: 3M 2w 5d 21h 51m 25s - Number of current processes: 1 | 'processes.total.count'=1;;;0;
            ...     10    ps-sap.output           cs.sapC4P_C00     2:2         ${EMPTY}   WARNING: Number of current processes: 1 | 'processes.total.count'=1;2:2;;0;
            ...     11    ps-sap.output           cs.sapC4P_C00     2:2         2:2        CRITICAL: Number of current processes: 1 | 'processes.total.count'=1;2:2;2:2;0;
            ...     12    ps-sap.output           cs.sapC4P_C00     1:1         1:1        OK: Process: [command => cs.sapC4P_C00] [arg => cs.sapC4P_C00 pf=/usr/sap/C4P/SYS/profile/C4P_C00_lunisapcsprd2] [state => S] duration: 3M 2w 5d 21h 51m 25s - Number of current processes: 1 | 'processes.total.count'=1;1:1;1:1;0;
            ...     13    ps-sap.output           gorgone-proxy     ${EMPTY}    ${EMPTY}   OK: Number of current processes: 0 | 'processes.total.count'=0;;;0;
            ...     14    ps-sap.output           gorgone-proxy     2:2         ${EMPTY}   WARNING: Number of current processes: 0 | 'processes.total.count'=0;2:2;;0;
            ...     15    ps-sap.output           gorgone-proxy     2:2         2:2        CRITICAL: Number of current processes: 0 | 'processes.total.count'=0;2:2;2:2;0;
            ...     16    ps-sap.output           gorgone-proxy     0:0         0:0        OK: Number of current processes: 0 | 'processes.total.count'=0;0:0;0:0;0;

