*** Settings ***

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource
Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::nortel::standard::snmp::plugin


*** Test Cases ***
hardware-4950gts ${tc}
    [Tags]    network    snmp
    [Documentation]    Ethernet Routing Switch 4950GTS-PWR+
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=hardware
    ...    --hostname=${HOSTNAME}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/nortel/standard/snmp/4950gts-pwr
    ...    --component=${component}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    component        extra_options     expected_result    --
            ...      1     ${EMPTY}         ${EMPTY}          OK: All 13 components are ok [12/12 entities, 1/1 temperatures]. | '5.10.0#hardware.temperature.celsius'=43.50C;;;; 'hardware.entity.count'=12;;;; 'hardware.temperature.count'=1;;;;
            ...      2     fan              ${EMPTY}          CRITICAL: No components are checked.
            ...      3     psu              ${EMPTY}          CRITICAL: No components are checked.
            ...      4     card             ${EMPTY}          CRITICAL: No components are checked.
            ...      5     entity           ${EMPTY}          OK: All 12 components are ok [12/12 entities]. | 'hardware.entity.count'=12;;;;
            ...      6     led              ${EMPTY}          CRITICAL: No components are checked.
            ...      7     temperature      ${EMPTY}          OK: All 1 components are ok [1/1 temperatures]. | '5.10.0#hardware.temperature.celsius'=43.50C;;;; 'hardware.temperature.count'=1;;;;

hardware-5520-24t ${tc}
    [Tags]    network    snmp
    [Documentation]    Ethernet Routing Switch 4950GTS-PWR+
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=hardware
    ...    --hostname=${HOSTNAME}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/nortel/standard/snmp/5520-24t
    ...    --component=${component}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    component        extra_options     expected_result    --
            ...      1     ${EMPTY}         ${EMPTY}          OK: All 24 components are ok [2/2 cards, 4/4 fans, 9/9 led, 2/2 psus, 7/7 temperatures]. | 'CPU#hardware.temperature.celsius'=40C;;;; 'MAC#hardware.temperature.celsius'=38C;;;; 'INTERNAL MAC#hardware.temperature.celsius'=49C;;;; 'PHY1#hardware.temperature.celsius'=32C;;;; 'PHY2#hardware.temperature.celsius'=33C;;;; 'PHY3#hardware.temperature.celsius'=34C;;;; 'OPTIC#hardware.temperature.celsius'=0C;;;; 'hardware.card.count'=2;;;; 'hardware.fan.count'=4;;;; 'hardware.led.count'=9;;;; 'hardware.psu.count'=2;;;; 'hardware.temperature.count'=7;;;;
            ...      2     fan              ${EMPTY}          OK: All 4 components are ok [4/4 fans]. | 'hardware.fan.count'=4;;;;
            ...      3     psu              ${EMPTY}          OK: All 2 components are ok [2/2 psus]. | 'hardware.psu.count'=2;;;;
            ...      4     card             ${EMPTY}          OK: All 2 components are ok [2/2 cards]. | 'hardware.card.count'=2;;;;
            ...      5     entity           ${EMPTY}          CRITICAL: No components are checked.
            ...      6     led              ${EMPTY}          OK: All 9 components are ok [9/9 led]. | 'hardware.led.count'=9;;;;
            ...      7     temperature      ${EMPTY}          OK: All 7 components are ok [7/7 temperatures]. | 'CPU#hardware.temperature.celsius'=40C;;;; 'MAC#hardware.temperature.celsius'=38C;;;; 'INTERNAL MAC#hardware.temperature.celsius'=49C;;;; 'PHY1#hardware.temperature.celsius'=32C;;;; 'PHY2#hardware.temperature.celsius'=33C;;;; 'PHY3#hardware.temperature.celsius'=34C;;;; 'OPTIC#hardware.temperature.celsius'=0C;;;; 'hardware.temperature.count'=7;;;;

