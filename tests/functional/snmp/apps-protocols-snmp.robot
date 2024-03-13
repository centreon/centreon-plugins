*** Settings ***
Documentation       OS Linux SNMP plugin

Library             Examples
Library             OperatingSystem
Library             Process
Library             String

Test Timeout        120s
Suite Setup         Start Mockoon
Suite Teardown      Stop Mockoon

*** Variables ***
${CENTREON_PLUGINS}     ${CURDIR}${/}..${/}..${/}..${/}src${/}centreon_plugins.pl
${MOCKOON_JSON}         ${CURDIR}${/}..${/}..${/}resources${/}mockoon${/}centreon-plugins-passwordmgr-hashicorpvault.json

${CMD}                  perl ${CENTREON_PLUGINS} --plugin apps::protocols::snmp::plugin  --hostname=127.0.0.1


*** Test Cases ***
check hashicorp vault manager${Name}
    [Documentation]    Check hashicorp vaultmanager
    [Tags]    snmp    vault
    ${cmd_hashicorp}    Catenate
    ...    ${CMD}
    ...    --pass-manager hashicorpvault --vault-address='127.0.0.1' --vault-port 3000 --vault-protocol http --auth-method userpass
    ...    --auth-settings="username=hcvaultuser"  --secret-path="path/of/the/secret" --snmp-port=2024
    ...    --map-option="snmp_community=\\%{value_path/of/the/secret}"
    ...    --mode=string-value  --snmp-version=2c --oid='.1.3.6.1.2.1.1.1.0' ${path-param} --format-ok='current value is: \\%{details_ok}' --format-details-warning='current value is: \\%{details_warning}'  --format-details-critical='current value is: \\%{details_critical}'
     ${output}    Run
    ...    ${cmd_hashicorp}
    ${output}    Strip String    ${output}
    Should Be Equal As Strings
    ...    ${output}
    ...    ${result}
    ...    Wrong output result for hashicorp auth manager on snmp generic plugin :\n\n ${output} \n\n ${result}\n\n

    Examples:    Name    path-param    result   --
    ...    default path    --auth-path='' --auth-settings="password=secrethashicorpPassword"    OK: current value is: Linux centreon-devbox 5.10.0-28-amd64 #1 SMP Debian 5.10.209-2 (2024-01-31) x86_64
    ...    wrong path    --auth-path='specific-url' --auth-settings="password=secrethashicorpPassword"    OK: current value is: Linux centreon-devbox 5.10.0-28-amd64 #1 SMP Debian 5.10.209-2 (2024-01-31) x86_64
    ...    wrong password    --auth-path='' --auth-settings="password=WrongPassword"    UNKNOWN: 401 Unauthorized

*** Keywords ***
Start Mockoon
    ${process}    Start Process
    ...    mockoon-cli
    ...    start
    ...    --data
    ...    ${MOCKOON_JSON}
    ...    --port
    ...    3000
    Sleep    5s

Stop Mockoon
    Terminate All Processes