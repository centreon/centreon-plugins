*** Settings ***
Documentation       Aruba Standard SNMP License

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}
...         --plugin=network::aruba::standard::snmp::plugin
...         --mode=license
...         --hostname=${HOSTNAME}
...         --snmp-version=${SNMPVERSION}
...         --snmp-port=${SNMPPORT}
...         --snmp-community=network/aruba/standard/snmp/aruba-license
...         --snmp-timeout=1


*** Test Cases ***
License ${tc}
    [Documentation]    Check Aruba license status and expiry
    [Tags]    network    aruba    snmp    license

    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Regexp    ${command}    ${expected_regexp}

    Examples:    tc    extra_options                                                       expected_regexp    --
        ...      1     ${EMPTY}                                                            ^OK: All licenses status are ok
        ...      2     --critical-status='' --warning-status='\\\%{flag}=~/enabled/i'      WARNING: License 'WebCC: 33' status is 'enabled', expires.* - License 'Yo0: 20' status is 'enabled', never expires - License 'Yo1: 35' status is 'enabled', never expires - License 'Yo2: 50' status is 'enabled', never expires
        ...      3     --warning-status='\\\%{expires} !~ /Never/'                         ^WARNING: License 'WebCC: 33' status is 'enabled'.*expires in.*2029-10-25 06:56:50
        ...      4     --critical-status='\\\%{expires} !~ /Never/'                        ^CRITICAL: License 'WebCC: 33' status is 'enabled'.*expires in.*2029-10-25 06:56:50
        ...      5     --warning-status='\\\%{service} =~ /WebCC/'                         ^WARNING: License 'WebCC: 33' status is 'enabled'.*expires in.*2029-10-25 06:56:50
        ...      6     --critical-status='\\\%{flag} =~ /enabled/'                         ^CRITICAL:(?=.*Yo0: 20)(?=.*Yo1: 35)(?=.*Yo2: 50)(?=.*WebCC: 33)