hardware-7520-48y-8c ${tc}
    [Tags]    network    snmp
    [Documentation]    Ethernet Routing Switch 4950GTS-PWR+
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=hardware
    ...    --hostname=${HOSTNAME}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/nortel/standard/snmp/7520-48y-8c
    ...    --component=${component}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    component        extra_options     expected_result    --
            ...      1     ${EMPTY}         ${EMPTY}          OK: All 31 components are ok [1/1 cards, 12/12 fans, 6/6 led, 2/2 psus, 10/10 temperatures]. | 'Ambient 0#hardware.temperature.celsius'=29C;;;; 'Ambient 1#hardware.temperature.celsius'=30C;;;; 'Ambient 2#hardware.temperature.celsius'=21C;;;; 'Ambient 3#hardware.temperature.celsius'=27C;;;; 'Ambient 4#hardware.temperature.celsius'=28C;;;; 'Ambient 5#hardware.temperature.celsius'=28C;;;; 'Ambient 6#hardware.temperature.celsius'=26C;;;; 'CPU#hardware.temperature.celsius'=34C;;;; 'INTERNAL MAC#hardware.temperature.celsius'=37C;;;; 'SODIMM#hardware.temperature.celsius'=31C;;;; 'hardware.card.count'=1;;;; 'hardware.fan.count'=12;;;; 'hardware.led.count'=6;;;; 'hardware.psu.count'=2;;;; 'hardware.temperature.count'=10;;;;
            ...      2     fan              ${EMPTY}          OK: All 12 components are ok [12/12 fans]. | 'hardware.fan.count'=12;;;;
            ...      3     psu              ${EMPTY}          OK: All 2 components are ok [2/2 psus]. | 'hardware.psu.count'=2;;;;
            ...      4     card             ${EMPTY}          OK: All 1 components are ok [1/1 cards]. | 'hardware.card.count'=1;;;;
            ...      5     entity           ${EMPTY}          CRITICAL: No components are checked.
            ...      6     led              ${EMPTY}          OK: All 6 components are ok [6/6 led]. | 'hardware.led.count'=6;;;;
            ...      7     temperature      ${EMPTY}          OK: All 10 components are ok [10/10 temperatures]. | 'Ambient 0#hardware.temperature.celsius'=29C;;;; 'Ambient 1#hardware.temperature.celsius'=30C;;;; 'Ambient 2#hardware.temperature.celsius'=21C;;;; 'Ambient 3#hardware.temperature.celsius'=27C;;;; 'Ambient 4#hardware.temperature.celsius'=28C;;;; 'Ambient 5#hardware.temperature.celsius'=28C;;;; 'Ambient 6#hardware.temperature.celsius'=26C;;;; 'CPU#hardware.temperature.celsius'=34C;;;; 'INTERNAL MAC#hardware.temperature.celsius'=37C;;;; 'SODIMM#hardware.temperature.celsius'=31C;;;; 'hardware.temperature.count'=10;;;;

hardware-7520-48ye-8ce ${tc}
    [Tags]    network    snmp
    [Documentation]    Ethernet Routing Switch 4950GTS-PWR+
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=hardware
    ...    --hostname=${HOSTNAME}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/nortel/standard/snmp/7520-48ye-8ce
    ...    --component=${component}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    component        extra_options     expected_result    --
            ...      1     ${EMPTY}         ${EMPTY}          OK: All 31 components are ok [1/1 cards, 12/12 fans, 6/6 led, 2/2 psus, 10/10 temperatures]. | 'Ambient 0#hardware.temperature.celsius'=36C;;;; 'Ambient 1#hardware.temperature.celsius'=37C;;;; 'Ambient 2#hardware.temperature.celsius'=21C;;;; 'Ambient 3#hardware.temperature.celsius'=31C;;;; 'Ambient 4#hardware.temperature.celsius'=37C;;;; 'Ambient 5#hardware.temperature.celsius'=40C;;;; 'Ambient 6#hardware.temperature.celsius'=29C;;;; 'CPU#hardware.temperature.celsius'=41C;;;; 'INTERNAL MAC#hardware.temperature.celsius'=41C;;;; 'SODIMM#hardware.temperature.celsius'=34C;;;; 'hardware.card.count'=1;;;; 'hardware.fan.count'=12;;;; 'hardware.led.count'=6;;;; 'hardware.psu.count'=2;;;; 'hardware.temperature.count'=10;;;;
            ...      2     fan              ${EMPTY}          OK: All 12 components are ok [12/12 fans]. | 'hardware.fan.count'=12;;;;
            ...      3     psu              ${EMPTY}          OK: All 2 components are ok [2/2 psus]. | 'hardware.psu.count'=2;;;;
            ...      4     card             ${EMPTY}          OK: All 1 components are ok [1/1 cards]. | 'hardware.card.count'=1;;;;
            ...      5     entity           ${EMPTY}          CRITICAL: No components are checked.
            ...      6     led              ${EMPTY}          OK: All 6 components are ok [6/6 led]. | 'hardware.led.count'=6;;;;
            ...      7     temperature      ${EMPTY}          OK: All 10 components are ok [10/10 temperatures]. | 'Ambient 0#hardware.temperature.celsius'=36C;;;; 'Ambient 1#hardware.temperature.celsius'=37C;;;; 'Ambient 2#hardware.temperature.celsius'=21C;;;; 'Ambient 3#hardware.temperature.celsius'=31C;;;; 'Ambient 4#hardware.temperature.celsius'=37C;;;; 'Ambient 5#hardware.temperature.celsius'=40C;;;; 'Ambient 6#hardware.temperature.celsius'=29C;;;; 'CPU#hardware.temperature.celsius'=41C;;;; 'INTERNAL MAC#hardware.temperature.celsius'=41C;;;; 'SODIMM#hardware.temperature.celsius'=34C;;;; 'hardware.temperature.count'=10;;;;
