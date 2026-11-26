*** Settings ***
Documentation     network::mikrotik::snmp::plugin

Resource          ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup       Ctn Generic Suite Setup
Suite Teardown    Ctn Generic Suite Teardown
Test Timeout      120s


*** Variables ***
${CMD}    ${CENTREON_PLUGINS}
...       --plugin=network::mikrotik::snmp::plugin
...       --mode=sfp
...       --hostname=${HOSTNAME}
...       --snmp-version=${SNMPVERSION}
...       --snmp-port=${SNMPPORT}
...       --statefile-dir=/dev/shm/
...       --lockfile-dir=/dev/shm/


*** Test Cases ***
Sfp ${tc}
    [Tags]    network    mikrotik    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --snmp-community=network/mikrotik/snmp/${community}
    ...    --statefile-suffix=_sfp_${community}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    community
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    crs305
    ...    ${EMPTY}
    ...    OK: All SFP modules are ok | 'sfp-sfpplus1#port.temperature.celsius'=34C;;;; 'sfp-sfpplus1#port.voltage.volt'=3.29V;;;; 'sfp-sfpplus1#port.bias.current.milliampere'=21.00mA;;;; 'sfp-sfpplus1#port.output.power.dbm'=-6.50dBm;;;; 'sfp-sfpplus1#port.output.power.milliwatt'=0.2236mW;;;; 'sfp-sfpplus1#port.input.power.dbm'=-6.83dBm;;;; 'sfp-sfpplus1#port.input.power.milliwatt'=0.2073mW;;;; 'sfp-sfpplus2#port.temperature.celsius'=46C;;;; 'sfp-sfpplus2#port.voltage.volt'=3.32V;;;; 'sfp-sfpplus2#port.bias.current.milliampere'=32.00mA;;;; 'sfp-sfpplus2#port.output.power.dbm'=-6.12dBm;;;; 'sfp-sfpplus2#port.output.power.milliwatt'=0.2445mW;;;; 'sfp-sfpplus2#port.input.power.dbm'=-5.05dBm;;;; 'sfp-sfpplus2#port.input.power.milliwatt'=0.3128mW;;;;
    ...    2
    ...    crs305
    ...    --include-name=sfpplus2
    ...    OK: SFP 'sfp-sfpplus2' [vendor: OEM, serial: SN00000002, wavelength: 1310.00 nm] rx loss: false, tx fault: false, temperature: 46 C, voltage: 3.32 V, bias current: 32.00 mA, output power: -6.12 dBm, input power: -5.05 dBm | 'sfp-sfpplus2#port.temperature.celsius'=46C;;;; 'sfp-sfpplus2#port.voltage.volt'=3.32V;;;; 'sfp-sfpplus2#port.bias.current.milliampere'=32.00mA;;;; 'sfp-sfpplus2#port.output.power.dbm'=-6.12dBm;;;; 'sfp-sfpplus2#port.output.power.milliwatt'=0.2445mW;;;; 'sfp-sfpplus2#port.input.power.dbm'=-5.05dBm;;;; 'sfp-sfpplus2#port.input.power.milliwatt'=0.3128mW;;;;
    ...    3
    ...    crs305
    ...    --exclude-serial=SN00000002
    ...    OK: SFP 'sfp-sfpplus1' [vendor: FOUNDRY NETWORKS, serial: SN00000001, wavelength: 1310.00 nm] rx loss: false, tx fault: false, temperature: 34 C, voltage: 3.29 V, bias current: 21.00 mA, output power: -6.50 dBm, input power: -6.83 dBm | 'sfp-sfpplus1#port.temperature.celsius'=34C;;;; 'sfp-sfpplus1#port.voltage.volt'=3.29V;;;; 'sfp-sfpplus1#port.bias.current.milliampere'=21.00mA;;;; 'sfp-sfpplus1#port.output.power.dbm'=-6.50dBm;;;; 'sfp-sfpplus1#port.output.power.milliwatt'=0.2236mW;;;; 'sfp-sfpplus1#port.input.power.dbm'=-6.83dBm;;;; 'sfp-sfpplus1#port.input.power.milliwatt'=0.2073mW;;;;
    ...    4
    ...    crs305
    ...    --include-name=sfpplus1 --warning-rx-input-power-dbm=-6: --critical-temperature=30
    ...    CRITICAL: SFP 'sfp-sfpplus1' [vendor: FOUNDRY NETWORKS, serial: SN00000001, wavelength: 1310.00 nm] temperature: 34 C, input power: -6.83 dBm | 'sfp-sfpplus1#port.temperature.celsius'=34C;;0:30;; 'sfp-sfpplus1#port.voltage.volt'=3.29V;;;; 'sfp-sfpplus1#port.bias.current.milliampere'=21.00mA;;;; 'sfp-sfpplus1#port.output.power.dbm'=-6.50dBm;;;; 'sfp-sfpplus1#port.output.power.milliwatt'=0.2236mW;;;; 'sfp-sfpplus1#port.input.power.dbm'=-6.83dBm;-6:;;; 'sfp-sfpplus1#port.input.power.milliwatt'=0.2073mW;;;;
    ...    5
    ...    crs305
    ...    --include-name=sfpplus1 --warning-tx-output-power=0.3: --critical-volt=3.3:
    ...    CRITICAL: SFP 'sfp-sfpplus1' [vendor: FOUNDRY NETWORKS, serial: SN00000001, wavelength: 1310.00 nm] voltage: 3.29 V, output power: 0.2236 mW | 'sfp-sfpplus1#port.temperature.celsius'=34C;;;; 'sfp-sfpplus1#port.voltage.volt'=3.29V;;3.3:;; 'sfp-sfpplus1#port.bias.current.milliampere'=21.00mA;;;; 'sfp-sfpplus1#port.output.power.dbm'=-6.50dBm;;;; 'sfp-sfpplus1#port.output.power.milliwatt'=0.2236mW;0.3:;;; 'sfp-sfpplus1#port.input.power.dbm'=-6.83dBm;;;; 'sfp-sfpplus1#port.input.power.milliwatt'=0.2073mW;;;;
    ...    6
    ...    crs305
    ...    --include-name=sfpplus2 --warning-bias-current=30 --critical-tx-output-power-dbm=:-7
    ...    CRITICAL: SFP 'sfp-sfpplus2' [vendor: OEM, serial: SN00000002, wavelength: 1310.00 nm] bias current: 32.00 mA, output power: -6.12 dBm | 'sfp-sfpplus2#port.temperature.celsius'=46C;;;; 'sfp-sfpplus2#port.voltage.volt'=3.32V;;;; 'sfp-sfpplus2#port.bias.current.milliampere'=32.00mA;0:30;;; 'sfp-sfpplus2#port.output.power.dbm'=-6.12dBm;;0:-7;; 'sfp-sfpplus2#port.output.power.milliwatt'=0.2445mW;;;; 'sfp-sfpplus2#port.input.power.dbm'=-5.05dBm;;;; 'sfp-sfpplus2#port.input.power.milliwatt'=0.3128mW;;;;
    ...    7
    ...    crs305
    ...    --warning-status='\\\%{vendor} eq "OEM"'
    ...    WARNING: SFP 'sfp-sfpplus2' [vendor: OEM, serial: SN00000002, wavelength: 1310.00 nm] rx loss: false, tx fault: false | 'sfp-sfpplus1#port.temperature.celsius'=34C;;;; 'sfp-sfpplus1#port.voltage.volt'=3.29V;;;; 'sfp-sfpplus1#port.bias.current.milliampere'=21.00mA;;;; 'sfp-sfpplus1#port.output.power.dbm'=-6.50dBm;;;; 'sfp-sfpplus1#port.output.power.milliwatt'=0.2236mW;;;; 'sfp-sfpplus1#port.input.power.dbm'=-6.83dBm;;;; 'sfp-sfpplus1#port.input.power.milliwatt'=0.2073mW;;;; 'sfp-sfpplus2#port.temperature.celsius'=46C;;;; 'sfp-sfpplus2#port.voltage.volt'=3.32V;;;; 'sfp-sfpplus2#port.bias.current.milliampere'=32.00mA;;;; 'sfp-sfpplus2#port.output.power.dbm'=-6.12dBm;;;; 'sfp-sfpplus2#port.output.power.milliwatt'=0.2445mW;;;; 'sfp-sfpplus2#port.input.power.dbm'=-5.05dBm;;;; 'sfp-sfpplus2#port.input.power.milliwatt'=0.3128mW;;;;
    ...    8
    ...    crs305
    ...    --include-name=nothing
    ...    UNKNOWN: No SFP module found (check the filters or reload the cache).
    ...    9
    ...    crs305-rxloss
    ...    ${EMPTY}
    ...    CRITICAL: SFP 'sfp-sfpplus3' [vendor: OEM, serial: SN00000003, wavelength: 1550.00 nm] rx loss: true, tx fault: false | 'sfp-sfpplus1#port.temperature.celsius'=34C;;;; 'sfp-sfpplus1#port.voltage.volt'=3.29V;;;; 'sfp-sfpplus1#port.bias.current.milliampere'=21.00mA;;;; 'sfp-sfpplus1#port.output.power.dbm'=-6.50dBm;;;; 'sfp-sfpplus1#port.output.power.milliwatt'=0.2236mW;;;; 'sfp-sfpplus1#port.input.power.dbm'=-6.83dBm;;;; 'sfp-sfpplus1#port.input.power.milliwatt'=0.2073mW;;;; 'sfp-sfpplus2#port.temperature.celsius'=46C;;;; 'sfp-sfpplus2#port.voltage.volt'=3.32V;;;; 'sfp-sfpplus2#port.bias.current.milliampere'=32.00mA;;;; 'sfp-sfpplus2#port.output.power.dbm'=-6.12dBm;;;; 'sfp-sfpplus2#port.output.power.milliwatt'=0.2445mW;;;; 'sfp-sfpplus2#port.input.power.dbm'=-5.05dBm;;;; 'sfp-sfpplus2#port.input.power.milliwatt'=0.3128mW;;;; 'sfp-sfpplus3#port.temperature.celsius'=39C;;;; 'sfp-sfpplus3#port.voltage.volt'=3.30V;;;; 'sfp-sfpplus3#port.bias.current.milliampere'=25.00mA;;;; 'sfp-sfpplus3#port.output.power.dbm'=-5.51dBm;;;; 'sfp-sfpplus3#port.output.power.milliwatt'=0.2811mW;;;; 'sfp-sfpplus3#port.input.power.dbm'=-40.00dBm;;;; 'sfp-sfpplus3#port.input.power.milliwatt'=0.0001mW;;;;
    ...    10
    ...    crs305-rxloss
    ...    --critical-status= --warning-rx-input-power-dbm=-20:
    ...    WARNING: SFP 'sfp-sfpplus3' [vendor: OEM, serial: SN00000003, wavelength: 1550.00 nm] input power: -40.00 dBm | 'sfp-sfpplus1#port.temperature.celsius'=34C;;;; 'sfp-sfpplus1#port.voltage.volt'=3.29V;;;; 'sfp-sfpplus1#port.bias.current.milliampere'=21.00mA;;;; 'sfp-sfpplus1#port.output.power.dbm'=-6.50dBm;;;; 'sfp-sfpplus1#port.output.power.milliwatt'=0.2236mW;;;; 'sfp-sfpplus1#port.input.power.dbm'=-6.83dBm;-20:;;; 'sfp-sfpplus1#port.input.power.milliwatt'=0.2073mW;;;; 'sfp-sfpplus2#port.temperature.celsius'=46C;;;; 'sfp-sfpplus2#port.voltage.volt'=3.32V;;;; 'sfp-sfpplus2#port.bias.current.milliampere'=32.00mA;;;; 'sfp-sfpplus2#port.output.power.dbm'=-6.12dBm;;;; 'sfp-sfpplus2#port.output.power.milliwatt'=0.2445mW;;;; 'sfp-sfpplus2#port.input.power.dbm'=-5.05dBm;-20:;;; 'sfp-sfpplus2#port.input.power.milliwatt'=0.3128mW;;;; 'sfp-sfpplus3#port.temperature.celsius'=39C;;;; 'sfp-sfpplus3#port.voltage.volt'=3.30V;;;; 'sfp-sfpplus3#port.bias.current.milliampere'=25.00mA;;;; 'sfp-sfpplus3#port.output.power.dbm'=-5.51dBm;;;; 'sfp-sfpplus3#port.output.power.milliwatt'=0.2811mW;;;; 'sfp-sfpplus3#port.input.power.dbm'=-40.00dBm;-20:;;; 'sfp-sfpplus3#port.input.power.milliwatt'=0.0001mW;;;;
    ...    11
    ...    mikrotik-chateau-lte6
    ...    ${EMPTY}
    ...    UNKNOWN: Can't construct cache: no SFP module found.

