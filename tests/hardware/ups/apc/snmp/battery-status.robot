*** Settings ***
Documentation       Check battery status

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Test Timeout        120s


*** Variables ***
${CMD}     ${CENTREON_PLUGINS}
    ...    --plugin=hardware::ups::apc::snmp::plugin
    ...    --mode=battery-status
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-timeout=1


*** Test Cases ***
battery status ${tc}
    [Tags]    hardware    ups    apc
    ${command}    Catenate
    ...    ${CMD}
    ...    --snmp-community=hardware/ups/apc/snmp/ups-apc-battery-ok
    ...    ${extra_options}

    Ctn Run Command And Check Result As Regexp    ${command}    ${expected_regexp}    ${tc}

    Examples:    tc    extra_options                                                             expected_regexp    --
    ...          1     ${EMPTY}                                                              ^OK: battery status is 'batteryNormal' \\\\[battery needs replace: no\\\\] \\\\[last replace date: 10-05-2022\\\\], remaining capacity: 100 %, remaining time: 665.00 minutes, time on battery: 205761.00 minutes, voltage: 110 V, temperature: 23 C - All battery packs are ok \\\\| 'battery.charge.remaining.percent'=100%;;;0;100 'battery.charge.remaining.minutes'=665.00m;;;0; 'battery.timeon.minutes'=205761.00m;;;0; 'battery.voltage.volt'=110V;;;; 'battery.temperature.celsius'=23C;;;;
    ...          2     --replace-lasttime-format='%d-%m-%Y'                                  ^OK: battery status is 'batteryNormal' \\\\[battery needs replace: no\\\\] \\\\[last replace date: 10-05-2022\\\\], remaining capacity: 100 %, remaining time: 665.00 minutes, time on battery: 205761.00 minutes, voltage: 110 V, temperature: 23 C - All battery packs are ok \\\\| 'battery.charge.remaining.percent'=100%;;;0;100 'battery.charge.remaining.minutes'=665.00m;;;0; 'battery.timeon.minutes'=205761.00m;;;0; 'battery.voltage.volt'=110V;;;; 'battery.temperature.celsius'=23C;;;; 'battery.replace.lasttime.seconds'=\\\\d*s;;;;
    ...          3     --replace-lasttime-format='%d-%m-%Y' --warning-replace-lasttime=2     ^WARNING: replace last time: (\\\\d+y )?(\\\\d+M )?(\\\\d+w )?(\\\\d+d )?(\\\\d+h )?(\\\\d+m )?(\\\\d+s )?\\\\| 'battery.charge.remaining.percent'=100%;;;0;100 'battery.charge.remaining.minutes'=665.00m;;;0; 'battery.timeon.minutes'=205761.00m;;;0; 'battery.voltage.volt'=110V;;;; 'battery.temperature.celsius'=23C;;;; 'battery.replace.lasttime.seconds'=\\\\d*s;0:2;;;$
    ...          4     --replace-lasttime-format='%d-%m-%Y' --critical-replace-lasttime=2    ^CRITICAL: replace last time: (\\\\d+y )?(\\\\d+M )?(\\\\d+w )?(\\\\d+d )?(\\\\d+h )?(\\\\d+m )?(\\\\d+s )?\\\\| 'battery.charge.remaining.percent'=100%;;;0;100 'battery.charge.remaining.minutes'=665.00m;;;0; 'battery.timeon.minutes'=205761.00m;;;0; 'battery.voltage.volt'=110V;;;; 'battery.temperature.celsius'=23C;;;; 'battery.replace.lasttime.seconds'=\\\\d*s;;0:2;;$

