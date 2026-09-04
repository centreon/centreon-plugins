*** Settings ***
Documentation       Check swap table

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}                  ${CENTREON_PLUGINS} --plugin=os::linux::snmp::plugin
${CGS_COLLECTIONS}      ${CURDIR}${/}..${/}..${/}..${/}..${/}rust-plugins${/}rs-collections${/}operatingsystems-linux-snmp


*** Test Cases ***
swap ${tc}
    [Tags]    os    linux
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=swap
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=os/linux/snmp/swap
    ...    --snmp-timeout=1
    ...    --warning-usage=${warning-usage}
    ...    --warning-usage-free=${warning-usage-free}
    ...    --warning-usage-prct=${warning-usage-prct}
    ...    --critical-usage=${critical-usage}
    ...    --critical-usage-free=${critical-usage-free}
    ...    --critical-usage-prct=${critical-usage-prct}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    warning-usage
    ...    warning-usage-free
    ...    warning-usage-prct
    ...    critical-usage
    ...    critical-usage-free
    ...    critical-usage-prct
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    ${EMPTY}
    ...    ${EMPTY}
    ...    ${EMPTY}
    ...    ${EMPTY}
    ...    ${EMPTY}
    ...    OK: Swap Total: 976.00 MB Used: 487.71 MB (49.97%) Free: 488.28 MB (50.03%) | 'used'=511406080B;;;0;1023406080 'free'=512000000B;;;0;1023406080 'used_prct'=49.97%;;;0;100
    ...    2
    ...    '10'
    ...    ${EMPTY}
    ...    ${EMPTY}
    ...    ${EMPTY}
    ...    ${EMPTY}
    ...    ${EMPTY}
    ...    WARNING: Swap Total: 976.00 MB Used: 487.71 MB (49.97%) Free: 488.28 MB (50.03%) | 'used'=511406080B;0:10;;0;1023406080 'free'=512000000B;;;0;1023406080 'used_prct'=49.97%;;;0;100
    ...    3
    ...    '10'
    ...    ${EMPTY}
    ...    ${EMPTY}
    ...    '30'
    ...    ${EMPTY}
    ...    ${EMPTY}
    ...    CRITICAL: Swap Total: 976.00 MB Used: 487.71 MB (49.97%) Free: 488.28 MB (50.03%) | 'used'=511406080B;0:10;0:30;0;1023406080 'free'=512000000B;;;0;1023406080 'used_prct'=49.97%;;;0;100
    ...    4
    ...    ${EMPTY}
    ...    '10'
    ...    ${EMPTY}
    ...    ${EMPTY}
    ...    ${EMPTY}
    ...    ${EMPTY}
    ...    WARNING: Swap Total: 976.00 MB Used: 487.71 MB (49.97%) Free: 488.28 MB (50.03%) | 'used'=511406080B;;;0;1023406080 'free'=512000000B;0:10;;0;1023406080 'used_prct'=49.97%;;;0;100
    ...    5
    ...    ${EMPTY}
    ...    '10'
    ...    ${EMPTY}
    ...    ${EMPTY}
    ...    '30'
    ...    ${EMPTY}
    ...    CRITICAL: Swap Total: 976.00 MB Used: 487.71 MB (49.97%) Free: 488.28 MB (50.03%) | 'used'=511406080B;;;0;1023406080 'free'=512000000B;0:10;0:30;0;1023406080 'used_prct'=49.97%;;;0;100
    ...    6
    ...    ${EMPTY}
    ...    ${EMPTY}
    ...    '10'
    ...    ${EMPTY}
    ...    ${EMPTY}
    ...    ${EMPTY}
    ...    WARNING: Used : 49.97 % | 'used'=511406080B;;;0;1023406080 'free'=512000000B;;;0;1023406080 'used_prct'=49.97%;0:10;;0;100
    ...    7
    ...    ${EMPTY}
    ...    ${EMPTY}
    ...    '10'
    ...    ${EMPTY}
    ...    ${EMPTY}
    ...    '30'
    ...    CRITICAL: Used : 49.97 % | 'used'=511406080B;;;0;1023406080 'free'=512000000B;;;0;1023406080 'used_prct'=49.97%;0:10;0:30;0;100