# The cache file is shared by the walks (same host, port and suffix): the cases depend on each other and run in order

Sfp cache ${tc}
    [Tags]    network    mikrotik    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --snmp-community=network/mikrotik/snmp/${community}
    ...    --statefile-suffix=_sfp_cache
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    community
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    crs305
    ...    ${EMPTY}
    ...    OK: All SFP modules are ok | 'sfp-sfpplus1#port.temperature.celsius'=34C;;;; 'sfp-sfpplus1#port.voltage.volt'=3.29V;;;; 'sfp-sfpplus1#port.bias.current.milliampere'=21.00mA;;;; 'sfp-sfpplus1#port.output.power.dbm'=-6.50dBm;;;; 'sfp-sfpplus1#port.output.power.milliwatt'=0.2236mW;;;; 'sfp-sfpplus1#port.input.power.dbm'=-6.83dBm;;;; 'sfp-sfpplus1#port.input.power.milliwatt'=0.2073mW;;;; 'sfp-sfpplus2#port.temperature.celsius'=46C;;;; 'sfp-sfpplus2#port.voltage.volt'=3.32V;;;; 'sfp-sfpplus2#port.bias.current.milliampere'=32.00mA;;;; 'sfp-sfpplus2#port.output.power.dbm'=-6.12dBm;;;; 'sfp-sfpplus2#port.output.power.milliwatt'=0.2445mW;;;; 'sfp-sfpplus2#port.input.power.dbm'=-5.05dBm;;;; 'sfp-sfpplus2#port.input.power.milliwatt'=0.3128mW;;;;
    ...    2
    ...    crs305-rxloss
    ...    ${EMPTY}
    ...    OK: All SFP modules are ok | 'sfp-sfpplus1#port.temperature.celsius'=34C;;;; 'sfp-sfpplus1#port.voltage.volt'=3.29V;;;; 'sfp-sfpplus1#port.bias.current.milliampere'=21.00mA;;;; 'sfp-sfpplus1#port.output.power.dbm'=-6.50dBm;;;; 'sfp-sfpplus1#port.output.power.milliwatt'=0.2236mW;;;; 'sfp-sfpplus1#port.input.power.dbm'=-6.83dBm;;;; 'sfp-sfpplus1#port.input.power.milliwatt'=0.2073mW;;;; 'sfp-sfpplus2#port.temperature.celsius'=46C;;;; 'sfp-sfpplus2#port.voltage.volt'=3.32V;;;; 'sfp-sfpplus2#port.bias.current.milliampere'=32.00mA;;;; 'sfp-sfpplus2#port.output.power.dbm'=-6.12dBm;;;; 'sfp-sfpplus2#port.output.power.milliwatt'=0.2445mW;;;; 'sfp-sfpplus2#port.input.power.dbm'=-5.05dBm;;;; 'sfp-sfpplus2#port.input.power.milliwatt'=0.3128mW;;;;
    ...    3
    ...    crs305-rxloss
    ...    --reload-cache-time=0
    ...    CRITICAL: SFP 'sfp-sfpplus3' [vendor: OEM, serial: SN00000003, wavelength: 1550.00 nm] rx loss: true, tx fault: false | 'sfp-sfpplus1#port.temperature.celsius'=34C;;;; 'sfp-sfpplus1#port.voltage.volt'=3.29V;;;; 'sfp-sfpplus1#port.bias.current.milliampere'=21.00mA;;;; 'sfp-sfpplus1#port.output.power.dbm'=-6.50dBm;;;; 'sfp-sfpplus1#port.output.power.milliwatt'=0.2236mW;;;; 'sfp-sfpplus1#port.input.power.dbm'=-6.83dBm;;;; 'sfp-sfpplus1#port.input.power.milliwatt'=0.2073mW;;;; 'sfp-sfpplus2#port.temperature.celsius'=46C;;;; 'sfp-sfpplus2#port.voltage.volt'=3.32V;;;; 'sfp-sfpplus2#port.bias.current.milliampere'=32.00mA;;;; 'sfp-sfpplus2#port.output.power.dbm'=-6.12dBm;;;; 'sfp-sfpplus2#port.output.power.milliwatt'=0.2445mW;;;; 'sfp-sfpplus2#port.input.power.dbm'=-5.05dBm;;;; 'sfp-sfpplus2#port.input.power.milliwatt'=0.3128mW;;;; 'sfp-sfpplus3#port.temperature.celsius'=39C;;;; 'sfp-sfpplus3#port.voltage.volt'=3.30V;;;; 'sfp-sfpplus3#port.bias.current.milliampere'=25.00mA;;;; 'sfp-sfpplus3#port.output.power.dbm'=-5.51dBm;;;; 'sfp-sfpplus3#port.output.power.milliwatt'=0.2811mW;;;; 'sfp-sfpplus3#port.input.power.dbm'=-40.00dBm;;;; 'sfp-sfpplus3#port.input.power.milliwatt'=0.0001mW;;;;
    ...    4
    ...    crs305
    ...    ${EMPTY}
    ...    OK: All SFP modules are ok | 'sfp-sfpplus1#port.temperature.celsius'=34C;;;; 'sfp-sfpplus1#port.voltage.volt'=3.29V;;;; 'sfp-sfpplus1#port.bias.current.milliampere'=21.00mA;;;; 'sfp-sfpplus1#port.output.power.dbm'=-6.50dBm;;;; 'sfp-sfpplus1#port.output.power.milliwatt'=0.2236mW;;;; 'sfp-sfpplus1#port.input.power.dbm'=-6.83dBm;;;; 'sfp-sfpplus1#port.input.power.milliwatt'=0.2073mW;;;; 'sfp-sfpplus2#port.temperature.celsius'=46C;;;; 'sfp-sfpplus2#port.voltage.volt'=3.32V;;;; 'sfp-sfpplus2#port.bias.current.milliampere'=32.00mA;;;; 'sfp-sfpplus2#port.output.power.dbm'=-6.12dBm;;;; 'sfp-sfpplus2#port.output.power.milliwatt'=0.2445mW;;;; 'sfp-sfpplus2#port.input.power.dbm'=-5.05dBm;;;; 'sfp-sfpplus2#port.input.power.milliwatt'=0.3128mW;;;;

