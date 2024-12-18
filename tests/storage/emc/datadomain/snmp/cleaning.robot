*** Settings ***
Documentation       Check EMC DataDomain in SNMP

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=storage::emc::datadomain::snmp::plugin


*** Test Cases ***
cleaning ${tc}
    [Tags]    snmp  storage
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=cleaning
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=${SNMPCOMMUNITY}
    ...    --snmp-timeout=5
    ...    ${extra_options}
  
    # first run to build cache
    Run    ${command}
    # second run to control the output
    Ctn Run Command And Check Result As Regexp    ${command}    ${expected_result}
    

    Examples:        tc    extra_options                                                                      SNMPCOMMUNITY                                                                       expected_result    --
            ...      1     ${EMPTY}                                                                           storage/emc/datadomain/snmp/slim-datadomain                                         OK: cleaning last execution: \\\\d+M \\\\d+w \\\\d+h \\\\d+m \\\\d+s \\\\| 'filesystems.cleaning.execution.last.days'=\\\\d+d;;;0;$
            ...      2     --unit='w'                                                                         storage/emc/datadomain/snmp/slim-datadomain                                         OK: cleaning last execution: 3M 3w 17h 9m 7s | 'filesystems.cleaning.execution.last.weeks'=16w;;;0;
            ...      3     --warning-last-cleaning-execution='115' --critical-last-cleaning-execution='0'     storage/emc/datadomain/snmp/slim-datadomain                                         CRITICAL: cleaning last execution: 3M 3w 16h 52m 15s | 'filesystems.cleaning.execution.last.days'=113d;0:115;0:0;0;
            ...      4     ${EMPTY}                                                                           storage/emc/datadomain/snmp/slim-datadomain-cleaning-running                        OK: cleaning last execution: running (phase 5 of 6 : copy) | 'filesystems.cleaning.execution.last.days'=0d;;;0;