*** Settings ***
Documentation       Hardware lenovo xcc SNMP checks

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}
...         --plugin=hardware::server::lenovo::xcc::snmp::plugin
...         --mode=hardware
...         --hostname=${HOSTNAME}
...         --snmp-port=${SNMPPORT}

*** Test Cases ***
lenovo xcc hardware Alarms ${tc}
    [Documentation]    Hardware lenovo xcc SNMP
    [Tags]    hardware    lenovo
    ${command}    Catenate
    ...    ${CMD}
    ...    --snmp-community=hardware/server/lenovo/xcc/snmp/${arguments}
    ...    --component=${component}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    arguments                                                               component    expected_result    --
        ...      1     system-health-critical                                                  health         CRITICAL: 'Error' health status for 'Anonymized 1' - 'Error' health status for 'Anonymized 2' - 'Error' health status for 'Anonymized 3' | 'count_health'=3;;;;
        ...      2     system-health-ok                                                        health         OK: All 3 components are ok [3/3 health]. | 'count_health'=3;;;;
        ...      3     system-health-nonRecoverable                                            health         CRITICAL: 'NonRecoverable' health status for 'Anonymized 1' - 'NonRecoverable' health status for 'Anonymized 2' - 'NonRecoverable' health status for 'Anonymized 3' | 'count_health'=3;;;;
        # check filters, each mode have to implement it, here we test only the health thoroughly and some part of the other modes.
        ...      4     system-health-ok --output-ignore-perfdata                               ${space}       OK: All 43 components are ok [1/1 cpu, 2/2 disk, 12/12 fans, 3/3 health, 8/8 memory, 2/2 psu, 1/1 raidvolume, 10/10 temperatures, 4/4 voltages].
        ...      5     system-health-ok --output-ignore-perfdata --filter='health'             ${space}       OK: All 40 components are ok [1/1 cpu, 2/2 disk, 12/12 fans, 8/8 memory, 2/2 psu, 1/1 raidvolume, 10/10 temperatures, 4/4 voltages].
        ...      6     system-health-critical --filter='health,1' --output-ignore-perfdata     ${space}       CRITICAL: Temperature 'Ambient Temp' status is 'NonRecoverable' - 'Error' health status for 'Anonymized 2' - 'Error' health status for 'Anonymized 3'
        ...      7     system-health-ok --filter='cpu' --filter='disk' --filter='fan' --filter='memory' --filter='psu' --filter='raidvolume' --filter='temperature' --filter='voltage' --output-ignore-perfdata    ${space}     OK: All 3 components are ok [3/3 health].
        ...      8     system-health-ok                                                        cpu            OK: All 1 components are ok [1/1 cpu]. | 'count_cpu'=1;;;;
        ...      9     system-health-ok                                                        memory         OK: All 8 components are ok [8/8 memory]. | 'count_memory'=8;;;;
        ...      10    system-health-critical --output-ignore-perfdata                         temperature    CRITICAL: Temperature 'Ambient Temp' status is 'NonRecoverable'