Sfp show cache
    [Tags]    network    mikrotik    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --snmp-community=network/mikrotik/snmp/crs305
    ...    --statefile-suffix=_sfp_cache
    ...    --show-cache

    Ctn Run Command And Check Result As Regexp    ${command}    ^UNKNOWN: Cache content:[^@]*'name' => 'sfp-sfpplus3'

List sfp ${tc}
    [Tags]    network    mikrotik    snmp
    ${command}    Catenate
    ...    ${CENTREON_PLUGINS}
    ...    --plugin=network::mikrotik::snmp::plugin
    ...    --mode=list-sfp
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/mikrotik/snmp/crs305-rxloss
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    List SFP modules: [index: 2][name: sfp-sfpplus1][vendor: FOUNDRY NETWORKS][serial: SN00000001][wavelength: 1310.00] [index: 3][name: sfp-sfpplus2][vendor: OEM][serial: SN00000002][wavelength: 1310.00] [index: 4][name: sfp-sfpplus3][vendor: OEM][serial: SN00000003][wavelength: 1550.00]
    ...    2
    ...    --include-name=sfpplus[13]
    ...    List SFP modules: [index: 2][name: sfp-sfpplus1][vendor: FOUNDRY NETWORKS][serial: SN00000001][wavelength: 1310.00] [index: 4][name: sfp-sfpplus3][vendor: OEM][serial: SN00000003][wavelength: 1550.00]
