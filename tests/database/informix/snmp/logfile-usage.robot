*** Settings ***
Documentation       Check log files usage.

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s

*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=database::informix::snmp::plugin

*** Test Cases ***
logfile-usage ${tc}
    [Tags]    database    informix
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=logfile-usage
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=database/informix/snmp/slim_informix-log
    ...    --snmp-timeout=1
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}    ${tc}

    Examples:        tc    extra_options                                                                                           expected_result    --
            ...      1     --verbose                                                                                               OK: All dbspace log files usage are ok | 'used_default.linies'=0.00%;;;0;100 'used_default.logical_log'=0.73%;;;0;100 'used_default.rootdbs'=0.00%;;;0;100 Dbspace 'default.linies' Log Files Used: 0.00% Dbspace 'default.logical_log' Log Files Used: 0.73% Dbspace 'default.rootdbs' Log Files Used: 0.00%
            ...      2     --filter-name='default.linies'                                                                          OK: Dbspace 'default.linies' Log Files Used: 0.00% | 'used'=0.00%;;;0;100
            ...      3     --warning-usage=80:90                                                                                   WARNING: Dbspace 'default.linies' Log Files Used: 0.00% - Dbspace 'default.logical_log' Log Files Used: 0.73% - Dbspace 'default.rootdbs' Log Files Used: 0.00% | 'used_default.linies'=0.00%;80:90;;0;100 'used_default.logical_log'=0.73%;80:90;;0;100 'used_default.rootdbs'=0.00%;80:90;;0;100
            ...      4     --critical-usage=80:90                                                                                  CRITICAL: Dbspace 'default.linies' Log Files Used: 0.00% - Dbspace 'default.logical_log' Log Files Used: 0.73% - Dbspace 'default.rootdbs' Log Files Used: 0.00% | 'used_default.linies'=0.00%;;80:90;0;100 'used_default.logical_log'=0.73%;;80:90;0;100 'used_default.rootdbs'=0.00%;;80:90;0;100