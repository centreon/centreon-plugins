*** Settings ***
Documentation       Check Stormshield equipment (also Netasq) in SNMP

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s
Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::nokia::timos::snmp::plugin


*** Test Cases ***
sas-alarm ${tc}
    [Tags]    network    nokia
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=sas-alarm
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/nokia/timos/snmp/nokia
    ...    --snmp-timeout=1
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                                                                                                                          expected_result    --
            ...      1     --verbose                                                                                                                                                              CRITICAL: Alarm input 'PSU_1_Sammelalarm' Alarm input status : alarm (Alarm input admin state: up (Alarm output severity: major) Alarm input 'PSU_1_Sammelalarm' Alarm input status : alarm (Alarm input admin state: up (Alarm output severity: major) Alarm input 'PSU_1_230V_fehlt' Alarm input status : noAlarm (Alarm input admin state: up (Alarm output severity: major) Alarm input 'PSU_2_Sammelalarm' Alarm input status : noAlarm (Alarm input admin state: up (Alarm output severity: major) Alarm input 'PSU_2_230V_fehlt' Alarm input status : noAlarm (Alarm input admin state: up (Alarm output severity: major)
            ...      2     --warning-status='\\\%{alarm_input_admin_state} eq "up" and \\\%{alarm_input_status} eq "alarm" and \\\%{alarm_output_severity} =~ /minor/'                            CRITICAL: Alarm input 'PSU_1_Sammelalarm' Alarm input status : alarm (Alarm input admin state: up (Alarm output severity: major)
            ...      3     --critical-status='\\\%{alarm_input_admin_state} eq "up" and \\\%{alarm_input_status} eq "alarm" and \\\%{alarm_output_severity} =~ /major|critical/'                  CRITICAL: Alarm input 'PSU_1_Sammelalarm' Alarm input status : alarm (Alarm input admin state: up (Alarm output severity: major)
            ...      4     --filter-name                                                                                                                                                          CRITICAL: Alarm input 'PSU_1_Sammelalarm' Alarm input status : alarm (Alarm input admin state: up (Alarm output severity: major)