*** Test Cases ***
battery low status ${tc}
    [Tags]    hardware    ups    apc
    ${command}    Catenate
    ...    ${CMD}
    ...    --snmp-community=hardware/ups/apc/snmp/ups-apc-battery-low
    ...    --warning-status='${warning_status}'
    ...    --critical-status='${critical_status}'
    ...    --critical-battery-pack-status='${critical_battery_pack_status}'
    ...    --critical-cartridge-status='${critical_cartridge_status}'
    ...    ${extra_options}

    Ctn Run Command And Check Result As Regexp    ${command}    ${expected_regexp}    ${tc}

    Examples:    tc    warning_status                   critical_status            critical_battery_pack_status    critical_cartridge_status    extra_options    expected_regexp    --
    ...          1     \\\%{status} =~ /batteryLow/i    \\\%{replace} =~ /yes/i    \\\%{status} ne "OK"            \\\%{status} ne "OK"         ${EMPTY}         ^CRITICAL: battery status is 'batteryLow' \\\\[battery needs replace: yes\\\\] \\\\[last replace date: 10/05/2022\\\\] - battery pack '1' status is 'needsReplacement' - cartridge '1' status is 'needsReplacement' - cartridge '2' status is 'needsReplacement' - battery pack '2' status is 'needsReplacement' \\\\| 'battery.charge.remaining.percent'=75%;;;0;100 'battery.charge.remaining.minutes'=665.00m;;;0; 'battery.timeon.minutes'=390946.00m;;;0; 'battery.voltage.volt'=110V;;;; 'battery.temperature.celsius'=23C;;;; 'battery.replace.lasttime.seconds'=\\\\d*s;;;;$
    ...          2     \\\%{status} =~ /batteryLow/i    ${EMPTY}                   ${EMPTY}                        ${EMPTY}                     ${EMPTY}         ^WARNING: battery status is 'batteryLow' \\\\[battery needs replace: yes\\\\] \\\\[last replace date: 10/05/2022\\\\] \\\\| 'battery.charge.remaining.percent'=75%;;;0;100 'battery.charge.remaining.minutes'=665.00m;;;0; 'battery.timeon.minutes'=390946.00m;;;0; 'battery.voltage.volt'=110V;;;; 'battery.temperature.celsius'=23C;;;; 'battery.replace.lasttime.seconds'=\\\\d*s;;;;$
    ...          3     ${EMPTY}                         \\\%{replace} =~ /yes/i    ${EMPTY}                        ${EMPTY}                     ${EMPTY}         ^CRITICAL: battery status is 'batteryLow' \\\\[battery needs replace: yes\\\\] \\\\[last replace date: 10/05/2022\\\\] \\\\| 'battery.charge.remaining.percent'=75%;;;0;100 'battery.charge.remaining.minutes'=665.00m;;;0; 'battery.timeon.minutes'=390946.00m;;;0; 'battery.voltage.volt'=110V;;;; 'battery.temperature.celsius'=23C;;;; 'battery.replace.lasttime.seconds'=\\\\d*s;;;;$
    ...          4     ${EMPTY}                         ${EMPTY}                   \\\%{status} ne "OK"            ${EMPTY}                     ${EMPTY}         ^CRITICAL: battery pack '1' status is 'needsReplacement' - battery pack '2' status is 'needsReplacement' \\\\| 'battery.charge.remaining.percent'=75%;;;0;100 'battery.charge.remaining.minutes'=665.00m;;;0; 'battery.timeon.minutes'=390946.00m;;;0; 'battery.voltage.volt'=110V;;;; 'battery.temperature.celsius'=23C;;;; 'battery.replace.lasttime.seconds'=\\\\d*s;;;;$
    ...          5     ${EMPTY}                         ${EMPTY}                   ${EMPTY}                        ${EMPTY}                     --warning-battery-pack-status='\\\%{status} ne "OK"'    ^WARNING: battery pack '1' status is 'needsReplacement' - battery pack '2' status is 'needsReplacement' \\\\| 'battery.charge.remaining.percent'=75%;;;0;100 'battery.charge.remaining.minutes'=665.00m;;;0; 'battery.timeon.minutes'=390946.00m;;;0; 'battery.voltage.volt'=110V;;;; 'battery.temperature.celsius'=23C;;;; 'battery.replace.lasttime.seconds'=\\\\d*s;;;;$
    ...          6     ${EMPTY}                         ${EMPTY}                   ${EMPTY}                        \\\%{status} ne "OK"         ${EMPTY}         ^CRITICAL: battery pack '1' cartridge '1' status is 'needsReplacement' - cartridge '2' status is 'needsReplacement' \\\\| 'battery.charge.remaining.percent'=75%;;;0;100 'battery.charge.remaining.minutes'=665.00m;;;0; 'battery.timeon.minutes'=390946.00m;;;0; 'battery.voltage.volt'=110V;;;; 'battery.temperature.celsius'=23C;;;; 'battery.replace.lasttime.seconds'=\\\\d*s;;;;$
    ...          7     ${EMPTY}                         ${EMPTY}                   ${EMPTY}                        ${EMPTY}                     --warning-cartridge-status='\\\%{status} ne "OK"'    ^WARNING: battery pack '1' cartridge '1' status is 'needsReplacement' - cartridge '2' status is 'needsReplacement' \\\\| 'battery.charge.remaining.percent'=75%;;;0;100 'battery.charge.remaining.minutes'=665.00m;;;0; 'battery.timeon.minutes'=390946.00m;;;0; 'battery.voltage.volt'=110V;;;; 'battery.temperature.celsius'=23C;;;; 'battery.replace.lasttime.seconds'=\\\\d*s;;;;$
