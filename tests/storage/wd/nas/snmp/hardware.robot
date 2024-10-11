*** Settings ***
Documentation       Check WD (Western Digital) NAS in SNMP

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}                                              ${CENTREON_PLUGINS} --plugin=storage::wd::nas::snmp::plugin

*** Test Cases ***
Hardware${tc}
    [Tags]    hardware    storage    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=hardware
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=storage/wd/nas/snmp/nas-wd
    ...    ${extra_option}
    
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:         tc  extra_option                                                                        expected_result    --
            ...       1   --warning-fan-status='\\\%{status} =~ "running"'                                    WARNING: fan '0' status: running | 'system#hardware.temperature.celsius'=34C;;;; 'drive:WD-WCC130163701#hardware.temperature.celsius'=40C;;;; 'drive:WD-WCC4E0HRX2TN#hardware.temperature.celsius'=36C;;;; 'drive:WD-WCC4E6KA8V1T#hardware.temperature.celsius'=37C;;;; 'drive:WD-WCC4E7ZHA6A7#hardware.temperature.celsius'=36C;;;;
            ...       2   --critical-fan-status='\\\%{status} =~ "running"'                                   CRITICAL: fan '0' status: running | 'system#hardware.temperature.celsius'=34C;;;; 'drive:WD-WCC130163701#hardware.temperature.celsius'=40C;;;; 'drive:WD-WCC4E0HRX2TN#hardware.temperature.celsius'=36C;;;; 'drive:WD-WCC4E6KA8V1T#hardware.temperature.celsius'=37C;;;; 'drive:WD-WCC4E7ZHA6A7#hardware.temperature.celsius'=36C;;;;
            ...       3   --warning-system-temperature='0'                                                    WARNING: system temperature: 34 C | 'system#hardware.temperature.celsius'=34C;0:0;;; 'drive:WD-WCC130163701#hardware.temperature.celsius'=40C;;;; 'drive:WD-WCC4E0HRX2TN#hardware.temperature.celsius'=36C;;;; 'drive:WD-WCC4E6KA8V1T#hardware.temperature.celsius'=37C;;;; 'drive:WD-WCC4E7ZHA6A7#hardware.temperature.celsius'=36C;;;;
            ...       4   --warning-system-temperature='36'                                                   OK: system temperature: 34 C - fan '0' status: running | 'system#hardware.temperature.celsius'=34C;0:36;;; 'drive:WD-WCC130163701#hardware.temperature.celsius'=40C;;;; 'drive:WD-WCC4E0HRX2TN#hardware.temperature.celsius'=36C;;;; 'drive:WD-WCC4E6KA8V1T#hardware.temperature.celsius'=37C;;;; 'drive:WD-WCC4E7ZHA6A7#hardware.temperature.celsius'=36C;;;;
            ...       5   --warning-drive-temperature='0'                                                     WARNING: drive 'WD-WCC130163701' temperature: 40 C - drive 'WD-WCC4E0HRX2TN' temperature: 36 C - drive 'WD-WCC4E6KA8V1T' temperature: 37 C - drive 'WD-WCC4E7ZHA6A7' temperature: 36 C | 'system#hardware.temperature.celsius'=34C;;;; 'drive:WD-WCC130163701#hardware.temperature.celsius'=40C;0:0;;; 'drive:WD-WCC4E0HRX2TN#hardware.temperature.celsius'=36C;0:0;;; 'drive:WD-WCC4E6KA8V1T#hardware.temperature.celsius'=37C;0:0;;; 'drive:WD-WCC4E7ZHA6A7#hardware.temperature.celsius'=36C;0:0;;;
            ...       6   --warning-drive-temperature='70'                                                    OK: system temperature: 34 C - fan '0' status: running | 'system#hardware.temperature.celsius'=34C;;;; 'drive:WD-WCC130163701#hardware.temperature.celsius'=40C;0:70;;; 'drive:WD-WCC4E0HRX2TN#hardware.temperature.celsius'=36C;0:70;;; 'drive:WD-WCC4E6KA8V1T#hardware.temperature.celsius'=37C;0:70;;; 'drive:WD-WCC4E7ZHA6A7#hardware.temperature.celsius'=36C;0:70;;;
            ...       7   --critical-system-temperature='0'                                                   CRITICAL: system temperature: 34 C | 'system#hardware.temperature.celsius'=34C;;0:0;; 'drive:WD-WCC130163701#hardware.temperature.celsius'=40C;;;; 'drive:WD-WCC4E0HRX2TN#hardware.temperature.celsius'=36C;;;; 'drive:WD-WCC4E6KA8V1T#hardware.temperature.celsius'=37C;;;; 'drive:WD-WCC4E7ZHA6A7#hardware.temperature.celsius'=36C;;;;
            ...       8   --critical-system-temperature='70'                                                  OK: system temperature: 34 C - fan '0' status: running | 'system#hardware.temperature.celsius'=34C;;0:70;; 'drive:WD-WCC130163701#hardware.temperature.celsius'=40C;;;; 'drive:WD-WCC4E0HRX2TN#hardware.temperature.celsius'=36C;;;; 'drive:WD-WCC4E6KA8V1T#hardware.temperature.celsius'=37C;;;; 'drive:WD-WCC4E7ZHA6A7#hardware.temperature.celsius'=36C;;;;
            ...       9   --critical-drive-temperature='0'                                                    CRITICAL: drive 'WD-WCC130163701' temperature: 40 C - drive 'WD-WCC4E0HRX2TN' temperature: 36 C - drive 'WD-WCC4E6KA8V1T' temperature: 37 C - drive 'WD-WCC4E7ZHA6A7' temperature: 36 C | 'system#hardware.temperature.celsius'=34C;;;; 'drive:WD-WCC130163701#hardware.temperature.celsius'=40C;;0:0;; 'drive:WD-WCC4E0HRX2TN#hardware.temperature.celsius'=36C;;0:0;; 'drive:WD-WCC4E6KA8V1T#hardware.temperature.celsius'=37C;;0:0;; 'drive:WD-WCC4E7ZHA6A7#hardware.temperature.celsius'=36C;;0:0;;
            ...       10  --critical-drive-temperature='36'                                                   CRITICAL: drive 'WD-WCC130163701' temperature: 40 C - drive 'WD-WCC4E6KA8V1T' temperature: 37 C | 'system#hardware.temperature.celsius'=34C;;;; 'drive:WD-WCC130163701#hardware.temperature.celsius'=40C;;0:36;; 'drive:WD-WCC4E0HRX2TN#hardware.temperature.celsius'=36C;;0:36;; 'drive:WD-WCC4E6KA8V1T#hardware.temperature.celsius'=37C;;0:36;; 'drive:WD-WCC4E7ZHA6A7#hardware.temperature.celsius'=36C;;0:36;;