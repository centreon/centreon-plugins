*** Settings ***
Documentation       Check Hardware (Fans, Power supplies, chassis, io cards, blades, fabric extenders).

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=hardware::server::cisco::ucs::snmp::plugin


*** Test Cases ***
equipment ${tc}
    [Tags]    hardware    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=equipment
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=hardware/server/cisco/ucs/snmp/slim-ucs-equipment
    ...    ${extra_options}
 
    Ctn Verify Command Output    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                                                                expected_result    --
            ...      1     ${EMPTY}                                                                                                     WARNING: memory 'Anonymized-001/mem-12' presence is: 'missing' - memory 'Anonymized-001/mem-15' presence is: 'missing'
            ...      2     --threshold-overload='presence,OK,missing' --threshold-overload='operability,OK,removed'                     OK: All 100 components are ok [100/100 memories]. | 'hardware.memory.count'=100;;;;
            ...      3     --threshold-overload='presence,UNKNOWN,missing' --component='memory'                                         UNKNOWN: memory 'Anonymized-001/mem-12' presence is: 'missing' - memory 'Anonymized-001/mem-15' presence is: 'missing'
            ...      4     --threshold-overload='operability,WARNING,missing' --component='memory'                                      WARNING: memory 'Anonymized-001/mem-12' presence is: 'missing' - memory 'Anonymized-001/mem-15' presence is: 'missing'
            ...      5     --component='cpu'                                                                                            CRITICAL: No components are checked.
            ...      6     --filter=fan,/sys/chassis-7/fan-module-1-7/fan-1                                                             WARNING: memory 'Anonymized-001/mem-12' presence is: 'missing' - memory 'Anonymized-001/mem-15' presence is: 'missing'
            ...      7     --absent-problem=fan,/sys/chassis-7/fan-module-1-7/fan-1                                                     WARNING: memory 'Anonymized-001/mem-12' presence is: 'missing' - memory 'Anonymized-001/mem-15' presence is: 'missing'
            ...      8     --no-component=UNKNOWN --filter='.*'                                                                         UNKNOWN: No components are checked.
            ...      9     --threshold-overload='presence,CRITICAL,equipped'                                                            CRITICAL: memory 'Anonymized-001/mem-10' presence is: 'equipped' - memory 'Anonymized-001/mem-11' presence is: 'equipped'
            ...      10    --filter='.*'                                                                                                CRITICAL: No components are checked.
            ...      11    --filter                                                                                                     WARNING: memory 'Anonymized-001/mem-12' presence is: 'missing' - memory 'Anonymized-001/mem-15' presence is: 'missing'
