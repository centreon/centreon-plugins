*** Settings ***
Documentation       

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::cisco::wlc::snmp::plugin


*** Test Cases ***
ap-channel-noise ${tc}
    [Tags]    network    wlc    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=ap-channel-noise
    ...    --hostname=${HOSTNAME}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/cisco/wlc/snmp/slim_cisco_wlc
    ...    ${extra_options}

    ${output}    Run    ${command}
    ${output}    Strip String    ${output}
    Should Contain    
    ...    ${output}    
    ...    ${expected_result}
    ...    Wrong output result for command:\n${command}\n\nObtained:\n${output}\n\nExpected:\n${expected_result}\n
    ...    values=False
    ...    collapse_spaces=True


    Examples:        tc    extra_options                                                            expected_result    --
            ...      1     --filter-name                                                            OK: All access points are ok | 'noise_power_Anonymized 007_slot0:channel1'=-95dBm;;;; 'noise_power_Anonymized 007_slot0:channel10'=-94dBm;;;; 'noise_power_Anonymized 007_slot0:channel11'=-94dBm;;;; 'noise_power_Anonymized 007_slot0:channel12'=-95dBm;;;; 'noise_power_Anonymized 007_slot0:channel13'=-96dBm;;;; 'noise_power_Anonymized 007_slot0:channel2'=-98dBm;;;; 'noise_power_Anonymized 007_slot0:channel3'=-95dBm;;;; 'noise_power_Anonymized 007_slot0:channel4'=-96dBm;;;; 'noise_power_Anonymized 007_slot0:channel5'=-96dBm;;;; 'noise_power_Anonymized 007_slot0:channel6'=-95dBm;;;; 'noise_power_Anonymized 007_slot0:channel7'=-93dBm;;;; 'noise_power_Anonymized 007_slot0:channel8'=-95dBm;;;; 'noise_power_Anonymized 007_slot0:channel9'=-93dBm;;;; 'noise_power_Anonymized 015_slot0:channel1'=-86dBm;;;; 'noise_power_Anonymized 015_slot0:channel10'=-96dBm;;;; 'noise_power_Anonymized 015_slot0:channel11'=-99dBm;;;;
            ...      2     --filter-group                                                           OK: All access points are ok | 'noise_power_Anonymized 007_slot0:channel1'=-95dBm;;;; 'noise_power_Anonymized 007_slot0:channel10'=-94dBm;;;; 'noise_power_Anonymized 007_slot0:channel11'=-94dBm;;;; 'noise_power_Anonymized 007_slot0:channel12'=-95dBm;;;; 'noise_power_Anonymized 007_slot0:channel13'=-96dBm;;;; 'noise_power_Anonymized 007_slot0:channel2'=-98dBm;;;; 'noise_power_Anonymized 007_slot0:channel3'=-95dBm;;;; 'noise_power_Anonymized 007_slot0:channel4'=-96dBm;;;; 'noise_power_Anonymized 007_slot0:channel5'=-96dBm;;;; 'noise_power_Anonymized 007_slot0:channel6'=-95dBm;;;; 'noise_power_Anonymized 007_slot0:channel7'=-93dBm;;;; 'noise_power_Anonymized 007_slot0:channel8'=-95dBm;;;; 'noise_power_Anonymized 007_slot0:channel9'=-93dBm;;;; 'noise_power_Anonymized 015_slot0:channel1'=-86dBm;;;; 'noise_power_Anonymized 015_slot0:channel10'=-96dBm;;;; 'noise_power_Anonymized 015_slot0:channel11'=-99dBm;;;;
            ...      3     --filter-channel='slot0:channel3'                                        OK: All access points are ok | 'noise_power_Anonymized 007'=-95dBm;;;; 'noise_power_Anonymized 015'=-96dBm;;;; 'noise_power_Anonymized 035'=-96dBm;;;; 'noise_power_Anonymized 072'=-96dBm;;;; 'noise_power_Anonymized 089'=-93dBm;;;; 'noise_power_Anonymized 108'=-99dBm;;;; 'noise_power_Anonymized 122'=-97dBm;;;; 'noise_power_Anonymized 181'=-97dBm;;;; 'noise_power_Anonymized 201'=-95dBm;;;; 'noise_power_Anonymized 249'=-95dBm;;;;
            ...      4     --warning-noise-power --critical-noise-power                             K: All access points are ok | 'noise_power_Anonymized 007_slot0:channel1'=-95dBm;;;; 'noise_power_Anonymized 007_slot0:channel10'=-94dBm;;;; 'noise_power_Anonymized 007_slot0:channel11'=-94dBm;;;; 'noise_power_Anonymized 007_slot0:channel12'=-95dBm;;;; 'noise_power_Anonymized 007_slot0:channel13'=-96dBm;;;; 'noise_power_Anonymized 007_slot0:channel2'=-98dBm;;;; 'noise_power_Anonymized 007_slot0:channel3'=-95dBm;;;; 'noise_power_Anonymized 007_slot0:channel4'=-96dBm;;;; 'noise_power_Anonymized 007_slot0:channel5'=-96dBm;;;; 'noise_power_Anonymized 007_slot0:channel6'=-95dBm;;;; 'noise_power_Anonymized 007_slot0:channel7'=-93dBm;;;; 'noise_power_Anonymized 007_slot0:channel8'=-95dBm;;;; 'noise_power_Anonymized 007_slot0:channel9'=-93dBm;;;; 'noise_power_Anonymized 015_slot0:channel1'=-86dBm;;;; 'noise_power_Anonymized 015_slot0:channel10'=-96dBm;;;; 'noise_power_Anonymized 015_slot0:channel11'=-99dBm;;;;
            ...      5     --warning-noise-power=0 --critical-noise-power=100                       CRITICAL: access point 'Anonymized 007' channel 'slot0:channel1' noise power: -95 dBm - channel 'slot0:channel10' noise power: -94 dBm - channel 'slot0:channel11' noise power: -94 dBm - channel 'slot0:channel12' noise power: -95 dBm - channel 'slot0:channel13' noise power: -96 dBm - channel 'slot0:channel2' noise power: -98 dBm - channel 'slot0:channel3' noise power: -95 dBm - channel 'slot0:channel4' noise power: -96 dBm - channel 'slot0:channel5' noise power: -96 dBm - channel 'slot0:channel6' noise power: -95 dBm - channel 'slot0:channel7' noise power: -93 dBm - channel 'slot0:channel8' noise power: -95 dBm - channel 'slot0:channel9' noise power: -93 dBm - access point 'Anonymized 015' channel 'slot0:channel1' noise power: -86 dBm - channel 'slot0:channel10' noise power: -96 dBm - channel 'slot0:channel11' noise power: -99 dBm - channel 'slot0:channel12' noise power: -99 dBm - channel 'slot0:channel13' noise power: -98 dBm - channel 'slot0:channel2' noise power: -97 dBm
            ...      6     --verbose                                                                OK: All access points are ok | 'noise_power_Anonymized 007_slot0:channel1'=-95dBm;;;; 'noise_power_Anonymized 007_slot0:channel10'=-94dBm;;;; 'noise_power_Anonymized 007_slot0:channel11'=-94dBm;;;; 'noise_power_Anonymized 007_slot0:channel12'=-95dBm;;;; 'noise_power_Anonymized 007_slot0:channel13'=-96dBm;;;; 'noise_power_Anonymized 007_slot0:channel2'=-98dBm;;;; 'noise_power_Anonymized 007_slot0:channel3'=-95dBm;;;; 'noise_power_Anonymized 007_slot0:channel4'=-96dBm;;;; 'noise_power_Anonymized 007_slot0:channel5'=-96dBm;;;; 'noise_power_Anonymized 007_slot0:channel6'=-95dBm;;;; 'noise_power_Anonymized 007_slot0:channel7'=-93dBm;;;; 'noise_power_Anonymized 007_slot0:channel8'=-95dBm;;;; 'noise_power_Anonymized 007_slot0:channel9'=-93dBm;;;; 'noise_power_Anonymized 015_slot0:channel1'=-86dBm;;;; 'noise_power_Anonymized 015_slot0:channel10'=-96dBm;;;; 'noise_power_Anonymized 015_slot0:channel11'=-99dBm;;;;
            ...      7     --warning-noise-power=100 --critical-noise-power=0                       CRITICAL: access point 'Anonymized 007' channel 'slot0:channel1' noise power: -95 dBm - channel 'slot0:channel10' noise power: -94 dBm - channel 'slot0:channel11' noise power: -94 dBm - channel 'slot0:channel12' noise power: -95 dBm - channel 'slot0:channel13' noise power: -96 dBm - channel 'slot0:channel2' noise power: -98 dBm - channel 'slot0:channel3' noise power: -95 dBm - channel 'slot0:channel4' noise power: -96 dBm - channel 'slot0:channel5' noise power: -96 dBm - channel 'slot0:channel6' noise power: -95 dBm - channel 'slot0:channel7' noise power: -93 dBm - channel 'slot0:channel8' noise power: -95 dBm - channel 'slot0:channel9' noise power: -93 dBm - access point 'Anonymized 015' channel 'slot0:channel1' noise power: -86 dBm - channel 'slot0:channel10' noise power: -96 dBm - channel 'slot0:channel11' noise power: -99 dBm - channel 'slot0:channel12' noise power: -99 dBm - channel 'slot0:channel13' noise power: -98 dBm