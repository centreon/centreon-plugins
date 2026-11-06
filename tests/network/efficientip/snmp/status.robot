*** Settings ***
Documentation     Check Efficient IP SOLIDserver role and status

Resource          ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup       Ctn Generic Suite Setup
Suite Teardown    Ctn Generic Suite Teardown
Test Timeout      120s


*** Variables ***
${CMD}    ${CENTREON_PLUGINS} --plugin=network::efficientip::snmp::plugin


*** Test Cases ***
status ${tc}
    [Tags]    network    efficientip    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=status
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    --snmp-community=network/efficientip/snmp/remote-managed
    ...    OK: Status: 'ok', Role: 'remote managed'
    ...    2
    ...    --snmp-community=network/efficientip/snmp/remote-managed --critical-status='\\\%{role} =~ /remote managed/'
    ...    CRITICAL: Status: 'ok', Role: 'remote managed'
    ...    3
    ...    --snmp-community=network/efficientip/snmp/init-master
    ...    OK: Status: 'init master', Role: 'master'
    ...    4
    ...    --snmp-community=network/efficientip/snmp/init-master --warning-status='\\\%{status} =~ /init master/'
    ...    WARNING: Status: 'init master', Role: 'master'
    ...    5
    ...    --snmp-community=network/efficientip/snmp/unmapped
    ...    UNKNOWN: Status: 'unknown', Role: 'unknown'
    ...    6
    ...    --snmp-community=network/efficientip/snmp/missing-status
    ...    UNKNOWN: No data!
