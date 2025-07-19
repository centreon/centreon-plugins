*** Settings ***
Documentation     Huawei Management Module SNMP

Resource          ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup       Ctn Generic Suite Setup
Test Timeout      120s


*** Variables ***
${CMD}                                          ${CENTREON_PLUGINS} --plugin=hardware::server::huawei::hmm::snmp::plugin

*** Test Cases ***
blade ${tc}
    [Tags]    harware huawei snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=blade
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --blade-id=1
    ...    --snmp-community=hardware/server/huawei/hmm/snmp/huawei
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                               expected_result    --
            ...      1     ${EMPTY}                                                    OK: All 22 components are ok [2/2 cpus, 2/2 disks, 16/16 memory slots, 1/1 mezz cards, 1/1 temperatures]. | 'temperature_Anonymized 052'=49C;;;0; 'temperature_Anonymized 250'=52C;;;0; 'temperature_1'=24C;;;; 'count_cpu'=2;;;; 'count_disk'=2;;;; 'count_memory'=16;;;; 'count_mezz'=1;;;; 'count_temperature'=1;;;;
            ...      2     --component=mezz                                            OK: All 1 components are ok [1/1 mezz cards]. | 'count_mezz'=1;;;;
            ...      3     --blade-id=10                                               CRITICAL: No components are checked.
            ...      4     --blade-id=10 --no-component=warning                        WARNING: No components are checked.
            ...      5     --threshold-overload='cpu,WARNING,^(?!(ok)$)'               WARNING: Cpu 'Anonymized 052' status is 'normal' - Cpu 'Anonymized 250' status is 'normal' | 'temperature_Anonymized 052'=49C;;;0; 'temperature_Anonymized 250'=52C;;;0; 'temperature_1'=24C;;;; 'count_cpu'=2;;;; 'count_disk'=2;;;; 'count_memory'=16;;;; 'count_mezz'=1;;;; 'count_temperature'=1;;;;
            ...      6      --critical='temperature,.*,:10'                            CRITICAL: Temperature '1' is '24' celsius degrees | 'temperature_Anonymized 052'=49C;;;0; 'temperature_Anonymized 250'=52C;;;0; 'temperature_1'=24C;;0:10;; 'count_cpu'=2;;;; 'count_disk'=2;;;; 'count_memory'=16;;;; 'count_mezz'=1;;;; 'count_temperature'=1;;;;
