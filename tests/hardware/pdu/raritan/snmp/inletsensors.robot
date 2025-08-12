*** Settings ***
Documentation       Check inlet sensors

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=hardware::pdu::raritan::snmp::plugin


*** Test Cases ***
inlet ${tc}
    [Tags]    hardware    pdu    raritan   inlet   sensors
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=inlet-sensors
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=hardware/pdu/raritan/snmp/raritan
    ...    --snmp-timeout=1
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                                 expected_result    --
            ...      1     ${EMPTY}                                                                      OK: All 7 components are ok [1/1 activeEnergy, 1/1 activePower, 1/1 apparentPower, 1/1 frequency, 1/1 powerFactor, 1/1 rmsCurrent, 1/1 rmsVoltage]. | 'Anonymized 102~Anonymized 027#hardware.sensor.inlet.activeenergy.watthour'=1444088wattHour;;;; 'Anonymized 102~Anonymized 027#hardware.sensor.inlet.activepower.watt'=242W;;;; 'Anonymized 102~Anonymized 027#hardware.sensor.inlet.apparentpower.voltamp'=379voltamp;;;; 'Anonymized 102~Anonymized 027#hardware.sensor.inlet.frequency.hertz'=50Hz;;;; 'Anonymized 102~Anonymized 027#hardware.sensor.inlet.powerfactor'=0.64;;;; 'Anonymized 102~Anonymized 027#hardware.sensor.inlet.rmscurrent.ampere'=1.626A;~:10.4;~:12.8;; 'Anonymized 102~Anonymized 027#hardware.sensor.inlet.rmsvoltage.volt'=233V;194:247;188:254;; 'hardware.activeEnergy.count'=1;;;; 'hardware.activePower.count'=1;;;; 'hardware.apparentPower.count'=1;;;; 'hardware.frequency.count'=1;;;; 'hardware.powerFactor.count'=1;;;; 'hardware.rmsCurrent.count'=1;;;; 'hardware.rmsVoltage.count'=1;;;;
            ...      2     --filter=powerFactor                                                          OK: All 6 components are ok [1/1 activeEnergy, 1/1 activePower, 1/1 apparentPower, 1/1 frequency, 1/1 rmsCurrent, 1/1 rmsVoltage]. | 'Anonymized 102~Anonymized 027#hardware.sensor.inlet.activeenergy.watthour'=1444088wattHour;;;; 'Anonymized 102~Anonymized 027#hardware.sensor.inlet.activepower.watt'=242W;;;; 'Anonymized 102~Anonymized 027#hardware.sensor.inlet.apparentpower.voltamp'=379voltamp;;;; 'Anonymized 102~Anonymized 027#hardware.sensor.inlet.frequency.hertz'=50Hz;;;; 'Anonymized 102~Anonymized 027#hardware.sensor.inlet.rmscurrent.ampere'=1.626A;~:10.4;~:12.8;; 'Anonymized 102~Anonymized 027#hardware.sensor.inlet.rmsvoltage.volt'=233V;194:247;188:254;; 'hardware.activeEnergy.count'=1;;;; 'hardware.activePower.count'=1;;;; 'hardware.apparentPower.count'=1;;;; 'hardware.frequency.count'=1;;;; 'hardware.rmsCurrent.count'=1;;;; 'hardware.rmsVoltage.count'=1;;;;
            ...      3     --component=powerFactor                                                       OK: All 1 components are ok [1/1 powerFactor]. | 'Anonymized 102~Anonymized 027#hardware.sensor.inlet.powerfactor'=0.64;;;; 'hardware.powerFactor.count'=1;;;;
            ...      4     --component=powerFactor --threshold-overload='powerFactor,CRITICAL,normal'    CRITICAL: 'Anonymized 027' powerFactor state is 'normal' | 'Anonymized 102~Anonymized 027#hardware.sensor.inlet.powerfactor'=0.64;;;; 'hardware.powerFactor.count'=1;;;;
