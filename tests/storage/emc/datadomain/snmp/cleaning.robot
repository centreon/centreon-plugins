*** Settings ***
Documentation       Check EMC DataDomain in SNMP

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=storage::emc::DataDomain::snmp::plugin


*** Test Cases ***
cleaning ${tc}
    [Tags]    os    linux
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=cleaning
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=storage/emc/datadomain/snmp/slim-datadomain
    ...    --snmp-timeout=1
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                                   expected_result    --
            ...      1     --verbose                                                                       OK: cleaning last execution: never | 'filesystems.cleaning.execution.last.days'=-1d;;;0;
            ...      2     --unit='h'                                                                      OK: cleaning last execution: never | 'filesystems.cleaning.execution.last.hours'=-1h;;;0;
            ...      3     --unit='s'                                                                      OK: cleaning last execution: never | 'filesystems.cleaning.execution.last.seconds'=-1s;;;0;
            ...      4     --unit='w'                                                                      OK: cleaning last execution: never | 'filesystems.cleaning.execution.last.weeks'=-1w;;;0;
            ...      5     --warning-last-cleaning-execution='' --critical-last-cleaning-execution=''      OK: cleaning last execution: never | 'filesystems.cleaning.execution.last.days'=-1d;;;0;