cgs-swap ${tc}
    [Tags]    os    linux    centreon-plugin-rust-snmp
    ${command}    Catenate
    ...    ${CENTREON_PLUGIN_RUST_SNMP}
    ...    -j ${CGS_COLLECTIONS}${/}swap.json
    ...    --hostname=${HOSTNAME}
    ...    --port=${SNMPPORT}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-community=os/linux/snmp/swap
    ...    ${extra_options}

    Ctn Run Command Without Connector And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    OK: Swap Total: 976.00 MB Used: 487.71 MB (49.97%) Free: 488.28 MB (50.03%) | 'used'=511406080B;;;0;1023406080 'free'=512000000B;;;0;1023406080 'used_prct'=49.97%;;;0;100
    ...    2
    ...    --warning-usage=10
    ...    WARNING: Swap Total: 976.00 MB Used: 487.71 MB (49.97%) Free: 488.28 MB (50.03%) | 'used'=511406080B;0:10;;0;1023406080 'free'=512000000B;;;0;1023406080 'used_prct'=49.97%;;;0;100
    ...    3
    ...    --warning-usage=10 --critical-usage=30
    ...    CRITICAL: Swap Total: 976.00 MB Used: 487.71 MB (49.97%) Free: 488.28 MB (50.03%) | 'used'=511406080B;0:10;0:30;0;1023406080 'free'=512000000B;;;0;1023406080 'used_prct'=49.97%;;;0;100
    ...    4
    ...    --warning-usage-free=10
    ...    WARNING: Swap Total: 976.00 MB Used: 487.71 MB (49.97%) Free: 488.28 MB (50.03%) | 'used'=511406080B;;;0;1023406080 'free'=512000000B;0:10;;0;1023406080 'used_prct'=49.97%;;;0;100
    ...    5
    ...    --warning-usage-free=10 --critical-usage-free=30
    ...    CRITICAL: Swap Total: 976.00 MB Used: 487.71 MB (49.97%) Free: 488.28 MB (50.03%) | 'used'=511406080B;;;0;1023406080 'free'=512000000B;0:10;0:30;0;1023406080 'used_prct'=49.97%;;;0;100
    ...    6
    ...    --warning-usage-prct=10
    ...    WARNING: Used : 49.97 % | 'used'=511406080B;;;0;1023406080 'free'=512000000B;;;0;1023406080 'used_prct'=49.97%;0:10;;0;100
    ...    7
    ...    --warning-usage-prct=10 --critical-usage-prct=30
    ...    CRITICAL: Used : 49.97 % | 'used'=511406080B;;;0;1023406080 'free'=512000000B;;;0;1023406080 'used_prct'=49.97%;0:10;0:30;0;100
    ...    8
    ...    --check-format
    ...    Check format of JSON file '${CGS_COLLECTIONS}${/}swap.json' JSON is valid

cgs-swap-64 ${tc}
    [Tags]    os    linux    centreon-plugin-rust-snmp
    ${command}    Catenate
    ...    ${CENTREON_PLUGIN_RUST_SNMP}
    ...    -j ${CGS_COLLECTIONS}${/}swap-64.json
    ...    --hostname=${HOSTNAME}
    ...    --port=${SNMPPORT}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-community=os/linux/snmp/swap
    ...    ${extra_options}

    Ctn Run Command Without Connector And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    OK: Swap Total: 976.00 MB Used: 487.71 MB (49.97%) Free: 488.28 MB (50.03%) | 'used'=511406080B;;;0;1023406080 'free'=512000000B;;;0;1023406080 'used_prct'=49.97%;;;0;100
    ...    2
    ...    --warning-usage=10
    ...    WARNING: Swap Total: 976.00 MB Used: 487.71 MB (49.97%) Free: 488.28 MB (50.03%) | 'used'=511406080B;0:10;;0;1023406080 'free'=512000000B;;;0;1023406080 'used_prct'=49.97%;;;0;100
    ...    3
    ...    --warning-usage=10 --critical-usage=30
    ...    CRITICAL: Swap Total: 976.00 MB Used: 487.71 MB (49.97%) Free: 488.28 MB (50.03%) | 'used'=511406080B;0:10;0:30;0;1023406080 'free'=512000000B;;;0;1023406080 'used_prct'=49.97%;;;0;100
    ...    4
    ...    --warning-usage-free=10
    ...    WARNING: Swap Total: 976.00 MB Used: 487.71 MB (49.97%) Free: 488.28 MB (50.03%) | 'used'=511406080B;;;0;1023406080 'free'=512000000B;0:10;;0;1023406080 'used_prct'=49.97%;;;0;100
    ...    5
    ...    --warning-usage-free=10 --critical-usage-free=30
    ...    CRITICAL: Swap Total: 976.00 MB Used: 487.71 MB (49.97%) Free: 488.28 MB (50.03%) | 'used'=511406080B;;;0;1023406080 'free'=512000000B;0:10;0:30;0;1023406080 'used_prct'=49.97%;;;0;100
    ...    6
    ...    --warning-usage-prct=10
    ...    WARNING: Used : 49.97 % | 'used'=511406080B;;;0;1023406080 'free'=512000000B;;;0;1023406080 'used_prct'=49.97%;0:10;;0;100
    ...    7
    ...    --warning-usage-prct=10 --critical-usage-prct=30
    ...    CRITICAL: Used : 49.97 % | 'used'=511406080B;;;0;1023406080 'free'=512000000B;;;0;1023406080 'used_prct'=49.97%;0:10;0:30;0;100
    ...    8
    ...    --check-format
    ...    Check format of JSON file '${CGS_COLLECTIONS}${/}swap-64.json' JSON is valid
