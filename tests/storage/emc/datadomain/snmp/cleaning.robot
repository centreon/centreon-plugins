*** Settings ***
Documentation       Check EMC DataDomain in SNMP

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
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
    ...    --snmp-community=${snmp_community}
    ...    --snmp-timeout=5
    ...    ${extra_options}
  
    # first run to build cache
    Run    ${command}
    # second run to control the output
    Ctn Run Command And Check Result As Regexp    ${command}    ${expected_result}
    

    Examples:        tc    extra_options                                                                      snmp_community                                                                      expected_result    --
            ...      1     ${EMPTY}                                     storage/emc/datadomain/snmp/slim-datadomain                     OK: cleaning last execution: (\\\\d+[yY]] )?(\\\\d+M )?(\\\\d+w )?(\\\\d+d )?(\\\\d+h )?(\\\\d+m )?(\\\\d+s )?\\\\| 'filesystems.cleaning.execution.last.days'=\\\\d+d;;;0;$
            ...      2     --unit='w'                                   storage/emc/datadomain/snmp/slim-datadomain                     OK: cleaning last execution: (\\\\d+[yY]] )?(\\\\d+M )?(\\\\d+w )?(\\\\d+d )?(\\\\d+h )?(\\\\d+m )?(\\\\d+s )?\\\\| 'filesystems.cleaning.execution.last.weeks'=\\\\d+w;;;0;$
            ...      3     --warning-last-cleaning-execution='115'      storage/emc/datadomain/snmp/slim-datadomain                     WARNING: cleaning last execution: (\\\\d+[yY]] )?(\\\\d+M )?(\\\\d+w )?(\\\\d+d )?(\\\\d+h )?(\\\\d+m )?(\\\\d+s )?\\\\| 'filesystems.cleaning.execution.last.days'=\\\\d+d;0:115;;0;
            ...      4     --critical-last-cleaning-execution='0'       storage/emc/datadomain/snmp/slim-datadomain                     CRITICAL: cleaning last execution: (\\\\d+[yY]] )?(\\\\d+M )?(\\\\d+w )?(\\\\d+d )?(\\\\d+h )?(\\\\d+m )?(\\\\d+s )?\\\\| 'filesystems.cleaning.execution.last.days'=\\\\d+d;;0:0;0;
            ...      5     ${EMPTY}                                     storage/emc/datadomain/snmp/slim-datadomain-cleaning-running    OK: cleaning last execution: running \\\\(phase 5 of 6 : copy\\\\) \\\\| 'filesystems.cleaning.execution.last.days'=0d;;;0;
            ...      6     --timezone='Europe/Paris'                    storage/emc/datadomain/snmp/slim-datadomain-cleaning-ok         OK: cleaning last execution: .* \\\\| 'filesystems.cleaning.execution.last.days'=\\\\d+d;;;0;
            ...      7     --timezone='America/Los_Angeles'             storage/emc/datadomain/snmp/slim-datadomain-cleaning-ok         OK: cleaning last execution: .* \\\\| 'filesystems.cleaning.execution.last.days'=\\\\d+d;;;0;
            ...      8     --timezone='bad/timezone'                    storage/emc/datadomain/snmp/slim-datadomain-cleaning-ok         UNKNOWN: Invalid timezone provided: 'bad/timezone'. Check in /usr/share/zoneinfo for valid time zones.
