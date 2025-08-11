*** Settings ***
Documentation       Check EMC DataDomain in SNMP

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=storage::emc::datadomain::snmp::plugin


*** Test Cases ***
Hardware ${tc}
    [Tags]    snmp  storage
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=hardware
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=storage/emc/datadomain/snmp/slim-datadomain
    ...    --snmp-timeout=1
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Regexp    ${command}    ${expected_result}    ${tc}

    Examples:        tc    extra_options                                                             expected_result    --
            ...      1     ${EMPTY}                                                                  UNKNOWN: Disk '4.1' status is 'unknown' - Disk '4.2' status is 'unknown' - Disk '4.3' status is 'unknown' - Disk '4.4' status is 'unknown' - Disk '4.5' status is 'unknown' - Disk '4.6' status is 'unknown' - Disk '4.7' status is 'unknown' - Disk '4.8' status is 'unknown' - Disk '4.9' status is 'unknown' - Disk '4.10' status is 'unknown' - Disk '4.11' status is 'unknown' - Disk '4.12' status is 'unknown' - Disk '4.13' status is 'unknown' - Disk '4.14' status is 'unknown' - Disk '4.15' status is 'unknown'
            ...      2     --threshold-overload='fan,CRITICAL,^(?!(ok)$)'                            UNKNOWN: Disk '4.1' status is 'unknown' - Disk '4.2' status is 'unknown' - Disk '4.3' status is 'unknown' - Disk '4.4' status is 'unknown' - Disk '4.5' status is 'unknown' - Disk '4.6' status is 'unknown' - Disk '4.7' status is 'unknown' - Disk '4.8' status is 'unknown' - Disk '4.9' status is 'unknown' - Disk '4.10' status is 'unknown' - Disk '4.11' status is 'unknown' - Disk '4.12' status is 'unknown' - Disk '4.13' status is 'unknown' - Disk '4.14' status is 'unknown'
            ...      3     --warning='temperature,10,27'                                             WARNING:.*Temperature 'Anonymized 157' is 33 degree centigrade
            ...      4     --critical='temperature,1.1,25' --critical='battery,.*,20:'               CRITICAL: Temperature 'Anonymized 126' is 36 degree centigrade UNKNOWN: Disk '4.1' status is 'unknown' - Disk '4.2' status is 'unknown' - Disk '4.3' status is 'unknown' - Disk '4.4' status is 'unknown' - Disk '4.5' status is 'unknown' - Disk '4.6' status is 'unknown' - Disk '4.7' status is 'unknown' - Disk '4.8' status is 'unknown' - Disk '4.9' status is 'unknown' - Disk '4.10' status is 'unknown' - Disk '4.11' status is 'unknown'
