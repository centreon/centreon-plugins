*** Settings ***
Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}vault-authentication-hashicorp.json

${CMD}              ${CENTREON_PLUGINS} --plugin apps::protocols::snmp::plugin --hostname=${HOSTNAME}


*** Test Cases ***
check hashicorp vault manager${Name}
    [Documentation]    Check hashicorp vaultmanager
    [Tags]    snmp    vault
    ${command}    Catenate
    ...    ${CMD}
    ...    --pass-manager=hashicorpvault
    ...    --vault-address=${HOSTNAME}
    ...    --vault-port=${APIPORT}
    ...    --vault-protocol=http
    ...    --auth-method=userpass
    ...    --auth-settings="username=hcvaultuser"
    ...    --secret-path="path/of/the/secret"
    ...    --snmp-port=${SNMPPORT}
    ...    --map-option="snmp_community=\\%{value_path/of/the/secret}"
    ...    --mode=string-value
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-community=apps/protocols/snmp/snmp-single-oid
    ...    --oid='.1.3.6.1.2.1.1.1.0' ${path-param}
    ...    --format-ok='current value is: \\%{details_ok}'
    ...    --format-details-warning='current value is: \\%{details_warning}'
    ...    --format-details-critical='current value is: \\%{details_critical}'
    
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:    Name    path-param    expected_result   --
    ...    default path    --auth-path='' --auth-settings="password=secrethashicorpPassword"    OK: current value is: Linux centreon-devbox 5.10.0-28-amd64 #1 SMP Debian 5.10.209-2 (2024-01-31) x86_64
    ...    wrong path    --auth-path='specific-url' --auth-settings="password=secrethashicorpPassword"    OK: current value is: Linux centreon-devbox 5.10.0-28-amd64 #1 SMP Debian 5.10.209-2 (2024-01-31) x86_64
    ...    wrong password    --auth-path='' --auth-settings="password=WrongPassword"    UNKNOWN: 401 Unauthorized
