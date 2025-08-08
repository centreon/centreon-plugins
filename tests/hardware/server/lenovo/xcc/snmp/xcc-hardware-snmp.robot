*** Settings ***
Documentation       Hardware lenovo xcc SNMP checks

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
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

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}    ${tc}

    Examples:        tc    arguments                                                               component    expected_result    --
        ...      1     system-health-critical                                                  health         CRITICAL: 'Error' health status for 'Anonymized 144' - 'Error' health status for 'Anonymized 149' - 'Error' health status for 'Anonymized 127' - 'Warning' health status for 'Anonymized 130' | 'count_health'=4;;;;
        ...      2     system-health-ok                                                        health         OK: All 4 components are ok [4/4 health]. | 'count_health'=4;;;;
        ...      3     system-health-nonRecoverable                                            health         CRITICAL: 'NonRecoverable' health status for 'Anonymized 144' - 'NonRecoverable' health status for 'Anonymized 149' - 'NonRecoverable' health status for 'Anonymized 127' | 'count_health'=4;;;;
        # check filters, each mode have to implement it, here we test only the health thoroughly and some part of the other modes.
        ...      4     system-health-ok --output-ignore-perfdata                               ${space}       OK: All 44 components are ok [1/1 cpu, 2/2 disk, 12/12 fans, 4/4 health, 8/8 memory, 2/2 psu, 1/1 raidvolume, 10/10 temperatures, 4/4 voltages].
        ...      5     system-health-ok --output-ignore-perfdata --filter='health'             ${space}       OK: All 40 components are ok [1/1 cpu, 2/2 disk, 12/12 fans, 8/8 memory, 2/2 psu, 1/1 raidvolume, 10/10 temperatures, 4/4 voltages].
        ...      6     system-health-critical --filter='health,1' --output-ignore-perfdata     ${space}       CRITICAL: Temperature 'Ambient Temp' status is 'critical' - Temperature 'DIMM 8 Temp' status is 'critical' - Voltage 'SysBrd 12V' status is 'critical' - Voltage 'SysBrd 3.3V' status is 'critical' - Fan 'Fan 1 Front Tach' status is 'critical' - Fan 'Fan 4 Front Tach' status is 'critical' - Fan 'Fan 2 Rear Tach' status is 'critical' - Fan 'Fan 6 Rear Tach' status is 'critical' - Power supply 'Anonymized 250' status is 'Anonymized 022' - Power supply 'Anonymized 193' status is 'Anonymized 076' - Disk 'Anonymized 016' status is 'critical' - 'Error' health status for 'Anonymized 149' - 'Error' health status for 'Anonymized 127' - 'Warning' health status for 'Anonymized 130' - 'Anonymized 227' cpu status for 'Anonymized 155' - 'critical' memory status for 'DIMM_2' - 'critical' memory status for 'DIMM_6' - 'critical' memory status for 'DIMM_8' - 'critical' memory status for 'DIMM_11'
        ...      7     system-health-ok --filter='cpu' --filter='disk' --filter='fan' --filter='memory' --filter='psu' --filter='raidvolume' --filter='temperature' --filter='voltage' --output-ignore-perfdata    ${space}     OK: All 4 components are ok [4/4 health].
        ...      8     system-health-ok                                                        cpu            OK: All 1 components are ok [1/1 cpu]. | 'count_cpu'=1;;;;
        ...      9     system-health-ok                                                        memory         OK: All 8 components are ok [8/8 memory]. | 'count_memory'=8;;;;
        ...      10    system-health-critical --output-ignore-perfdata                         temperature    CRITICAL: Temperature 'Ambient Temp' status is 'critical' - Temperature 'DIMM 8 Temp' status is 'critical'